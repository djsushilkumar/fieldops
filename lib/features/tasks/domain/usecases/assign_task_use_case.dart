import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class AssignTaskUseCase {
  final TaskRepository repository;

  AssignTaskUseCase(this.repository);

  Future<TaskEntity> execute(String taskId, String userId) async {
    if (taskId.trim().isEmpty) {
      throw Exception('Task ID cannot be empty');
    }
    if (userId.trim().isEmpty) {
      throw Exception('User ID cannot be empty');
    }
    return await repository.assignTask(taskId, userId);
  }
}
