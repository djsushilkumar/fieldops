import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/location/location_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/datasources/attendance_local_datasource.dart';
import '../../data/datasources/attendance_remote_datasource.dart';
import '../../data/datasources/mock_attendance_remote_datasource.dart';
import '../../data/repositories/attendance_repository_impl.dart';
import '../../domain/entities/attendance_entity.dart';
import '../../domain/entities/attendance_status.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../domain/usecases/attendance_check_in_use_case.dart';
import '../../domain/usecases/attendance_check_out_use_case.dart';
import '../../domain/usecases/get_attendance_history_use_case.dart';
import '../../domain/usecases/get_team_attendance_use_case.dart';
import '../../domain/usecases/get_today_attendance_use_case.dart';

// ============================================================================
// Dependency Providers
// ============================================================================

final attendanceLocalDataSourceProvider = Provider<AttendanceLocalDataSource>((ref) {
  return AttendanceLocalDataSourceImpl();
});

final attendanceRemoteDataSourceProvider = Provider<AttendanceRemoteDataSource>((ref) {
  final supabase = SupabaseConfig.client;
  if (supabase != null) {
    return SupabaseAttendanceRemoteDataSource(supabase);
  }
  return MockAttendanceRemoteDataSource();
});

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepositoryImpl(
    remoteDataSource: ref.watch(attendanceRemoteDataSourceProvider),
    localDataSource: ref.watch(attendanceLocalDataSourceProvider),
  );
});

final getTodayAttendanceUseCaseProvider = Provider<GetTodayAttendanceUseCase>((ref) {
  return GetTodayAttendanceUseCase(ref.watch(attendanceRepositoryProvider));
});

final getAttendanceHistoryUseCaseProvider = Provider<GetAttendanceHistoryUseCase>((ref) {
  return GetAttendanceHistoryUseCase(ref.watch(attendanceRepositoryProvider));
});

final getTeamAttendanceUseCaseProvider = Provider<GetTeamAttendanceUseCase>((ref) {
  return GetTeamAttendanceUseCase(ref.watch(attendanceRepositoryProvider));
});

final attendanceCheckInUseCaseProvider = Provider<AttendanceCheckInUseCase>((ref) {
  return AttendanceCheckInUseCase(
    repository: ref.watch(attendanceRepositoryProvider),
    locationService: ref.watch(locationServiceProvider),
  );
});

final attendanceCheckOutUseCaseProvider = Provider<AttendanceCheckOutUseCase>((ref) {
  return AttendanceCheckOutUseCase(
    repository: ref.watch(attendanceRepositoryProvider),
    locationService: ref.watch(locationServiceProvider),
  );
});

// ============================================================================
// Today Attendance Notifier & State
// ============================================================================

enum TodayAttendanceStatus { initial, loading, ready, error }

class TodayAttendanceState {
  final TodayAttendanceStatus status;
  final AttendanceEntity? attendance;
  final Duration elapsedDuration;
  final bool isActionInProgress;
  final String? errorMessage;

  const TodayAttendanceState({
    this.status = TodayAttendanceStatus.initial,
    this.attendance,
    this.elapsedDuration = Duration.zero,
    this.isActionInProgress = false,
    this.errorMessage,
  });

  bool get isCheckedIn => attendance != null && attendance!.isCheckedIn;
  bool get isCompleted => attendance != null && attendance!.isCheckedOut;
  bool get isNotCheckedIn => attendance == null;

