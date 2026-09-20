import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../../../core/database/sqlite_database.dart';
import '../data/datasources/sync_remote_datasource.dart';
import '../data/models/sync_queue_model.dart';
import '../domain/entities/conflict_resolution_strategy.dart';
import '../domain/entities/sync_entity_type.dart';
import '../domain/entities/sync_operation.dart';
import '../domain/entities/sync_queue_item.dart';
import '../domain/entities/sync_status.dart';
import '../domain/repositories/sync_queue_repository.dart';
import 'network_connectivity_service.dart';

class SyncResult {
  final int totalProcessed;
  final int successCount;
  final int failedCount;
  final int conflictsResolved;
  final List<String> errors;

  const SyncResult({
    this.totalProcessed = 0,
    this.successCount = 0,
    this.failedCount = 0,
    this.conflictsResolved = 0,
    this.errors = const [],
  });

  bool get hasErrors => errors.isNotEmpty || failedCount > 0;
  bool get isSuccess => !hasErrors;
}

class SyncQueueEngine {
  final SyncQueueRepository repository;
  final SyncRemoteDataSource remoteDataSource;
  final SqliteDatabase database;
  final NetworkConnectivityService connectivityService;
  ConflictResolutionStrategy conflictStrategy;

  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  StreamSubscription<ConnectivityStatus>? _connectivitySub;

  SyncQueueEngine({
    required this.repository,
    required this.remoteDataSource,
    required this.database,
    required this.connectivityService,
    this.conflictStrategy = ConflictResolutionStrategy.clientWins,
  }) {
    _connectivitySub = connectivityService.onConnectivityChanged.listen((status) {
      if (status == ConnectivityStatus.online && !_isSyncing) {
        syncAll();
      }
    });
  }

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;

  void dispose() {
    _connectivitySub?.cancel();
  }

  /// Enqueue an offline mutation from any feature or repository
  Future<SyncQueueItem> enqueueMutation({
    required String userId,
    required SyncEntityType entityType,
    required String entityId,
    required SyncOperation operation,
    required Map<String, dynamic> payload,
    int maxAttempts = 5,
  }) async {
    final now = DateTime.now();
    final item = SyncQueueItem(
      id: const Uuid().v4(),
      userId: userId,
      operation: operation,
      entityType: entityType,
      entityId: entityId,
      payload: payload,
      status: SyncStatus.pending,
      attempts: 0,
      maxAttempts: maxAttempts,
      createdAt: now,
      updatedAt: now,
    );

    await repository.enqueue(item);

    // Optimistically update local database table if applicable
    await _applyMutationToLocalDatabase(item);

    return item;
  }

  /// Process all pending queue items (Push changes to server)
  Future<SyncResult> processQueue({String? userId}) async {
    if (!connectivityService.isOnline) {
      return const SyncResult(
        errors: ['Device is offline; sync deferred'],
      );
    }

    final pending = await repository.getPendingItems(userId: userId);
    final now = DateTime.now();

    // Filter out items not yet ready for retry under exponential backoff
    final readyItems = pending.where((item) {
      if (item.scheduledRetryAt != null && now.isBefore(item.scheduledRetryAt!)) {
        return false;
      }
      return true;
    }).toList();

    int success = 0;
    int failed = 0;
    final errors = <String>[];

    for (final item in readyItems) {
      try {
        await repository.updateItemStatus(item.id, SyncStatus.syncing);

        final model = SyncQueueModel.fromEntity(item);
        await remoteDataSource.pushQueueItem(model);

        await repository.markSynced(item.id);
        success++;
      } catch (e) {
        failed++;
        final errMsg = e.toString();
        errors.add(errMsg);

        final nextRetryAt = DateTime.now().add(item.nextBackoffDuration);
        await repository.markFailed(item.id, errMsg, nextRetryAt: nextRetryAt);
      }
    }

    return SyncResult(
      totalProcessed: readyItems.length,
      successCount: success,
      failedCount: failed,
      errors: errors,
    );
  }

