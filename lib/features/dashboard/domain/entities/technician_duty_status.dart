import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

enum TechnicianDutyStatus {
  onDuty,
  inTransit,
  onSite,
  idle,
  offDuty;

  String get displayName {
    switch (this) {
      case TechnicianDutyStatus.onDuty:
        return 'On Duty';
      case TechnicianDutyStatus.inTransit:
        return 'In Transit';
      case TechnicianDutyStatus.onSite:
        return 'On Site';
      case TechnicianDutyStatus.idle:
        return 'Idle';
      case TechnicianDutyStatus.offDuty:
        return 'Off Duty';
    }
  }

  Color get color {
    switch (this) {
      case TechnicianDutyStatus.onDuty:
        return AppColors.primary;
      case TechnicianDutyStatus.inTransit:
        return AppColors.accent;
      case TechnicianDutyStatus.onSite:
        return AppColors.secondary;
      case TechnicianDutyStatus.idle:
        return AppColors.warning;
      case TechnicianDutyStatus.offDuty:
        return AppColors.textSecondary;
    }
  }

  IconData get icon {
    switch (this) {
      case TechnicianDutyStatus.onDuty:
        return Icons.work_rounded;
      case TechnicianDutyStatus.inTransit:
        return Icons.directions_car_rounded;
      case TechnicianDutyStatus.onSite:
        return Icons.location_on_rounded;
      case TechnicianDutyStatus.idle:
        return Icons.pause_circle_rounded;
      case TechnicianDutyStatus.offDuty:
        return Icons.bedtime_rounded;
    }
  }

  static TechnicianDutyStatus fromString(String? val) {
    if (val == null) return TechnicianDutyStatus.offDuty;
    switch (val.toUpperCase().trim()) {
      case 'ON_DUTY':
      case 'ONDUTY':
        return TechnicianDutyStatus.onDuty;
      case 'IN_TRANSIT':
      case 'INTRANSIT':
        return TechnicianDutyStatus.inTransit;
      case 'ON_SITE':
      case 'ONSITE':
        return TechnicianDutyStatus.onSite;
      case 'IDLE':
        return TechnicianDutyStatus.idle;
      case 'OFF_DUTY':
      case 'OFFDUTY':
      default:
        return TechnicianDutyStatus.offDuty;
    }
  }
}