  TodayAttendanceState copyWith({
    TodayAttendanceStatus? status,
    AttendanceEntity? Function()? attendance,
    Duration? elapsedDuration,
    bool? isActionInProgress,
    String? Function()? errorMessage,
  }) {
    return TodayAttendanceState(
      status: status ?? this.status,
      attendance: attendance != null ? attendance() : this.attendance,
      elapsedDuration: elapsedDuration ?? this.elapsedDuration,
      isActionInProgress: isActionInProgress ?? this.isActionInProgress,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

class TodayAttendanceNotifier extends StateNotifier<TodayAttendanceState> {
  final GetTodayAttendanceUseCase _getTodayAttendanceUseCase;
  final AttendanceCheckInUseCase _checkInUseCase;
  final AttendanceCheckOutUseCase _checkOutUseCase;
  final Ref _ref;
  Timer? _ticker;

  TodayAttendanceNotifier(
    this._getTodayAttendanceUseCase,
    this._checkInUseCase,
    this._checkOutUseCase,
    this._ref,
  ) : super(const TodayAttendanceState()) {
    loadTodayAttendance();
  }

  Future<void> loadTodayAttendance() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = state.copyWith(status: TodayAttendanceStatus.ready);
      return;
    }

    state = state.copyWith(status: TodayAttendanceStatus.loading, errorMessage: () => null);
    try {
      final record = await _getTodayAttendanceUseCase(userId: user.id);
      final elapsed = record != null ? record.workingDuration : Duration.zero;
      state = state.copyWith(
        status: TodayAttendanceStatus.ready,
        attendance: () => record,
        elapsedDuration: elapsed,
      );
      _updateTicker();
    } catch (e) {
      state = state.copyWith(
        status: TodayAttendanceStatus.error,
        errorMessage: () => e.toString(),
      );
    }
  }

  void _updateTicker() {
    _ticker?.cancel();
    if (state.isCheckedIn) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (state.attendance != null && state.isCheckedIn) {
          state = state.copyWith(
            elapsedDuration: state.attendance!.workingDuration,
          );
        }
      });
    }
  }

  Future<bool> checkIn({double? latitude, double? longitude}) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = state.copyWith(errorMessage: () => 'User not authenticated');
      return false;
    }

    state = state.copyWith(isActionInProgress: true, errorMessage: () => null);
    try {
      final record = await _checkInUseCase(
        userId: user.id,
        organizationId: user.organizationId,
        latitude: latitude,
        longitude: longitude,
      );
      state = state.copyWith(
        status: TodayAttendanceStatus.ready,
        attendance: () => record,
        isActionInProgress: false,
        elapsedDuration: Duration.zero,
      );
      _updateTicker();
      return true;
    } catch (e) {
      state = state.copyWith(
        isActionInProgress: false,
        errorMessage: () => e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> checkOut({double? latitude, double? longitude}) async {
    final record = state.attendance;
    if (record == null) {
      state = state.copyWith(errorMessage: () => 'No active attendance record to check out');
      return false;
    }

    state = state.copyWith(isActionInProgress: true, errorMessage: () => null);
    try {
      final updated = await _checkOutUseCase(
        attendanceId: record.id,
        latitude: latitude,
        longitude: longitude,
      );
      _ticker?.cancel();
      state = state.copyWith(
        status: TodayAttendanceStatus.ready,
        attendance: () => updated,
        isActionInProgress: false,
        elapsedDuration: updated.workingDuration,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isActionInProgress: false,
        errorMessage: () => e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final todayAttendanceNotifierProvider =
    StateNotifierProvider<TodayAttendanceNotifier, TodayAttendanceState>((ref) {
  return TodayAttendanceNotifier(
    ref.watch(getTodayAttendanceUseCaseProvider),
    ref.watch(attendanceCheckInUseCaseProvider),
    ref.watch(attendanceCheckOutUseCaseProvider),
    ref,
  );
});

// ============================================================================
// Attendance History Notifier & State
// ============================================================================

enum AttendanceHistoryStatus { initial, loading, ready, error }

class AttendanceHistoryState {
  final AttendanceHistoryStatus status;
  final List<AttendanceEntity> records;
  final String? errorMessage;

  const AttendanceHistoryState({
    this.status = AttendanceHistoryStatus.initial,
    this.records = const [],
    this.errorMessage,
  });

  int get totalDaysPresent =>
      records.where((r) => r.status == AttendanceStatus.present).length;

  int get totalMinutesWorked => records.fold<int>(
        0,
        (sum, r) => sum + (r.totalMinutes ?? r.workingDuration.inMinutes),
      );

  String get formattedTotalHours {
    final hours = totalMinutesWorked ~/ 60;
    final minutes = totalMinutesWorked % 60;
    return '${hours}h ${minutes}m';
  }

  AttendanceHistoryState copyWith({
    AttendanceHistoryStatus? status,
    List<AttendanceEntity>? records,
    String? Function()? errorMessage,
  }) {
    return AttendanceHistoryState(
      status: status ?? this.status,
      records: records ?? this.records,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

class AttendanceHistoryNotifier extends StateNotifier<AttendanceHistoryState> {
  final GetAttendanceHistoryUseCase _getHistoryUseCase;
  final Ref _ref;

  AttendanceHistoryNotifier(this._getHistoryUseCase, this._ref)
      : super(const AttendanceHistoryState()) {
    loadHistory();
  }

  Future<void> loadHistory({DateTime? startDate, DateTime? endDate}) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = state.copyWith(status: AttendanceHistoryStatus.ready);
      return;
    }

    state = state.copyWith(status: AttendanceHistoryStatus.loading, errorMessage: () => null);
    try {
      final records = await _getHistoryUseCase(
        userId: user.id,
        startDate: startDate,
        endDate: endDate,
      );
      state = state.copyWith(
        status: AttendanceHistoryStatus.ready,
        records: records,
      );
    } catch (e) {
      state = state.copyWith(
        status: AttendanceHistoryStatus.error,
        errorMessage: () => e.toString(),
      );
    }
  }
}

final attendanceHistoryNotifierProvider =
    StateNotifierProvider<AttendanceHistoryNotifier, AttendanceHistoryState>((ref) {
  return AttendanceHistoryNotifier(
    ref.watch(getAttendanceHistoryUseCaseProvider),
    ref,
  );
});

// ============================================================================
// Team Attendance Notifier & State (Manager / Admin view)
// ============================================================================

enum TeamAttendanceStatus { initial, loading, ready, error }

class TeamAttendanceState {
  final TeamAttendanceStatus status;
  final DateTime selectedDate;
  final List<AttendanceEntity> records;
  final AttendanceStatus? statusFilter;
  final String? errorMessage;

  TeamAttendanceState({
    this.status = TeamAttendanceStatus.initial,
    DateTime? selectedDate,
    this.records = const [],
    this.statusFilter,
    this.errorMessage,
  }) : selectedDate = selectedDate ?? DateTime.now();

  List<AttendanceEntity> get filteredRecords {
    if (statusFilter == null) return records;
    return records.where((r) => r.status == statusFilter).toList();
  }

  int get totalEmployees => records.length;
  int get presentCount =>
      records.where((r) => r.status == AttendanceStatus.present).length;
  int get halfDayCount =>
      records.where((r) => r.status == AttendanceStatus.halfDay).length;
  int get onLeaveCount =>
      records.where((r) => r.status == AttendanceStatus.onLeave).length;
  int get absentCount =>
      records.where((r) => r.status == AttendanceStatus.absent).length;

  TeamAttendanceState copyWith({
    TeamAttendanceStatus? status,
    DateTime? selectedDate,
    List<AttendanceEntity>? records,
    AttendanceStatus? Function()? statusFilter,
    String? Function()? errorMessage,
  }) {
    return TeamAttendanceState(
      status: status ?? this.status,
      selectedDate: selectedDate ?? this.selectedDate,
      records: records ?? this.records,
      statusFilter: statusFilter != null ? statusFilter() : this.statusFilter,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

class TeamAttendanceNotifier extends StateNotifier<TeamAttendanceState> {
  final GetTeamAttendanceUseCase _getTeamAttendanceUseCase;
  final Ref _ref;

  TeamAttendanceNotifier(this._getTeamAttendanceUseCase, this._ref)
      : super(TeamAttendanceState()) {
    loadTeamAttendance();
  }

  void selectDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
    loadTeamAttendance();
  }

  void setFilter(AttendanceStatus? filter) {
    state = state.copyWith(statusFilter: () => filter);
  }

  Future<void> loadTeamAttendance() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = state.copyWith(status: TeamAttendanceStatus.ready);
      return;
    }

    state = state.copyWith(status: TeamAttendanceStatus.loading, errorMessage: () => null);
    try {
      final records = await _getTeamAttendanceUseCase(
        organizationId: user.organizationId,
        date: state.selectedDate,
      );
      state = state.copyWith(
        status: TeamAttendanceStatus.ready,
        records: records,
      );
    } catch (e) {
      state = state.copyWith(
        status: TeamAttendanceStatus.error,
        errorMessage: () => e.toString(),
      );
    }
  }
}

final teamAttendanceNotifierProvider =
    StateNotifierProvider<TeamAttendanceNotifier, TeamAttendanceState>((ref) {
  return TeamAttendanceNotifier(
    ref.watch(getTeamAttendanceUseCaseProvider),
    ref,
  );
});
