import 'package:flutter/material.dart';

enum TaskPriority {
  low('LOW', 'Low', Color(0xFF5F6368), Color(0xFFF1F3F4)),
  medium('MEDIUM', 'Medium', Color(0xFF1A73E8), Color(0xFFE8F0FE)),
  high('HIGH', 'High', Color(0xFFE37400), Color(0xFFFEF7E0)),
  urgent('URGENT', 'Urgent', Color(0xFFD93025), Color(0xFFFCE8E6));

  final String value;
  final String label;
  final Color color;
  final Color backgroundColor;

  const TaskPriority(this.value, this.label, this.color, this.backgroundColor);

  static TaskPriority fromString(String? val) {
    if (val == null) return TaskPriority.medium;
    switch (val.toUpperCase()) {
      case 'LOW':
        return TaskPriority.low;
      case 'HIGH':
        return TaskPriority.high;
      case 'URGENT':
        return TaskPriority.urgent;
      case 'MEDIUM':
      default:
        return TaskPriority.medium;
    }
  }

  bool get isUrgent => this == TaskPriority.urgent;
  bool get isHigh => this == TaskPriority.high;
}
