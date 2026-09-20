import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/location/gps_distance_engine.dart';
import '../../../../core/location/location_coordinates.dart';
import '../../../../core/location/location_service.dart';
import '../../../customers/domain/entities/location_entity.dart';
import '../../data/datasources/mock_visit_remote_datasource.dart';
import '../../data/datasources/visit_local_datasource.dart';
import '../../data/datasources/visit_remote_datasource.dart';
import '../../data/repositories/visit_repository_impl.dart';
import '../../domain/entities/visit_entity.dart';
import '../../domain/repositories/visit_repository.dart';
import '../../domain/usecases/get_active_visit_use_case.dart';
import '../../domain/usecases/get_visits_use_case.dart';
import '../../domain/usecases/visit_check_in_use_case.dart';
import '../../domain/usecases/visit_check_out_use_case.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final visitLocalDataSourceProvider = Provider<VisitLocalDataSource>((ref) {
  return VisitLocalDataSourceImpl();
});

final visitRemoteDataSourceProvider = Provider<VisitRemoteDataSource>((ref) {
  final supabase = SupabaseConfig.client;
  if (supabase != null) {
    return SupabaseVisitRemoteDataSource(supabase);
  }
  return MockVisitRemoteDataSource();
});

final visitRepositoryProvider = Provider<VisitRepository>((ref) {
  final remote = ref.watch(visitRemoteDataSourceProvider);
  final local = ref.watch(visitLocalDataSourceProvider);
  return VisitRepositoryImpl(
    remoteDataSource: remote,
    localDataSource: local,
  );
});

final getVisitsUseCaseProvider = Provider<GetVisitsUseCase>((ref) {
  return GetVisitsUseCase(ref.watch(visitRepositoryProvider));
});

final getActiveVisitUseCaseProvider = Provider<GetActiveVisitUseCase>((ref) {
  return GetActiveVisitUseCase(ref.watch(visitRepositoryProvider));
});

final visitCheckInUseCaseProvider = Provider<VisitCheckInUseCase>((ref) {
  return VisitCheckInUseCase(ref.watch(visitRepositoryProvider));
});

