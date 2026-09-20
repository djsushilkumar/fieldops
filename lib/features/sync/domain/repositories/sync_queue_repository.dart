import '../entities/sync_queue_item.dart';
import '../entities/sync_status.dart';

abstract class SyncQueueRepository {
  Future<SyncQueueItem> enqueue(SyncQueueItem item);
  Future<List<SyncQueueItem>> getPendingItems({String? userId});
  Future<List<SyncQueueItem>> getAllItems({String? userId, SyncStatus? status});
  Future<void> updateItemStatus(
    String id,
    SyncStatus status, {
    String? error,
    DateTime? scheduledRetryAt,
  });
  Future<void> markSynced(String id);
  Future<void> markFailed(String id, String error, {DateTime? nextRetryAt});
  Future<void> removeItem(String id);
  Future<void> clearSyncedItems();
  Future<void> clearAll();
  Future<int> getPendingCount({String? userId});
}
