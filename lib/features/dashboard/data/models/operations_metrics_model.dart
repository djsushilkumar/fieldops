import '../../domain/entities/operations_metrics.dart';

class OperationsMetricsModel {
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
  final double proofComplianceRate;
  final int syncPendingQueueCount;

  const OperationsMetricsModel({
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

  factory OperationsMetricsModel.fromJson(Map<String, dynamic> json) {
    return OperationsMetricsModel(
      totalTechnicians: json['total_technicians'] as int? ?? 0,
      onDutyTechnicians: json['on_duty_technicians'] as int? ?? 0,
      idleTechnicians: json['idle_technicians'] as int? ?? 0,
      offDutyTechnicians: json['off_duty_technicians'] as int? ?? 0,
      totalTasksToday: json['total_tasks_today'] as int? ?? 0,
      assignedTasks: json['assigned_tasks'] as int? ?? 0,
      inProgressTasks: json['in_progress_tasks'] as int? ?? 0,
      completedTasksToday: json['completed_tasks_today'] as int? ?? 0,
      overdueTasks: json['overdue_tasks'] as int? ?? 0,
      completedVisitsToday: json['completed_visits_today'] as int? ?? 0,
      totalProofsUploadedToday: json['total_proofs_uploaded_today'] as int? ?? 0,
      proofComplianceRate: (json['proof_compliance_rate'] as num?)?.toDouble() ?? 100.0,
      syncPendingQueueCount: json['sync_pending_queue_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_technicians': totalTechnicians,
      'on_duty_technicians': onDutyTechnicians,
      'idle_technicians': idleTechnicians,
      'off_duty_technicians': offDutyTechnicians,
      'total_tasks_today': totalTasksToday,
      'assigned_tasks': assignedTasks,
      'in_progress_tasks': inProgressTasks,
      'completed_tasks_today': completedTasksToday,
      'overdue_tasks': overdueTasks,
      'completed_visits_today': completedVisitsToday,
      'total_proofs_uploaded_today': totalProofsUploadedToday,
      'proof_compliance_rate': proofComplianceRate,
      'sync_pending_queue_count': syncPendingQueueCount,
    };
  }

  OperationsMetrics toEntity() {
    return OperationsMetrics(
      totalTechnicians: totalTechnicians,
      onDutyTechnicians: onDutyTechnicians,
      idleTechnicians: idleTechnicians,
      offDutyTechnicians: offDutyTechnicians,
      totalTasksToday: totalTasksToday,
      assignedTasks: assignedTasks,
      inProgressTasks: inProgressTasks,
      completedTasksToday: completedTasksToday,
      overdueTasks: overdueTasks,
      completedVisitsToday: completedVisitsToday,
      totalProofsUploadedToday: totalProofsUploadedToday,
      proofComplianceRate: proofComplianceRate,
      syncPendingQueueCount: syncPendingQueueCount,
    );
  }

  factory OperationsMetricsModel.fromEntity(OperationsMetrics entity) {
    return OperationsMetricsModel(
      totalTechnicians: entity.totalTechnicians,
      onDutyTechnicians: entity.onDutyTechnicians,
      idleTechnicians: entity.idleTechnicians,
      offDutyTechnicians: entity.offDutyTechnicians,
      totalTasksToday: entity.totalTasksToday,
      assignedTasks: entity.assignedTasks,
      inProgressTasks: entity.inProgressTasks,
      completedTasksToday: entity.completedTasksToday,
      overdueTasks: entity.overdueTasks,
      completedVisitsToday: entity.completedVisitsToday,
      totalProofsUploadedToday: entity.totalProofsUploadedToday,
      proofComplianceRate: entity.proofComplianceRate,
      syncPendingQueueCount: entity.syncPendingQueueCount,
    );
  }
}
