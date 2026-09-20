import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class StartTaskUseCase {
  final TaskRepository repository;

  StartTaskUseCase(this.repository);

  Future<TaskEntity> execute(String taskId) async {
    if (taskId.trim().isEmpty) {
      throw Exception('Task ID cannot be empty');
    }
    return await repository.startTask(taskId);
  }
}
