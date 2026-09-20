import 'package:flutter_test/flutter_test.dart';
import 'package:field_ops/features/reports/domain/entities/export_type.dart';
import 'package:field_ops/features/reports/domain/entities/field_operations_report.dart';
import 'package:field_ops/features/reports/domain/entities/report_date_range.dart';
import 'package:field_ops/features/reports/domain/entities/technician_performance.dart';
import 'package:field_ops/features/reports/domain/repositories/reports_repository.dart';
import 'package:field_ops/features/reports/domain/usecases/generate_csv_export_use_case.dart';
import 'package:field_ops/features/reports/domain/usecases/get_field_operations_report_use_case.dart';
import 'package:field_ops/features/reports/presentation/controllers/reports_controller.dart';

class MockReportsRepository implements ReportsRepository {
  DateTime? lastQueryStart;
  DateTime? lastQueryEnd;
  String? lastTechnicianId;
  ExportType? lastExportType;

  @override
  Future<FieldOperationsReport> getOperationsReport({
    required DateTime startDate,
    required DateTime endDate,
    String? technicianId,
  }) async {
    lastQueryStart = startDate;
    lastQueryEnd = endDate;
    lastTechnicianId = technicianId;

    return FieldOperationsReport(
      dateRange: ReportDateRange(preset: DateRangePreset.thisWeek, startDate: startDate, endDate: endDate),
      totalTasksCreated: 20,
      totalTasksCompleted: 18,
      taskCompletionRate: 90.0,
      onTimeCompletionRate: 95.0,
      totalVisits: 22,
      completedVisits: 20,
      activeVisits: 2,
      avgVisitDurationMinutes: 42.0,
      uniqueCustomersVisited: 10,
      totalAttendanceHours: 80.0,
      activeTechniciansCount: 2,
      technicianBreakdowns: [
        const TechnicianPerformance(
          userId: 'tech-1',
          userName: 'Alex Rivera',
          assignedTasksCount: 12,
          completedTasksCount: 11,
          completionRate: 91.7,
        ),
      ],
      generatedAt: DateTime.now(),
    );
  }

  @override
  Future<String> generateCsvExport({
    required ExportType type,
    required DateTime startDate,
    required DateTime endDate,
    String? technicianId,
  }) async {
    lastExportType = type;
    return 'id,title,status\n1,Task A,Completed';
  }
}

void main() {
  late MockReportsRepository repository;
  late GetFieldOperationsReportUseCase getReportUseCase;
  late GenerateCsvExportUseCase exportUseCase;
  late ReportsController controller;

  setUp(() {
    repository = MockReportsRepository();
    getReportUseCase = GetFieldOperationsReportUseCase(repository);
    exportUseCase = GenerateCsvExportUseCase(repository);
    controller = ReportsController(
      getReportUseCase: getReportUseCase,
      exportCsvUseCase: exportUseCase,
    );
  });

  group('ReportsController Unit Tests', () {
    test('initial state loads report on creation', () async {
      // Controller automatically invokes loadReport in constructor
      await Future.delayed(const Duration(milliseconds: 20));

      expect(controller.state.isLoading, false);
      expect(controller.state.report, isNotNull);
      expect(controller.state.report!.totalTasksCreated, 20);
      expect(controller.state.report!.taskCompletionRate, 90.0);
    });

    test('setDateRangePreset updates date range and triggers reload', () async {
      await Future.delayed(const Duration(milliseconds: 10));
      controller.setDateRangePreset(DateRangePreset.today);

      expect(controller.state.dateRange.preset, DateRangePreset.today);
      await Future.delayed(const Duration(milliseconds: 10));
      expect(repository.lastQueryStart, controller.state.dateRange.startDate);
    });

    test('setCustomDateRange updates date range to custom and reloads', () async {
      final start = DateTime(2026, 9, 1);
      final end = DateTime(2026, 9, 10);
      controller.setCustomDateRange(start, end);

      expect(controller.state.dateRange.preset, DateRangePreset.custom);
      expect(controller.state.dateRange.startDate.day, 1);
      expect(controller.state.dateRange.endDate.day, 10);
    });

    test('setTechnicianFilter updates selected technician and filters report', () async {
      controller.setTechnicianFilter('tech-1');
      expect(controller.state.selectedTechnicianId, 'tech-1');

      await Future.delayed(const Duration(milliseconds: 10));
      expect(repository.lastTechnicianId, 'tech-1');

      // Clear filter
      controller.setTechnicianFilter(null);
      expect(controller.state.selectedTechnicianId, isNull);
    });

    test('exportCsv sets isExporting, saves last export and returns CSV', () async {
      final csv = await controller.exportCsv(ExportType.tasks);

      expect(csv, 'id,title,status\n1,Task A,Completed');
      expect(controller.state.isExporting, false);
      expect(controller.state.lastExportType, ExportType.tasks);
      expect(controller.state.lastExportedContent, csv);
    });
  });
}
