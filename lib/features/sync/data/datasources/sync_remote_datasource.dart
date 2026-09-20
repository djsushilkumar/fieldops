import '../../../../core/errors/exceptions.dart';
import '../models/sync_queue_model.dart';

abstract class SyncRemoteDataSource {
  Future<void> pushQueueItem(SyncQueueModel item);
  Future<List<String>> pushBatch(List<SyncQueueModel> items);
  Future<List<Map<String, dynamic>>> fetchServerDeltas(String entityType, DateTime since);
}

class MockSyncRemoteDataSource implements SyncRemoteDataSource {
  bool simulateError = false;
  final List<SyncQueueModel> _pushedItems = [];
  final Map<String, List<Map<String, dynamic>>> _serverDeltas = {};

  List<SyncQueueModel> get pushedItems => List.unmodifiable(_pushedItems);

  void addServerDelta(String entityType, Map<String, dynamic> record) {
    _serverDeltas.putIfAbsent(entityType, () => []).add(record);
  }

  void clearPushedItems() {
    _pushedItems.clear();
  }

  @override
  Future<void> pushQueueItem(SyncQueueModel item) async {
    if (simulateError) {
      throw const ServerException('Simulated network error during sync push');
    }
    _pushedItems.add(item);
  }

  @override
  Future<List<String>> pushBatch(List<SyncQueueModel> items) async {
    if (simulateError) {
      throw const ServerException('Simulated network error during batch sync push');
    }
    final syncedIds = <String>[];
    for (final item in items) {
      _pushedItems.add(item);
      syncedIds.add(item.id);
    }
    return syncedIds;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchServerDeltas(String entityType, DateTime since) async {
    if (simulateError) {
      throw const ServerException('Simulated network error during delta fetch');
    }
    final records = _serverDeltas[entityType] ?? [];
    return records.where((r) {
      final updatedStr = r['updated_at']?.toString();
      if (updatedStr == null) return true;
      final updated = DateTime.tryParse(updatedStr);
      if (updated == null) return true;
      return updated.isAfter(since);
    }).toList();
  }
}
