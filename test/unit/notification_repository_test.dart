import 'package:flutter_test/flutter_test.dart';
import 'package:field_ops/features/notifications/data/datasources/notification_local_datasource.dart';
import 'package:field_ops/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:field_ops/features/notifications/data/models/notification_model.dart';
import 'package:field_ops/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:field_ops/features/notifications/domain/entities/notification_entity.dart';
import 'package:field_ops/features/notifications/domain/entities/notification_type.dart';
import 'package:field_ops/features/notifications/domain/usecases/get_notifications_use_case.dart';
import 'package:field_ops/features/notifications/domain/usecases/mark_all_read_use_case.dart';
import 'package:field_ops/features/notifications/domain/usecases/mark_notification_read_use_case.dart';
import 'package:field_ops/features/notifications/domain/usecases/send_notification_use_case.dart';

class FailingRemoteDataSource implements NotificationRemoteDataSource {
  @override
  Future<List<NotificationModel>> getNotifications({
    required String userId,
    String? organizationId,
  }) async {
    throw Exception('Network unreachable');
  }

  @override
  Future<NotificationModel> sendNotification(NotificationModel notification) async {
    throw Exception('Network unreachable');
  }

  @override
  Future<void> markAsRead(String id, DateTime readAt) async {
    throw Exception('Network unreachable');
  }

  @override
  Future<void> markAllAsRead(String userId, DateTime readAt) async {
    throw Exception('Network unreachable');
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    throw Exception('Network unreachable');
  }
}

