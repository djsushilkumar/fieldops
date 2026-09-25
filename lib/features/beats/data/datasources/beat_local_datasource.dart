import '../../../../core/database/sqlite_database.dart';
import '../models/beat_execution_model.dart';
import '../models/beat_plan_model.dart';

abstract class BeatLocalDataSource {
  Future<List<BeatPlanModel>> getBeatPlans({String? technicianId, bool? activeOnly});
  Future<BeatPlanModel?> getBeatPlanById(String id);
  Future<void> saveBeatPlan(BeatPlanModel plan);
  Future<BeatExecutionModel?> getTodayBeatExecution(String userId, String date);
  Future<void> saveBeatExecution(BeatExecutionModel execution);
  Future<List<BeatExecutionModel>> getAllBeatExecutions();
}

class BeatLocalDataSourceImpl implements BeatLocalDataSource {
  final SqliteDatabase _database;
  static const String plansTable = 'beat_plans';
  static const String executionsTable = 'beat_executions';

  BeatLocalDataSourceImpl(this._database);

  @override
  Future<List<BeatPlanModel>> getBeatPlans({String? technicianId, bool? activeOnly}) async {
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (technicianId != null && technicianId.isNotEmpty) {
      whereClauses.add('assigned_technician_id = ?');
      whereArgs.add(technicianId);
    }

    if (activeOnly == true) {
      whereClauses.add('is_active = 1');
    }

    final where = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;
    final rows = await _database.query(
      plansTable,
      where: where,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at DESC',
    );

    return rows.map((r) => BeatPlanModel.fromSqlMap(r)).toList();
  }

  @override
  Future<BeatPlanModel?> getBeatPlanById(String id) async {
    final rows = await _database.query(
      plansTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return BeatPlanModel.fromSqlMap(rows.first);
  }

  @override
  Future<void> saveBeatPlan(BeatPlanModel plan) async {
    await _database.insert(
      plansTable,
      plan.toSqlMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<BeatExecutionModel?> getTodayBeatExecution(String userId, String date) async {
    final rows = await _database.query(
      executionsTable,
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, date],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return BeatExecutionModel.fromSqlMap(rows.first);
  }

  @override
  Future<void> saveBeatExecution(BeatExecutionModel execution) async {
    await _database.insert(
      executionsTable,
      execution.toSqlMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<BeatExecutionModel>> getAllBeatExecutions() async {
    final rows = await _database.query(
      executionsTable,
      orderBy: 'date DESC',
    );
    return rows.map((r) => BeatExecutionModel.fromSqlMap(r)).toList();
  }
}
