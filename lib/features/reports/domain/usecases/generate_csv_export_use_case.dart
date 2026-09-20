import '../entities/export_type.dart';
import '../repositories/reports_repository.dart';

class GenerateCsvExportUseCase {
  final ReportsRepository repository;

  GenerateCsvExportUseCase(this.repository);

  Future<String> call({
    required ExportType type,
    required DateTime startDate,
    required DateTime endDate,
    String? technicianId,
  }) {
    return repository.generateCsvExport(
      type: type,
      startDate: startDate,
      endDate: endDate,
      technicianId: technicianId,
    );
  }
}
