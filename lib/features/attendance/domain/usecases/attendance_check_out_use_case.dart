import '../../../../core/errors/failures.dart';
import '../../../../core/location/location_service.dart';
import '../entities/attendance_entity.dart';
import '../repositories/attendance_repository.dart';

class AttendanceCheckOutUseCase {
  final AttendanceRepository _repository;
  final LocationService _locationService;

  AttendanceCheckOutUseCase({
    required AttendanceRepository repository,
    required LocationService locationService,
  })  : _repository = repository,
        _locationService = locationService;

  Future<AttendanceEntity> call({
    required String attendanceId,
    double? latitude,
    double? longitude,
    DateTime? checkOutTime,
  }) async {
    if (attendanceId.isEmpty) {
      throw const ValidationFailure('Attendance ID cannot be empty');
    }

    // 1. Obtain GPS coordinates if not provided
    double lat = latitude ?? 0.0;
    double lng = longitude ?? 0.0;

    if (latitude == null || longitude == null) {
      final loc = await _locationService.getCurrentLocation();
      lat = loc.latitude;
      lng = loc.longitude;
    }

    return _repository.checkOut(
      attendanceId: attendanceId,
      latitude: lat,
      longitude: lng,
      checkOutTime: checkOutTime,
    );
  }
}
