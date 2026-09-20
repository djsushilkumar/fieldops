import 'dart:convert';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/notification_type.dart';

class NotificationModel {
  final String id;
  final String organizationId;
  final String userId;
  final String type;
  final String title;
  final String body;
  final DateTime? readAt;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.organizationId,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.readAt,
    this.data = const {},
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> parsedData = {};
    if (json['data'] != null) {
      if (json['data'] is Map) {
        parsedData = Map<String, dynamic>.from(json['data'] as Map);
      } else if (json['data'] is String) {
        try {
          parsedData = Map<String, dynamic>.from(
            jsonDecode(json['data'] as String) as Map,
          );
        } catch (_) {}
      }
    }

    return NotificationModel(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      type: json['type'] as String? ?? 'TASK_ASSIGNED',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'] as String)
          : null,
      data: parsedData,
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
      'type': type,
      'title': title,
      'body': body,
      'read_at': readAt?.toIso8601String(),
      'data': data,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory NotificationModel.fromSqlMap(Map<String, dynamic> map) {
    Map<String, dynamic> parsedData = {};
    if (map['data'] != null) {
      if (map['data'] is Map) {
        parsedData = Map<String, dynamic>.from(map['data'] as Map);
      } else if (map['data'] is String) {
        try {
          parsedData = Map<String, dynamic>.from(
            jsonDecode(map['data'] as String) as Map,
          );
        } catch (_) {}
      }
    }

    return NotificationModel(
      id: map['id'] as String,
      organizationId: map['organization_id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      type: map['type'] as String? ?? 'TASK_ASSIGNED',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      readAt: map['read_at'] != null
          ? DateTime.tryParse(map['read_at'] as String)
          : null,
      data: parsedData,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toSqlMap() {
    return {
      'id': id,
      'organization_id': organizationId,
      'user_id': userId,
      'type': type,
      'title': title,
      'body': body,
      'read_at': readAt?.toIso8601String(),
      'data': jsonEncode(data),
      'created_at': createdAt.toIso8601String(),
    };
  }

  NotificationEntity toEntity() {
    return NotificationEntity(
      id: id,
      organizationId: organizationId,
      userId: userId,
      type: NotificationType.fromString(type),
      title: title,
      body: body,
      readAt: readAt,
      data: data,
      createdAt: createdAt,
    );
  }

  factory NotificationModel.fromEntity(NotificationEntity entity) {
    return NotificationModel(
      id: entity.id,
      organizationId: entity.organizationId,
      userId: entity.userId,
      type: entity.type.code,
      title: entity.title,
      body: entity.body,
      readAt: entity.readAt,
      data: entity.data,
      createdAt: entity.createdAt,
    );
  }
}
