import '../../domain/entities/task_entity.dart';
import '../../domain/entities/task_priority.dart';
import '../../domain/entities/task_status.dart';

class TaskModel {
  final String id;
  final String organizationId;
  final String title;
  final String? description;
  final String? taskTypeId;
  final String priority;
  final String status;
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

  TaskModel({
    required this.id,
    required this.organizationId,
    required this.title,
    this.description,
    this.taskTypeId,
    required this.priority,
    required this.status,
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

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      title: json['title'] as String? ?? 'Untitled Task',
      description: json['description'] as String?,
      taskTypeId: json['task_type_id'] as String?,
      priority: json['priority'] as String? ?? 'MEDIUM',
      status: json['status'] as String? ?? 'ASSIGNED',
      assignedToUserId: json['assigned_to_user_id'] as String? ?? json['assignee_id'] as String?,
      assignedToUserName: json['assigned_to_user_name'] as String? ?? json['assignee_name'] as String?,
      customerId: json['customer_id'] as String?,
      customerName: json['customer_name'] as String?,
      locationId: json['location_id'] as String?,
      locationName: json['location_name'] as String?,
      createdBy: json['created_by'] as String?,
      creatorName: json['creator_name'] as String?,
      scheduledStart: json['scheduled_start'] != null
          ? DateTime.tryParse(json['scheduled_start'] as String)
          : null,
      scheduledEnd: json['scheduled_end'] != null
          ? DateTime.tryParse(json['scheduled_end'] as String)
          : null,
      actualStart: json['actual_start'] != null
          ? DateTime.tryParse(json['actual_start'] as String)
          : null,
      actualEnd: json['actual_end'] != null
          ? DateTime.tryParse(json['actual_end'] as String)
          : null,
      requiresGps: json['requires_gps'] as bool? ?? false,
      requiresPhoto: json['requires_photo'] as bool? ?? false,
      requiresForm: json['requires_form'] as bool? ?? false,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'title': title,
      'description': description,
      'task_type_id': taskTypeId,
      'priority': priority,
      'status': status,
      'assigned_to_user_id': assignedToUserId,
      'assigned_to_user_name': assignedToUserName,
      'customer_id': customerId,
      'customer_name': customerName,
      'location_id': locationId,
      'location_name': locationName,
      'created_by': createdBy,
      'creator_name': creatorName,
      'scheduled_start': scheduledStart?.toIso8601String(),
      'scheduled_end': scheduledEnd?.toIso8601String(),
      'actual_start': actualStart?.toIso8601String(),
      'actual_end': actualEnd?.toIso8601String(),
      'requires_gps': requiresGps,
      'requires_photo': requiresPhoto,
      'requires_form': requiresForm,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  TaskEntity toEntity() {
    return TaskEntity(
      id: id,
      organizationId: organizationId,
      title: title,
      description: description,
      taskTypeId: taskTypeId,
      priority: TaskPriority.fromString(priority),
      status: TaskStatus.fromString(status),
      assignedToUserId: assignedToUserId,
      assignedToUserName: assignedToUserName,
      customerId: customerId,
      customerName: customerName,
      locationId: locationId,
      locationName: locationName,
      createdBy: createdBy,
      creatorName: creatorName,
      scheduledStart: scheduledStart,
      scheduledEnd: scheduledEnd,
      actualStart: actualStart,
      actualEnd: actualEnd,
      requiresGps: requiresGps,
      requiresPhoto: requiresPhoto,
      requiresForm: requiresForm,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory TaskModel.fromEntity(TaskEntity entity) {
    return TaskModel(
      id: entity.id,
      organizationId: entity.organizationId,
      title: entity.title,
      description: entity.description,
      taskTypeId: entity.taskTypeId,
      priority: entity.priority.value,
      status: entity.status.value,
      assignedToUserId: entity.assignedToUserId,
      assignedToUserName: entity.assignedToUserName,
      customerId: entity.customerId,
      customerName: entity.customerName,
      locationId: entity.locationId,
      locationName: entity.locationName,
      createdBy: entity.createdBy,
      creatorName: entity.creatorName,
      scheduledStart: entity.scheduledStart,
      scheduledEnd: entity.scheduledEnd,
      actualStart: entity.actualStart,
      actualEnd: entity.actualEnd,
      requiresGps: entity.requiresGps,
      requiresPhoto: entity.requiresPhoto,
      requiresForm: entity.requiresForm,
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
