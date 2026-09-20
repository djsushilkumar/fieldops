import 'dart:convert';
import '../../domain/entities/activity_log_entity.dart';

class ActivityLogModel {
  final String id;
  final String organizationId;
  final String? userId;
  final String userName;
  final String action;
  final String entityType;
  final String? entityId;
  final String? details;
  final DateTime createdAt;

  const ActivityLogModel({
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

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) {
    String? detailsString;
    if (json['details'] != null) {
      if (json['details'] is String) {
        detailsString = json['details'] as String;
      } else {
        detailsString = jsonEncode(json['details']);
      }
    }

    return ActivityLogModel(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String? ?? '',
      userId: json['user_id'] as String?,
      userName: json['user_name'] as String? ?? json['users']?['name'] as String? ?? 'System',
      action: json['action'] as String? ?? '',
      entityType: json['entity_type'] as String? ?? '',
      entityId: json['entity_id'] as String?,
      details: detailsString,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'user_id': userId,
      'user_name': userName,
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'details': details,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ActivityLogEntity toEntity() {
    return ActivityLogEntity(
      id: id,
      organizationId: organizationId,
      userId: userId,
      userName: userName,
      action: action,
      entityType: entityType,
      entityId: entityId,
      details: details,
      createdAt: createdAt,
    );
  }

  factory ActivityLogModel.fromEntity(ActivityLogEntity entity) {
    return ActivityLogModel(
      id: entity.id,
      organizationId: entity.organizationId,
      userId: entity.userId,
      userName: entity.userName,
      action: entity.action,
      entityType: entity.entityType,
      entityId: entity.entityId,
      details: entity.details,
      createdAt: entity.createdAt,
    );
  }
}
