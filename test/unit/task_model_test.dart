import 'package:flutter_test/flutter_test.dart';
import 'package:field_ops/features/tasks/data/models/task_model.dart';
import 'package:field_ops/features/tasks/domain/entities/task_entity.dart';
import 'package:field_ops/features/tasks/domain/entities/task_filter.dart';
import 'package:field_ops/features/tasks/domain/entities/task_priority.dart';
import 'package:field_ops/features/tasks/domain/entities/task_status.dart';

void main() {
  group('TaskPriority', () {
    test('fromString parses correctly with case insensitivity', () {
      expect(TaskPriority.fromString('LOW'), equals(TaskPriority.low));
      expect(TaskPriority.fromString('low'), equals(TaskPriority.low));
      expect(TaskPriority.fromString('MEDIUM'), equals(TaskPriority.medium));
      expect(TaskPriority.fromString('HIGH'), equals(TaskPriority.high));
      expect(TaskPriority.fromString('URGENT'), equals(TaskPriority.urgent));
      expect(TaskPriority.fromString(null), equals(TaskPriority.medium));
      expect(TaskPriority.fromString('UNKNOWN'), equals(TaskPriority.medium));
    });

    test('labels and values match expected strings', () {
      expect(TaskPriority.low.value, equals('LOW'));
      expect(TaskPriority.low.label, equals('Low'));
      expect(TaskPriority.urgent.value, equals('URGENT'));
      expect(TaskPriority.urgent.label, equals('Urgent'));
    });
  });

  group('TaskStatus', () {
    test('fromString parses all enum values', () {
      expect(TaskStatus.fromString('DRAFT'), equals(TaskStatus.draft));
      expect(TaskStatus.fromString('ASSIGNED'), equals(TaskStatus.assigned));
      expect(TaskStatus.fromString('ACCEPTED'), equals(TaskStatus.accepted));
      expect(TaskStatus.fromString('IN_PROGRESS'), equals(TaskStatus.inProgress));
      expect(TaskStatus.fromString('COMPLETED'), equals(TaskStatus.completed));
      expect(TaskStatus.fromString('CANCELLED'), equals(TaskStatus.cancelled));
      expect(TaskStatus.fromString('OVERDUE'), equals(TaskStatus.overdue));
      expect(TaskStatus.fromString(null), equals(TaskStatus.assigned));
      expect(TaskStatus.fromString('OTHER'), equals(TaskStatus.assigned));
    });

    test('status helper getters work correctly', () {
      expect(TaskStatus.draft.isDraft, isTrue);
      expect(TaskStatus.assigned.isAssigned, isTrue);
      expect(TaskStatus.accepted.isAccepted, isTrue);
      expect(TaskStatus.inProgress.isInProgress, isTrue);
      expect(TaskStatus.completed.isCompleted, isTrue);
      expect(TaskStatus.cancelled.isCancelled, isTrue);
      expect(TaskStatus.overdue.isOverdue, isTrue);

      expect(TaskStatus.inProgress.isActive, isTrue);
      expect(TaskStatus.assigned.isActive, isTrue);
      expect(TaskStatus.accepted.isActive, isTrue);
      expect(TaskStatus.completed.isActive, isFalse);
      expect(TaskStatus.cancelled.isActive, isFalse);
    });

    test('canTransitionTo enforces valid lifecycle transitions', () {
      // Draft transitions
      expect(TaskStatus.draft.canTransitionTo(TaskStatus.assigned), isTrue);
      expect(TaskStatus.draft.canTransitionTo(TaskStatus.cancelled), isTrue);
      expect(TaskStatus.draft.canTransitionTo(TaskStatus.completed), isFalse);

      // Assigned transitions
      expect(TaskStatus.assigned.canTransitionTo(TaskStatus.accepted), isTrue);
      expect(TaskStatus.assigned.canTransitionTo(TaskStatus.inProgress), isTrue);
      expect(TaskStatus.assigned.canTransitionTo(TaskStatus.cancelled), isTrue);
      expect(TaskStatus.assigned.canTransitionTo(TaskStatus.completed), isFalse);

      // In Progress transitions
      expect(TaskStatus.inProgress.canTransitionTo(TaskStatus.completed), isTrue);
      expect(TaskStatus.inProgress.canTransitionTo(TaskStatus.cancelled), isTrue);
      expect(TaskStatus.inProgress.canTransitionTo(TaskStatus.draft), isFalse);

      // Terminal states (Completed and Cancelled) cannot transition
      expect(TaskStatus.completed.canTransitionTo(TaskStatus.inProgress), isFalse);
      expect(TaskStatus.completed.canTransitionTo(TaskStatus.assigned), isFalse);
      expect(TaskStatus.cancelled.canTransitionTo(TaskStatus.inProgress), isFalse);

      // Transitioning to same status is allowed
      expect(TaskStatus.inProgress.canTransitionTo(TaskStatus.inProgress), isTrue);
    });
  });

  group('TaskModel Serialization & Deserialization', () {
    final taskJson = {
      'id': 'task-001',
      'organization_id': 'org-001',
      'title': 'HVAC Filter Replacement',
      'description': 'Replace HEPA filters on Floor 3',
      'task_type_id': 'type-001',
      'priority': 'HIGH',
      'status': 'IN_PROGRESS',
      'assigned_to_user_id': 'usr-002',
      'assigned_to_user_name': 'Sarah Connor',
      'customer_id': 'cust-001',
      'customer_name': 'Acme Corp',
      'location_id': 'loc-001',
      'location_name': 'Building A',
      'created_by': 'usr-001',
      'creator_name': 'John Boss',
      'scheduled_start': '2026-09-20T08:00:00.000Z',
      'scheduled_end': '2026-09-20T12:00:00.000Z',
      'actual_start': '2026-09-20T08:15:00.000Z',
      'actual_end': null,
      'requires_gps': true,
      'requires_photo': true,
      'requires_form': false,
      'notes': 'Call reception upon arrival',
      'created_at': '2026-09-19T10:00:00.000Z',
      'updated_at': '2026-09-20T08:15:00.000Z',
    };

    test('fromJson parses full JSON correctly', () {
      final model = TaskModel.fromJson(taskJson);

      expect(model.id, equals('task-001'));
      expect(model.organizationId, equals('org-001'));
      expect(model.title, equals('HVAC Filter Replacement'));
      expect(model.description, equals('Replace HEPA filters on Floor 3'));
      expect(model.priority, equals('HIGH'));
      expect(model.status, equals('IN_PROGRESS'));
      expect(model.assignedToUserId, equals('usr-002'));
      expect(model.assignedToUserName, equals('Sarah Connor'));
      expect(model.customerName, equals('Acme Corp'));
      expect(model.requiresGps, isTrue);
      expect(model.requiresPhoto, isTrue);
      expect(model.requiresForm, isFalse);
      expect(model.scheduledStart, isNotNull);
      expect(model.scheduledEnd, isNotNull);
      expect(model.actualStart, isNotNull);
      expect(model.actualEnd, isNull);
    });

    test('toJson serializes correctly', () {
      final model = TaskModel.fromJson(taskJson);
      final serialized = model.toJson();

      expect(serialized['id'], equals('task-001'));
      expect(serialized['organization_id'], equals('org-001'));
      expect(serialized['title'], equals('HVAC Filter Replacement'));
      expect(serialized['priority'], equals('HIGH'));
      expect(serialized['status'], equals('IN_PROGRESS'));
      expect(serialized['requires_gps'], isTrue);
      expect(serialized['requires_photo'], isTrue);
    });

    test('toEntity converts to TaskEntity with correct enum values', () {
      final model = TaskModel.fromJson(taskJson);
      final entity = model.toEntity();

      expect(entity.id, equals('task-001'));
      expect(entity.priority, equals(TaskPriority.high));
      expect(entity.status, equals(TaskStatus.inProgress));
      expect(entity.isInProgress, isTrue);
      expect(entity.isAssigned, isTrue);
      expect(entity.hasProofRequirements, isTrue);
      expect(entity.canComplete, isTrue);
      expect(entity.canStart, isFalse); // Already in progress
    });

    test('fromEntity converts TaskEntity back to TaskModel', () {
      final model = TaskModel.fromJson(taskJson);
      final entity = model.toEntity();
      final roundTripModel = TaskModel.fromEntity(entity);

      expect(roundTripModel.id, equals(model.id));
      expect(roundTripModel.title, equals(model.title));
      expect(roundTripModel.priority, equals(model.priority));
      expect(roundTripModel.status, equals(model.status));
      expect(roundTripModel.assignedToUserId, equals(model.assignedToUserId));
    });
  });

  group('TaskEntity getters and copyWith', () {
    final baseEntity = TaskEntity(
      id: 'task-test',
      organizationId: 'org-test',
      title: 'Site Visit',
      status: TaskStatus.assigned,
      priority: TaskPriority.medium,
      requiresGps: true,
      scheduledEnd: DateTime.now().add(const Duration(hours: 2)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('canStart is true when assigned or accepted', () {
      expect(baseEntity.canStart, isTrue);

      final acceptedEntity = baseEntity.copyWith(status: TaskStatus.accepted);
      expect(acceptedEntity.canStart, isTrue);

      final inProgressEntity = baseEntity.copyWith(status: TaskStatus.inProgress);
      expect(inProgressEntity.canStart, isFalse);
    });

    test('canComplete is true only when inProgress', () {
      expect(baseEntity.canComplete, isFalse);

      final inProgressEntity = baseEntity.copyWith(status: TaskStatus.inProgress);
      expect(inProgressEntity.canComplete, isTrue);

      final completedEntity = baseEntity.copyWith(status: TaskStatus.completed);
      expect(completedEntity.canComplete, isFalse);
    });

    test('isOverdue logic works based on scheduledEnd or overdue status', () {
      // Future scheduledEnd: not overdue
      expect(baseEntity.isOverdue, isFalse);

      // Past scheduledEnd: is overdue
      final pastEntity = baseEntity.copyWith(
        scheduledEnd: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(pastEntity.isOverdue, isTrue);

      // If already completed, not overdue even if scheduledEnd passed
      final completedPastEntity = pastEntity.copyWith(status: TaskStatus.completed);
      expect(completedPastEntity.isOverdue, isFalse);

      // Explicit overdue status
      final explicitOverdue = baseEntity.copyWith(status: TaskStatus.overdue);
      expect(explicitOverdue.isOverdue, isTrue);
    });

    test('copyWith updates specified fields only', () {
      final updated = baseEntity.copyWith(
        title: 'Updated Site Visit',
        priority: TaskPriority.urgent,
        assignedToUserId: 'usr-new',
      );

      expect(updated.id, equals(baseEntity.id));
      expect(updated.title, equals('Updated Site Visit'));
      expect(updated.priority, equals(TaskPriority.urgent));
      expect(updated.assignedToUserId, equals('usr-new'));
      expect(updated.organizationId, equals(baseEntity.organizationId));
    });
  });

  group('TaskFilter', () {
    test('default values are empty and null', () {
      const filter = TaskFilter();
      expect(filter.status, isNull);
      expect(filter.priority, isNull);
      expect(filter.assignedUserId, isNull);
      expect(filter.searchQuery, isNull);
      expect(filter.isEmpty, isTrue);
    });

    test('copyWith works and isEmpty is false when criteria set', () {
      const filter = TaskFilter();
      final updated = filter.copyWith(
        status: TaskStatus.inProgress,
        searchQuery: 'filter check',
      );

      expect(updated.status, equals(TaskStatus.inProgress));
      expect(updated.searchQuery, equals('filter check'));
      expect(updated.isEmpty, isFalse);
    });
  });
}
