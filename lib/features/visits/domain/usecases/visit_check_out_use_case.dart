import '../entities/visit_entity.dart';
import '../repositories/visit_repository.dart';

class VisitCheckOutUseCase {
  final VisitRepository repository;

  VisitCheckOutUseCase(this.repository);

  Future<VisitEntity> call({
    required String visitId,
    required double latitude,
    required double longitude,
    String? notes,
  }) async {
    return repository.checkOut(
      visitId: visitId,
      latitude: latitude,
      longitude: longitude,
      notes: notes,
    );
  }
}
