import 'task_priority.dart';
import 'task_status.dart';

class TaskEntity {
  final String id;
  final String organizationId;
  final String title;
  final String? description;
  final String? taskTypeId;
  final TaskPriority priority;
  final TaskStatus status;
  final String? assignedToUserId;
  final String? assignedToUserName;
  final String? customerId;
  final String? customerName;
  final String? locationId;
  final String? locationName;
  final String? createdBy;
  final String? creatorName;
  final DateTime? scheduledStart;
  final DateTime? scheduledEnd;
  final DateTime? actualStart;
  final DateTime? actualEnd;
  final bool requiresGps;
  final bool requiresPhoto;
  final bool requiresForm;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskEntity({
    required this.id,
    required this.organizationId,
    required this.title,
    this.description,
    this.taskTypeId,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.assigned,
    this.assignedToUserId,
    this.assignedToUserName,
    this.customerId,
    this.customerName,
    this.locationId,
    this.locationName,
    this.createdBy,
    this.creatorName,
    this.scheduledStart,
    this.scheduledEnd,
    this.actualStart,
    this.actualEnd,
    this.requiresGps = false,
    this.requiresPhoto = false,
    this.requiresForm = false,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isAssigned => assignedToUserId != null;
  bool get hasProofRequirements => requiresGps || requiresPhoto || requiresForm;

  bool get isCompleted => status.isCompleted;
  bool get isInProgress => status.isInProgress;
  bool get isOverdue {
    if (status.isCompleted || status.isCancelled) return false;
    if (status.isOverdue) return true;
    if (scheduledEnd != null && DateTime.now().isAfter(scheduledEnd!)) return true;
    return false;
  }

  bool get canStart => status == TaskStatus.assigned || status == TaskStatus.accepted;
  bool get canComplete => status == TaskStatus.inProgress;

  TaskEntity copyWith({
    String? id,
    String? organizationId,
    String? title,
    String? description,
    String? taskTypeId,
    TaskPriority? priority,
    TaskStatus? status,
    String? assignedToUserId,
    String? assignedToUserName,
    String? customerId,
    String? customerName,
    String? locationId,
    String? locationName,
    String? createdBy,
    String? creatorName,
    DateTime? scheduledStart,
    DateTime? scheduledEnd,
    DateTime? actualStart,
    DateTime? actualEnd,
    bool? requiresGps,
    bool? requiresPhoto,
    bool? requiresForm,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskEntity(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      title: title ?? this.title,
      description: description ?? this.description,
      taskTypeId: taskTypeId ?? this.taskTypeId,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      assignedToUserId: assignedToUserId ?? this.assignedToUserId,
      assignedToUserName: assignedToUserName ?? this.assignedToUserName,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      locationId: locationId ?? this.locationId,
      locationName: locationName ?? this.locationName,
      createdBy: createdBy ?? this.createdBy,
      creatorName: creatorName ?? this.creatorName,
      scheduledStart: scheduledStart ?? this.scheduledStart,
      scheduledEnd: scheduledEnd ?? this.scheduledEnd,
      actualStart: actualStart ?? this.actualStart,
      actualEnd: actualEnd ?? this.actualEnd,
      requiresGps: requiresGps ?? this.requiresGps,
      requiresPhoto: requiresPhoto ?? this.requiresPhoto,
      requiresForm: requiresForm ?? this.requiresForm,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          organizationId == other.organizationId &&
          status == other.status &&
          priority == other.priority;

  @override
  int get hashCode => id.hashCode ^ organizationId.hashCode ^ status.hashCode;

  @override
  String toString() => 'TaskEntity(id: $id, title: $title, status: ${status.value}, priority: ${priority.value})';
}
