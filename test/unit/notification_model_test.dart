import 'package:flutter_test/flutter_test.dart';
import 'package:field_ops/features/notifications/data/models/notification_model.dart';
import 'package:field_ops/features/notifications/domain/entities/notification_entity.dart';
import 'package:field_ops/features/notifications/domain/entities/notification_type.dart';

void main() {
  group('NotificationType Enum Tests', () {
    test('NotificationType fromString parses known codes properly', () {
      expect(NotificationType.fromString('TASK_ASSIGNED'), NotificationType.taskAssigned);
      expect(NotificationType.fromString('TASK_STARTED'), NotificationType.taskStarted);
      expect(NotificationType.fromString('TASK_COMPLETED'), NotificationType.taskCompleted);
      expect(NotificationType.fromString('OVERDUE_WARNING'), NotificationType.overdueWarning);
      expect(NotificationType.fromString('VISIT_ALERT'), NotificationType.visitAlert);
      expect(NotificationType.fromString('ATTENDANCE_REMINDER'), NotificationType.attendanceReminder);
      expect(NotificationType.fromString('PROOF_VERIFIED'), NotificationType.proofVerified);
      expect(NotificationType.fromString('SYSTEM_ANNOUNCEMENT'), NotificationType.systemAnnouncement);
      // Fallback
      expect(NotificationType.fromString('UNKNOWN_CODE'), NotificationType.taskAssigned);
      expect(NotificationType.fromString(null), NotificationType.taskAssigned);
    });

    test('NotificationType properties (code, displayName, icon, color) are non-null', () {
      for (final type in NotificationType.values) {
        expect(type.code.isNotEmpty, isTrue);
        expect(type.displayName.isNotEmpty, isTrue);
        expect(type.icon, isNotNull);
        expect(type.color, isNotNull);
      }
    });
  });

  group('NotificationModel Serialization Tests', () {
    final now = DateTime(2026, 9, 20, 10, 30);
    final model = NotificationModel(
      id: 'notif-123',
      organizationId: 'org-001',
      userId: 'usr-001',
      type: 'TASK_ASSIGNED',
      title: 'New Assignment',
      body: 'HVAC repair task assigned',
      readAt: null,
      data: {'task_id': 'task-999', 'priority': 'HIGH'},
      createdAt: now,
    );

    test('toJson and fromJson work reversibly', () {
      final json = model.toJson();
      expect(json['id'], 'notif-123');
      expect(json['organization_id'], 'org-001');
      expect(json['user_id'], 'usr-001');
      expect(json['type'], 'TASK_ASSIGNED');
      expect(json['title'], 'New Assignment');
      expect(json['body'], 'HVAC repair task assigned');
      expect(json['read_at'], isNull);
      expect(json['data']['task_id'], 'task-999');

      final deserialized = NotificationModel.fromJson(json);
      expect(deserialized.id, model.id);
      expect(deserialized.organizationId, model.organizationId);
      expect(deserialized.type, model.type);
      expect(deserialized.title, model.title);
      expect(deserialized.body, model.body);
      expect(deserialized.data['task_id'], 'task-999');
      expect(deserialized.createdAt, now);
    });

    test('toSqlMap and fromSqlMap serialize data as string properly', () {
      final sqlMap = model.toSqlMap();
      expect(sqlMap['id'], 'notif-123');
      expect(sqlMap['data'], isA<String>());
      expect((sqlMap['data'] as String).contains('task-999'), isTrue);

      final deserialized = NotificationModel.fromSqlMap(sqlMap);
      expect(deserialized.id, model.id);
      expect(deserialized.data['task_id'], 'task-999');
    });

    test('toEntity and fromEntity convert accurately', () {
      final entity = model.toEntity();
      expect(entity.id, 'notif-123');
      expect(entity.type, NotificationType.taskAssigned);
      expect(entity.isUnread, isTrue);
      expect(entity.isRead, isFalse);
      expect(entity.taskId, 'task-999');
      expect(entity.visitId, isNull);

      final fromEntityModel = NotificationModel.fromEntity(entity);
      expect(fromEntityModel.id, model.id);
      expect(fromEntityModel.type, 'TASK_ASSIGNED');
    });

    test('NotificationEntity timeAgo and copyWith work as expected', () {
      final entity = NotificationEntity(
        id: 'notif-999',
        organizationId: 'org-001',
        userId: 'usr-001',
        type: NotificationType.visitAlert,
        title: 'Geofence alert',
        body: 'You arrived at site',
        readAt: null,
        data: {'visit_id': 'visit-456'},
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      expect(entity.timeAgo, '5m ago');
      expect(entity.visitId, 'visit-456');

      final readEntity = entity.copyWith(readAt: DateTime.now());
      expect(readEntity.isRead, isTrue);
      expect(readEntity.isUnread, isFalse);
    });
  });
}
