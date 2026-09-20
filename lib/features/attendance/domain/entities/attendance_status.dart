import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

enum AttendanceStatus {
  present,
  absent,
  halfDay,
  onLeave;

  String get code {
    switch (this) {
      case AttendanceStatus.present:
        return 'PRESENT';
      case AttendanceStatus.absent:
        return 'ABSENT';
      case AttendanceStatus.halfDay:
        return 'HALF_DAY';
      case AttendanceStatus.onLeave:
        return 'ON_LEAVE';
    }
  }

  String get label {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.halfDay:
        return 'Half Day';
      case AttendanceStatus.onLeave:
        return 'On Leave';
    }
  }

  Color get color {
    switch (this) {
      case AttendanceStatus.present:
        return AppColors.success;
      case AttendanceStatus.absent:
        return AppColors.error;
      case AttendanceStatus.halfDay:
        return AppColors.warning;
      case AttendanceStatus.onLeave:
        return AppColors.info;
    }
  }

  static AttendanceStatus fromCode(String code) {
    switch (code.toUpperCase()) {
      case 'PRESENT':
        return AttendanceStatus.present;
      case 'ABSENT':
        return AttendanceStatus.absent;
      case 'HALF_DAY':
        return AttendanceStatus.halfDay;
      case 'ON_LEAVE':
        return AttendanceStatus.onLeave;
      default:
        return AttendanceStatus.present;
    }
  }
}
