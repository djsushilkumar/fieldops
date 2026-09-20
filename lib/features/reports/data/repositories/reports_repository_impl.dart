import '../../domain/entities/export_type.dart';
import '../../domain/entities/field_operations_report.dart';
import '../../domain/repositories/reports_repository.dart';
import '../datasources/reports_local_datasource.dart';
import '../datasources/reports_remote_datasource.dart';
import '../services/csv_export_service.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  final ReportsRemoteDataSource remoteDataSource;
  final ReportsLocalDataSource localDataSource;
  final CsvExportService csvExportService;
  final String Function()? getOrgId;

  ReportsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    CsvExportService? csvExportService,
    this.getOrgId,
  }) : csvExportService = csvExportService ?? CsvExportService();

  String _resolveOrgId() {
    return getOrgId?.call() ?? 'org-demo-001';
  }

  @override
  Future<FieldOperationsReport> getOperationsReport({
    required DateTime startDate,
    required DateTime endDate,
    String? technicianId,
  }) async {
    final orgId = _resolveOrgId();
    try {
      return await remoteDataSource.getOperationsReport(
        organizationId: orgId,
        startDate: startDate,
        endDate: endDate,
        technicianId: technicianId,
      );
    } catch (_) {
      // Offline fallback: aggregate from local SQLite database
      return await localDataSource.getOperationsReport(
        organizationId: orgId,
        startDate: startDate,
        endDate: endDate,
        technicianId: technicianId,
      );
    }
  }

  @override
  Future<String> generateCsvExport({
    required ExportType type,
    required DateTime startDate,
    required DateTime endDate,
    String? technicianId,
  }) async {
    final orgId = _resolveOrgId();

    switch (type) {
      case ExportType.tasks:
        try {
          final tasks = await remoteDataSource.getTasksForRange(
            organizationId: orgId,
            startDate: startDate,
            endDate: endDate,
            technicianId: technicianId,
          );
          if (tasks.isNotEmpty) {
            return csvExportService.generateTasksCsv(tasks);
          }
        } catch (_) {}
        final localTasks = await localDataSource.getTasksForRange(
          organizationId: orgId,
          startDate: startDate,
          endDate: endDate,
          technicianId: technicianId,
        );
        return csvExportService.generateTasksCsv(localTasks);

      case ExportType.visits:
        try {
          final visits = await remoteDataSource.getVisitsForRange(
            organizationId: orgId,
            startDate: startDate,
            endDate: endDate,
            technicianId: technicianId,
          );
          if (visits.isNotEmpty) {
            return csvExportService.generateVisitsCsv(visits);
          }
        } catch (_) {}
        final localVisits = await localDataSource.getVisitsForRange(
          organizationId: orgId,
          startDate: startDate,
          endDate: endDate,
          technicianId: technicianId,
        );
        return csvExportService.generateVisitsCsv(localVisits);

      case ExportType.attendance:
        try {
          final attendance = await remoteDataSource.getAttendanceForRange(
            organizationId: orgId,
            startDate: startDate,
            endDate: endDate,
            technicianId: technicianId,
          );
          if (attendance.isNotEmpty) {
            return csvExportService.generateAttendanceCsv(attendance);
          }
        } catch (_) {}
        final localAttendance = await localDataSource.getAttendanceForRange(
          organizationId: orgId,
          startDate: startDate,
          endDate: endDate,
          technicianId: technicianId,
        );
        return csvExportService.generateAttendanceCsv(localAttendance);

      case ExportType.technicians:
        final report = await getOperationsReport(
          startDate: startDate,
          endDate: endDate,
          technicianId: technicianId,
        );
        return csvExportService.generateTechniciansCsv(report.technicianBreakdowns);

      case ExportType.executiveSummary:
        final report = await getOperationsReport(
          startDate: startDate,
          endDate: endDate,
          technicianId: technicianId,
        );
        return csvExportService.generateExecutiveSummaryCsv(report);
    }
  }
}
