import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/task_filter.dart';
import '../../domain/entities/task_status.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_datasource.dart';
import '../datasources/task_remote_datasource.dart';
import '../models/task_model.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource remoteDataSource;
  final TaskLocalDataSource localDataSource;

  TaskRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<TaskEntity>> getTasks({TaskFilter? filter}) async {
    try {
      final remoteList = await remoteDataSource.getTasks(
        status: filter?.status?.value,
        priority: filter?.priority?.value,
        assignedUserId: filter?.assignedUserId,
      );

      // Cache locally for offline availability
      await localDataSource.cacheTasks(remoteList);

      var entities = remoteList.map((m) => m.toEntity()).toList();

      if (filter?.searchQuery != null && filter!.searchQuery!.trim().isNotEmpty) {
        final query = filter.searchQuery!.trim().toLowerCase();
        entities = entities.where((t) {
          final titleMatch = t.title.toLowerCase().contains(query);
          final descMatch = t.description?.toLowerCase().contains(query) ?? false;
          final custMatch = t.customerName?.toLowerCase().contains(query) ?? false;
          final userMatch = t.assignedToUserName?.toLowerCase().contains(query) ?? false;
          return titleMatch || descMatch || custMatch || userMatch;
        }).toList();
      }

      return entities;
    } catch (e) {
      // Fallback to local offline cache
      try {
        final cached = await localDataSource.getCachedTasks();
        var entities = cached.map((m) => m.toEntity()).toList();

        if (filter?.status != null) {
          entities = entities.where((t) => t.status == filter!.status).toList();
        }
        if (filter?.priority != null) {
          entities = entities.where((t) => t.priority == filter!.priority).toList();
        }
        if (filter?.assignedUserId != null) {
          entities = entities.where((t) => t.assignedToUserId == filter!.assignedUserId).toList();
        }
        if (filter?.searchQuery != null && filter!.searchQuery!.trim().isNotEmpty) {
          final query = filter.searchQuery!.trim().toLowerCase();
          entities = entities.where((t) {
            final titleMatch = t.title.toLowerCase().contains(query);
            final descMatch = t.description?.toLowerCase().contains(query) ?? false;
            final custMatch = t.customerName?.toLowerCase().contains(query) ?? false;
            final userMatch = t.assignedToUserName?.toLowerCase().contains(query) ?? false;
            return titleMatch || descMatch || custMatch || userMatch;
          }).toList();
        }

        return entities;
      } catch (_) {
        throw const ServerFailure('Failed to load tasks');
      }
    }
  }

  @override
  Future<TaskEntity> getTask(String taskId) async {
    try {
      final model = await remoteDataSource.getTask(taskId);
      await localDataSource.cacheTask(model);
      return model.toEntity();
    } catch (e) {
      final cached = await localDataSource.getCachedTask(taskId);
      if (cached != null) {
        return cached.toEntity();
      }
      throw NotFoundFailure('Task $taskId not found');
    }
  }

  @override
  Future<TaskEntity> createTask(TaskEntity task, {String? assignToUserId}) async {
    try {
      final model = TaskModel.fromEntity(task);
      final created = await remoteDataSource.createTask(model, assignToUserId: assignToUserId);
      await localDataSource.cacheTask(created);
      return created.toEntity();
    } on ServerException catch (e) {
      throw ServerFailure(e.message, e.code);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<TaskEntity> assignTask(String taskId, String userId) async {
    try {
      final assigned = await remoteDataSource.assignTask(taskId, userId);
      await localDataSource.cacheTask(assigned);
      return assigned.toEntity();
    } on ServerException catch (e) {
      throw ServerFailure(e.message, e.code);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<TaskEntity> updateTaskStatus(String taskId, TaskStatus status, {String? notes}) async {
    try {
      DateTime? actualStart;
      DateTime? actualEnd;
      if (status == TaskStatus.inProgress) {
        actualStart = DateTime.now();
      } else if (status == TaskStatus.completed) {
        actualEnd = DateTime.now();
      }

      final updated = await remoteDataSource.updateTaskStatus(
        taskId,
        status.value,
        actualStart: actualStart,
        actualEnd: actualEnd,
        notes: notes,
      );
      await localDataSource.cacheTask(updated);
      return updated.toEntity();
    } on ServerException catch (e) {
      // Offline support: update local cache immediately so worker can continue
      final cached = await localDataSource.getCachedTask(taskId);
      if (cached != null) {
        final localUpdated = TaskModel(
          id: cached.id,
          organizationId: cached.organizationId,
          title: cached.title,
          description: cached.description,
          taskTypeId: cached.taskTypeId,
          priority: cached.priority,
          status: status.value,
          assignedToUserId: cached.assignedToUserId,
          assignedToUserName: cached.assignedToUserName,
          customerId: cached.customerId,
          customerName: cached.customerName,
          locationId: cached.locationId,
          locationName: cached.locationName,
          createdBy: cached.createdBy,
          creatorName: cached.creatorName,
          scheduledStart: cached.scheduledStart,
          scheduledEnd: cached.scheduledEnd,
          actualStart: status == TaskStatus.inProgress ? DateTime.now() : cached.actualStart,
          actualEnd: status == TaskStatus.completed ? DateTime.now() : cached.actualEnd,
          requiresGps: cached.requiresGps,
          requiresPhoto: cached.requiresPhoto,
          requiresForm: cached.requiresForm,
          notes: notes ?? cached.notes,
          createdAt: cached.createdAt,
          updatedAt: DateTime.now(),
        );
        await localDataSource.cacheTask(localUpdated);
        return localUpdated.toEntity();
      }
      throw ServerFailure(e.message, e.code);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
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
