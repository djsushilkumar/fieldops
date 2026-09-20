class TechnicianPerformance {
  final String userId;
  final String userName;
  final int assignedTasksCount;
  final int completedTasksCount;
  final int cancelledTasksCount;
  final int inProgressTasksCount;
  final int onTimeTasksCount;
  final double completionRate;
  final double onTimeRate;
  final int totalVisitsCount;
  final double avgVisitDurationMinutes;
  final int totalWorkMinutes;
  final int attendanceDaysCount;

  const TechnicianPerformance({
    required this.userId,
    required this.userName,
    this.assignedTasksCount = 0,
    this.completedTasksCount = 0,
    this.cancelledTasksCount = 0,
    this.inProgressTasksCount = 0,
    this.onTimeTasksCount = 0,
    this.completionRate = 0.0,
    this.onTimeRate = 0.0,
    this.totalVisitsCount = 0,
    this.avgVisitDurationMinutes = 0.0,
    this.totalWorkMinutes = 0,
    this.attendanceDaysCount = 0,
  });

  String get formattedWorkHours {
    final hours = totalWorkMinutes ~/ 60;
    final mins = totalWorkMinutes % 60;
    return '${hours}h ${mins}m';
  }

  String get formattedAvgVisitDuration {
    return '${avgVisitDurationMinutes.toStringAsFixed(1)} min';
  }

  TechnicianPerformance copyWith({
    String? userId,
    String? userName,
    int? assignedTasksCount,
    int? completedTasksCount,
    int? cancelledTasksCount,
    int? inProgressTasksCount,
    int? onTimeTasksCount,
    double? completionRate,
    double? onTimeRate,
    int? totalVisitsCount,
    double? avgVisitDurationMinutes,
    int? totalWorkMinutes,
    int? attendanceDaysCount,
  }) {
    return TechnicianPerformance(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      assignedTasksCount: assignedTasksCount ?? this.assignedTasksCount,
      completedTasksCount: completedTasksCount ?? this.completedTasksCount,
      cancelledTasksCount: cancelledTasksCount ?? this.cancelledTasksCount,
      inProgressTasksCount: inProgressTasksCount ?? this.inProgressTasksCount,
      onTimeTasksCount: onTimeTasksCount ?? this.onTimeTasksCount,
      completionRate: completionRate ?? this.completionRate,
      onTimeRate: onTimeRate ?? this.onTimeRate,
      totalVisitsCount: totalVisitsCount ?? this.totalVisitsCount,
      avgVisitDurationMinutes: avgVisitDurationMinutes ?? this.avgVisitDurationMinutes,
      totalWorkMinutes: totalWorkMinutes ?? this.totalWorkMinutes,
      attendanceDaysCount: attendanceDaysCount ?? this.attendanceDaysCount,
    );
  }
}
