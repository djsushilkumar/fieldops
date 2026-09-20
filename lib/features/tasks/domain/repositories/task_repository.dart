import '../entities/task_entity.dart';
import '../entities/task_filter.dart';
import '../entities/task_status.dart';

abstract class TaskRepository {
  Future<List<TaskEntity>> getTasks({TaskFilter? filter});
  Future<TaskEntity> getTask(String taskId);
  Future<TaskEntity> createTask(TaskEntity task, {String? assignToUserId});
  Future<TaskEntity> assignTask(String taskId, String userId);
  Future<TaskEntity> updateTaskStatus(String taskId, TaskStatus status, {String? notes});
  Future<TaskEntity> startTask(String taskId);
  Future<TaskEntity> completeTask(String taskId, {String? notes});
}
