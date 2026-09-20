import 'task_priority.dart';
import 'task_status.dart';

class TaskFilter {
  final TaskStatus? status;
  final TaskPriority? priority;
  final String? assignedUserId;
  final String? searchQuery;
  final DateTime? date;

  const TaskFilter({
    this.status,
    this.priority,
    this.assignedUserId,
    this.searchQuery,
    this.date,
  });

  bool get isEmpty =>
      status == null &&
      priority == null &&
      assignedUserId == null &&
      (searchQuery == null || searchQuery!.trim().isEmpty) &&
      date == null;

  TaskFilter copyWith({
    TaskStatus? status,
    bool clearStatus = false,
    TaskPriority? priority,
    bool clearPriority = false,
    String? assignedUserId,
    bool clearAssignedUser = false,
    String? searchQuery,
    DateTime? date,
    bool clearDate = false,
  }) {
    return TaskFilter(
      status: clearStatus ? null : (status ?? this.status),
      priority: clearPriority ? null : (priority ?? this.priority),
      assignedUserId: clearAssignedUser ? null : (assignedUserId ?? this.assignedUserId),
      searchQuery: searchQuery ?? this.searchQuery,
      date: clearDate ? null : (date ?? this.date),
    );
  }
}
