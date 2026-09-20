import 'package:flutter_test/flutter_test.dart';
import 'package:field_ops/features/attendance/data/datasources/attendance_local_datasource.dart';
import 'package:field_ops/features/attendance/data/datasources/mock_attendance_remote_datasource.dart';
import 'package:field_ops/features/attendance/data/repositories/attendance_repository_impl.dart';

void main() {
  late MockAttendanceRemoteDataSource remoteDataSource;
  late AttendanceLocalDataSource localDataSource;
  late AttendanceRepositoryImpl repository;

  setUp(() {
    remoteDataSource = MockAttendanceRemoteDataSource(seedData: true);
    localDataSource = AttendanceLocalDataSourceImpl();
    repository = AttendanceRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
    );
  });

  group('AttendanceRepositoryImpl Tests', () {
    test('getTodayAttendance returns null when no check-in exists for user', () async {
      final result = await repository.getTodayAttendance(userId: 'usr-employee-001');
      expect(result, isNull);
    });

    test('checkIn successfully records check-in and updates local cache', () async {
      final record = await repository.checkIn(
        userId: 'usr-employee-001',
        organizationId: 'org-001',
        latitude: 37.7749,
        longitude: -122.4194,
      );

      expect(record.id, isNotEmpty);
      expect(record.userId, 'usr-employee-001');
      expect(record.isCheckedIn, true);
      expect(record.checkInLatitude, 37.7749);

      // Verify cached locally
      final cached = await localDataSource.getCachedTodayAttendance('usr-employee-001');
      expect(cached, isNotNull);
      expect(cached!.id, record.id);
    });

    test('checkOut updates checkout time and total minutes', () async {
      final checkInRecord = await repository.checkIn(
        userId: 'usr-employee-001',
        organizationId: 'org-001',
        latitude: 37.7749,
        longitude: -122.4194,
      );

      final checkOutTime = checkInRecord.checkInAt.add(const Duration(hours: 8));
      final checkedOut = await repository.checkOut(
        attendanceId: checkInRecord.id,
        latitude: 37.7755,
        longitude: -122.4180,
        checkOutTime: checkOutTime,
      );

      expect(checkedOut.isCheckedOut, true);
      expect(checkedOut.checkOutLatitude, 37.7755);
      expect(checkedOut.totalMinutes, 480);
      expect(checkedOut.formattedDuration, '8h 0m');
    });

    test('getMyAttendanceHistory fetches seeded history and falls back to cache', () async {
      final history = await repository.getMyAttendanceHistory(userId: 'usr-employee-001');
      expect(history.length, 4);

      // Verify cached locally
      final cached = await localDataSource.getCachedHistory('usr-employee-001');
      expect(cached.length, 4);

      // Simulate remote failure -> should return cached data
      remoteDataSource.shouldThrowError = true;
      final fallbackHistory = await repository.getMyAttendanceHistory(userId: 'usr-employee-001');
      expect(fallbackHistory.length, 4);
    });

    test('getTeamAttendance returns team members for date and falls back to cache', () async {
      final today = DateTime.now();
      final team = await repository.getTeamAttendance(
        organizationId: 'org-001',
        date: today,
      );

      expect(team.length, greaterThanOrEqualTo(3));

      // Simulate remote failure -> returns cached
      remoteDataSource.shouldThrowError = true;
      final cachedTeam = await repository.getTeamAttendance(
        organizationId: 'org-001',
        date: today,
      );
      expect(cachedTeam.length, team.length);
    });

    test('checkIn offline fallback creates local record when remote fails', () async {
      remoteDataSource.shouldThrowError = true;

      final record = await repository.checkIn(
        userId: 'usr-employee-001',
        organizationId: 'org-001',
        latitude: 37.7749,
        longitude: -122.4194,
      );

      expect(record.id, startsWith('local-att-'));
      expect(record.isCheckedIn, true);

      final cached = await localDataSource.getCachedTodayAttendance('usr-employee-001');
      expect(cached?.id, record.id);
    });
  });
}
