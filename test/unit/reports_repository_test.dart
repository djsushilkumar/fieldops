import 'package:flutter_test/flutter_test.dart';
import 'package:field_ops/features/attendance/domain/entities/attendance_entity.dart';
import 'package:field_ops/features/reports/data/datasources/reports_local_datasource.dart';
import 'package:field_ops/features/reports/data/datasources/reports_remote_datasource.dart';
import 'package:field_ops/features/reports/data/models/field_operations_report_model.dart';
import 'package:field_ops/features/reports/data/models/technician_performance_model.dart';
import 'package:field_ops/features/reports/data/repositories/reports_repository_impl.dart';
import 'package:field_ops/features/reports/domain/entities/export_type.dart';
import 'package:field_ops/features/reports/domain/entities/field_operations_report.dart';
import 'package:field_ops/features/reports/domain/entities/report_date_range.dart';
import 'package:field_ops/features/tasks/domain/entities/task_entity.dart';
import 'package:field_ops/features/visits/domain/entities/visit_entity.dart';

class FakeRemoteDataSource implements ReportsRemoteDataSource {
  bool shouldThrow = false;

  @override
  Future<FieldOperationsReportModel> getOperationsReport({
    required String organizationId,
    required DateTime startDate,
    required DateTime endDate,
    String? technicianId,
  }) async {
    if (shouldThrow) throw Exception('Network offline');
    return FieldOperationsReportModel(
      dateRange: ReportDateRange(preset: DateRangePreset.thisWeek, startDate: startDate, endDate: endDate),
      totalTasksCreated: 15,
      totalTasksCompleted: 14,
      taskCompletionRate: 93.3,
      onTimeCompletionRate: 92.8,
      totalVisits: 18,
      completedVisits: 16,
      activeVisits: 2,
      avgVisitDurationMinutes: 44.0,
      uniqueCustomersVisited: 8,
      totalAttendanceHours: 65.0,
      activeTechniciansCount: 3,
      technicianBreakdowns: const [
        TechnicianPerformanceModel(
          userId: 'tech-1',
          userName: 'Alex Rivera',
          assignedTasksCount: 8,
          completedTasksCount: 8,
          completionRate: 100.0,
        ),
      ],
      generatedAt: DateTime.now(),
    );
  }

