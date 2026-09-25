import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/location/location_coordinates.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/datasources/beat_local_datasource.dart';
import '../../data/datasources/beat_remote_datasource.dart';
import '../../data/repositories/beat_repository_impl.dart';
import '../../domain/entities/beat_execution_entity.dart';
import '../../domain/entities/beat_plan_entity.dart';
import '../../domain/repositories/beat_repository.dart';
import '../../domain/services/route_optimization_engine.dart';
import '../../domain/usecases/get_beat_plans_use_case.dart';
import '../../domain/usecases/get_today_beat_use_case.dart';
import '../../domain/usecases/start_beat_execution_use_case.dart';
import '../../domain/usecases/update_stop_visit_use_case.dart';

// --- Data Layer Providers ---

final beatLocalDataSourceProvider = Provider<BeatLocalDataSource>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return BeatLocalDataSourceImpl(db);
});

final beatRemoteDataSourceProvider = Provider<BeatRemoteDataSource>((ref) {
  return MockBeatRemoteDataSource();
});

final beatRepositoryProvider = Provider<BeatRepository>((ref) {
  final local = ref.watch(beatLocalDataSourceProvider);
  final remote = ref.watch(beatRemoteDataSourceProvider);
  return BeatRepositoryImpl(localDataSource: local, remoteDataSource: remote);
});

// --- Use Case Providers ---

final getBeatPlansUseCaseProvider = Provider<GetBeatPlansUseCase>((ref) {
  final repo = ref.watch(beatRepositoryProvider);
  return GetBeatPlansUseCase(repo);
});

final getTodayBeatUseCaseProvider = Provider<GetTodayBeatUseCase>((ref) {
  final repo = ref.watch(beatRepositoryProvider);
  return GetTodayBeatUseCase(repo);
});

final startBeatExecutionUseCaseProvider = Provider<StartBeatExecutionUseCase>((ref) {
  final repo = ref.watch(beatRepositoryProvider);
  return StartBeatExecutionUseCase(repo);
});

final updateStopVisitUseCaseProvider = Provider<UpdateStopVisitUseCase>((ref) {
  final repo = ref.watch(beatRepositoryProvider);
  return UpdateStopVisitUseCase(repo);
});

// --- State & Notifiers ---

class TodayBeatState {
  final bool isLoading;
  final BeatPlanEntity? assignedPlan;
  final BeatExecutionEntity? execution;
  final RouteOptimizationResult? optimizationResult;
  final String? errorMessage;
  final String? successMessage;

  const TodayBeatState({
    this.isLoading = false,
    this.assignedPlan,
    this.execution,
    this.optimizationResult,
    this.errorMessage,
    this.successMessage,
  });

  bool get hasActiveExecution => execution != null && execution!.status == BeatExecutionStatus.inProgress;
  bool get isExecutionCompleted => execution != null && execution!.status == BeatExecutionStatus.completed;

