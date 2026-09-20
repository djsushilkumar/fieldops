import '../entities/activity_log_entity.dart';
import '../entities/field_technician_location.dart';
import '../entities/operations_metrics.dart';

abstract class DashboardRepository {
  Future<OperationsMetrics> getOperationsMetrics(String organizationId);
  Future<List<FieldTechnicianLocation>> getLiveTechnicianLocations(String organizationId);
  Future<List<ActivityLogEntity>> getRecentActivityLogs(String organizationId, {int limit = 20});
}
