import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:field_ops/core/errors/failures.dart';
import 'package:field_ops/features/auth/domain/entities/user_entity.dart';
import 'package:field_ops/features/auth/domain/entities/user_role.dart';
import 'package:field_ops/features/auth/presentation/controllers/auth_controller.dart';
import 'package:field_ops/features/tasks/domain/entities/task_entity.dart';
import 'package:field_ops/features/tasks/domain/entities/task_priority.dart';
import 'package:field_ops/features/tasks/domain/entities/task_status.dart';
import 'package:field_ops/features/tasks/domain/repositories/task_repository.dart';
import 'package:field_ops/features/tasks/presentation/controllers/task_controller.dart';

class StubTaskRepository implements TaskRepository {
  List<TaskEntity> tasksList = [];
  bool throwError = false;

  @override
  Future<List<TaskEntity>> getTasks({dynamic filter}) async {
    if (throwError) throw const ServerFailure('Failed to load tasks');
    var list = List<TaskEntity>.from(tasksList);
    if (filter != null) {
      if (filter.status != null) {
        list = list.where((t) => t.status == filter.status).toList();
      }
      if (filter.assignedUserId != null) {
        list = list.where((t) => t.assignedToUserId == filter.assignedUserId).toList();
      }
      if (filter.searchQuery != null && filter.searchQuery.isNotEmpty) {
        list = list.where((t) => t.title.toLowerCase().contains(filter.searchQuery.toLowerCase())).toList();
      }
    }
    return list;
  }

  @override
  Future<TaskEntity> getTask(String taskId) async {
    if (throwError) throw const NotFoundFailure('Task not found');
    final match = tasksList.where((t) => t.id == taskId).toList();
    if (match.isEmpty) throw const NotFoundFailure('Task not found');
    return match.first;
  }

  @override
  Future<TaskEntity> createTask(TaskEntity task, {String? assignToUserId}) async {
    if (throwError) throw const ServerFailure('Cannot create');
    final created = task.copyWith(
      id: 'tsk-created-id',
      assignedToUserId: assignToUserId ?? task.assignedToUserId,
      status: assignToUserId != null ? TaskStatus.assigned : task.status,
    );
    tasksList.add(created);
    return created;
  }

  @override
  Future<TaskEntity> assignTask(String taskId, String userId) async {
    final idx = tasksList.indexWhere((t) => t.id == taskId);
    if (idx == -1) throw const NotFoundFailure('Task not found');
    final updated = tasksList[idx].copyWith(
      assignedToUserId: userId,
      assignedToUserName: 'Assigned $userId',
      status: TaskStatus.assigned,
    );
    tasksList[idx] = updated;
    return updated;
  }

  @override
  Future<TaskEntity> updateTaskStatus(String taskId, TaskStatus status, {String? notes}) async {
    final idx = tasksList.indexWhere((t) => t.id == taskId);
    if (idx == -1) throw const NotFoundFailure('Task not found');
    final updated = tasksList[idx].copyWith(
      status: status,
      notes: notes ?? tasksList[idx].notes,
      actualStart: status == TaskStatus.inProgress ? DateTime.now() : tasksList[idx].actualStart,
      actualEnd: status == TaskStatus.completed ? DateTime.now() : tasksList[idx].actualEnd,
    );
    tasksList[idx] = updated;
    return updated;
  }

  @override
  Future<TaskEntity> startTask(String taskId) async {
    return await updateTaskStatus(taskId, TaskStatus.inProgress);
  }

