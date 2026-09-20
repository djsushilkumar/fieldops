import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:field_ops/core/errors/exceptions.dart';
import 'package:field_ops/core/errors/failures.dart';
import 'package:field_ops/features/tasks/data/datasources/task_local_datasource.dart';
import 'package:field_ops/features/tasks/data/datasources/task_remote_datasource.dart';
import 'package:field_ops/features/tasks/data/models/task_model.dart';
import 'package:field_ops/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:field_ops/features/tasks/domain/entities/task_entity.dart';
import 'package:field_ops/features/tasks/domain/entities/task_filter.dart';
import 'package:field_ops/features/tasks/domain/entities/task_priority.dart';
import 'package:field_ops/features/tasks/domain/entities/task_status.dart';

class FakeRemoteDataSource implements TaskRemoteDataSource {
  final Map<String, TaskModel> tasks = {};
  bool throwError = false;

  @override
  Future<List<TaskModel>> getTasks({
    String? organizationId,
    String? assignedUserId,
    String? status,
    String? priority,
  }) async {
    if (throwError) throw const ServerException('Network connection failure');
    var list = tasks.values.toList();
    if (organizationId != null) {
      list = list.where((t) => t.organizationId == organizationId).toList();
    }
    if (status != null) {
      list = list.where((t) => t.status == status).toList();
    }
    if (priority != null) {
      list = list.where((t) => t.priority == priority).toList();
    }
    if (assignedUserId != null) {
      list = list.where((t) => t.assignedToUserId == assignedUserId).toList();
    }
    return list;
  }

  @override
  Future<TaskModel> getTask(String taskId) async {
    if (throwError) throw const ServerException('Network connection failure');
    final task = tasks[taskId];
    if (task == null) throw const ServerException('Task not found', '404');
    return task;
  }

  @override
  Future<TaskModel> createTask(TaskModel task, {String? assignToUserId}) async {
    if (throwError) throw const ServerException('Failed to create task');
    final created = TaskModel(
      id: task.id.isEmpty ? 'generated-id' : task.id,
      organizationId: task.organizationId,
      title: task.title,
      description: task.description,
      priority: task.priority,
      status: assignToUserId != null ? 'ASSIGNED' : task.status,
      assignedToUserId: assignToUserId ?? task.assignedToUserId,
      assignedToUserName: assignToUserId != null ? 'Assigned Worker' : task.assignedToUserName,
      customerName: task.customerName,
      locationName: task.locationName,
      requiresGps: task.requiresGps,
      requiresPhoto: task.requiresPhoto,
      requiresForm: task.requiresForm,
      notes: task.notes,
      createdAt: task.createdAt,
      updatedAt: DateTime.now(),
    );
    tasks[created.id] = created;
    return created;
  }

  @override
  Future<TaskModel> assignTask(String taskId, String userId) async {
    if (throwError) throw const ServerException('Failed to assign task');
    final existing = tasks[taskId];
    if (existing == null) throw const ServerException('Task not found');
    final updated = TaskModel(
      id: existing.id,
      organizationId: existing.organizationId,
      title: existing.title,
      description: existing.description,
      priority: existing.priority,
      status: 'ASSIGNED',
      assignedToUserId: userId,
      assignedToUserName: 'Assigned User $userId',
      customerName: existing.customerName,
      locationName: existing.locationName,
      requiresGps: existing.requiresGps,
      requiresPhoto: existing.requiresPhoto,
      requiresForm: existing.requiresForm,
      notes: existing.notes,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );
    tasks[taskId] = updated;
    return updated;
  }

