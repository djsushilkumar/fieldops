import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ActivityLogEntity {
  final String id;
  final String organizationId;
  final String? userId;
  final String userName;
  final String action;
  final String entityType;
  final String? entityId;
  final String? details;
  final DateTime createdAt;

  const ActivityLogEntity({
    required this.id,
    required this.organizationId,
    this.userId,
    required this.userName,
    required this.action,
    required this.entityType,
    this.entityId,
    this.details,
    required this.createdAt,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  IconData get icon {
    switch (action.toUpperCase()) {
      case 'TASK_CREATED':
      case 'TASK_ASSIGNED':
        return Icons.assignment_ind_rounded;
      case 'TASK_STARTED':
        return Icons.play_arrow_rounded;
      case 'TASK_COMPLETED':
        return Icons.check_circle_rounded;
      case 'VISIT_CHECK_IN':
        return Icons.login_rounded;
      case 'VISIT_CHECK_OUT':
        return Icons.logout_rounded;
      case 'PROOF_UPLOADED':
        return Icons.camera_alt_rounded;
      case 'SIGNATURE_CAPTURED':
        return Icons.draw_rounded;
      case 'ATTENDANCE_CHECK_IN':
        return Icons.fingerprint_rounded;
      case 'ATTENDANCE_CHECK_OUT':
        return Icons.done_all_rounded;
      case 'SYNC_COMPLETED':
        return Icons.sync_rounded;
      default:
        return Icons.history_rounded;
    }
  }

  Color get color {
    switch (action.toUpperCase()) {
      case 'TASK_COMPLETED':
      case 'SIGNATURE_CAPTURED':
        return AppColors.secondary;
      case 'TASK_STARTED':
      case 'VISIT_CHECK_IN':
        return AppColors.primary;
      case 'PROOF_UPLOADED':
        return AppColors.accent;
      case 'ATTENDANCE_CHECK_IN':
        return AppColors.roleEmployee;
      default:
        return AppColors.textSecondary;
    }
  }
}
