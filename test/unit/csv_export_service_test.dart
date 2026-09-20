import 'package:flutter_test/flutter_test.dart';
import 'package:field_ops/features/attendance/domain/entities/attendance_entity.dart';
import 'package:field_ops/features/attendance/domain/entities/attendance_status.dart';
import 'package:field_ops/features/reports/data/services/csv_export_service.dart';
import 'package:field_ops/features/reports/domain/entities/field_operations_report.dart';
import 'package:field_ops/features/reports/domain/entities/report_date_range.dart';
import 'package:field_ops/features/reports/domain/entities/technician_performance.dart';
import 'package:field_ops/features/tasks/domain/entities/task_entity.dart';
import 'package:field_ops/features/tasks/domain/entities/task_priority.dart';
import 'package:field_ops/features/tasks/domain/entities/task_status.dart';
import 'package:field_ops/features/visits/domain/entities/visit_entity.dart';

void main() {
  late CsvExportService service;

  setUp(() {
    service = CsvExportService();
  });

  group('CsvExportService RFC-4180 Escaping', () {
    test('escapeCell handles plain strings without modification', () {
      expect(CsvExportService.escapeCell('Simple text'), 'Simple text');
      expect(CsvExportService.escapeCell(123), '123');
      expect(CsvExportService.escapeCell(null), '');
    });

    test('escapeCell wraps values with commas in double quotes', () {
      expect(CsvExportService.escapeCell('San Francisco, CA'), '"San Francisco, CA"');
    });

    test('escapeCell escapes existing double quotes and wraps in quotes', () {
      expect(CsvExportService.escapeCell('Check "HVAC" motor'), '"Check ""HVAC"" motor"');
    });

    test('escapeCell wraps values with newlines in double quotes', () {
      expect(CsvExportService.escapeCell('Line 1\nLine 2'), '"Line 1\nLine 2"');
    });

    test('buildCsv builds properly formatted RFC-4180 lines', () {
      final headers = ['Name', 'Role', 'Notes'];
      final rows = [
        ['Alex Rivera', 'Senior Tech', 'Completed, all clear'],
        ['Elena "The Specialist"', 'Lead', 'No issue\nVerified'],
      ];

      final csv = service.buildCsv(headers: headers, rows: rows);
      final lines = csv.trim().split('\n');

      expect(lines[0], 'Name,Role,Notes');
      expect(lines[1], 'Alex Rivera,Senior Tech,"Completed, all clear"');
      expect(lines[2], '"Elena ""The Specialist""",Lead,"No issue');
    });
  });

  group('CsvExportService Domain Export Generators', () {
    test('generateTasksCsv produces valid headers and rows', () {
      final now = DateTime(2026, 9, 20, 10, 0, 0);
      final tasks = [
        TaskEntity(
          id: 'task-1',
          organizationId: 'org-1',
          title: 'AC Maintenance',
          priority: TaskPriority.high,
          status: TaskStatus.completed,
          assignedToUserName: 'Alex Rivera',
          customerName: 'Acme Corp',
          scheduledStart: now,
          scheduledEnd: now.add(const Duration(hours: 2)),
          actualStart: now,
          actualEnd: now.add(const Duration(hours: 1, minutes: 45)),
          createdAt: now.subtract(const Duration(days: 1)),
          updatedAt: now,
          notes: 'Standard service, no leaks',
        ),
      ];

      final csv = service.generateTasksCsv(tasks);
      expect(csv, contains('Task ID,Title,Status,Priority,Assigned Technician'));
      expect(csv, contains('task-1,AC Maintenance,Completed,High,Alex Rivera,Acme Corp'));
      expect(csv, contains('"Standard service, no leaks"'));
      expect(csv, contains('Yes')); // On-time: actualEnd <= scheduledEnd
    });

    test('generateVisitsCsv produces valid headers and 6-decimal coordinates', () {
      final now = DateTime(2026, 9, 20, 11, 0, 0);
      final visits = [
        VisitEntity(
          id: 'visit-1',
          organizationId: 'org-1',
          taskId: 'task-1',
          userId: 'user-1',
          userName: 'Alex Rivera',
          customerName: 'St. Jude Hospital',
          checkInAt: now,
          checkInLatitude: 37.774929,
          checkInLongitude: -122.419416,
          checkOutAt: now.add(const Duration(minutes: 45)),
          checkOutLatitude: 37.774950,
          checkOutLongitude: -122.419420,
          notes: 'Customer signed work sheet',
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final csv = service.generateVisitsCsv(visits);
      expect(csv, contains('Visit ID,Task ID,Technician,Customer / Site,Check-in Time'));
      expect(csv, contains('visit-1,task-1,Alex Rivera,St. Jude Hospital'));
      expect(csv, contains('37.774929,-122.419416'));
      expect(csv, contains('45,Completed,Customer signed work sheet'));
    });

    test('generateAttendanceCsv produces valid timesheet rows', () {
      final today = DateTime(2026, 9, 20);
      final records = [
        AttendanceEntity(
          id: 'att-1',
          organizationId: 'org-1',
          userId: 'user-1',
          userName: 'Elena Rostova',
          userEmail: 'elena@fieldops.com',
          date: today,
          checkInAt: today.add(const Duration(hours: 8)),
          checkInLatitude: 37.78,
          checkInLongitude: -122.41,
          checkOutAt: today.add(const Duration(hours: 16, minutes: 30)),
          totalMinutes: 510,
          status: AttendanceStatus.present,
        ),
      ];

      final csv = service.generateAttendanceCsv(records);
      expect(csv, contains('Record ID,Technician Name,Technician Email,Date,Check-in Time'));
      expect(csv, contains('att-1,Elena Rostova,elena@fieldops.com,2026-09-20'));
      expect(csv, contains('8h 30m,510,Present'));
    });

    test('generateTechniciansCsv produces rankings with percentage and duration formatting', () {
      final techs = [
        const TechnicianPerformance(
          userId: 'tech-1',
          userName: 'Alex Rivera',
          assignedTasksCount: 10,
          completedTasksCount: 9,
          inProgressTasksCount: 1,
          cancelledTasksCount: 0,
          onTimeTasksCount: 8,
          completionRate: 90.0,
          onTimeRate: 88.9,
          totalVisitsCount: 12,
          avgVisitDurationMinutes: 42.0,
          totalWorkMinutes: 2400,
          attendanceDaysCount: 5,
        ),
      ];

      final csv = service.generateTechniciansCsv(techs);
      expect(csv, contains('Technician ID,Technician Name,Assigned Tasks,Completed Tasks'));
      expect(csv, contains('tech-1,Alex Rivera,10,9,1,0,90.0,88.9,12,42.0,40.0,5'));
    });

    test('generateExecutiveSummaryCsv outputs high-level KPIs correctly', () {
      final now = DateTime(2026, 9, 20);
      final report = FieldOperationsReport(
        dateRange: ReportDateRange.fromPreset(DateRangePreset.thisWeek, now: now),
        totalTasksCreated: 50,
        totalTasksCompleted: 45,
        totalTasksInProgress: 4,
        totalTasksCancelled: 1,
        taskCompletionRate: 90.0,
        onTimeCompletionRate: 92.5,
        totalVisits: 55,
        completedVisits: 52,
        activeVisits: 3,
        avgVisitDurationMinutes: 43.5,
        uniqueCustomersVisited: 18,
        totalAttendanceHours: 195.0,
        activeTechniciansCount: 5,
        generatedAt: now,
      );

      final csv = service.generateExecutiveSummaryCsv(report);
      expect(csv, contains('Metric,Value,Date Range,Generated At'));
      expect(csv, contains('Total Tasks Created,50'));
      expect(csv, contains('Task Completion Rate (%),90.0%'));
      expect(csv, contains('On-Time Completion Rate (%),92.5%'));
      expect(csv, contains('Total Customer Visits,55'));
      expect(csv, contains('Total Staff Clocked Hours,195.0 hrs'));
    });
  });
}
