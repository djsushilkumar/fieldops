import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class CreateTaskUseCase {
  final TaskRepository repository;

  CreateTaskUseCase(this.repository);

  Future<TaskEntity> execute(TaskEntity task, {String? assignToUserId}) async {
    if (task.title.trim().isEmpty) {
      throw Exception('Task title cannot be empty');
    }
    return await repository.createTask(task, assignToUserId: assignToUserId);
  }
}
