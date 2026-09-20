import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

enum NotificationType {
  taskAssigned,
  taskStarted,
  taskCompleted,
  overdueWarning,
  visitAlert,
  attendanceReminder,
  proofVerified,
  systemAnnouncement;

  String get code {
    switch (this) {
      case NotificationType.taskAssigned:
        return 'TASK_ASSIGNED';
      case NotificationType.taskStarted:
        return 'TASK_STARTED';
      case NotificationType.taskCompleted:
        return 'TASK_COMPLETED';
      case NotificationType.overdueWarning:
        return 'OVERDUE_WARNING';
      case NotificationType.visitAlert:
        return 'VISIT_ALERT';
      case NotificationType.attendanceReminder:
        return 'ATTENDANCE_REMINDER';
      case NotificationType.proofVerified:
        return 'PROOF_VERIFIED';
      case NotificationType.systemAnnouncement:
        return 'SYSTEM_ANNOUNCEMENT';
    }
  }

  String get displayName {
    switch (this) {
      case NotificationType.taskAssigned:
        return 'Task Assigned';
      case NotificationType.taskStarted:
        return 'Task Started';
      case NotificationType.taskCompleted:
        return 'Task Completed';
      case NotificationType.overdueWarning:
        return 'Overdue Warning';
      case NotificationType.visitAlert:
        return 'Site Visit Alert';
      case NotificationType.attendanceReminder:
        return 'Shift Attendance';
      case NotificationType.proofVerified:
        return 'Proof Verified';
      case NotificationType.systemAnnouncement:
        return 'Announcement';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationType.taskAssigned:
        return Icons.assignment_ind_rounded;
      case NotificationType.taskStarted:
        return Icons.play_arrow_rounded;
      case NotificationType.taskCompleted:
        return Icons.check_circle_rounded;
      case NotificationType.overdueWarning:
        return Icons.warning_amber_rounded;
      case NotificationType.visitAlert:
        return Icons.location_on_rounded;
      case NotificationType.attendanceReminder:
        return Icons.access_time_rounded;
      case NotificationType.proofVerified:
        return Icons.verified_rounded;
      case NotificationType.systemAnnouncement:
        return Icons.campaign_rounded;
    }
  }

  Color get color {
    switch (this) {
      case NotificationType.taskAssigned:
        return AppColors.primary;
      case NotificationType.taskStarted:
        return AppColors.roleManager;
      case NotificationType.taskCompleted:
      case NotificationType.proofVerified:
        return AppColors.secondary;
      case NotificationType.overdueWarning:
        return AppColors.error;
      case NotificationType.visitAlert:
        return AppColors.accent;
      case NotificationType.attendanceReminder:
        return AppColors.roleEmployee;
      case NotificationType.systemAnnouncement:
        return AppColors.roleAdmin;
    }
  }

  static NotificationType fromString(String? val) {
    if (val == null) return NotificationType.taskAssigned;
    switch (val.toUpperCase().trim()) {
      case 'TASK_ASSIGNED':
      case 'TASKASSIGNED':
        return NotificationType.taskAssigned;
      case 'TASK_STARTED':
      case 'TASKSTARTED':
        return NotificationType.taskStarted;
      case 'TASK_COMPLETED':
      case 'TASKCOMPLETED':
        return NotificationType.taskCompleted;
      case 'OVERDUE_WARNING':
      case 'OVERDUE':
        return NotificationType.overdueWarning;
      case 'VISIT_ALERT':
      case 'VISIT':
        return NotificationType.visitAlert;
      case 'ATTENDANCE_REMINDER':
      case 'ATTENDANCE':
        return NotificationType.attendanceReminder;
      case 'PROOF_VERIFIED':
      case 'PROOF':
        return NotificationType.proofVerified;
      case 'SYSTEM_ANNOUNCEMENT':
      case 'ANNOUNCEMENT':
        return NotificationType.systemAnnouncement;
      default:
        return NotificationType.taskAssigned;
    }
  }
}
