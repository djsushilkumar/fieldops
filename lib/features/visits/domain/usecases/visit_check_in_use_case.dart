import '../../../../core/errors/failures.dart';
import '../../../../core/location/gps_distance_engine.dart';
import '../../../customers/domain/entities/location_entity.dart';
import '../entities/visit_entity.dart';
import '../repositories/visit_repository.dart';

class VisitCheckInUseCase {
  final VisitRepository repository;

  VisitCheckInUseCase(this.repository);

  Future<VisitEntity> call({
    required String taskId,
    required LocationEntity location,
    required double currentLatitude,
    required double currentLongitude,
    String? notes,
    bool enforceRadius = true,
  }) async {
    if (enforceRadius) {
      final radiusResult = GpsDistanceEngine.checkRadius(
        currentLatitude: currentLatitude,
        currentLongitude: currentLongitude,
        targetLatitude: location.latitude,
        targetLongitude: location.longitude,
        radiusMeters: location.radiusMeters,
      );

      if (!radiusResult.isWithinRadius) {
        final dist = GpsDistanceEngine.formatDistance(radiusResult.distanceMeters);
        final allowed = GpsDistanceEngine.formatDistance(radiusResult.allowedRadiusMeters.toDouble());
        throw ValidationFailure(
          'Cannot check in: You are outside the allowed site radius ($dist away, maximum allowed is $allowed).',
        );
      }
    }

    return repository.checkIn(
      taskId: taskId,
      locationId: location.id,
      latitude: currentLatitude,
      longitude: currentLongitude,
      notes: notes,
    );
  }
}
