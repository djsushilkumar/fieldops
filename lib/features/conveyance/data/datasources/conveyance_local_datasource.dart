import '../../../../core/database/sqlite_database.dart';
import '../models/conveyance_claim_model.dart';

abstract class ConveyanceLocalDataSource {
  Future<ConveyanceClaimModel?> getClaimById(String id);
  Future<ConveyanceClaimModel?> getActiveShiftClaim(String userId, String shiftDate);
  Future<List<ConveyanceClaimModel>> getUserClaims(String userId);
  Future<List<ConveyanceClaimModel>> getAllClaims({
    String? status,
    bool? flaggedOnly,
    String? searchQuery,
  });
  Future<void> saveClaim(ConveyanceClaimModel claim);
  Future<void> deleteClaim(String id);
}

class ConveyanceLocalDataSourceImpl implements ConveyanceLocalDataSource {
  final SqliteDatabase _database;
  static const String tableName = 'conveyance_claims';

  ConveyanceLocalDataSourceImpl(this._database);

  @override
  Future<ConveyanceClaimModel?> getClaimById(String id) async {
    final rows = await _database.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ConveyanceClaimModel.fromSqlMap(rows.first);
  }

  @override
  Future<ConveyanceClaimModel?> getActiveShiftClaim(String userId, String shiftDate) async {
    final rows = await _database.query(
      tableName,
      where: 'user_id = ? AND shift_date = ?',
      whereArgs: [userId, shiftDate],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ConveyanceClaimModel.fromSqlMap(rows.first);
  }

  @override
  Future<List<ConveyanceClaimModel>> getUserClaims(String userId) async {
    final rows = await _database.query(
      tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return rows.map((r) => ConveyanceClaimModel.fromSqlMap(r)).toList();
  }

  @override
  Future<List<ConveyanceClaimModel>> getAllClaims({
    String? status,
    bool? flaggedOnly,
    String? searchQuery,
  }) async {
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (status != null && status.isNotEmpty) {
      whereClauses.add('status = ?');
      whereArgs.add(status);
    }

    if (flaggedOnly == true) {
      whereClauses.add('is_flagged = 1');
    }

    final where = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;
    final rows = await _database.query(
      tableName,
      where: where,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at DESC',
    );

    var claims = rows.map((r) => ConveyanceClaimModel.fromSqlMap(r)).toList();

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = searchQuery.trim().toLowerCase();
      claims = claims.where((c) {
        return c.userName.toLowerCase().contains(query) ||
            c.shiftDate.contains(query) ||
            c.vehicleType.displayName.toLowerCase().contains(query);
      }).toList();
    }

    return claims;
  }

  @override
  Future<void> saveClaim(ConveyanceClaimModel claim) async {
    await _database.insert(
      tableName,
      claim.toSqlMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteClaim(String id) async {
    await _database.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
