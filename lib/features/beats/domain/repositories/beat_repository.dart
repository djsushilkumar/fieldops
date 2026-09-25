import '../entities/beat_execution_entity.dart';
import '../entities/beat_plan_entity.dart';
import '../entities/beat_stop_entity.dart';

abstract class BeatRepository {
  Future<List<BeatPlanEntity>> getBeatPlans({String? technicianId, bool? activeOnly});

  Future<BeatPlanEntity?> getBeatPlanById(String id);

  Future<BeatPlanEntity> createBeatPlan(BeatPlanEntity beatPlan);

  Future<BeatExecutionEntity?> getTodayBeatExecution(String userId, String date);

  Future<BeatExecutionEntity> startBeatExecution({
    required String beatPlanId,
    required String userId,
    required String userName,
    required String date,
    required List<BeatStopEntity> stops,
  });

  Future<BeatExecutionEntity> updateStopVisit({
    required String executionId,
    required String stopId,
    required bool isVisited,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    String? skipReason,
  });

  Future<BeatExecutionEntity> completeBeatExecution(String executionId);

  Future<String> exportBeatComplianceCsv(List<BeatExecutionEntity> executions);
}
