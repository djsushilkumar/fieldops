import 'package:uuid/uuid.dart';
import '../../domain/entities/beat_execution_entity.dart';
import '../../domain/entities/beat_plan_entity.dart';
import '../../domain/entities/beat_stop_entity.dart';
import '../../domain/repositories/beat_repository.dart';
import '../../domain/services/route_optimization_engine.dart';
import '../datasources/beat_local_datasource.dart';
import '../datasources/beat_remote_datasource.dart';
import '../models/beat_execution_model.dart';
import '../models/beat_plan_model.dart';
import '../models/beat_stop_model.dart';

class BeatRepositoryImpl implements BeatRepository {
  final BeatLocalDataSource _localDataSource;
  final BeatRemoteDataSource _remoteDataSource;
  final Uuid _uuid;

  BeatRepositoryImpl({
    required BeatLocalDataSource localDataSource,
    required BeatRemoteDataSource remoteDataSource,
    Uuid? uuid,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _uuid = uuid ?? const Uuid();

  @override
  Future<List<BeatPlanEntity>> getBeatPlans({String? technicianId, bool? activeOnly}) async {
    try {
      final remotePlans = await _remoteDataSource.getBeatPlans();
      for (final plan in remotePlans) {
        await _localDataSource.saveBeatPlan(plan);
      }
    } catch (_) {}

    final plans = await _localDataSource.getBeatPlans(
      technicianId: technicianId,
      activeOnly: activeOnly,
    );
    if (plans.isNotEmpty) return plans;

    if (technicianId != null) {
      return await _localDataSource.getBeatPlans(activeOnly: activeOnly);
    }
    return plans;
  }

  @override
  Future<BeatPlanEntity?> getBeatPlanById(String id) async {
    final local = await _localDataSource.getBeatPlanById(id);
    if (local != null) return local;

    try {
      final remote = await _remoteDataSource.getBeatPlanById(id);
      if (remote != null) {
        await _localDataSource.saveBeatPlan(remote);
        return remote;
      }
    } catch (_) {}

    return null;
  }

  @override
  Future<BeatPlanEntity> createBeatPlan(BeatPlanEntity beatPlan) async {
    final model = BeatPlanModel.fromEntity(beatPlan);
    await _localDataSource.saveBeatPlan(model);
    try {
      await _remoteDataSource.saveBeatPlan(model);
    } catch (_) {}
    return model;
  }

  @override
  Future<BeatExecutionEntity?> getTodayBeatExecution(String userId, String date) async {
    final local = await _localDataSource.getTodayBeatExecution(userId, date);
    if (local != null) return local;

    try {
      final remote = await _remoteDataSource.getTodayBeatExecution(userId, date);
      if (remote != null) {
        await _localDataSource.saveBeatExecution(remote);
        return remote;
      }
    } catch (_) {}

    return null;
  }

  @override
  Future<BeatExecutionEntity> startBeatExecution({
    required String beatPlanId,
    required String userId,
    required String userName,
    required String date,
    required List<BeatStopEntity> stops,
  }) async {
    final plan = await getBeatPlanById(beatPlanId);
    final beatName = plan?.name ?? 'Daily PJP Beat';

    final execution = BeatExecutionModel(
      id: _uuid.v4(),
      beatPlanId: beatPlanId,
      beatName: beatName,
      userId: userId,
      userName: userName,
      date: date,
      status: BeatExecutionStatus.inProgress,
      totalStops: stops.length,
      visitedStops: 0,
      skippedStops: 0,
      complianceRate: 0.0,
      startTime: DateTime.now(),
      stops: stops.map((s) => BeatStopModel.fromEntity(s)).toList(),
      createdAt: DateTime.now(),
    );

    await _localDataSource.saveBeatExecution(execution);
    try {
      await _remoteDataSource.saveBeatExecution(execution);
    } catch (_) {}

    return execution;
  }

  @override
  Future<BeatExecutionEntity> updateStopVisit({
    required String executionId,
    required String stopId,
    required bool isVisited,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    String? skipReason,
  }) async {
    final executions = await _localDataSource.getAllBeatExecutions();
    final current = executions.firstWhere((e) => e.id == executionId);

    final updatedStops = current.stops.map((s) {
      if (s.id == stopId) {
        return s.copyWith(
          isVisited: isVisited,
          checkInTime: checkInTime ?? s.checkInTime,
          checkOutTime: checkOutTime ?? s.checkOutTime,
          skipReason: skipReason ?? s.skipReason,
        );
      }
      return s;
    }).toList();

    final visitedCount = updatedStops.where((s) => s.isVisited).length;
    final skippedCount = updatedStops.where((s) => s.skipReason != null).length;
    final compliance = RouteOptimizationEngine.calculateBeatCompliance(
      plannedStops: current.totalStops,
      visitedStops: visitedCount,
    );

    final updated = current.copyWith(
      stops: updatedStops,
      visitedStops: visitedCount,
      skippedStops: skippedCount,
      complianceRate: compliance,
    );

    final model = BeatExecutionModel.fromEntity(updated);
    await _localDataSource.saveBeatExecution(model);
    try {
      await _remoteDataSource.saveBeatExecution(model);
    } catch (_) {}

    return model;
  }

  @override
  Future<BeatExecutionEntity> completeBeatExecution(String executionId) async {
    final executions = await _localDataSource.getAllBeatExecutions();
    final current = executions.firstWhere((e) => e.id == executionId);

    final updated = current.copyWith(
      status: BeatExecutionStatus.completed,
      endTime: DateTime.now(),
    );

    final model = BeatExecutionModel.fromEntity(updated);
    await _localDataSource.saveBeatExecution(model);
    try {
      await _remoteDataSource.saveBeatExecution(model);
    } catch (_) {}

    return model;
  }

  @override
  Future<String> exportBeatComplianceCsv(List<BeatExecutionEntity> executions) async {
    final buffer = StringBuffer();
    buffer.writeln(
      'Execution ID,Beat Name,Technician,Date,Status,Total Stops,Visited Stops,Skipped Stops,Compliance %,Rating,Start Time,End Time',
    );

    for (final e in executions) {
      final rating = RouteOptimizationEngine.getComplianceRating(e.complianceRate);
      final row = [
        e.id,
        '"${e.beatName.replaceAll('"', '""')}"',
        '"${e.userName.replaceAll('"', '""')}"',
        e.date,
        e.status.displayName,
        e.totalStops,
        e.visitedStops,
        e.skippedStops,
        '${e.complianceRate.toStringAsFixed(1)}%',
        rating,
        e.startTime?.toIso8601String() ?? 'N/A',
        e.endTime?.toIso8601String() ?? 'N/A',
      ];
      buffer.writeln(row.join(','));
    }

    return buffer.toString();
  }
}
