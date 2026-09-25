import '../entities/beat_execution_entity.dart';
import '../repositories/beat_repository.dart';

class UpdateStopVisitUseCase {
  final BeatRepository _repository;

  UpdateStopVisitUseCase(this._repository);

  Future<BeatExecutionEntity> call({
    required String executionId,
    required String stopId,
    required bool isVisited,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    String? skipReason,
  }) async {
    return await _repository.updateStopVisit(
      executionId: executionId,
      stopId: stopId,
      isVisited: isVisited,
      checkInTime: checkInTime,
      checkOutTime: checkOutTime,
      skipReason: skipReason,
    );
  }
}
