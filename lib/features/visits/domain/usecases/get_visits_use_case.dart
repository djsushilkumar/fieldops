import '../entities/visit_entity.dart';
import '../repositories/visit_repository.dart';

class GetVisitsUseCase {
  final VisitRepository repository;

  GetVisitsUseCase(this.repository);

  Future<List<VisitEntity>> call({
    String? userId,
    String? taskId,
    DateTime? date,
  }) async {
    return repository.getVisits(
      userId: userId,
      taskId: taskId,
      date: date,
    );
  }
}
