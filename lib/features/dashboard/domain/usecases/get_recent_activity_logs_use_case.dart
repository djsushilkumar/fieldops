import '../entities/activity_log_entity.dart';
import '../repositories/dashboard_repository.dart';

class GetRecentActivityLogsUseCase {
  final DashboardRepository repository;

  GetRecentActivityLogsUseCase(this.repository);

  Future<List<ActivityLogEntity>> call(String organizationId, {int limit = 20}) {
    return repository.getRecentActivityLogs(organizationId, limit: limit);
  }
}
