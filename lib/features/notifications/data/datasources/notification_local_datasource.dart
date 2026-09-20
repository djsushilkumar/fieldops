import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/database/sqlite_database.dart';
import '../models/notification_model.dart';

abstract class NotificationLocalDataSource {
  Future<List<NotificationModel>> getCachedNotifications({
    String? userId,
    String? organizationId,
  });
  Future<NotificationModel?> getCachedNotificationById(String id);
  Future<void> cacheNotification(NotificationModel notification);
  Future<void> cacheNotifications(List<NotificationModel> notifications);
  Future<void> markAsRead(String id, DateTime readAt);
  Future<void> markAllAsRead(String userId, DateTime readAt);
  Future<void> deleteNotification(String id);
  Future<void> clearAll();
}

class NotificationLocalDataSourceImpl implements NotificationLocalDataSource {
  final SharedPreferences? sharedPreferences;
  final SqliteDatabase? database;

  static const String _notificationsKey = 'cached_notifications';

  final Map<String, NotificationModel> _memoryNotifications = {};

  NotificationLocalDataSourceImpl({
    this.sharedPreferences,
    this.database,
  });

  @override
  Future<List<NotificationModel>> getCachedNotifications({
    String? userId,
    String? organizationId,
  }) async {
    // 1. In-memory cache
    if (_memoryNotifications.isNotEmpty) {
      var matches = _memoryNotifications.values.toList();
      if (userId != null) {
        matches = matches.where((n) => n.userId == userId).toList();
      }
      if (organizationId != null) {
        matches = matches.where((n) => n.organizationId == organizationId).toList();
      }
      if (matches.isNotEmpty) {
        matches.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return matches;
      }
    }

    // 2. Check SQLite
    if (database != null) {
      try {
        String? whereClause;
        List<dynamic>? whereArgs;

        if (userId != null && organizationId != null) {
          whereClause = 'user_id = ? AND organization_id = ?';
          whereArgs = [userId, organizationId];
        } else if (userId != null) {
          whereClause = 'user_id = ?';
          whereArgs = [userId];
        } else if (organizationId != null) {
          whereClause = 'organization_id = ?';
          whereArgs = [organizationId];
        }

        final rows = await database!.query(
          'notifications',
          where: whereClause,
          whereArgs: whereArgs,
          orderBy: 'created_at DESC',
        );
        if (rows.isNotEmpty) {
          final models = rows.map((r) => NotificationModel.fromSqlMap(r)).toList();
          for (final m in models) {
            _memoryNotifications[m.id] = m;
          }
          return models;
        }
      } catch (_) {}
    }

    // 3. Fallback to SharedPreferences
    final raw = sharedPreferences?.getString(_notificationsKey);
    if (raw != null) {
      try {
        final list = (jsonDecode(raw) as List)
            .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
            .toList();
        for (final m in list) {
          _memoryNotifications[m.id] = m;
        }
        var filtered = list;
        if (userId != null) {
          filtered = filtered.where((n) => n.userId == userId).toList();
        }
        if (organizationId != null) {
          filtered = filtered.where((n) => n.organizationId == organizationId).toList();
        }
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return filtered;
      } catch (_) {}
    }

    return [];
  }

  @override
  Future<NotificationModel?> getCachedNotificationById(String id) async {
    if (_memoryNotifications.containsKey(id)) {
      return _memoryNotifications[id];
    }
    if (database != null) {
      try {
        final rows = await database!.query(
          'notifications',
          where: 'id = ?',
          whereArgs: [id],
          limit: 1,
        );
        if (rows.isNotEmpty) {
          final model = NotificationModel.fromSqlMap(rows.first);
          _memoryNotifications[id] = model;
          return model;
        }
      } catch (_) {}
    }
    return null;
  }

  @override
  Future<void> cacheNotification(NotificationModel notification) async {
    _memoryNotifications[notification.id] = notification;

    if (database != null) {
      try {
        await database!.insert(
          'notifications',
          notification.toSqlMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (_) {}
    }

    await _syncToPrefs();
  }

  @override
  Future<void> cacheNotifications(List<NotificationModel> notifications) async {
    for (final n in notifications) {
      _memoryNotifications[n.id] = n;
      if (database != null) {
        try {
          await database!.insert(
            'notifications',
            n.toSqlMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        } catch (_) {}
      }
    }
    await _syncToPrefs();
  }

  @override
  Future<void> markAsRead(String id, DateTime readAt) async {
    final existing = _memoryNotifications[id];
    if (existing != null) {
      final updated = NotificationModel(
        id: existing.id,
        organizationId: existing.organizationId,
        userId: existing.userId,
        type: existing.type,
        title: existing.title,
        body: existing.body,
        readAt: readAt,
        data: existing.data,
        createdAt: existing.createdAt,
      );
      _memoryNotifications[id] = updated;
    }

    if (database != null) {
      try {
        await database!.update(
          'notifications',
          {'read_at': readAt.toIso8601String()},
          where: 'id = ?',
          whereArgs: [id],
        );
      } catch (_) {}
    }

    await _syncToPrefs();
  }

  @override
  Future<void> markAllAsRead(String userId, DateTime readAt) async {
    for (final entry in _memoryNotifications.entries) {
      if (entry.value.userId == userId && entry.value.readAt == null) {
        _memoryNotifications[entry.key] = NotificationModel(
          id: entry.value.id,
          organizationId: entry.value.organizationId,
          userId: entry.value.userId,
          type: entry.value.type,
          title: entry.value.title,
          body: entry.value.body,
          readAt: readAt,
          data: entry.value.data,
          createdAt: entry.value.createdAt,
        );
      }
    }

    if (database != null) {
      try {
        await database!.update(
          'notifications',
          {'read_at': readAt.toIso8601String()},
          where: 'user_id = ? AND read_at IS NULL',
          whereArgs: [userId],
        );
      } catch (_) {}
    }

    await _syncToPrefs();
  }

  @override
  Future<void> deleteNotification(String id) async {
    _memoryNotifications.remove(id);
    if (database != null) {
      try {
        await database!.delete(
          'notifications',
          where: 'id = ?',
          whereArgs: [id],
        );
      } catch (_) {}
    }
    await _syncToPrefs();
  }

  @override
  Future<void> clearAll() async {
    _memoryNotifications.clear();
    if (database != null) {
      try {
        await database!.delete('notifications');
      } catch (_) {}
    }
    await sharedPreferences?.remove(_notificationsKey);
  }

  Future<void> _syncToPrefs() async {
    if (sharedPreferences != null) {
      try {
        final list = _memoryNotifications.values.map((n) => n.toJson()).toList();
        await sharedPreferences!.setString(_notificationsKey, jsonEncode(list));
      } catch (_) {}
    }
  }
}
