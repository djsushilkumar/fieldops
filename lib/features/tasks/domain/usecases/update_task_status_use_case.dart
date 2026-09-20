import '../entities/task_entity.dart';
import '../entities/task_status.dart';
import '../repositories/task_repository.dart';

class UpdateTaskStatusUseCase {
  final TaskRepository repository;

  UpdateTaskStatusUseCase(this.repository);

  Future<TaskEntity> execute(String taskId, TaskStatus newStatus, {String? notes}) async {
    if (taskId.trim().isEmpty) {
      throw Exception('Task ID cannot be empty');
    }
    return await repository.updateTaskStatus(taskId, newStatus, notes: notes);
  }
}