  @override
  Future<TaskModel> updateTaskStatus(
    String taskId,
    String status, {
    DateTime? actualStart,
    DateTime? actualEnd,
    String? notes,
  }) async {
    if (throwError) throw const ServerException('Network down');
    final existing = tasks[taskId];
    if (existing == null) throw const ServerException('Task not found');
    final updated = TaskModel(
      id: existing.id,
      organizationId: existing.organizationId,
      title: existing.title,
      description: existing.description,
      priority: existing.priority,
      status: status,
      assignedToUserId: existing.assignedToUserId,
      assignedToUserName: existing.assignedToUserName,
      customerName: existing.customerName,
      locationName: existing.locationName,
      requiresGps: existing.requiresGps,
      requiresPhoto: existing.requiresPhoto,
      requiresForm: existing.requiresForm,
      notes: notes ?? existing.notes,
      actualStart: actualStart ?? existing.actualStart,
      actualEnd: actualEnd ?? existing.actualEnd,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );
    tasks[taskId] = updated;
    return updated;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeRemoteDataSource remoteDataSource;
  late TaskLocalDataSource localDataSource;
  late TaskRepositoryImpl repository;

  final sampleTask = TaskModel(
    id: 'tsk-001',
    organizationId: 'org-001',
    title: 'AC Maintenance Check',
    description: 'Quarterly filter and coolant audit',
    priority: 'HIGH',
    status: 'ASSIGNED',
    assignedToUserId: 'usr-100',
    assignedToUserName: 'Alice Tech',
    customerName: 'Apex Hospital',
    locationName: 'Roof Unit 4',
    requiresGps: true,
    requiresPhoto: true,
    requiresForm: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    remoteDataSource = FakeRemoteDataSource();
    localDataSource = TaskLocalDataSourceImpl();
    repository = TaskRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
    );

    remoteDataSource.tasks[sampleTask.id] = sampleTask;
  });

  group('TaskRepositoryImpl - getTasks', () {
    test('fetches tasks from remote and caches them locally', () async {
      final tasks = await repository.getTasks();

      expect(tasks.length, equals(1));
      expect(tasks.first.title, equals('AC Maintenance Check'));

      // Check local cache
      final cached = await localDataSource.getCachedTasks();
      expect(cached.length, equals(1));
      expect(cached.first.id, equals('tsk-001'));
    });

    test('falls back to local cache when remote throws ServerException', () async {
      // First populate cache
      await localDataSource.cacheTask(sampleTask);

      // Break remote
      remoteDataSource.throwError = true;

      final tasks = await repository.getTasks();
      expect(tasks.length, equals(1));
      expect(tasks.first.id, equals('tsk-001'));
    });

    test('filters tasks by status and priority', () async {
      final task2 = TaskModel(
        id: 'tsk-002',
        organizationId: 'org-001',
        title: 'Emergency Generator Fix',
        priority: 'URGENT',
        status: 'IN_PROGRESS',
        assignedToUserId: 'usr-100',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      remoteDataSource.tasks[task2.id] = task2;

      const urgentFilter = TaskFilter(priority: TaskPriority.urgent);
      final urgentTasks = await repository.getTasks(filter: urgentFilter);
      expect(urgentTasks.length, equals(1));
      expect(urgentTasks.first.id, equals('tsk-002'));

      const assignedFilter = TaskFilter(status: TaskStatus.assigned);
      final assignedTasks = await repository.getTasks(filter: assignedFilter);
      expect(assignedTasks.length, equals(1));
      expect(assignedTasks.first.id, equals('tsk-001'));
    });

    test('filters tasks by search query matching title or customer', () async {
      const filter = TaskFilter(searchQuery: 'hospital');
      final result = await repository.getTasks(filter: filter);
      expect(result.length, equals(1));
      expect(result.first.customerName, equals('Apex Hospital'));

      const noMatchFilter = TaskFilter(searchQuery: 'nonexistent keyword');
      final emptyResult = await repository.getTasks(filter: noMatchFilter);
      expect(emptyResult, isEmpty);
    });
  });

  group('TaskRepositoryImpl - getTask', () {
    test('returns task detail from remote', () async {
      final task = await repository.getTask('tsk-001');
      expect(task.id, equals('tsk-001'));
      expect(task.title, equals('AC Maintenance Check'));
    });

    test('falls back to local cache when remote fails', () async {
      await localDataSource.cacheTask(sampleTask);
      remoteDataSource.throwError = true;

      final task = await repository.getTask('tsk-001');
      expect(task.id, equals('tsk-001'));
    });

    test('throws NotFoundFailure when task does not exist anywhere', () async {
      expect(
        () => repository.getTask('tsk-unknown'),
        throwsA(isA<NotFoundFailure>()),
      );
    });
  });

  group('TaskRepositoryImpl - createTask and assignTask', () {
    test('creates new task and caches it', () async {
      final newTask = TaskEntity(
        id: 'tsk-new-01',
        organizationId: 'org-001',
        title: 'New Valve Inspection',
        priority: TaskPriority.medium,
        status: TaskStatus.draft,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created = await repository.createTask(newTask, assignToUserId: 'usr-200');
      expect(created.id, equals('tsk-new-01'));
      expect(created.status, equals(TaskStatus.assigned));
      expect(created.assignedToUserId, equals('usr-200'));

      final cached = await localDataSource.getCachedTask('tsk-new-01');
      expect(cached, isNotNull);
      expect(cached!.assignedToUserId, equals('usr-200'));
    });

    test('assigns task to a user', () async {
      final assigned = await repository.assignTask('tsk-001', 'usr-300');
      expect(assigned.assignedToUserId, equals('usr-300'));
      expect(assigned.status, equals(TaskStatus.assigned));
    });
  });

  group('TaskRepositoryImpl - updateTaskStatus, startTask, completeTask', () {
    test('startTask transitions status to inProgress and sets actualStart', () async {
      final started = await repository.startTask('tsk-001');
      expect(started.status, equals(TaskStatus.inProgress));
      expect(started.actualStart, isNotNull);
    });

    test('completeTask transitions status to completed with optional notes', () async {
      final completed = await repository.completeTask('tsk-001', notes: 'Done according to protocol');
      expect(completed.status, equals(TaskStatus.completed));
      expect(completed.notes, equals('Done according to protocol'));
      expect(completed.actualEnd, isNotNull);
    });

    test('offline status update modifies local cache when remote is down', () async {
      // Prime local cache
      await localDataSource.cacheTask(sampleTask);

      // Kill remote
      remoteDataSource.throwError = true;

      // Update offline
      final offlineResult = await repository.startTask('tsk-001');
      expect(offlineResult.status, equals(TaskStatus.inProgress));

      // Verify local cache reflects the offline progress
      final cached = await localDataSource.getCachedTask('tsk-001');
      expect(cached!.status, equals('IN_PROGRESS'));
      expect(cached.actualStart, isNotNull);
    });
  });
}
