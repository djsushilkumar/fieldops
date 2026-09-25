import '../entities/beat_plan_entity.dart';
import '../repositories/beat_repository.dart';

class GetBeatPlansUseCase {
  final BeatRepository _repository;

  GetBeatPlansUseCase(this._repository);

  Future<List<BeatPlanEntity>> call({String? technicianId, bool? activeOnly}) async {
    return await _repository.getBeatPlans(
      technicianId: technicianId,
      activeOnly: activeOnly,
    );
  }
}