final visitCheckOutUseCaseProvider = Provider<VisitCheckOutUseCase>((ref) {
  return VisitCheckOutUseCase(ref.watch(visitRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Visit List State & Notifier
// ---------------------------------------------------------------------------

enum VisitListStatus { initial, loading, success, error }

class VisitListState {
  final VisitListStatus status;
  final List<VisitEntity> visits;
  final DateTime? filterDate;
  final String? filterUserId;
  final String? errorMessage;

  const VisitListState({
    this.status = VisitListStatus.initial,
    this.visits = const [],
    this.filterDate,
    this.filterUserId,
    this.errorMessage,
  });

  VisitListState copyWith({
    VisitListStatus? status,
    List<VisitEntity>? visits,
    DateTime? filterDate,
    String? filterUserId,
    String? errorMessage,
  }) {
    return VisitListState(
      status: status ?? this.status,
      visits: visits ?? this.visits,
      filterDate: filterDate ?? this.filterDate,
      filterUserId: filterUserId ?? this.filterUserId,
      errorMessage: errorMessage,
    );
  }
}

class VisitListNotifier extends StateNotifier<VisitListState> {
  final GetVisitsUseCase _getVisitsUseCase;

  VisitListNotifier({
    required GetVisitsUseCase getVisitsUseCase,
  })  : _getVisitsUseCase = getVisitsUseCase,
        super(const VisitListState()) {
    loadVisits();
  }

  Future<void> loadVisits({String? userId, DateTime? date}) async {
    state = state.copyWith(
      status: VisitListStatus.loading,
      filterUserId: userId,
      filterDate: date,
    );
    try {
      final list = await _getVisitsUseCase(
        userId: userId ?? state.filterUserId,
        date: date ?? state.filterDate,
      );
      if (!mounted) return;
      state = state.copyWith(
        status: VisitListStatus.success,
        visits: list,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        status: VisitListStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    try {
      final list = await _getVisitsUseCase(
        userId: state.filterUserId,
        date: state.filterDate,
      );
      if (!mounted) return;
      state = state.copyWith(
        status: VisitListStatus.success,
        visits: list,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        status: VisitListStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}

final visitListNotifierProvider =
    StateNotifierProvider<VisitListNotifier, VisitListState>((ref) {
  return VisitListNotifier(
    getVisitsUseCase: ref.watch(getVisitsUseCaseProvider),
  );
});

// ---------------------------------------------------------------------------
// Visit Execution State & Notifier (for field task GPS check-in/out)
// ---------------------------------------------------------------------------

class VisitExecutionState {
  final bool isLoading;
  final bool isCheckingIn;
  final bool isCheckingOut;
  final VisitEntity? activeVisit;
  final LocationCoordinates? currentCoordinates;
  final GpsRadiusCheckResult? radiusResult;
  final String? errorMessage;
  final String? successMessage;

  const VisitExecutionState({
    this.isLoading = false,
    this.isCheckingIn = false,
    this.isCheckingOut = false,
    this.activeVisit,
    this.currentCoordinates,
    this.radiusResult,
    this.errorMessage,
    this.successMessage,
  });

  VisitExecutionState copyWith({
    bool? isLoading,
    bool? isCheckingIn,
    bool? isCheckingOut,
    VisitEntity? activeVisit,
    LocationCoordinates? currentCoordinates,
    GpsRadiusCheckResult? radiusResult,
    String? errorMessage,
    String? successMessage,
    bool clearActiveVisit = false,
  }) {
    return VisitExecutionState(
      isLoading: isLoading ?? this.isLoading,
      isCheckingIn: isCheckingIn ?? this.isCheckingIn,
      isCheckingOut: isCheckingOut ?? this.isCheckingOut,
      activeVisit: clearActiveVisit ? null : (activeVisit ?? this.activeVisit),
      currentCoordinates: currentCoordinates ?? this.currentCoordinates,
      radiusResult: radiusResult ?? this.radiusResult,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

class VisitExecutionNotifier extends StateNotifier<VisitExecutionState> {
  final String taskId;
  final LocationEntity? targetLocation;
  final LocationService _locationService;
  final GetActiveVisitUseCase _getActiveVisitUseCase;
  final VisitCheckInUseCase _visitCheckInUseCase;
  final VisitCheckOutUseCase _visitCheckOutUseCase;

  VisitExecutionNotifier({
    required this.taskId,
    this.targetLocation,
    required LocationService locationService,
    required GetActiveVisitUseCase getActiveVisitUseCase,
    required VisitCheckInUseCase visitCheckInUseCase,
    required VisitCheckOutUseCase visitCheckOutUseCase,
  })  : _locationService = locationService,
        _getActiveVisitUseCase = getActiveVisitUseCase,
        _visitCheckInUseCase = visitCheckInUseCase,
        _visitCheckOutUseCase = visitCheckOutUseCase,
        super(const VisitExecutionState()) {
    init();
  }

  Future<void> init() async {
    state = state.copyWith(isLoading: true);
    try {
      final active = await _getActiveVisitUseCase(taskId: taskId);
      final coords = await _locationService.getCurrentLocation();

      GpsRadiusCheckResult? radiusCheck;
      if (targetLocation != null) {
        radiusCheck = GpsDistanceEngine.checkRadius(
          currentLatitude: coords.latitude,
          currentLongitude: coords.longitude,
          targetLatitude: targetLocation!.latitude,
          targetLongitude: targetLocation!.longitude,
          radiusMeters: targetLocation!.radiusMeters,
        );
      }

      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        activeVisit: active,
        currentCoordinates: coords,
        radiusResult: radiusCheck,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> refreshGps() async {
    try {
      final coords = await _locationService.getCurrentLocation();
      GpsRadiusCheckResult? radiusCheck;
      if (targetLocation != null) {
        radiusCheck = GpsDistanceEngine.checkRadius(
          currentLatitude: coords.latitude,
          currentLongitude: coords.longitude,
          targetLatitude: targetLocation!.latitude,
          targetLongitude: targetLocation!.longitude,
          radiusMeters: targetLocation!.radiusMeters,
        );
      }
      if (!mounted) return;
      state = state.copyWith(
        currentCoordinates: coords,
        radiusResult: radiusCheck,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(errorMessage: 'Failed to acquire GPS: $e');
    }
  }

  Future<VisitEntity> checkIn({String? notes, bool enforceRadius = true}) async {
    state = state.copyWith(isCheckingIn: true, errorMessage: null);
    try {
      final coords = await _locationService.getCurrentLocation();

      LocationEntity loc;
      if (targetLocation != null) {
        loc = targetLocation!;
      } else {
        // Fallback default location if not specified
        final now = DateTime.now();
        loc = LocationEntity(
          id: 'loc-default',
          organizationId: 'org-001',
          name: 'Customer Site',
          latitude: coords.latitude,
          longitude: coords.longitude,
          radiusMeters: 500,
          createdAt: now,
          updatedAt: now,
        );
      }

      final visit = await _visitCheckInUseCase(
        taskId: taskId,
        location: loc,
        currentLatitude: coords.latitude,
        currentLongitude: coords.longitude,
        notes: notes,
        enforceRadius: enforceRadius,
      );

      if (!mounted) return visit;
      state = state.copyWith(
        isCheckingIn: false,
        activeVisit: visit,
        successMessage: 'Successfully checked in via GPS!',
      );
      return visit;
    } catch (e) {
      if (!mounted) rethrow;
      state = state.copyWith(
        isCheckingIn: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      rethrow;
    }
  }

  Future<VisitEntity> checkOut({String? notes}) async {
    final active = state.activeVisit;
    if (active == null) {
      throw Exception('No active visit to check out');
    }

    state = state.copyWith(isCheckingOut: true, errorMessage: null);
    try {
      final coords = await _locationService.getCurrentLocation();
      final visit = await _visitCheckOutUseCase(
        visitId: active.id,
        latitude: coords.latitude,
        longitude: coords.longitude,
        notes: notes,
      );

      if (!mounted) return visit;
      state = state.copyWith(
        isCheckingOut: false,
        clearActiveVisit: true,
        successMessage: 'Successfully checked out! Visit duration recorded.',
      );
      return visit;
    } catch (e) {
      if (!mounted) rethrow;
      state = state.copyWith(
        isCheckingOut: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      rethrow;
    }
  }
}

class VisitExecutionParams {
  final String taskId;
  final LocationEntity? targetLocation;

  const VisitExecutionParams({
    required this.taskId,
    this.targetLocation,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VisitExecutionParams &&
        other.taskId == taskId &&
        other.targetLocation?.id == targetLocation?.id;
  }

  @override
  int get hashCode => taskId.hashCode ^ (targetLocation?.id.hashCode ?? 0);
}

final visitExecutionNotifierProvider = StateNotifierProvider.family<
    VisitExecutionNotifier, VisitExecutionState, VisitExecutionParams>((ref, params) {
  return VisitExecutionNotifier(
    taskId: params.taskId,
    targetLocation: params.targetLocation,
    locationService: ref.watch(locationServiceProvider),
    getActiveVisitUseCase: ref.watch(getActiveVisitUseCaseProvider),
    visitCheckInUseCase: ref.watch(visitCheckInUseCaseProvider),
    visitCheckOutUseCase: ref.watch(visitCheckOutUseCaseProvider),
  );
});
