import '../entities/export_type.dart';
import '../entities/field_operations_report.dart';

abstract class ReportsRepository {
  Future<FieldOperationsReport> getOperationsReport({
    required DateTime startDate,
    required DateTime endDate,
    String? technicianId,
  });

  Future<String> generateCsvExport({
    required ExportType type,
    required DateTime startDate,
    required DateTime endDate,
    String? technicianId,
  });
}