  /// Pull server deltas and reconcile with local database (Pull changes)
  Future<int> pullDeltas() async {
    if (!connectivityService.isOnline) return 0;

    final since = _lastSyncTime ?? DateTime.now().subtract(const Duration(days: 30));
    int resolved = 0;

    // Entities to reconcile: tasks, visits, customers, forms
    final entityTypes = [
      SyncEntityType.task,
      SyncEntityType.visit,
      SyncEntityType.customer,
      SyncEntityType.attendance,
      SyncEntityType.form,
    ];

    for (final entityType in entityTypes) {
      try {
        final deltas = await remoteDataSource.fetchServerDeltas(entityType.code, since);
        for (final remoteRecord in deltas) {
          final recordId = remoteRecord['id']?.toString() ?? '';
          if (recordId.isEmpty) continue;

          // Check if there are pending local mutations for this record
          final pendingLocal = await repository.getAllItems();
          final hasConflict = pendingLocal.any(
            (q) => q.entityId == recordId && q.isPending,
          );

          if (hasConflict) {
            resolved++;
            _resolveConflict(entityType, recordId, remoteRecord);
          } else {
            // Apply delta directly to local database
            await _upsertLocalRecord(entityType, remoteRecord);
          }
        }
      } catch (_) {}
    }

    return resolved;
  }

  /// Two-way full synchronization: Push local queue + Pull remote deltas
  Future<SyncResult> syncAll({String? userId}) async {
    if (_isSyncing) {
      return const SyncResult(errors: ['Sync already in progress']);
    }

    _isSyncing = true;
    try {
      final pushResult = await processQueue(userId: userId);
      final conflicts = await pullDeltas();

      _lastSyncTime = DateTime.now();

      return SyncResult(
        totalProcessed: pushResult.totalProcessed,
        successCount: pushResult.successCount,
        failedCount: pushResult.failedCount,
        conflictsResolved: conflicts,
        errors: pushResult.errors,
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Reset all failed items back to pending and trigger sync
  Future<SyncResult> retryAllFailed({String? userId}) async {
    final allItems = await repository.getAllItems(userId: userId, status: SyncStatus.failed);
    for (final item in allItems) {
      await repository.updateItemStatus(
        item.id,
        SyncStatus.pending,
        scheduledRetryAt: null,
      );
    }
    return syncAll(userId: userId);
  }

  // --- Internal Conflict Resolution and Database Operations ---

  void _resolveConflict(
    SyncEntityType entityType,
    String recordId,
    Map<String, dynamic> remoteRecord,
  ) async {
    switch (conflictStrategy) {
      case ConflictResolutionStrategy.clientWins:
        // Client wins: Keep local state; pending queue item will push and overwrite server
        break;

      case ConflictResolutionStrategy.serverWins:
        // Server wins: Overwrite local database with remote record and remove pending item
        await _upsertLocalRecord(entityType, remoteRecord);
        final pending = await repository.getAllItems();
        for (final q in pending) {
          if (q.entityId == recordId) {
            await repository.removeItem(q.id);
          }
        }
        break;

      case ConflictResolutionStrategy.merge:
        // Merge: Non-null fields from local record combine with remote record
        final localRows = await database.query(_tableNameForType(entityType), where: 'id = ?', whereArgs: [recordId]);
        if (localRows.isNotEmpty) {
          final merged = Map<String, dynamic>.from(remoteRecord);
          for (final entry in localRows.first.entries) {
            if (entry.value != null) {
              merged[entry.key] = entry.value;
            }
          }
          await _upsertLocalRecord(entityType, merged);
        } else {
          await _upsertLocalRecord(entityType, remoteRecord);
        }
        break;
    }
  }

  Future<void> _applyMutationToLocalDatabase(SyncQueueItem item) async {
    final tableName = _tableNameForType(item.entityType);
    if (tableName.isEmpty) return;

    try {
      if (item.operation == SyncOperation.delete) {
        await database.delete(tableName, where: 'id = ?', whereArgs: [item.entityId]);
      } else {
        final row = Map<String, dynamic>.from(item.payload);
        if (!row.containsKey('id')) {
          row['id'] = item.entityId;
        }
        await database.insert(
          tableName,
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (_) {}
  }

  Future<void> _upsertLocalRecord(SyncEntityType entityType, Map<String, dynamic> record) async {
    final tableName = _tableNameForType(entityType);
    if (tableName.isEmpty) return;

    try {
      await database.insert(
        tableName,
        record,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  String _tableNameForType(SyncEntityType entityType) {
    switch (entityType) {
      case SyncEntityType.task:
        return 'tasks';
      case SyncEntityType.visit:
        return 'visits';
      case SyncEntityType.attendance:
        return 'attendance';
      case SyncEntityType.form:
        return 'forms';
      case SyncEntityType.formSubmission:
        return 'form_submissions';
      case SyncEntityType.customer:
        return 'customers';
      case SyncEntityType.location:
        return 'locations';
    }
  }
}
