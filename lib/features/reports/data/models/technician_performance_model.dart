import '../../domain/entities/technician_performance.dart';

class TechnicianPerformanceModel extends TechnicianPerformance {
  const TechnicianPerformanceModel({
    required super.userId,
    required super.userName,
    super.assignedTasksCount = 0,
    super.completedTasksCount = 0,
    super.cancelledTasksCount = 0,
    super.inProgressTasksCount = 0,
    super.onTimeTasksCount = 0,
    super.completionRate = 0.0,
    super.onTimeRate = 0.0,
    super.totalVisitsCount = 0,
    super.avgVisitDurationMinutes = 0.0,
    super.totalWorkMinutes = 0,
    super.attendanceDaysCount = 0,
  });

  factory TechnicianPerformanceModel.fromJson(Map<String, dynamic> json) {
    return TechnicianPerformanceModel(
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      userName: json['technician_name'] as String? ?? json['userName'] as String? ?? 'Technician',
      assignedTasksCount: (json['total_assigned_tasks'] ?? json['assignedTasksCount'] ?? 0) as int,
      completedTasksCount: (json['completed_tasks'] ?? json['completedTasksCount'] ?? 0) as int,
      cancelledTasksCount: (json['cancelled_tasks'] ?? json['cancelledTasksCount'] ?? 0) as int,
      inProgressTasksCount: (json['in_progress_tasks'] ?? json['inProgressTasksCount'] ?? 0) as int,
      onTimeTasksCount: (json['on_time_tasks'] ?? json['onTimeTasksCount'] ?? 0) as int,
      completionRate: ((json['completion_rate_percentage'] ?? json['completionRate'] ?? 0.0) as num).toDouble(),
      onTimeRate: ((json['on_time_rate_percentage'] ?? json['onTimeRate'] ?? 0.0) as num).toDouble(),
      totalVisitsCount: (json['total_visits'] ?? json['totalVisitsCount'] ?? 0) as int,
      avgVisitDurationMinutes: ((json['avg_visit_duration_minutes'] ?? json['avgVisitDurationMinutes'] ?? 0.0) as num).toDouble(),
      totalWorkMinutes: (json['total_work_minutes'] ?? json['totalWorkMinutes'] ?? 0) as int,
      attendanceDaysCount: (json['attendance_days_count'] ?? json['attendanceDaysCount'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'technician_name': userName,
      'total_assigned_tasks': assignedTasksCount,
      'completed_tasks': completedTasksCount,
      'cancelled_tasks': cancelledTasksCount,
      'in_progress_tasks': inProgressTasksCount,
      'on_time_tasks': onTimeTasksCount,
      'completion_rate_percentage': completionRate,
      'on_time_rate_percentage': onTimeRate,
      'total_visits': totalVisitsCount,
      'avg_visit_duration_minutes': avgVisitDurationMinutes,
      'total_work_minutes': totalWorkMinutes,
      'attendance_days_count': attendanceDaysCount,
    };
  }

  factory TechnicianPerformanceModel.fromEntity(TechnicianPerformance entity) {
    return TechnicianPerformanceModel(
      userId: entity.userId,
      userName: entity.userName,
      assignedTasksCount: entity.assignedTasksCount,
      completedTasksCount: entity.completedTasksCount,
      cancelledTasksCount: entity.cancelledTasksCount,
      inProgressTasksCount: entity.inProgressTasksCount,
      onTimeTasksCount: entity.onTimeTasksCount,
      completionRate: entity.completionRate,
      onTimeRate: entity.onTimeRate,
      totalVisitsCount: entity.totalVisitsCount,
      avgVisitDurationMinutes: entity.avgVisitDurationMinutes,
      totalWorkMinutes: entity.totalWorkMinutes,
      attendanceDaysCount: entity.attendanceDaysCount,
    );
  }
}