  @override
  Future<List<TaskEntity>> getTasksForRange({
    required String organizationId,
    required DateTime startDate,
    required DateTime endDate,
    String? technicianId,
  }) async {
    if (shouldThrow) throw Exception('Network offline');
    return [
      TaskEntity(
        id: 'task-1',
        organizationId: organizationId,
        title: 'Check Pump',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  @override
  Future<List<VisitEntity>> getVisitsForRange({
    required String organizationId,
    required DateTime startDate,
    required DateTime endDate,
    String? technicianId,
  }) async {
    if (shouldThrow) throw Exception('Network offline');
    return [
      VisitEntity(
        id: 'visit-1',
        organizationId: organizationId,
        userId: 'tech-1',
        checkInAt: DateTime.now(),
        checkInLatitude: 37.77,
        checkInLongitude: -122.41,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  @override
  Future<List<AttendanceEntity>> getAttendanceForRange({
    required String organizationId,
    required DateTime startDate,
    required DateTime endDate,
    String? technicianId,
  }) async {
    if (shouldThrow) throw Exception('Network offline');
    return [
      AttendanceEntity(
        id: 'att-1',
        organizationId: organizationId,
        userId: 'tech-1',
        date: DateTime.now(),
        checkInAt: DateTime.now(),
        checkInLatitude: 37.77,
        checkInLongitude: -122.41,
      ),
    ];
  }
}

class FakeLocalDataSource implements ReportsLocalDataSource {
  @override
  Future<FieldOperationsReport> getOperationsReport({
    required String organizationId,
    required DateTime startDate,
    required DateTime endDate,
    String? technicianId,
  }) async {
    return FieldOperationsReport(
      dateRange: ReportDateRange(preset: DateRangePreset.thisWeek, startDate: startDate, endDate: endDate),
      totalTasksCreated: 5,
      totalTasksCompleted: 4,
      taskCompletionRate: 80.0,
      generatedAt: DateTime.now(),
    );
  }

  @override
  Future<List<TaskEntity>> getTasksForRange({
    required String organizationId,
    required DateTime startDate,
    required DateTime endDate,
    String? technicianId,
  }) async {
    return [
      TaskEntity(
        id: 'local-task-1',
        organizationId: organizationId,
        title: 'Offline Task',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  @override
  Future<List<VisitEntity>> getVisitsForRange({
    required String organizationId,
    required DateTime startDate,
    required DateTime endDate,
    String? technicianId,
  }) async {
    return [
      VisitEntity(
        id: 'local-visit-1',
        organizationId: organizationId,
        userId: 'tech-1',
        checkInAt: DateTime.now(),
        checkInLatitude: 37.77,
        checkInLongitude: -122.41,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  @override
  Future<List<AttendanceEntity>> getAttendanceForRange({
    required String organizationId,
    required DateTime startDate,
    required DateTime endDate,
    String? technicianId,
  }) async {
    return [];
  }
}

void main() {
  late FakeRemoteDataSource remoteDataSource;
  late FakeLocalDataSource localDataSource;
  late ReportsRepositoryImpl repository;

  setUp(() {
    remoteDataSource = FakeRemoteDataSource();
    localDataSource = FakeLocalDataSource();
    repository = ReportsRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
      getOrgId: () => 'org-test-123',
    );
  });

  group('ReportsRepositoryImpl Unit Tests', () {
    test('getOperationsReport returns remote data when online', () async {
      final now = DateTime.now();
      final report = await repository.getOperationsReport(
        startDate: now.subtract(const Duration(days: 7)),
        endDate: now,
      );

      expect(report.totalTasksCreated, 15);
      expect(report.totalTasksCompleted, 14);
      expect(report.technicianBreakdowns.length, 1);
    });

    test('getOperationsReport falls back to local SQLite data when remote throws', () async {
      remoteDataSource.shouldThrow = true;

      final now = DateTime.now();
      final report = await repository.getOperationsReport(
        startDate: now.subtract(const Duration(days: 7)),
        endDate: now,
      );

      expect(report.totalTasksCreated, 5);
      expect(report.totalTasksCompleted, 4);
    });

    test('generateCsvExport produces CSV strings for all export types', () async {
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 7));
      final end = now;

      // Tasks export
      final tasksCsv = await repository.generateCsvExport(
        type: ExportType.tasks,
        startDate: start,
        endDate: end,
      );
      expect(tasksCsv, contains('Task ID,Title,Status'));
      expect(tasksCsv, contains('task-1,Check Pump'));

      // Visits export
      final visitsCsv = await repository.generateCsvExport(
        type: ExportType.visits,
        startDate: start,
        endDate: end,
      );
      expect(visitsCsv, contains('Visit ID,Task ID,Technician'));
      expect(visitsCsv, contains('visit-1'));

      // Attendance export
      final attCsv = await repository.generateCsvExport(
        type: ExportType.attendance,
        startDate: start,
        endDate: end,
      );
      expect(attCsv, contains('Record ID,Technician Name'));
      expect(attCsv, contains('att-1'));

      // Technicians export
      final techsCsv = await repository.generateCsvExport(
        type: ExportType.technicians,
        startDate: start,
        endDate: end,
      );
      expect(techsCsv, contains('Technician ID,Technician Name'));
      expect(techsCsv, contains('Alex Rivera'));

      // Executive summary export
      final execCsv = await repository.generateCsvExport(
        type: ExportType.executiveSummary,
        startDate: start,
        endDate: end,
      );
      expect(execCsv, contains('Metric,Value,Date Range'));
      expect(execCsv, contains('Total Tasks Created,15'));
    });
  });
}
