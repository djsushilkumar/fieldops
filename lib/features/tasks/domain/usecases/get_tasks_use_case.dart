import '../entities/task_entity.dart';
import '../entities/task_filter.dart';
import '../repositories/task_repository.dart';

class GetTasksUseCase {
  final TaskRepository repository;

  GetTasksUseCase(this.repository);

  Future<List<TaskEntity>> execute({TaskFilter? filter}) async {
    return await repository.getTasks(filter: filter);
  }
}
