import '../../../../core/errors/exceptions.dart';
import '../models/attendance_model.dart';
import '../../domain/entities/attendance_status.dart';
import 'attendance_remote_datasource.dart';

class MockAttendanceRemoteDataSource implements AttendanceRemoteDataSource {
  final Map<String, AttendanceModel> records = {};
  bool shouldThrowError = false;
  Duration simulatedDelay = Duration.zero;

  MockAttendanceRemoteDataSource({bool seedData = true}) {
    if (seedData) {
      _seedSampleAttendance();
    }
  }

  void _seedSampleAttendance() {
    final now = DateTime.now();

    // 1. Employee (Alex River) historical records over the past 4 days
    final pastDays = [
      (4, 8, 30, 17, 0, 510, AttendanceStatus.present),
      (3, 8, 45, 17, 15, 510, AttendanceStatus.present),
      (2, 9, 0, 13, 0, 240, AttendanceStatus.halfDay),
      (1, 8, 30, 17, 30, 540, AttendanceStatus.present),
    ];

    for (final (dayOffset, inHour, inMin, outHour, outMin, totalMins, status) in pastDays) {
      final date = now.subtract(Duration(days: dayOffset));
      final checkIn = DateTime(date.year, date.month, date.day, inHour, inMin);
      final checkOut = DateTime(date.year, date.month, date.day, outHour, outMin);
      final id = 'att-hist-00$dayOffset';

      records[id] = AttendanceModel(
        id: id,
        organizationId: 'org-001',
        userId: 'usr-employee-001',
        userName: 'Alex River',
        userEmail: 'employee@fieldops.com',
        date: DateTime(date.year, date.month, date.day),
        checkInAt: checkIn,
        checkInLatitude: 37.7749,
        checkInLongitude: -122.4194,
        checkOutAt: checkOut,
        checkOutLatitude: 37.7751,
        checkOutLongitude: -122.4196,
        totalMinutes: totalMins,
        status: status,
      );
    }

    // 2. Team members records for today (for Manager Team Attendance view)
    final today = DateTime(now.year, now.month, now.day);

    // Jordan Lee: Checked in today, currently active
    records['att-team-002'] = AttendanceModel(
      id: 'att-team-002',
      organizationId: 'org-001',
      userId: 'usr-employee-002',
      userName: 'Jordan Lee',
      userEmail: 'jordan@fieldops.com',
      date: today,
      checkInAt: DateTime(now.year, now.month, now.day, 8, 45),
      checkInLatitude: 37.7790,
      checkInLongitude: -122.4180,
      checkOutAt: null,
      checkOutLatitude: null,
      checkOutLongitude: null,
      totalMinutes: null,
      status: AttendanceStatus.present,
    );

    // Sam Taylor: Checked in today, completed shift
    records['att-team-003'] = AttendanceModel(
      id: 'att-team-003',
      organizationId: 'org-001',
      userId: 'usr-employee-003',
      userName: 'Sam Taylor',
      userEmail: 'sam@fieldops.com',
      date: today,
      checkInAt: DateTime(now.year, now.month, now.day, 8, 0),
      checkInLatitude: 37.7810,
      checkInLongitude: -122.4150,
      checkOutAt: DateTime(now.year, now.month, now.day, 16, 30),
      checkOutLatitude: 37.7812,
      checkOutLongitude: -122.4152,
      totalMinutes: 510,
      status: AttendanceStatus.present,
    );

    // Morgan Chen: On leave today
    records['att-team-004'] = AttendanceModel(
      id: 'att-team-004',
      organizationId: 'org-001',
      userId: 'usr-employee-004',
      userName: 'Morgan Chen',
      userEmail: 'morgan@fieldops.com',
      date: today,
      checkInAt: DateTime(now.year, now.month, now.day, 9, 0),
      checkInLatitude: 0.0,
      checkInLongitude: 0.0,
      checkOutAt: DateTime(now.year, now.month, now.day, 9, 0),
      checkOutLatitude: 0.0,
      checkOutLongitude: 0.0,
      totalMinutes: 0,
      status: AttendanceStatus.onLeave,
    );
  }

  @override
  Future<AttendanceModel?> getTodayAttendance({required String userId}) async {
    if (simulatedDelay > Duration.zero) await Future.delayed(simulatedDelay);
    if (shouldThrowError) throw const ServerException('Simulated network failure');

    final now = DateTime.now();
    for (final rec in records.values) {
      if (rec.userId == userId &&
          rec.date.year == now.year &&
          rec.date.month == now.month &&
          rec.date.day == now.day) {
        return rec;
      }
    }
    return null;
  }

  @override
  Future<List<AttendanceModel>> getAttendanceHistory({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (simulatedDelay > Duration.zero) await Future.delayed(simulatedDelay);
    if (shouldThrowError) throw const ServerException('Simulated network failure');

    var list = records.values.where((r) => r.userId == userId).toList();
    if (startDate != null) {
      list = list.where((r) => !r.date.isBefore(DateTime(startDate.year, startDate.month, startDate.day))).toList();
    }
    if (endDate != null) {
      list = list.where((r) => !r.date.isAfter(DateTime(endDate.year, endDate.month, endDate.day))).toList();
    }

    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<List<AttendanceModel>> getTeamAttendance({
    required String organizationId,
    required DateTime date,
  }) async {
    if (simulatedDelay > Duration.zero) await Future.delayed(simulatedDelay);
    if (shouldThrowError) throw const ServerException('Simulated network failure');

    final list = records.values
        .where((r) =>
            r.organizationId == organizationId &&
            r.date.year == date.year &&
            r.date.month == date.month &&
            r.date.day == date.day)
        .toList();

    list.sort((a, b) => a.checkInAt.compareTo(b.checkInAt));
    return list;
  }

  @override
  Future<AttendanceModel> checkIn({
    required String userId,
    required String organizationId,
    required double latitude,
    required double longitude,
    DateTime? checkInTime,
  }) async {
    if (simulatedDelay > Duration.zero) await Future.delayed(simulatedDelay);
    if (shouldThrowError) throw const ServerException('Simulated network failure');

    final now = checkInTime ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final id = 'att-${DateTime.now().millisecondsSinceEpoch}';

    final model = AttendanceModel(
      id: id,
      organizationId: organizationId,
      userId: userId,
      userName: userId == 'usr-employee-001' ? 'Alex River' : 'Field Employee',
      userEmail: userId == 'usr-employee-001' ? 'employee@fieldops.com' : 'user@fieldops.com',
      date: today,
      checkInAt: now,
      checkInLatitude: latitude,
      checkInLongitude: longitude,
      status: AttendanceStatus.present,
    );

    records[id] = model;
    return model;
  }

  @override
  Future<AttendanceModel> checkOut({
    required String attendanceId,
    required double latitude,
    required double longitude,
    DateTime? checkOutTime,
  }) async {
    if (simulatedDelay > Duration.zero) await Future.delayed(simulatedDelay);
    if (shouldThrowError) throw const ServerException('Simulated network failure');

    final existing = records[attendanceId];
    if (existing == null) {
      throw const ServerException('Attendance record not found');
    }

    final now = checkOutTime ?? DateTime.now();
    final totalMinutes = now.difference(existing.checkInAt).inMinutes;

    final updated = existing.copyWith(
      checkOutAt: now,
      checkOutLatitude: latitude,
      checkOutLongitude: longitude,
      totalMinutes: totalMinutes > 0 ? totalMinutes : 1,
    );

    records[attendanceId] = updated;
    return updated;
  }
}
