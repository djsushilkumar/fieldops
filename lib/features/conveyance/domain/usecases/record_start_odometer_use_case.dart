import '../entities/conveyance_claim_entity.dart';
import '../entities/odometer_reading_entity.dart';
import '../entities/vehicle_type.dart';
import '../repositories/conveyance_repository.dart';

class RecordStartOdometerUseCase {
  final ConveyanceRepository _repository;

  RecordStartOdometerUseCase(this._repository);

  Future<ConveyanceClaimEntity> call({
    required String organizationId,
    required String userId,
    required String userName,
    required String shiftDate,
    required VehicleType vehicleType,
    required double ratePerKm,
    required OdometerReadingEntity reading,
  }) async {
    if (reading.reading < 0) {
      throw ArgumentError('Odometer reading cannot be negative');
    }
    return await _repository.recordStartOdometer(
      organizationId: organizationId,
      userId: userId,
      userName: userName,
      shiftDate: shiftDate,
      vehicleType: vehicleType,
      ratePerKm: ratePerKm,
      reading: reading,
    );
  }
}
