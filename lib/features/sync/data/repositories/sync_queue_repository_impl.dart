import '../../domain/entities/sync_queue_item.dart';
import '../../domain/entities/sync_status.dart';
import '../../domain/repositories/sync_queue_repository.dart';
import '../datasources/sync_queue_local_datasource.dart';
import '../models/sync_queue_model.dart';

class SyncQueueRepositoryImpl implements SyncQueueRepository {
  final SyncQueueLocalDataSource localDataSource;

  SyncQueueRepositoryImpl({required this.localDataSource});

  @override
  Future<SyncQueueItem> enqueue(SyncQueueItem item) async {
    final model = SyncQueueModel.fromEntity(item);
    await localDataSource.enqueueItem(model);
    return model;
  }

  @override
  Future<List<SyncQueueItem>> getPendingItems({String? userId}) async {
    return localDataSource.getPendingItems(userId: userId);
  }

  @override
  Future<List<SyncQueueItem>> getAllItems({String? userId, SyncStatus? status}) async {
    return localDataSource.getAllItems(userId: userId, status: status);
  }

  @override
  Future<void> updateItemStatus(
    String id,
    SyncStatus status, {
    String? error,
    DateTime? scheduledRetryAt,
  }) async {
    final item = await localDataSource.getItemById(id);
    if (item == null) return;

    final updated = item.copyWith(
      status: status,
      lastError: error ?? item.lastError,
      scheduledRetryAt: scheduledRetryAt,
      updatedAt: DateTime.now(),
    );
    await localDataSource.updateItem(updated);
  }

  @override
  Future<void> markSynced(String id) async {
    await updateItemStatus(id, SyncStatus.synced);
  }

  @override
  Future<void> markFailed(String id, String error, {DateTime? nextRetryAt}) async {
    final item = await localDataSource.getItemById(id);
    if (item == null) return;

    final nextAttempts = item.attempts + 1;
    final isExhausted = nextAttempts >= item.maxAttempts;

    final updated = item.copyWith(
      status: isExhausted ? SyncStatus.failed : SyncStatus.pending,
      attempts: nextAttempts,
      lastError: error,
      scheduledRetryAt: nextRetryAt,
      updatedAt: DateTime.now(),
    );
    await localDataSource.updateItem(updated);
  }

  @override
  Future<void> removeItem(String id) async {
    await localDataSource.deleteItem(id);
  }

  @override
  Future<void> clearSyncedItems() async {
    await localDataSource.clearSynced();
  }

  @override
  Future<void> clearAll() async {
    await localDataSource.clearAll();
  }

  @override
  Future<int> getPendingCount({String? userId}) async {
    return localDataSource.countPending(userId: userId);
  }
}