  TodayBeatState copyWith({
    bool? isLoading,
    BeatPlanEntity? assignedPlan,
    BeatExecutionEntity? execution,
    RouteOptimizationResult? optimizationResult,
    String? errorMessage,
    String? successMessage,
  }) {
    return TodayBeatState(
      isLoading: isLoading ?? this.isLoading,
      assignedPlan: assignedPlan ?? this.assignedPlan,
      execution: execution ?? this.execution,
      optimizationResult: optimizationResult ?? this.optimizationResult,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

class TodayBeatNotifier extends StateNotifier<TodayBeatState> {
  final GetBeatPlansUseCase _getPlansUseCase;
  final GetTodayBeatUseCase _getTodayBeatUseCase;
  final StartBeatExecutionUseCase _startExecutionUseCase;
  final UpdateStopVisitUseCase _updateStopVisitUseCase;
  final BeatRepository _repository;
  final String? _userId;
  final String? _userName;

  TodayBeatNotifier({
    required GetBeatPlansUseCase getPlansUseCase,
    required GetTodayBeatUseCase getTodayBeatUseCase,
    required StartBeatExecutionUseCase startExecutionUseCase,
    required UpdateStopVisitUseCase updateStopVisitUseCase,
    required BeatRepository repository,
    String? userId,
    String? userName,
  })  : _getPlansUseCase = getPlansUseCase,
        _getTodayBeatUseCase = getTodayBeatUseCase,
        _startExecutionUseCase = startExecutionUseCase,
        _updateStopVisitUseCase = updateStopVisitUseCase,
        _repository = repository,
        _userId = userId,
        _userName = userName,
        super(const TodayBeatState()) {
    loadTodayBeat();
  }

  String _todayDateStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> loadTodayBeat() async {
    final userId = _userId;
    if (userId == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final date = _todayDateStr();
      final execution = await _getTodayBeatUseCase(userId, date);

      final plans = await _getPlansUseCase(technicianId: userId, activeOnly: true);
      final assignedPlan = plans.isNotEmpty ? plans.first : null;

      state = state.copyWith(
        isLoading: false,
        assignedPlan: assignedPlan,
        execution: execution,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> startBeat() async {
    final userId = _userId;
    final userName = _userName;
    final plan = state.assignedPlan;
    if (userId == null || userName == null || plan == null) return false;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final date = _todayDateStr();
      final execution = await _startExecutionUseCase(
        beatPlanId: plan.id,
        userId: userId,
        userName: userName,
        date: date,
        stops: plan.stops,
      );

      state = state.copyWith(
        isLoading: false,
        execution: execution,
        successMessage: 'Beat itinerary started. Ready for customer visits.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  void optimizeCurrentRoute(LocationCoordinates currentLocation) {
    final currentStops = state.execution?.stops ?? state.assignedPlan?.stops ?? [];
    if (currentStops.isEmpty) return;

    final result = RouteOptimizationEngine.optimizeStopSequence(
      startLocation: currentLocation,
      stops: currentStops,
    );

    if (state.execution != null) {
      final updated = state.execution!.copyWith(stops: result.optimizedStops);
      state = state.copyWith(
        execution: updated,
        optimizationResult: result,
        successMessage: 'Route optimized! Saved ${result.savedDistanceKm} km (${result.savingsPercentage}%).',
      );
    } else {
      state = state.copyWith(
        optimizationResult: result,
        successMessage: 'Route optimized! Saved ${result.savedDistanceKm} km (${result.savingsPercentage}%).',
      );
    }
  }

  Future<void> checkInStop(String stopId) async {
    final execution = state.execution;
    if (execution == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updated = await _updateStopVisitUseCase(
        executionId: execution.id,
        stopId: stopId,
        isVisited: true,
        checkInTime: DateTime.now(),
      );
      state = state.copyWith(isLoading: false, execution: updated);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> completeBeat() async {
    final execution = state.execution;
    if (execution == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updated = await _repository.completeBeatExecution(execution.id);
      state = state.copyWith(
        isLoading: false,
        execution: updated,
        successMessage: 'Beat completed with ${updated.complianceRate.toStringAsFixed(1)}% compliance!',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final todayBeatNotifierProvider =
    StateNotifierProvider<TodayBeatNotifier, TodayBeatState>((ref) {
  final plansUseCase = ref.watch(getBeatPlansUseCaseProvider);
  final todayBeatUseCase = ref.watch(getTodayBeatUseCaseProvider);
  final startUseCase = ref.watch(startBeatExecutionUseCaseProvider);
  final updateStopUseCase = ref.watch(updateStopVisitUseCaseProvider);
  final repo = ref.watch(beatRepositoryProvider);
  final auth = ref.watch(authNotifierProvider);

  return TodayBeatNotifier(
    getPlansUseCase: plansUseCase,
    getTodayBeatUseCase: todayBeatUseCase,
    startExecutionUseCase: startUseCase,
    updateStopVisitUseCase: updateStopUseCase,
    repository: repo,
    userId: auth.user?.id,
    userName: auth.user?.name,
  );
});
