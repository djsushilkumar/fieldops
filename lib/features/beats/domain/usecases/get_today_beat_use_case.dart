import '../entities/beat_execution_entity.dart';
import '../repositories/beat_repository.dart';

class GetTodayBeatUseCase {
  final BeatRepository _repository;

  GetTodayBeatUseCase(this._repository);

  Future<BeatExecutionEntity?> call(String userId, String date) async {
    return await _repository.getTodayBeatExecution(userId, date);
  }
}
