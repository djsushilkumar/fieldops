import '../entities/attendance_entity.dart';

abstract class AttendanceRepository {
  /// Retrieves today's attendance record for the current user, or null if not yet checked in.
  Future<AttendanceEntity?> getTodayAttendance({required String userId});

  /// Retrieves personal attendance history for a user over an optional date range.
  Future<List<AttendanceEntity>> getMyAttendanceHistory({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Retrieves team attendance for an entire organization on a specific date (Manager / Admin view).
  Future<List<AttendanceEntity>> getTeamAttendance({
    required String organizationId,
    required DateTime date,
  });

  /// Records daily check-in with GPS coordinates.
  Future<AttendanceEntity> checkIn({
    required String userId,
    required String organizationId,
    required double latitude,
    required double longitude,
    DateTime? checkInTime,
  });

  /// Records daily check-out with GPS coordinates, calculating total working minutes.
  Future<AttendanceEntity> checkOut({
    required String attendanceId,
    required double latitude,
    required double longitude,
    DateTime? checkOutTime,
  });
}
