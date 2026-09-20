import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_ops/features/notifications/domain/entities/notification_entity.dart';
import 'package:field_ops/features/notifications/domain/entities/notification_type.dart';
import 'package:field_ops/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:field_ops/features/notifications/presentation/screens/notification_list_screen.dart';
import 'package:field_ops/features/notifications/presentation/widgets/notification_badge_icon.dart';
import 'package:field_ops/features/notifications/presentation/widgets/notification_item_card.dart';

class FakeNotificationsController extends NotificationsController {
  FakeNotificationsController(super.ref, List<NotificationEntity> notifs) {
    state = NotificationsState(
      isLoading: false,
      notifications: notifs,
      filter: 'all',
    );
  }

  @override
  Future<void> loadNotifications() async {}
}

void main() {
  Widget buildTestableWidget({required Widget child, List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: child,
      ),
    );
  }

  final testNotifications = [
    NotificationEntity(
      id: 'notif-1',
      organizationId: 'org-001',
      userId: 'emp-001',
      type: NotificationType.taskAssigned,
      title: 'Emergency Generator Inspection',
      body: 'Please attend to building B generator urgently.',
      readAt: null,
      data: {'task_id': 'task-555'},
      createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
    NotificationEntity(
      id: 'notif-2',
      organizationId: 'org-001',
      userId: 'emp-001',
      type: NotificationType.visitAlert,
      title: 'Customer Site Geofence',
      body: 'You are near customer location.',
      readAt: null,
      data: {},
      createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
    ),
  ];

  group('NotificationBadgeIcon Widget Tests', () {
    testWidgets('NotificationBadgeIcon shows unread count badge when > 0', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: AppBar(
                actions: const [NotificationBadgeIcon()],
              ),
            ),
          ),
          overrides: [
            unreadNotificationsCountProvider.overrideWithValue(3),
          ],
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(NotificationBadgeIcon), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('NotificationBadgeIcon does not show number badge when 0 unread', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: Scaffold(
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: AppBar(
                actions: const [NotificationBadgeIcon()],
              ),
            ),
          ),
          overrides: [
            unreadNotificationsCountProvider.overrideWithValue(0),
          ],
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(NotificationBadgeIcon), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });
  });

  group('NotificationItemCard Widget Tests', () {
    testWidgets('renders notification details and action hint for task', (tester) async {
      final notif = NotificationEntity(
        id: 'notif-test',
        organizationId: 'org-001',
        userId: 'emp-001',
        type: NotificationType.taskAssigned,
        title: 'Emergency Generator Inspection',
        body: 'Please attend to building B generator urgently.',
        readAt: null,
        data: {'task_id': 'task-555'},
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      );

      bool markReadCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationItemCard(
              notification: notif,
              onMarkRead: () {
                markReadCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Emergency Generator Inspection'), findsOneWidget);
      expect(find.text('Please attend to building B generator urgently.'), findsOneWidget);
      expect(find.text('TASK ASSIGNED'), findsOneWidget);
      expect(find.text('Open Task Details'), findsOneWidget);

      final markReadBtn = find.byTooltip('Mark as read');
      expect(markReadBtn, findsOneWidget);
      await tester.tap(markReadBtn);
      await tester.pumpAndSettle();

      expect(markReadCalled, isTrue);
    });
  });

  group('NotificationListScreen Widget Tests', () {
    testWidgets('renders list of notifications with filter chips and actions', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const NotificationListScreen(),
          overrides: [
            notificationsControllerProvider.overrideWith(
              (ref) => FakeNotificationsController(ref, List.from(testNotifications)),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.textContaining('All ('), findsOneWidget);
      expect(find.textContaining('Unread ('), findsOneWidget);
      expect(find.byKey(const Key('mark_all_read_button')), findsOneWidget);

      // Switch to unread filter
      await tester.tap(find.textContaining('Unread ('));
      await tester.pumpAndSettle();

      // Tap Mark All Read
      await tester.tap(find.byKey(const Key('mark_all_read_button')));
      await tester.pumpAndSettle();

      // After mark all read, empty state should show
      expect(find.text('All Caught Up!'), findsOneWidget);
    });
  });
}
