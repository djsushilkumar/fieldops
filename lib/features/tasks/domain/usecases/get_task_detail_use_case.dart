import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class GetTaskDetailUseCase {
  final TaskRepository repository;

  GetTaskDetailUseCase(this.repository);

  Future<TaskEntity> execute(String taskId) async {
    if (taskId.trim().isEmpty) {
      throw Exception('Task ID cannot be empty');
    }
    return await repository.getTask(taskId);
  }
}
