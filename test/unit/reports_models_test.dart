import 'package:flutter_test/flutter_test.dart';
import 'package:field_ops/features/reports/data/models/field_operations_report_model.dart';
import 'package:field_ops/features/reports/data/models/technician_performance_model.dart';
import 'package:field_ops/features/reports/domain/entities/export_type.dart';
import 'package:field_ops/features/reports/domain/entities/report_date_range.dart';

void main() {
  group('ReportDateRange Unit Tests', () {
    test('today preset computes start and end of current day', () {
      final now = DateTime(2026, 9, 20, 14, 30, 0);
      final range = ReportDateRange.fromPreset(DateRangePreset.today, now: now);

      expect(range.preset, DateRangePreset.today);
      expect(range.startDate, DateTime(2026, 9, 20, 0, 0, 0));
      expect(range.endDate.day, 20);
      expect(range.endDate.hour, 23);
    });

    test('thisWeek preset computes start from Monday', () {
      final sunday = DateTime(2026, 9, 20); // Sunday (weekday 7)
      final range = ReportDateRange.fromPreset(DateRangePreset.thisWeek, now: sunday);

      expect(range.preset, DateRangePreset.thisWeek);
      expect(range.startDate, DateTime(2026, 9, 14)); // Monday
    });

    test('thisMonth preset computes 1st of month to end of month', () {
      final now = DateTime(2026, 9, 20);
      final range = ReportDateRange.fromPreset(DateRangePreset.thisMonth, now: now);

      expect(range.startDate, DateTime(2026, 9, 1));
      expect(range.endDate.month, 9);
      expect(range.endDate.day, 30);
    });

    test('custom range handles arbitrary start and end dates', () {
      final start = DateTime(2026, 8, 1);
      final end = DateTime(2026, 8, 15);
      final range = ReportDateRange.custom(start, end);

      expect(range.preset, DateRangePreset.custom);
      expect(range.startDate, DateTime(2026, 8, 1, 0, 0, 0));
      expect(range.endDate.day, 15);
      expect(range.formattedRange, 'Aug 1, 2026 – Aug 15, 2026');
    });
  });

  group('TechnicianPerformanceModel Unit Tests', () {
    test('fromJson and toJson maintain data fidelity', () {
      final json = {
        'user_id': 'tech-100',
        'technician_name': 'Marcus Vance',
        'total_assigned_tasks': 12,
        'completed_tasks': 10,
        'cancelled_tasks': 1,
        'in_progress_tasks': 1,
        'on_time_tasks': 9,
        'completion_rate_percentage': 83.3,
        'on_time_rate_percentage': 90.0,
        'total_visits': 15,
        'avg_visit_duration_minutes': 48.5,
        'total_work_minutes': 2160,
        'attendance_days_count': 5,
      };

      final model = TechnicianPerformanceModel.fromJson(json);
      expect(model.userId, 'tech-100');
      expect(model.userName, 'Marcus Vance');
      expect(model.assignedTasksCount, 12);
      expect(model.completedTasksCount, 10);
      expect(model.completionRate, 83.3);
      expect(model.formattedWorkHours, '36h 0m');
      expect(model.formattedAvgVisitDuration, '48.5 min');

      final serialized = model.toJson();
      expect(serialized['user_id'], 'tech-100');
      expect(serialized['completed_tasks'], 10);
      expect(serialized['total_work_minutes'], 2160);
    });
  });

  group('FieldOperationsReportModel Unit Tests', () {
    test('serializes and deserializes report with nested technicians', () {
      final now = DateTime(2026, 9, 20, 12, 0, 0);
      final json = {
        'start_date': '2026-09-01T00:00:00.000',
        'end_date': '2026-09-20T23:59:59.000',
        'preset': 'thisMonth',
        'total_tasks_created': 40,
        'total_tasks_completed': 36,
        'total_tasks_in_progress': 3,
        'total_tasks_cancelled': 1,
        'task_completion_rate': 90.0,
        'on_time_completion_rate': 94.4,
        'total_visits': 42,
        'completed_visits': 40,
        'active_visits': 2,
        'avg_visit_duration_minutes': 41.2,
        'unique_customers_visited': 15,
        'total_attendance_hours': 160.5,
        'active_technicians_count': 4,
        'technician_breakdowns': [
          {
            'user_id': 'tech-1',
            'technician_name': 'Alex Rivera',
            'total_assigned_tasks': 20,
            'completed_tasks': 18,
            'cancelled_tasks': 0,
            'in_progress_tasks': 2,
            'on_time_tasks': 17,
            'completion_rate_percentage': 90.0,
            'on_time_rate_percentage': 94.4,
            'total_visits': 22,
            'avg_visit_duration_minutes': 40.0,
            'total_work_minutes': 4800,
            'attendance_days_count': 10,
          }
        ],
        'generated_at': now.toIso8601String(),
      };

      final model = FieldOperationsReportModel.fromJson(json);
      expect(model.totalTasksCreated, 40);
      expect(model.totalTasksCompleted, 36);
      expect(model.formattedCompletionRate, '90.0%');
      expect(model.formattedOnTimeRate, '94.4%');
      expect(model.formattedAvgVisitDuration, '41.2 min');
      expect(model.formattedTotalHours, '160.5 hrs');
      expect(model.technicianBreakdowns.length, 1);
      expect(model.technicianBreakdowns.first.userName, 'Alex Rivera');

      final outputJson = model.toJson();
      expect(outputJson['total_tasks_created'], 40);
      expect(outputJson['technician_breakdowns'], isNotEmpty);
    });
  });

  group('ExportType Enum Unit Tests', () {
    test('contains all expected report export types with proper prefixes', () {
      expect(ExportType.tasks.filePrefix, 'tasks_report');
      expect(ExportType.visits.filePrefix, 'visits_report');
      expect(ExportType.attendance.filePrefix, 'attendance_report');
      expect(ExportType.technicians.filePrefix, 'technician_performance');
      expect(ExportType.executiveSummary.filePrefix, 'executive_summary');

      for (final type in ExportType.values) {
        expect(type.displayName, isNotEmpty);
        expect(type.description, isNotEmpty);
      }
    });
  });
}
