import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/database/app_database.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../sync/presentation/controllers/sync_controller.dart';
import '../../data/datasources/notification_local_datasource.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/notification_type.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/usecases/get_notifications_use_case.dart';
import '../../domain/usecases/mark_all_read_use_case.dart';
import '../../domain/usecases/mark_notification_read_use_case.dart';
import '../../domain/usecases/send_notification_use_case.dart';

// ============================================================================
// Providers
// ============================================================================

final notificationLocalDataSourceProvider = Provider<NotificationLocalDataSource>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return NotificationLocalDataSourceImpl(database: db);
});

final notificationRemoteDataSourceProvider = Provider<NotificationRemoteDataSource>((ref) {
  final supabase = SupabaseConfig.client;
  if (supabase != null) {
    return SupabaseNotificationRemoteDataSourceImpl(supabase);
  }
  return MockNotificationRemoteDataSource();
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final syncRepo = ref.watch(syncQueueRepositoryProvider);
  return NotificationRepositoryImpl(
    remoteDataSource: ref.watch(notificationRemoteDataSourceProvider),
    localDataSource: ref.watch(notificationLocalDataSourceProvider),
    syncQueueRepository: syncRepo,
    getOrgId: () => authState.user?.organizationId ?? 'org-acme-ops-001',
    getUserId: () => authState.user?.id ?? 'emp-001',
  );
});

final getNotificationsUseCaseProvider = Provider<GetNotificationsUseCase>((ref) {
  return GetNotificationsUseCase(ref.watch(notificationRepositoryProvider));
});

final markNotificationReadUseCaseProvider = Provider<MarkNotificationReadUseCase>((ref) {
  return MarkNotificationReadUseCase(ref.watch(notificationRepositoryProvider));
});

final markAllReadUseCaseProvider = Provider<MarkAllReadUseCase>((ref) {
  return MarkAllReadUseCase(ref.watch(notificationRepositoryProvider));
});

final sendNotificationUseCaseProvider = Provider<SendNotificationUseCase>((ref) {
  return SendNotificationUseCase(ref.watch(notificationRepositoryProvider));
});

// ============================================================================
// Controller & State
// ============================================================================

class NotificationsState {
  final bool isLoading;
  final List<NotificationEntity> notifications;
  final String filter; // 'all' or 'unread'
  final String? errorMessage;

  const NotificationsState({
    this.isLoading = false,
    this.notifications = const [],
    this.filter = 'all',
    this.errorMessage,
  });

  int get unreadCount => notifications.where((n) => n.isUnread).length;

  List<NotificationEntity> get filteredNotifications {
    if (filter == 'unread') {
      return notifications.where((n) => n.isUnread).toList();
    }
    return notifications;
  }

  NotificationsState copyWith({
    bool? isLoading,
    List<NotificationEntity>? notifications,
    String? filter,
    String? errorMessage,
  }) {
    return NotificationsState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      filter: filter ?? this.filter,
      errorMessage: errorMessage,
    );
  }
}

class NotificationsController extends StateNotifier<NotificationsState> {
  final Ref ref;

  NotificationsController(this.ref) : super(const NotificationsState()) {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final authState = ref.read(authNotifierProvider);
      final userId = authState.user?.id ?? 'emp-001';
      final orgId = authState.user?.organizationId;

      final getUseCase = ref.read(getNotificationsUseCaseProvider);
      final list = await getUseCase(userId: userId, organizationId: orgId);

      state = state.copyWith(
        isLoading: false,
        notifications: list,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load notifications: $e',
      );
    }
  }

  void setFilter(String filter) {
    state = state.copyWith(filter: filter);
  }

  Future<void> markAsRead(String id) async {
    final now = DateTime.now();
    // Optimistic update
    final updated = state.notifications.map((n) {
      if (n.id == id && n.isUnread) {
        return n.copyWith(readAt: now);
      }
      return n;
    }).toList();
    state = state.copyWith(notifications: updated);

    try {
      final markUseCase = ref.read(markNotificationReadUseCaseProvider);
      await markUseCase(id);
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    final now = DateTime.now();
    final updated = state.notifications.map((n) {
      return n.copyWith(readAt: n.readAt ?? now);
    }).toList();
    state = state.copyWith(notifications: updated);

    try {
      final authState = ref.read(authNotifierProvider);
      final userId = authState.user?.id ?? 'emp-001';
      final markAllUseCase = ref.read(markAllReadUseCaseProvider);
      await markAllUseCase(userId);
    } catch (_) {}
  }

  Future<void> sendNotification({
    required String title,
    required String body,
    required NotificationType type,
    String? targetUserId,
    Map<String, dynamic> data = const {},
  }) async {
    final authState = ref.read(authNotifierProvider);
    final userId = targetUserId ?? authState.user?.id ?? 'emp-001';
    final orgId = authState.user?.organizationId ?? 'org-acme-ops-001';

    final notif = NotificationEntity(
      id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
      organizationId: orgId,
      userId: userId,
      type: type,
      title: title,
      body: body,
      readAt: null,
      data: data,
      createdAt: DateTime.now(),
    );

    try {
      final sendUseCase = ref.read(sendNotificationUseCaseProvider);
      final sent = await sendUseCase(notif);
      if (sent.userId == (authState.user?.id ?? 'emp-001')) {
        state = state.copyWith(
          notifications: [sent, ...state.notifications],
        );
      }
    } catch (_) {}
  }

  Future<void> refresh() => loadNotifications();
}

final notificationsControllerProvider =
    StateNotifierProvider<NotificationsController, NotificationsState>((ref) {
  return NotificationsController(ref);
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationsControllerProvider).notifications;
  return notifs.where((n) => n.isUnread).length;
});
