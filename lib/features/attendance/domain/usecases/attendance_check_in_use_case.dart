import '../../../../core/errors/failures.dart';
import '../../../../core/location/location_service.dart';
import '../entities/attendance_entity.dart';
import '../repositories/attendance_repository.dart';

class AttendanceCheckInUseCase {
  final AttendanceRepository _repository;
  final LocationService _locationService;

  AttendanceCheckInUseCase({
    required AttendanceRepository repository,
    required LocationService locationService,
  })  : _repository = repository,
        _locationService = locationService;

  Future<AttendanceEntity> call({
    required String userId,
    required String organizationId,
    double? latitude,
    double? longitude,
    DateTime? checkInTime,
  }) async {
    // 1. Verify user does not already have an active or completed check-in for today
    final existing = await _repository.getTodayAttendance(userId: userId);
    if (existing != null) {
      if (existing.isCheckedIn) {
        throw const ValidationFailure('You are already checked in for today');
      } else {
        throw const ValidationFailure('You have already completed attendance for today');
      }
    }

    // 2. Obtain current GPS coordinates if not explicitly passed
    double lat = latitude ?? 0.0;
    double lng = longitude ?? 0.0;

    if (latitude == null || longitude == null) {
      final loc = await _locationService.getCurrentLocation();
      lat = loc.latitude;
      lng = loc.longitude;
    }

    return _repository.checkIn(
      userId: userId,
      organizationId: organizationId,
      latitude: lat,
      longitude: lng,
      checkInTime: checkInTime,
    );
  }
}
