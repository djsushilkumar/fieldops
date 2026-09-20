import 'dart:convert';
import '../../domain/entities/sync_entity_type.dart';
import '../../domain/entities/sync_operation.dart';
import '../../domain/entities/sync_queue_item.dart';
import '../../domain/entities/sync_status.dart';

class SyncQueueModel extends SyncQueueItem {
  const SyncQueueModel({
    required super.id,
    required super.userId,
    required super.operation,
    required super.entityType,
    required super.entityId,
    required super.payload,
    super.status = SyncStatus.pending,
    super.attempts = 0,
    super.maxAttempts = 5,
    super.lastError,
    required super.createdAt,
    required super.updatedAt,
    super.scheduledRetryAt,
  });

  factory SyncQueueModel.fromJson(Map<String, dynamic> json) {
    dynamic rawPayload = json['payload'];
    if (rawPayload is String) {
      try {
        rawPayload = jsonDecode(rawPayload);
      } catch (_) {
        rawPayload = <String, dynamic>{};
      }
    }

    final payloadMap = rawPayload is Map<String, dynamic>
        ? rawPayload
        : rawPayload is Map
            ? Map<String, dynamic>.from(rawPayload)
            : <String, dynamic>{};

    return SyncQueueModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      operation: SyncOperation.fromString(json['operation']?.toString() ?? 'UPDATE'),
      entityType: SyncEntityType.fromString(json['entity_type']?.toString() ?? 'task'),
      entityId: json['entity_id']?.toString() ?? '',
      payload: payloadMap,
      status: SyncStatus.fromString(json['status']?.toString() ?? 'PENDING'),
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      maxAttempts: (json['max_attempts'] as num?)?.toInt() ?? 5,
      lastError: json['last_error']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      scheduledRetryAt: json['scheduled_retry_at'] != null
          ? DateTime.tryParse(json['scheduled_retry_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'operation': operation.code,
      'entity_type': entityType.code,
      'entity_id': entityId,
      'payload': payload,
      'status': status.code,
      'attempts': attempts,
      'max_attempts': maxAttempts,
      if (lastError != null) 'last_error': lastError,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (scheduledRetryAt != null) 'scheduled_retry_at': scheduledRetryAt!.toIso8601String(),
    };
  }

  Map<String, dynamic> toSqlRow() {
    return {
      'id': id,
      'user_id': userId,
      'operation': operation.code,
      'entity_type': entityType.code,
      'entity_id': entityId,
      'payload': jsonEncode(payload),
      'status': status.code,
      'attempts': attempts,
      'max_attempts': maxAttempts,
      'last_error': lastError,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'scheduled_retry_at': scheduledRetryAt?.toIso8601String(),
    };
  }

  factory SyncQueueModel.fromSqlRow(Map<String, dynamic> row) {
    return SyncQueueModel.fromJson(row);
  }

  factory SyncQueueModel.fromEntity(SyncQueueItem entity) {
    return SyncQueueModel(
      id: entity.id,
      userId: entity.userId,
      operation: entity.operation,
      entityType: entity.entityType,
      entityId: entity.entityId,
      payload: entity.payload,
      status: entity.status,
      attempts: entity.attempts,
      maxAttempts: entity.maxAttempts,
      lastError: entity.lastError,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      scheduledRetryAt: entity.scheduledRetryAt,
    );
  }

  @override
  SyncQueueModel copyWith({
    String? id,
    String? userId,
    SyncOperation? operation,
    SyncEntityType? entityType,
    String? entityId,
    Map<String, dynamic>? payload,
    SyncStatus? status,
    int? attempts,
    int? maxAttempts,
    String? lastError,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? scheduledRetryAt,
  }) {
    return SyncQueueModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      operation: operation ?? this.operation,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      scheduledRetryAt: scheduledRetryAt ?? this.scheduledRetryAt,
    );
  }
}