  @override
  Future<TaskEntity> completeTask(String taskId, {String? notes}) async {
    return await updateTaskStatus(taskId, TaskStatus.completed, notes: notes);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StubTaskRepository stubRepo;
  late ProviderContainer container;

  final sampleTask = TaskEntity(
    id: 'tsk-001',
    organizationId: 'org-001',
    title: 'AC Maintenance Check',
    status: TaskStatus.assigned,
    priority: TaskPriority.high,
    assignedToUserId: 'usr-emp-001',
    assignedToUserName: 'John Worker',
    requiresGps: true,
    requiresPhoto: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    stubRepo = StubTaskRepository();
    stubRepo.tasksList = [sampleTask];

    container = ProviderContainer(
      overrides: [
        taskRepositoryProvider.overrideWithValue(stubRepo),
        currentUserProvider.overrideWithValue(
          UserEntity(
            id: 'usr-admin-001',
            organizationId: 'org-001',
            name: 'Admin Boss',
            email: 'admin@fieldops.com',
            role: UserRole.admin,
            status: 'active',
            createdAt: DateTime(2026, 1, 1),
            updatedAt: DateTime(2026, 1, 1),
          ),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('TaskListNotifier', () {
    test('loads tasks on initialization and updates state to success', () async {
      final notifier = container.read(taskListNotifierProvider.notifier);
      await notifier.loadTasks();

      final state = container.read(taskListNotifierProvider);
      expect(state.status, equals(TaskListStatus.success));
      expect(state.tasks.length, equals(1));
      expect(state.tasks.first.title, equals('AC Maintenance Check'));
      expect(state.isLoading, isFalse);
      expect(state.hasError, isFalse);
    });

    test('setStatusFilter reloads tasks with specific status filter', () async {
      final notifier = container.read(taskListNotifierProvider.notifier);
      await notifier.loadTasks();

      // Filter by completed (none exists)
      notifier.setStatusFilter(TaskStatus.completed);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final state = container.read(taskListNotifierProvider);
      expect(state.filter.status, equals(TaskStatus.completed));
      expect(state.tasks, isEmpty);
      expect(state.isEmpty, isTrue);

      // Filter by assigned
      notifier.setStatusFilter(TaskStatus.assigned);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final assignedState = container.read(taskListNotifierProvider);
      expect(assignedState.tasks.length, equals(1));
    });

    test('setSearchQuery filters by query', () async {
      final notifier = container.read(taskListNotifierProvider.notifier);
      await notifier.loadTasks();

      notifier.setSearchQuery('Nonexistent');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(container.read(taskListNotifierProvider).tasks, isEmpty);

      notifier.setSearchQuery('Maintenance');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(container.read(taskListNotifierProvider).tasks.length, equals(1));
    });

    test('handles error and sets TaskListStatus.error', () async {
      stubRepo.throwError = true;
      final notifier = container.read(taskListNotifierProvider.notifier);
      await notifier.loadTasks();

      final state = container.read(taskListNotifierProvider);
      expect(state.status, equals(TaskListStatus.error));
      expect(state.hasError, isTrue);
      expect(state.errorMessage, contains('Failed to load tasks'));
    });
  });

  group('TaskDetailNotifier', () {
    test('loads task details correctly by ID', () async {
      final detailNotifier = container.read(taskDetailNotifierProvider('tsk-001').notifier);
      await detailNotifier.loadTask();

      final state = container.read(taskDetailNotifierProvider('tsk-001'));
      expect(state.isLoading, isFalse);
      expect(state.task, isNotNull);
      expect(state.task!.id, equals('tsk-001'));
      expect(state.task!.title, equals('AC Maintenance Check'));
    });

    test('startTask updates task status to inProgress', () async {
      final detailNotifier = container.read(taskDetailNotifierProvider('tsk-001').notifier);
      await detailNotifier.loadTask();

      final success = await detailNotifier.startTask();
      expect(success, isTrue);

      final state = container.read(taskDetailNotifierProvider('tsk-001'));
      expect(state.task!.status, equals(TaskStatus.inProgress));
      expect(state.task!.actualStart, isNotNull);
    });

    test('completeTask updates task status to completed with notes', () async {
      final detailNotifier = container.read(taskDetailNotifierProvider('tsk-001').notifier);
      await detailNotifier.loadTask();

      final success = await detailNotifier.completeTask(notes: 'Job all done');
      expect(success, isTrue);

      final state = container.read(taskDetailNotifierProvider('tsk-001'));
      expect(state.task!.status, equals(TaskStatus.completed));
      expect(state.task!.notes, equals('Job all done'));
      expect(state.task!.actualEnd, isNotNull);
    });

    test('assignTask changes assigned user ID', () async {
      final detailNotifier = container.read(taskDetailNotifierProvider('tsk-001').notifier);
      await detailNotifier.loadTask();

      final success = await detailNotifier.assignTask('usr-emp-999');
      expect(success, isTrue);

      final state = container.read(taskDetailNotifierProvider('tsk-001'));
      expect(state.task!.assignedToUserId, equals('usr-emp-999'));
    });

    test('handles error on non-existent task', () async {
      final detailNotifier = container.read(taskDetailNotifierProvider('tsk-nonexistent').notifier);
      await detailNotifier.loadTask();

      final state = container.read(taskDetailNotifierProvider('tsk-nonexistent'));
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNotNull);
    });
  });
}
