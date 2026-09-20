class OperationsMetrics {
  final int totalTechnicians;
  final int onDutyTechnicians;
  final int idleTechnicians;
  final int offDutyTechnicians;
  final int totalTasksToday;
  final int assignedTasks;
  final int inProgressTasks;
  final int completedTasksToday;
  final int overdueTasks;
  final int completedVisitsToday;
  final int totalProofsUploadedToday;
  final double proofComplianceRate; // 0.0 to 100.0 %
  final int syncPendingQueueCount;

  const OperationsMetrics({
    this.totalTechnicians = 0,
    this.onDutyTechnicians = 0,
    this.idleTechnicians = 0,
    this.offDutyTechnicians = 0,
    this.totalTasksToday = 0,
    this.assignedTasks = 0,
    this.inProgressTasks = 0,
    this.completedTasksToday = 0,
    this.overdueTasks = 0,
    this.completedVisitsToday = 0,
    this.totalProofsUploadedToday = 0,
    this.proofComplianceRate = 100.0,
    this.syncPendingQueueCount = 0,
  });

  double get onDutyPercentage =>
      totalTechnicians > 0 ? (onDutyTechnicians / totalTechnicians) * 100 : 0.0;

  double get taskCompletionRate =>
      totalTasksToday > 0 ? (completedTasksToday / totalTasksToday) * 100 : 0.0;

  OperationsMetrics copyWith({
    int? totalTechnicians,
    int? onDutyTechnicians,
    int? idleTechnicians,
    int? offDutyTechnicians,
    int? totalTasksToday,
    int? assignedTasks,
    int? inProgressTasks,
    int? completedTasksToday,
    int? overdueTasks,
    int? completedVisitsToday,
    int? totalProofsUploadedToday,
    double? proofComplianceRate,
    int? syncPendingQueueCount,
  }) {
    return OperationsMetrics(
      totalTechnicians: totalTechnicians ?? this.totalTechnicians,
      onDutyTechnicians: onDutyTechnicians ?? this.onDutyTechnicians,
      idleTechnicians: idleTechnicians ?? this.idleTechnicians,
      offDutyTechnicians: offDutyTechnicians ?? this.offDutyTechnicians,
      totalTasksToday: totalTasksToday ?? this.totalTasksToday,
      assignedTasks: assignedTasks ?? this.assignedTasks,
      inProgressTasks: inProgressTasks ?? this.inProgressTasks,
      completedTasksToday: completedTasksToday ?? this.completedTasksToday,
      overdueTasks: overdueTasks ?? this.overdueTasks,
      completedVisitsToday: completedVisitsToday ?? this.completedVisitsToday,
      totalProofsUploadedToday:
          totalProofsUploadedToday ?? this.totalProofsUploadedToday,
      proofComplianceRate: proofComplianceRate ?? this.proofComplianceRate,
      syncPendingQueueCount:
          syncPendingQueueCount ?? this.syncPendingQueueCount,
    );
  }
}
