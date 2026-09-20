import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/database/sqlite_database.dart';
import '../models/attachment_model.dart';

abstract class AttachmentLocalDataSource {
  Future<List<AttachmentModel>> getCachedTaskAttachments(String taskId);
  Future<AttachmentModel?> getCachedAttachmentById(String attachmentId);
  Future<void> cacheAttachment(AttachmentModel attachment);
  Future<void> cacheAttachments(List<AttachmentModel> attachments);
  Future<void> deleteCachedAttachment(String attachmentId);
  Future<void> clearAll();
}

class AttachmentLocalDataSourceImpl implements AttachmentLocalDataSource {
  final SharedPreferences? sharedPreferences;
  final SqliteDatabase? database;

  static const String _attachmentsKey = 'cached_attachments';

  // In-memory cache keyed by attachment ID
  final Map<String, AttachmentModel> _memoryAttachments = {};

  AttachmentLocalDataSourceImpl({
    this.sharedPreferences,
    this.database,
  });

  @override
  Future<List<AttachmentModel>> getCachedTaskAttachments(String taskId) async {
    // 1. Check in-memory cache
    if (_memoryAttachments.isNotEmpty) {
      final matches = _memoryAttachments.values.where((a) => a.taskId == taskId).toList();
      if (matches.isNotEmpty) {
        matches.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return matches;
      }
    }

    // 2. Check SQLite database if available
    if (database != null) {
      try {
        final rows = await database!.query(
          'attachments',
          where: 'task_id = ?',
          whereArgs: [taskId],
          orderBy: 'created_at DESC',
        );
        if (rows.isNotEmpty) {
          final models = rows.map((r) => AttachmentModel.fromSqlMap(r)).toList();
          for (final m in models) {
            _memoryAttachments[m.id] = m;
          }
          return models;
        }
      } catch (_) {}
    }

    // 3. Fallback to SharedPreferences
    final raw = sharedPreferences?.getString(_attachmentsKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final models = list
          .map((e) => AttachmentModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      for (final m in models) {
        _memoryAttachments[m.id] = m;
      }
      final matches = models.where((a) => a.taskId == taskId).toList();
      matches.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return matches;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<AttachmentModel?> getCachedAttachmentById(String attachmentId) async {
    if (_memoryAttachments.containsKey(attachmentId)) {
      return _memoryAttachments[attachmentId];
    }

    if (database != null) {
      try {
        final rows = await database!.query(
          'attachments',
          where: 'id = ?',
          whereArgs: [attachmentId],
          limit: 1,
        );
        if (rows.isNotEmpty) {
          final model = AttachmentModel.fromSqlMap(rows.first);
          _memoryAttachments[model.id] = model;
          return model;
        }
      } catch (_) {}
    }

    return null;
  }

  @override
  Future<void> cacheAttachment(AttachmentModel attachment) async {
    _memoryAttachments[attachment.id] = attachment;

    // Persist to SQLite
    if (database != null) {
      try {
        await database!.insert(
          'attachments',
          attachment.toSqlMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (_) {}
    }

    // Persist to SharedPreferences
    await _persistMemoryToPrefs();
  }

  @override
  Future<void> cacheAttachments(List<AttachmentModel> attachments) async {
    for (final a in attachments) {
      _memoryAttachments[a.id] = a;
      if (database != null) {
        try {
          await database!.insert(
            'attachments',
            a.toSqlMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        } catch (_) {}
      }
    }
    await _persistMemoryToPrefs();
  }

  @override
  Future<void> deleteCachedAttachment(String attachmentId) async {
    _memoryAttachments.remove(attachmentId);

    if (database != null) {
      try {
        await database!.delete(
          'attachments',
          where: 'id = ?',
          whereArgs: [attachmentId],
        );
      } catch (_) {}
    }

    await _persistMemoryToPrefs();
  }

  @override
  Future<void> clearAll() async {
    _memoryAttachments.clear();
    if (database != null) {
      try {
        await database!.clearTable('attachments');
      } catch (_) {}
    }
    await sharedPreferences?.remove(_attachmentsKey);
  }

  Future<void> _persistMemoryToPrefs() async {
    if (sharedPreferences == null) return;
    try {
      final list = _memoryAttachments.values.map((e) => e.toJson()).toList();
      await sharedPreferences!.setString(_attachmentsKey, jsonEncode(list));
    } catch (_) {}
  }
}
