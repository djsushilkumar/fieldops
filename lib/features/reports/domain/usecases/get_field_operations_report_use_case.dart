import '../entities/field_operations_report.dart';
import '../repositories/reports_repository.dart';

class GetFieldOperationsReportUseCase {
  final ReportsRepository repository;

  GetFieldOperationsReportUseCase(this.repository);

  Future<FieldOperationsReport> call({
    required DateTime startDate,
    required DateTime endDate,
    String? technicianId,
  }) {
    return repository.getOperationsReport(
      startDate: startDate,
      endDate: endDate,
      technicianId: technicianId,
    );
  }
}
