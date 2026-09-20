import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class CompleteTaskUseCase {
  final TaskRepository repository;

  CompleteTaskUseCase(this.repository);

  Future<TaskEntity> execute(String taskId, {String? notes}) async {
    if (taskId.trim().isEmpty) {
      throw Exception('Task ID cannot be empty');
    }
    return await repository.completeTask(taskId, notes: notes);
  }
}
