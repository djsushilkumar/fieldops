import '../../../../core/database/sqlite_database.dart';
import '../../domain/entities/sync_status.dart';
import '../models/sync_queue_model.dart';

abstract class SyncQueueLocalDataSource {
  Future<void> enqueueItem(SyncQueueModel item);
  Future<List<SyncQueueModel>> getPendingItems({String? userId});
  Future<List<SyncQueueModel>> getAllItems({String? userId, SyncStatus? status});
  Future<SyncQueueModel?> getItemById(String id);
  Future<void> updateItem(SyncQueueModel item);
  Future<void> deleteItem(String id);
  Future<void> clearSynced();
  Future<void> clearAll();
  Future<int> countPending({String? userId});
}

class SyncQueueLocalDataSourceImpl implements SyncQueueLocalDataSource {
  final SqliteDatabase database;

  SyncQueueLocalDataSourceImpl({required this.database});

  static const String tableName = 'sync_queue';

  @override
  Future<void> enqueueItem(SyncQueueModel item) async {
    await database.insert(
      tableName,
      item.toSqlRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<SyncQueueModel>> getPendingItems({String? userId}) async {
    String? where;
    List<dynamic>? args;

    if (userId != null && userId.isNotEmpty) {
      where = 'status = ? AND user_id = ?';
      args = [SyncStatus.pending.code, userId];
    } else {
      where = 'status = ?';
      args = [SyncStatus.pending.code];
    }

    final rows = await database.query(
      tableName,
      where: where,
      whereArgs: args,
      orderBy: 'created_at ASC',
    );

    return rows.map((r) => SyncQueueModel.fromSqlRow(r)).toList();
  }

  @override
  Future<List<SyncQueueModel>> getAllItems({String? userId, SyncStatus? status}) async {
    final conditions = <String>[];
    final args = <dynamic>[];

    if (userId != null && userId.isNotEmpty) {
      conditions.add('user_id = ?');
      args.add(userId);
    }
    if (status != null) {
      conditions.add('status = ?');
      args.add(status.code);
    }

    final where = conditions.isNotEmpty ? conditions.join(' AND ') : null;
    final rows = await database.query(
      tableName,
      where: where,
      whereArgs: args.isNotEmpty ? args : null,
      orderBy: 'created_at DESC',
    );

    return rows.map((r) => SyncQueueModel.fromSqlRow(r)).toList();
  }

  @override
  Future<SyncQueueModel?> getItemById(String id) async {
    final rows = await database.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return SyncQueueModel.fromSqlRow(rows.first);
  }

  @override
  Future<void> updateItem(SyncQueueModel item) async {
    await database.update(
      tableName,
      item.toSqlRow(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  @override
  Future<void> deleteItem(String id) async {
    await database.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> clearSynced() async {
    await database.delete(
      tableName,
      where: 'status = ?',
      whereArgs: [SyncStatus.synced.code],
    );
  }

  @override
  Future<void> clearAll() async {
    await database.clearTable(tableName);
  }

  @override
  Future<int> countPending({String? userId}) async {
    String? where;
    List<dynamic>? args;

    if (userId != null && userId.isNotEmpty) {
      where = 'status = ? AND user_id = ?';
      args = [SyncStatus.pending.code, userId];
    } else {
      where = 'status = ?';
      args = [SyncStatus.pending.code];
    }

    return database.count(tableName, where: where, whereArgs: args);
  }
}
