import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../../../core/errors/exceptions.dart';
import '../models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationModel>> getNotifications({
    required String userId,
    String? organizationId,
  });
  Future<NotificationModel> sendNotification(NotificationModel notification);
  Future<void> markAsRead(String id, DateTime readAt);
  Future<void> markAllAsRead(String userId, DateTime readAt);
  Future<int> getUnreadCount(String userId);
}

class SupabaseNotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final supa.SupabaseClient client;

  SupabaseNotificationRemoteDataSourceImpl(this.client);

  @override
  Future<List<NotificationModel>> getNotifications({
    required String userId,
    String? organizationId,
  }) async {
    try {
      var query = client.from('notifications').select().eq('user_id', userId);
      if (organizationId != null) {
        query = query.eq('organization_id', organizationId);
      }
      final data = await query.order('created_at', ascending: false);
      return (data as List<dynamic>)
          .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<NotificationModel> sendNotification(NotificationModel notification) async {
    try {
      final res = await client
          .from('notifications')
          .insert(notification.toJson())
          .select()
          .single();
      return NotificationModel.fromJson(Map<String, dynamic>.from(res));
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> markAsRead(String id, DateTime readAt) async {
    try {
      await client
          .from('notifications')
          .update({'read_at': readAt.toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> markAllAsRead(String userId, DateTime readAt) async {
    try {
      await client
          .from('notifications')
          .update({'read_at': readAt.toIso8601String()})
          .eq('user_id', userId)
          .isFilter('read_at', null);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    try {
      final res = await client
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .isFilter('read_at', null);
      return (res as List).length;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}

class MockNotificationRemoteDataSource implements NotificationRemoteDataSource {
  final List<NotificationModel> _mockNotifications = [
    NotificationModel(
      id: 'notif-001',
      organizationId: 'org-001',
      userId: 'emp-001',
      type: 'TASK_ASSIGNED',
      title: 'New High Priority Task Assigned',
      body: 'HVAC Compressor Diagnostics assigned by Sarah Jenkins.',
      readAt: null,
      data: {'task_id': 'task-001'},
      createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
    ),
    NotificationModel(
      id: 'notif-002',
      organizationId: 'org-001',
      userId: 'emp-001',
      type: 'VISIT_ALERT',
      title: 'Approaching Customer Geofence',
      body: 'You are within 150m of Metro Tower A. Check-in is now unlocked.',
      readAt: null,
      data: {'visit_id': 'visit-001', 'task_id': 'task-001'},
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
    NotificationModel(
      id: 'notif-003',
      organizationId: 'org-001',
      userId: 'emp-001',
      type: 'ATTENDANCE_REMINDER',
      title: 'Shift Verified',
      body: 'Morning GPS check-in recorded at 08:30 AM (Geofence Verified).',
      readAt: DateTime.now().subtract(const Duration(hours: 3)),
      data: {},
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    NotificationModel(
      id: 'notif-004',
      organizationId: 'org-001',
      userId: 'emp-001',
      type: 'PROOF_VERIFIED',
      title: 'Client Signature Captured',
      body: 'Customer signature verified for Job #T-204.',
      readAt: DateTime.now().subtract(const Duration(hours: 5)),
      data: {'task_id': 'task-002'},
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    NotificationModel(
      id: 'notif-005',
      organizationId: 'org-001',
      userId: 'mgr-001',
      type: 'OVERDUE_WARNING',
      title: 'Task Overdue Alert',
      body: 'Chiller Maintenance (Tech: Alex Rivera) has exceeded scheduled window.',
      readAt: null,
      data: {'task_id': 'task-003'},
      createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
    ),
    NotificationModel(
      id: 'notif-006',
      organizationId: 'org-001',
      userId: 'mgr-001',
      type: 'TASK_COMPLETED',
      title: 'Task Finished & Verified',
      body: 'Safety valve calibration marked completed with 2 photo proofs.',
      readAt: null,
      data: {'task_id': 'task-004'},
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    NotificationModel(
      id: 'notif-007',
      organizationId: 'org-001',
      userId: 'admin-001',
      type: 'SYSTEM_ANNOUNCEMENT',
      title: 'Fleet Observability Online',
      body: 'Realtime GPS tracking and metrics stream activated across 3 branches.',
      readAt: null,
      data: {},
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  @override
  Future<List<NotificationModel>> getNotifications({
    required String userId,
    String? organizationId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));
    var results = _mockNotifications.where((n) => n.userId == userId).toList();
    if (organizationId != null) {
      results = results.where((n) => n.organizationId == organizationId).toList();
    }
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results;
  }

  @override
  Future<NotificationModel> sendNotification(NotificationModel notification) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _mockNotifications.insert(0, notification);
    return notification;
  }

  @override
  Future<void> markAsRead(String id, DateTime readAt) async {
    await Future.delayed(const Duration(milliseconds: 30));
    final index = _mockNotifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      final existing = _mockNotifications[index];
      _mockNotifications[index] = NotificationModel(
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
    }
  }

  @override
  Future<void> markAllAsRead(String userId, DateTime readAt) async {
    await Future.delayed(const Duration(milliseconds: 30));
    for (int i = 0; i < _mockNotifications.length; i++) {
      if (_mockNotifications[i].userId == userId && _mockNotifications[i].readAt == null) {
        final existing = _mockNotifications[i];
        _mockNotifications[i] = NotificationModel(
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
      }
    }
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    await Future.delayed(const Duration(milliseconds: 20));
    return _mockNotifications
        .where((n) => n.userId == userId && n.readAt == null)
        .length;
  }
}
