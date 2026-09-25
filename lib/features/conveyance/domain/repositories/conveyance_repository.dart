import '../entities/conveyance_claim_entity.dart';
import '../entities/conveyance_status.dart';
import '../entities/odometer_reading_entity.dart';
import '../entities/vehicle_type.dart';

abstract class ConveyanceRepository {
  Future<ConveyanceClaimEntity?> getActiveShiftClaim(String userId, String shiftDate);

  Future<List<ConveyanceClaimEntity>> getUserClaims(String userId);

  Future<List<ConveyanceClaimEntity>> getAllClaims({
    ConveyanceStatus? status,
    bool? flaggedOnly,
    String? searchQuery,
  });

  Future<ConveyanceClaimEntity> recordStartOdometer({
    required String organizationId,
    required String userId,
    required String userName,
    required String shiftDate,
    required VehicleType vehicleType,
    required double ratePerKm,
    required OdometerReadingEntity reading,
  });

  Future<ConveyanceClaimEntity> recordEndOdometer({
    required String claimId,
    required OdometerReadingEntity reading,
    required double gpsDistanceKm,
  });

  Future<ConveyanceClaimEntity> reviewClaim({
    required String claimId,
    required ConveyanceStatus newStatus,
    required double approvedPayout,
    String? managerNotes,
  });

  Future<String> exportClaimsCsv(List<ConveyanceClaimEntity> claims);
}