void main() {
  group('MockNotificationRemoteDataSource Tests', () {
    late MockNotificationRemoteDataSource dataSource;

    setUp(() {
      dataSource = MockNotificationRemoteDataSource();
    });

    test('getNotifications returns seeded notifications for employee', () async {
      final notifs = await dataSource.getNotifications(userId: 'emp-001');
      expect(notifs.isNotEmpty, isTrue);
      expect(notifs.every((n) => n.userId == 'emp-001'), isTrue);
    });

    test('getUnreadCount returns correct count and decreases after markAsRead', () async {
      final initialCount = await dataSource.getUnreadCount('emp-001');
      expect(initialCount, greaterThan(0));

      final notifs = await dataSource.getNotifications(userId: 'emp-001');
      final firstUnread = notifs.firstWhere((n) => n.readAt == null);

      await dataSource.markAsRead(firstUnread.id, DateTime.now());
      final countAfter = await dataSource.getUnreadCount('emp-001');
      expect(countAfter, equals(initialCount - 1));
    });

    test('markAllAsRead marks all notifications as read', () async {
      await dataSource.markAllAsRead('emp-001', DateTime.now());
      final count = await dataSource.getUnreadCount('emp-001');
      expect(count, equals(0));
    });

    test('sendNotification adds notification to data source', () async {
      final newNotif = NotificationModel(
        id: 'new-001',
        organizationId: 'org-001',
        userId: 'emp-001',
        type: 'SYSTEM_ANNOUNCEMENT',
        title: 'Emergency Maintenance',
        body: 'Server update at 11 PM',
        readAt: null,
        data: {},
        createdAt: DateTime.now(),
      );

      final result = await dataSource.sendNotification(newNotif);
      expect(result.id, 'new-001');

      final list = await dataSource.getNotifications(userId: 'emp-001');
      expect(list.any((n) => n.id == 'new-001'), isTrue);
    });
  });

  group('NotificationRepositoryImpl Tests', () {
    late NotificationLocalDataSource localDataSource;
    late MockNotificationRemoteDataSource remoteDataSource;
    late NotificationRepositoryImpl repository;

    setUp(() {
      localDataSource = NotificationLocalDataSourceImpl();
      remoteDataSource = MockNotificationRemoteDataSource();
      repository = NotificationRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
        getUserId: () => 'emp-001',
        getOrgId: () => 'org-001',
      );
    });

    test('getNotifications fetches from remote and caches locally', () async {
      final notifs = await repository.getNotifications(userId: 'emp-001');
      expect(notifs.isNotEmpty, isTrue);

      // Verify cached in local
      final cached = await localDataSource.getCachedNotifications(userId: 'emp-001');
      expect(cached.length, equals(notifs.length));
    });

    test('getNotifications falls back to local cache on remote error', () async {
      // Pre-seed local cache
      final seedModel = NotificationModel(
        id: 'local-001',
        organizationId: 'org-001',
        userId: 'emp-001',
        type: 'TASK_ASSIGNED',
        title: 'Cached Task',
        body: 'From SQLite cache',
        readAt: null,
        data: {},
        createdAt: DateTime.now(),
      );
      await localDataSource.cacheNotification(seedModel);

      final offlineRepo = NotificationRepositoryImpl(
        remoteDataSource: FailingRemoteDataSource(),
        localDataSource: localDataSource,
      );

      final results = await offlineRepo.getNotifications(userId: 'emp-001');
      expect(results.length, equals(1));
      expect(results.first.id, 'local-001');
    });

    test('markAsRead and markAllAsRead update status locally and remotely', () async {
      final notifs = await repository.getNotifications(userId: 'emp-001');
      final first = notifs.first;

      await repository.markAsRead(first.id);
      final cached = await localDataSource.getCachedNotificationById(first.id);
      expect(cached?.readAt, isNotNull);

      await repository.markAllAsRead('emp-001');
      final unreadCount = await repository.getUnreadCount('emp-001');
      expect(unreadCount, equals(0));
    });

    test('sendNotification caches locally and dispatches to remote', () async {
      final notifEntity = NotificationEntity(
        id: 'send-001',
        organizationId: 'org-001',
        userId: 'emp-001',
        type: NotificationType.taskAssigned,
        title: 'New Dispatch',
        body: 'Dispatched to customer site',
        readAt: null,
        data: {},
        createdAt: DateTime.now(),
      );

      final sent = await repository.sendNotification(notifEntity);
      expect(sent.id, 'send-001');

      final cached = await localDataSource.getCachedNotificationById('send-001');
      expect(cached, isNotNull);
    });
  });

  group('Notification Use Cases Tests', () {
    late NotificationRepositoryImpl repository;

    setUp(() {
      repository = NotificationRepositoryImpl(
        remoteDataSource: MockNotificationRemoteDataSource(),
        localDataSource: NotificationLocalDataSourceImpl(),
      );
    });

    test('GetNotificationsUseCase executes successfully', () async {
      final useCase = GetNotificationsUseCase(repository);
      final list = await useCase(userId: 'emp-001');
      expect(list.isNotEmpty, isTrue);
    });

    test('MarkNotificationReadUseCase marks read successfully', () async {
      final markUseCase = MarkNotificationReadUseCase(repository);
      final list = await repository.getNotifications(userId: 'emp-001');
      final id = list.first.id;

      await markUseCase(id);
      final notifs = await repository.getNotifications(userId: 'emp-001');
      expect(notifs.firstWhere((n) => n.id == id).isRead, isTrue);
    });

    test('MarkAllReadUseCase marks all notifications read', () async {
      final markAllUseCase = MarkAllReadUseCase(repository);
      await markAllUseCase('emp-001');

      final count = await repository.getUnreadCount('emp-001');
      expect(count, equals(0));
    });

    test('SendNotificationUseCase sends notification successfully', () async {
      final sendUseCase = SendNotificationUseCase(repository);
      final item = NotificationEntity(
        id: 'uc-001',
        organizationId: 'org-001',
        userId: 'emp-001',
        type: NotificationType.visitAlert,
        title: 'Visit scheduled',
        body: 'Customer visit booked',
        readAt: null,
        data: {},
        createdAt: DateTime.now(),
      );

      final sent = await sendUseCase(item);
      expect(sent.id, 'uc-001');
    });
  });
}
