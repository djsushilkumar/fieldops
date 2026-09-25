import '../entities/conveyance_claim_entity.dart';
import '../entities/odometer_reading_entity.dart';
import '../repositories/conveyance_repository.dart';

class RecordEndOdometerUseCase {
  final ConveyanceRepository _repository;

  RecordEndOdometerUseCase(this._repository);

  Future<ConveyanceClaimEntity> call({
    required String claimId,
    required OdometerReadingEntity reading,
    required double gpsDistanceKm,
  }) async {
    if (claimId.isEmpty) {
      throw ArgumentError('Claim ID cannot be empty');
    }
    if (reading.reading < 0) {
      throw ArgumentError('Odometer reading cannot be negative');
    }
    return await _repository.recordEndOdometer(
      claimId: claimId,
      reading: reading,
      gpsDistanceKm: gpsDistanceKm,
    );
  }
}
