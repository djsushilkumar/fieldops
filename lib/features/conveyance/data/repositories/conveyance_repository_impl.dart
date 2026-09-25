import 'package:uuid/uuid.dart';
import '../../domain/entities/conveyance_claim_entity.dart';
import '../../domain/entities/conveyance_status.dart';
import '../../domain/entities/odometer_reading_entity.dart';
import '../../domain/entities/vehicle_type.dart';
import '../../domain/repositories/conveyance_repository.dart';
import '../../domain/services/conveyance_reconciliation_engine.dart';
import '../datasources/conveyance_local_datasource.dart';
import '../datasources/conveyance_remote_datasource.dart';
import '../models/conveyance_claim_model.dart';
import '../models/odometer_reading_model.dart';

class ConveyanceRepositoryImpl implements ConveyanceRepository {
  final ConveyanceLocalDataSource _localDataSource;
  final ConveyanceRemoteDataSource _remoteDataSource;
  final Uuid _uuid;

  ConveyanceRepositoryImpl({
    required ConveyanceLocalDataSource localDataSource,
    required ConveyanceRemoteDataSource remoteDataSource,
    Uuid? uuid,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _uuid = uuid ?? const Uuid();

  @override
  Future<ConveyanceClaimEntity?> getActiveShiftClaim(String userId, String shiftDate) async {
    // Check local database first
    final localClaim = await _localDataSource.getActiveShiftClaim(userId, shiftDate);
    if (localClaim != null) return localClaim;

    // Check remote
    try {
      final remoteClaims = await _remoteDataSource.getUserClaims(userId);
      for (final claim in remoteClaims) {
        if (claim.shiftDate == shiftDate) {
          await _localDataSource.saveClaim(claim);
          return claim;
        }
      }
    } catch (_) {}

    return null;
  }

  @override
  Future<List<ConveyanceClaimEntity>> getUserClaims(String userId) async {
    final localClaims = await _localDataSource.getUserClaims(userId);
    if (localClaims.isNotEmpty) return localClaims;

    try {
      final remoteClaims = await _remoteDataSource.getUserClaims(userId);
      for (final claim in remoteClaims) {
        await _localDataSource.saveClaim(claim);
      }
      return remoteClaims;
    } catch (_) {
      return localClaims;
    }
  }

  @override
  Future<List<ConveyanceClaimEntity>> getAllClaims({
    ConveyanceStatus? status,
    bool? flaggedOnly,
    String? searchQuery,
  }) async {
    try {
      final remoteClaims = await _remoteDataSource.getAllClaims();
      for (final claim in remoteClaims) {
        await _localDataSource.saveClaim(claim);
      }
    } catch (_) {}

    final localClaims = await _localDataSource.getAllClaims(
      status: status?.name,
      flaggedOnly: flaggedOnly,
      searchQuery: searchQuery,
    );

    return localClaims;
  }

  @override
  Future<ConveyanceClaimEntity> recordStartOdometer({
    required String organizationId,
    required String userId,
    required String userName,
    required String shiftDate,
    required VehicleType vehicleType,
    required double ratePerKm,
    required OdometerReadingEntity reading,
  }) async {
    // Check if an existing draft claim exists for this shift
    final existing = await _localDataSource.getActiveShiftClaim(userId, shiftDate);
    final claimId = existing?.id ?? _uuid.v4();

    final claim = ConveyanceClaimModel(
      id: claimId,
      organizationId: organizationId,
      userId: userId,
      userName: userName,
      shiftDate: shiftDate,
      vehicleType: vehicleType,
      ratePerKm: ratePerKm,
      startReading: OdometerReadingModel.fromEntity(reading),
      endReading: null,
      claimedDistanceKm: 0.0,
      gpsDistanceKm: 0.0,
      discrepancyPercentage: 0.0,
      isFlaggedForFraud: false,
      fraudReason: null,
      status: ConveyanceStatus.draft,
      approvedPayoutAmount: 0.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _localDataSource.saveClaim(claim);
    try {
      await _remoteDataSource.upsertClaim(claim);
    } catch (_) {}

    return claim;
  }

  @override
  Future<ConveyanceClaimEntity> recordEndOdometer({
    required String claimId,
    required OdometerReadingEntity reading,
    required double gpsDistanceKm,
  }) async {
    final existing = await _localDataSource.getClaimById(claimId);
    if (existing == null) {
      throw StateError('Conveyance claim $claimId not found');
    }

    final startOdo = existing.startReading?.reading ?? 0.0;
    final endOdo = reading.reading;

    // Run reconciliation evaluation
    final eval = ConveyanceReconciliationEngine.evaluateClaim(
      startOdometer: startOdo,
      endOdometer: endOdo,
      gpsDistanceKm: gpsDistanceKm,
      ratePerKm: existing.ratePerKm,
    );

    final updated = existing.copyWith(
      endReading: OdometerReadingModel.fromEntity(reading),
      claimedDistanceKm: eval.claimedDistanceKm,
      gpsDistanceKm: eval.gpsDistanceKm,
      discrepancyPercentage: eval.discrepancyPercentage,
      isFlaggedForFraud: eval.isFlaggedForFraud,
      fraudReason: eval.fraudReason,
      status: eval.isFlaggedForFraud
          ? ConveyanceStatus.pendingApproval
          : ConveyanceStatus.approved,
      approvedPayoutAmount: eval.approvedPayout,
      updatedAt: DateTime.now(),
    );

    final model = ConveyanceClaimModel.fromEntity(updated);
    await _localDataSource.saveClaim(model);
    try {
      await _remoteDataSource.upsertClaim(model);
    } catch (_) {}

    return model;
  }

  @override
  Future<ConveyanceClaimEntity> reviewClaim({
    required String claimId,
    required ConveyanceStatus newStatus,
    required double approvedPayout,
    String? managerNotes,
  }) async {
    final existing = await _localDataSource.getClaimById(claimId);
    if (existing == null) {
      throw StateError('Conveyance claim $claimId not found');
    }

    final updated = existing.copyWith(
      status: newStatus,
      approvedPayoutAmount: approvedPayout,
      managerNotes: managerNotes,
      updatedAt: DateTime.now(),
    );

    final model = ConveyanceClaimModel.fromEntity(updated);
    await _localDataSource.saveClaim(model);
    try {
      await _remoteDataSource.upsertClaim(model);
    } catch (_) {}

    return model;
  }

  @override
  Future<String> exportClaimsCsv(List<ConveyanceClaimEntity> claims) async {
    final buffer = StringBuffer();
    // Headers compliant with RFC-4180
    buffer.writeln(
      'Claim ID,Technician Name,Shift Date,Vehicle Type,Start Odo (km),End Odo (km),Claimed Distance (km),GPS Distance (km),Discrepancy %,Rate (per km),Approved Payout,Status,Fraud Flag,Fraud Reason,Manager Notes',
    );

    for (final c in claims) {
      final row = [
        c.id,
        '"${c.userName.replaceAll('"', '""')}"',
        c.shiftDate,
        c.vehicleType.displayName,
        c.startReading?.reading.toStringAsFixed(1) ?? 'N/A',
        c.endReading?.reading.toStringAsFixed(1) ?? 'N/A',
        c.claimedDistanceKm.toStringAsFixed(1),
        c.gpsDistanceKm.toStringAsFixed(1),
        '${c.discrepancyPercentage.toStringAsFixed(1)}%',
        c.ratePerKm.toStringAsFixed(2),
        c.approvedPayoutAmount.toStringAsFixed(2),
        c.status.displayName,
        c.isFlaggedForFraud ? 'FLAGGED' : 'VERIFIED',
        '"${(c.fraudReason ?? '').replaceAll('"', '""')}"',
        '"${(c.managerNotes ?? '').replaceAll('"', '""')}"',
      ];
      buffer.writeln(row.join(','));
    }

    return buffer.toString();
  }
}
