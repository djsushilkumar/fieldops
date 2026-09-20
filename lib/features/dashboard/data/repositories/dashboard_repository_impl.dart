import '../../domain/entities/activity_log_entity.dart';
import '../../domain/entities/field_technician_location.dart';
import '../../domain/entities/operations_metrics.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;

  DashboardRepositoryImpl({required this.remoteDataSource});

  @override
  Future<OperationsMetrics> getOperationsMetrics(String organizationId) async {
    final model = await remoteDataSource.getOperationsMetrics(organizationId);
    return model.toEntity();
  }

  @override
  Future<List<FieldTechnicianLocation>> getLiveTechnicianLocations(String organizationId) async {
    final models = await remoteDataSource.getLiveTechnicianLocations(organizationId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<ActivityLogEntity>> getRecentActivityLogs(
    String organizationId, {
    int limit = 20,
  }) async {
    final models = await remoteDataSource.getRecentActivityLogs(
      organizationId,
      limit: limit,
    );
    return models.map((m) => m.toEntity()).toList();
  }
}
