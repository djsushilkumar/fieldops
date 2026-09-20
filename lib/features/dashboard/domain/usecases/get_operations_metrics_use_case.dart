import '../entities/operations_metrics.dart';
import '../repositories/dashboard_repository.dart';

class GetOperationsMetricsUseCase {
  final DashboardRepository repository;

  GetOperationsMetricsUseCase(this.repository);

  Future<OperationsMetrics> call(String organizationId) {
    return repository.getOperationsMetrics(organizationId);
  }
}
