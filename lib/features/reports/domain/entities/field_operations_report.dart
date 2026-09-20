import 'report_date_range.dart';
import 'technician_performance.dart';

class FieldOperationsReport {
  final ReportDateRange dateRange;
  final int totalTasksCreated;
  final int totalTasksCompleted;
  final int totalTasksInProgress;
  final int totalTasksCancelled;
  final double taskCompletionRate;
  final double onTimeCompletionRate;
  final int totalVisits;
  final int completedVisits;
  final int activeVisits;
  final double avgVisitDurationMinutes;
  final int uniqueCustomersVisited;
  final double totalAttendanceHours;
  final int activeTechniciansCount;
  final List<TechnicianPerformance> technicianBreakdowns;
  final DateTime generatedAt;

  const FieldOperationsReport({
    required this.dateRange,
    this.totalTasksCreated = 0,
    this.totalTasksCompleted = 0,
    this.totalTasksInProgress = 0,
    this.totalTasksCancelled = 0,
    this.taskCompletionRate = 0.0,
    this.onTimeCompletionRate = 0.0,
    this.totalVisits = 0,
    this.completedVisits = 0,
    this.activeVisits = 0,
    this.avgVisitDurationMinutes = 0.0,
    this.uniqueCustomersVisited = 0,
    this.totalAttendanceHours = 0.0,
    this.activeTechniciansCount = 0,
    this.technicianBreakdowns = const [],
    required this.generatedAt,
  });

  String get formattedCompletionRate => '${taskCompletionRate.toStringAsFixed(1)}%';
  String get formattedOnTimeRate => '${onTimeCompletionRate.toStringAsFixed(1)}%';
  String get formattedAvgVisitDuration => '${avgVisitDurationMinutes.toStringAsFixed(1)} min';
  String get formattedTotalHours => '${totalAttendanceHours.toStringAsFixed(1)} hrs';

  FieldOperationsReport copyWith({
    ReportDateRange? dateRange,
    int? totalTasksCreated,
    int? totalTasksCompleted,
    int? totalTasksInProgress,
    int? totalTasksCancelled,
    double? taskCompletionRate,
    double? onTimeCompletionRate,
    int? totalVisits,
    int? completedVisits,
    int? activeVisits,
    double? avgVisitDurationMinutes,
    int? uniqueCustomersVisited,
    double? totalAttendanceHours,
    int? activeTechniciansCount,
    List<TechnicianPerformance>? technicianBreakdowns,
    DateTime? generatedAt,
  }) {
    return FieldOperationsReport(
      dateRange: dateRange ?? this.dateRange,
      totalTasksCreated: totalTasksCreated ?? this.totalTasksCreated,
      totalTasksCompleted: totalTasksCompleted ?? this.totalTasksCompleted,
      totalTasksInProgress: totalTasksInProgress ?? this.totalTasksInProgress,
      totalTasksCancelled: totalTasksCancelled ?? this.totalTasksCancelled,
      taskCompletionRate: taskCompletionRate ?? this.taskCompletionRate,
      onTimeCompletionRate: onTimeCompletionRate ?? this.onTimeCompletionRate,
      totalVisits: totalVisits ?? this.totalVisits,
      completedVisits: completedVisits ?? this.completedVisits,
      activeVisits: activeVisits ?? this.activeVisits,
      avgVisitDurationMinutes: avgVisitDurationMinutes ?? this.avgVisitDurationMinutes,
      uniqueCustomersVisited: uniqueCustomersVisited ?? this.uniqueCustomersVisited,
      totalAttendanceHours: totalAttendanceHours ?? this.totalAttendanceHours,
      activeTechniciansCount: activeTechniciansCount ?? this.activeTechniciansCount,
      technicianBreakdowns: technicianBreakdowns ?? this.technicianBreakdowns,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }
}
