import '../entities/visit_entity.dart';
import '../repositories/visit_repository.dart';

class GetActiveVisitUseCase {
  final VisitRepository repository;

  GetActiveVisitUseCase(this.repository);

  Future<VisitEntity?> call({String? userId, String? taskId}) async {
    return repository.getActiveVisit(
      userId: userId,
      taskId: taskId,
    );
  }
}
