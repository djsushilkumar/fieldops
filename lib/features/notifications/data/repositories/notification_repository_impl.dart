import 'package:uuid/uuid.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_local_datasource.dart';
import '../datasources/notification_remote_datasource.dart';
import '../models/notification_model.dart';
import '../../../sync/domain/entities/sync_entity_type.dart';
import '../../../sync/domain/entities/sync_operation.dart';
import '../../../sync/domain/entities/sync_queue_item.dart';
import '../../../sync/domain/entities/sync_status.dart';
import '../../../sync/domain/repositories/sync_queue_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;
  final NotificationLocalDataSource localDataSource;
  final SyncQueueRepository? syncQueueRepository;
  final String Function()? getUserId;
  final String Function()? getOrgId;

  NotificationRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    this.syncQueueRepository,
    this.getUserId,
    this.getOrgId,
  });

  @override
  Future<List<NotificationEntity>> getNotifications({
    required String userId,
    String? organizationId,
  }) async {
    try {
      final remoteList = await remoteDataSource.getNotifications(
        userId: userId,
        organizationId: organizationId,
      );
      await localDataSource.cacheNotifications(remoteList);
      return remoteList.map((m) => m.toEntity()).toList();
    } catch (_) {
      final cachedList = await localDataSource.getCachedNotifications(
        userId: userId,
        organizationId: organizationId,
      );
      return cachedList.map((m) => m.toEntity()).toList();
    }
  }

  @override
  Future<NotificationEntity> sendNotification(
    NotificationEntity notification,
  ) async {
    final model = NotificationModel.fromEntity(notification);
    await localDataSource.cacheNotification(model);

    try {
      final remoteModel = await remoteDataSource.sendNotification(model);
      await localDataSource.cacheNotification(remoteModel);
      return remoteModel.toEntity();
    } catch (e) {
      if (syncQueueRepository != null) {
        final item = SyncQueueItem(
          id: const Uuid().v4(),
          userId: notification.userId,
          operation: SyncOperation.create,
          entityType: SyncEntityType.notification,
          entityId: notification.id,
          payload: model.toJson(),
          status: SyncStatus.pending,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await syncQueueRepository!.enqueue(item);
      }
      return notification;
    }
  }

  @override
  Future<void> markAsRead(String id) async {
    final readAt = DateTime.now();
    await localDataSource.markAsRead(id, readAt);
    try {
      await remoteDataSource.markAsRead(id, readAt);
    } catch (_) {
      // Offline fallback: will be synced or is locally preserved
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    final readAt = DateTime.now();
    await localDataSource.markAllAsRead(userId, readAt);
    try {
      await remoteDataSource.markAllAsRead(userId, readAt);
    } catch (_) {
      // Offline fallback
    }
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    try {
      return await remoteDataSource.getUnreadCount(userId);
    } catch (_) {
      final cached = await localDataSource.getCachedNotifications(userId: userId);
      return cached.where((n) => n.readAt == null).length;
    }
  }
}
