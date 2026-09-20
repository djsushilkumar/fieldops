import 'dart:math';
import 'sync_entity_type.dart';
import 'sync_operation.dart';
import 'sync_status.dart';

class SyncQueueItem {
  final String id;
  final String userId;
  final SyncOperation operation;
  final SyncEntityType entityType;
  final String entityId;
  final Map<String, dynamic> payload;
  final SyncStatus status;
  final int attempts;
  final int maxAttempts;
  final String? lastError;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? scheduledRetryAt;

  const SyncQueueItem({
    required this.id,
    required this.userId,
    required this.operation,
    required this.entityType,
    required this.entityId,
    required this.payload,
    this.status = SyncStatus.pending,
    this.attempts = 0,
    this.maxAttempts = 5,
    this.lastError,
    required this.createdAt,
    required this.updatedAt,
    this.scheduledRetryAt,
  });

  bool get canRetry => attempts < maxAttempts && status != SyncStatus.synced;
  bool get isFailed => status == SyncStatus.failed;
  bool get isPending => status == SyncStatus.pending;
  bool get isSyncing => status == SyncStatus.syncing;
  bool get isSynced => status == SyncStatus.synced;

  /// Calculate exponential backoff duration: 2^attempts seconds (min 2s, max 60s)
  Duration get nextBackoffDuration {
    final exp = min(attempts, 6);
    final secs = pow(2, exp).toInt();
    return Duration(seconds: max(2, min(secs, 60)));
  }

  SyncQueueItem copyWith({
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
    return SyncQueueItem(
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
