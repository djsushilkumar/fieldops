import '../entities/notification_entity.dart';

abstract class NotificationRepository {
  Future<List<NotificationEntity>> getNotifications({
    required String userId,
    String? organizationId,
  });

  Future<NotificationEntity> sendNotification(
    NotificationEntity notification,
  );

  Future<void> markAsRead(String id);

  Future<void> markAllAsRead(String userId);

  Future<int> getUnreadCount(String userId);
}
