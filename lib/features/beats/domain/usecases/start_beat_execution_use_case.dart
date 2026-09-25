import '../entities/beat_execution_entity.dart';
import '../entities/beat_stop_entity.dart';
import '../repositories/beat_repository.dart';

class StartBeatExecutionUseCase {
  final BeatRepository _repository;

  StartBeatExecutionUseCase(this._repository);

  Future<BeatExecutionEntity> call({
    required String beatPlanId,
    required String userId,
    required String userName,
    required String date,
    required List<BeatStopEntity> stops,
  }) async {
    return await _repository.startBeatExecution(
      beatPlanId: beatPlanId,
      userId: userId,
      userName: userName,
      date: date,
      stops: stops,
    );
  }
}
