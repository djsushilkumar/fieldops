import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/entities/activity_log_entity.dart';
import '../../domain/entities/field_technician_location.dart';
import '../../domain/entities/operations_metrics.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/usecases/get_live_technicians_use_case.dart';
import '../../domain/usecases/get_operations_metrics_use_case.dart';
import '../../domain/usecases/get_recent_activity_logs_use_case.dart';

// ============================================================================
// Providers
// ============================================================================

final dashboardRemoteDataSourceProvider = Provider<DashboardRemoteDataSource>((ref) {
  final supabase = SupabaseConfig.client;
  if (supabase != null) {
    return SupabaseDashboardRemoteDataSource(supabase);
  }
  return MockDashboardRemoteDataSource();
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(
    remoteDataSource: ref.watch(dashboardRemoteDataSourceProvider),
  );
});

final getOperationsMetricsUseCaseProvider = Provider<GetOperationsMetricsUseCase>((ref) {
  return GetOperationsMetricsUseCase(ref.watch(dashboardRepositoryProvider));
});

final getLiveTechniciansUseCaseProvider = Provider<GetLiveTechniciansUseCase>((ref) {
  return GetLiveTechniciansUseCase(ref.watch(dashboardRepositoryProvider));
});

final getRecentActivityLogsUseCaseProvider = Provider<GetRecentActivityLogsUseCase>((ref) {
  return GetRecentActivityLogsUseCase(ref.watch(dashboardRepositoryProvider));
});

// ============================================================================
// State & Controller
// ============================================================================

class DashboardState {
  final bool isLoading;
  final OperationsMetrics metrics;
  final List<FieldTechnicianLocation> technicians;
  final List<ActivityLogEntity> activityLogs;
  final String? errorMessage;
  final DateTime lastUpdated;

  DashboardState({
    this.isLoading = false,
    this.metrics = const OperationsMetrics(),
    this.technicians = const [],
    this.activityLogs = const [],
    this.errorMessage,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  DashboardState copyWith({
    bool? isLoading,
    OperationsMetrics? metrics,
    List<FieldTechnicianLocation>? technicians,
    List<ActivityLogEntity>? activityLogs,
    String? errorMessage,
    DateTime? lastUpdated,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      metrics: metrics ?? this.metrics,
      technicians: technicians ?? this.technicians,
      activityLogs: activityLogs ?? this.activityLogs,
      errorMessage: errorMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class DashboardController extends StateNotifier<DashboardState> {
  final Ref ref;

  DashboardController(this.ref) : super(DashboardState()) {
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final authState = ref.read(authNotifierProvider);
      final orgId = authState.user?.organizationId ?? 'org-acme-ops-001';

      final metricsUseCase = ref.read(getOperationsMetricsUseCaseProvider);
      final techUseCase = ref.read(getLiveTechniciansUseCaseProvider);
      final logsUseCase = ref.read(getRecentActivityLogsUseCaseProvider);

      final results = await Future.wait([
        metricsUseCase(orgId),
        techUseCase(orgId),
        logsUseCase(orgId),
      ]);

      state = state.copyWith(
        isLoading: false,
        metrics: results[0] as OperationsMetrics,
        technicians: results[1] as List<FieldTechnicianLocation>,
        activityLogs: results[2] as List<ActivityLogEntity>,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to refresh dashboard: $e',
      );
    }
  }

  Future<void> refresh() => loadDashboard();
}

final dashboardControllerProvider =
    StateNotifierProvider<DashboardController, DashboardState>((ref) {
  return DashboardController(ref);
});
