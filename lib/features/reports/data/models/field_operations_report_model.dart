import '../../domain/entities/field_operations_report.dart';
import '../../domain/entities/report_date_range.dart';
import 'technician_performance_model.dart';

class FieldOperationsReportModel extends FieldOperationsReport {
  const FieldOperationsReportModel({
    required super.dateRange,
    super.totalTasksCreated = 0,
    super.totalTasksCompleted = 0,
    super.totalTasksInProgress = 0,
    super.totalTasksCancelled = 0,
    super.taskCompletionRate = 0.0,
    super.onTimeCompletionRate = 0.0,
    super.totalVisits = 0,
    super.completedVisits = 0,
    super.activeVisits = 0,
    super.avgVisitDurationMinutes = 0.0,
    super.uniqueCustomersVisited = 0,
    super.totalAttendanceHours = 0.0,
    super.activeTechniciansCount = 0,
    super.technicianBreakdowns = const [],
    required super.generatedAt,
  });

  factory FieldOperationsReportModel.fromJson(Map<String, dynamic> json) {
    final start = DateTime.parse(json['start_date'] as String);
    final end = DateTime.parse(json['end_date'] as String);
    final presetName = json['preset'] as String? ?? 'custom';
    final preset = DateRangePreset.values.firstWhere(
      (p) => p.name == presetName,
      orElse: () => DateRangePreset.custom,
    );

    final techsJson = (json['technician_breakdowns'] as List<dynamic>?) ?? [];
    final technicians = techsJson
        .map((t) => TechnicianPerformanceModel.fromJson(t as Map<String, dynamic>))
        .toList();

    return FieldOperationsReportModel(
      dateRange: ReportDateRange(preset: preset, startDate: start, endDate: end),
      totalTasksCreated: (json['total_tasks_created'] ?? 0) as int,
      totalTasksCompleted: (json['total_tasks_completed'] ?? 0) as int,
      totalTasksInProgress: (json['total_tasks_in_progress'] ?? 0) as int,
      totalTasksCancelled: (json['total_tasks_cancelled'] ?? 0) as int,
      taskCompletionRate: ((json['task_completion_rate'] ?? 0.0) as num).toDouble(),
      onTimeCompletionRate: ((json['on_time_completion_rate'] ?? 0.0) as num).toDouble(),
      totalVisits: (json['total_visits'] ?? 0) as int,
      completedVisits: (json['completed_visits'] ?? 0) as int,
      activeVisits: (json['active_visits'] ?? 0) as int,
      avgVisitDurationMinutes: ((json['avg_visit_duration_minutes'] ?? 0.0) as num).toDouble(),
      uniqueCustomersVisited: (json['unique_customers_visited'] ?? 0) as int,
      totalAttendanceHours: ((json['total_attendance_hours'] ?? 0.0) as num).toDouble(),
      activeTechniciansCount: (json['active_technicians_count'] ?? 0) as int,
      technicianBreakdowns: technicians,
      generatedAt: json['generated_at'] != null
          ? DateTime.parse(json['generated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start_date': dateRange.startDate.toIso8601String(),
      'end_date': dateRange.endDate.toIso8601String(),
      'preset': dateRange.preset.name,
      'total_tasks_created': totalTasksCreated,
      'total_tasks_completed': totalTasksCompleted,
      'total_tasks_in_progress': totalTasksInProgress,
      'total_tasks_cancelled': totalTasksCancelled,
      'task_completion_rate': taskCompletionRate,
      'on_time_completion_rate': onTimeCompletionRate,
      'total_visits': totalVisits,
      'completed_visits': completedVisits,
      'active_visits': activeVisits,
      'avg_visit_duration_minutes': avgVisitDurationMinutes,
      'unique_customers_visited': uniqueCustomersVisited,
      'total_attendance_hours': totalAttendanceHours,
      'active_technicians_count': activeTechniciansCount,
      'technician_breakdowns': technicianBreakdowns
          .map((t) => TechnicianPerformanceModel.fromEntity(t).toJson())
          .toList(),
      'generated_at': generatedAt.toIso8601String(),
    };
  }
}
