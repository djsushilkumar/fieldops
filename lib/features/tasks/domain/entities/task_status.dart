import 'package:flutter/material.dart';

enum TaskStatus {
  draft('DRAFT', 'Draft', Color(0xFF5F6368), Color(0xFFF1F3F4)),
  assigned('ASSIGNED', 'Assigned', Color(0xFF1976D2), Color(0xFFE3F2FD)),
  accepted('ACCEPTED', 'Accepted', Color(0xFF0288D1), Color(0xFFE1F5FE)),
  inProgress('IN_PROGRESS', 'In Progress', Color(0xFFE65100), Color(0xFFFFF3E0)),
  completed('COMPLETED', 'Completed', Color(0xFF2E7D32), Color(0xFFE8F5E9)),
  cancelled('CANCELLED', 'Cancelled', Color(0xFF757575), Color(0xFFEEEEEE)),
  overdue('OVERDUE', 'Overdue', Color(0xFFC62828), Color(0xFFFFEBEE));

  final String value;
  final String label;
  final Color color;
  final Color backgroundColor;

  const TaskStatus(this.value, this.label, this.color, this.backgroundColor);

  static TaskStatus fromString(String? val) {
    if (val == null) return TaskStatus.assigned;
    switch (val.toUpperCase()) {
      case 'DRAFT':
        return TaskStatus.draft;
      case 'ASSIGNED':
        return TaskStatus.assigned;
      case 'ACCEPTED':
        return TaskStatus.accepted;
      case 'IN_PROGRESS':
        return TaskStatus.inProgress;
      case 'COMPLETED':
        return TaskStatus.completed;
      case 'CANCELLED':
        return TaskStatus.cancelled;
      case 'OVERDUE':
        return TaskStatus.overdue;
      default:
        return TaskStatus.assigned;
    }
  }

  bool get isDraft => this == TaskStatus.draft;
  bool get isAssigned => this == TaskStatus.assigned;
  bool get isAccepted => this == TaskStatus.accepted;
  bool get isInProgress => this == TaskStatus.inProgress;
  bool get isCompleted => this == TaskStatus.completed;
  bool get isCancelled => this == TaskStatus.cancelled;
  bool get isOverdue => this == TaskStatus.overdue;

  bool get isActive => isInProgress || isAssigned || isAccepted;

  // Allowed transitions
  bool canTransitionTo(TaskStatus next) {
    if (this == next) return true;
    if (this == TaskStatus.completed || this == TaskStatus.cancelled) return false;
    
    switch (this) {
      case TaskStatus.draft:
        return next == TaskStatus.assigned || next == TaskStatus.cancelled;
      case TaskStatus.assigned:
        return next == TaskStatus.accepted ||
            next == TaskStatus.inProgress ||
            next == TaskStatus.cancelled ||
            next == TaskStatus.overdue;
      case TaskStatus.accepted:
        return next == TaskStatus.inProgress ||
            next == TaskStatus.cancelled ||
            next == TaskStatus.overdue;
      case TaskStatus.inProgress:
        return next == TaskStatus.completed ||
            next == TaskStatus.cancelled ||
            next == TaskStatus.overdue;
      case TaskStatus.overdue:
        return next == TaskStatus.inProgress ||
            next == TaskStatus.completed ||
            next == TaskStatus.cancelled;
      default:
        return false;
    }
  }
}
