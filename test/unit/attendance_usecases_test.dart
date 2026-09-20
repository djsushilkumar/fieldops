import 'package:flutter_test/flutter_test.dart';
import 'package:field_ops/core/errors/failures.dart';
import 'package:field_ops/core/location/location_coordinates.dart';
import 'package:field_ops/core/location/location_service.dart';
import 'package:field_ops/features/attendance/data/datasources/attendance_local_datasource.dart';
import 'package:field_ops/features/attendance/data/datasources/mock_attendance_remote_datasource.dart';
import 'package:field_ops/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:field_ops/features/attendance/domain/usecases/attendance_check_in_use_case.dart';
import 'package:field_ops/features/attendance/domain/usecases/attendance_check_out_use_case.dart';
import 'package:field_ops/features/attendance/domain/usecases/get_attendance_history_use_case.dart';
import 'package:field_ops/features/attendance/domain/usecases/get_team_attendance_use_case.dart';
import 'package:field_ops/features/attendance/domain/usecases/get_today_attendance_use_case.dart';

void main() {
  late MockAttendanceRemoteDataSource remoteDataSource;
  late AttendanceLocalDataSource localDataSource;
  late AttendanceRepositoryImpl repository;
  late MockLocationService locationService;
  late AttendanceCheckInUseCase checkInUseCase;
  late AttendanceCheckOutUseCase checkOutUseCase;
  late GetTodayAttendanceUseCase getTodayUseCase;
  late GetAttendanceHistoryUseCase getHistoryUseCase;
  late GetTeamAttendanceUseCase getTeamUseCase;

  setUp(() {
    remoteDataSource = MockAttendanceRemoteDataSource(seedData: true);
    localDataSource = AttendanceLocalDataSourceImpl();
    repository = AttendanceRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
    );

    locationService = MockLocationService(
      initialCoordinates: const LocationCoordinates(
        latitude: 37.7749,
        longitude: -122.4194,
        accuracy: 4.0,
      ),
    );

    checkInUseCase = AttendanceCheckInUseCase(
      repository: repository,
      locationService: locationService,
    );
    checkOutUseCase = AttendanceCheckOutUseCase(
      repository: repository,
      locationService: locationService,
    );
    getTodayUseCase = GetTodayAttendanceUseCase(repository);
    getHistoryUseCase = GetAttendanceHistoryUseCase(repository);
    getTeamUseCase = GetTeamAttendanceUseCase(repository);
  });

  group('Attendance Use Cases Tests', () {
    test('checkInUseCase automatically acquires GPS and records attendance', () async {
      final record = await checkInUseCase(
        userId: 'usr-employee-001',
        organizationId: 'org-001',
      );

      expect(record.userId, 'usr-employee-001');
      expect(record.checkInLatitude, 37.7749);
      expect(record.checkInLongitude, -122.4194);
      expect(record.isCheckedIn, true);

      final today = await getTodayUseCase(userId: 'usr-employee-001');
      expect(today?.id, record.id);
    });

    test('checkInUseCase throws ValidationFailure on duplicate check-in', () async {
      await checkInUseCase(
        userId: 'usr-employee-001',
        organizationId: 'org-001',
      );

      expect(
        () => checkInUseCase(
          userId: 'usr-employee-001',
          organizationId: 'org-001',
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('checkOutUseCase automatically acquires GPS and calculates duration', () async {
      final record = await checkInUseCase(
        userId: 'usr-employee-001',
        organizationId: 'org-001',
      );

      // Change mock location before check-out
      locationService.setCoordinates(37.7800, -122.4100);

      final checkOutTime = record.checkInAt.add(const Duration(hours: 7, minutes: 30));
      final checkedOut = await checkOutUseCase(
        attendanceId: record.id,
        checkOutTime: checkOutTime,
      );

      expect(checkedOut.isCheckedOut, true);
      expect(checkedOut.checkOutLatitude, 37.7800);
      expect(checkedOut.checkOutLongitude, -122.4100);
      expect(checkedOut.totalMinutes, 450);
      expect(checkedOut.formattedDuration, '7h 30m');
    });

    test('checkOutUseCase throws ValidationFailure when attendance ID is empty', () {
      expect(
        () => checkOutUseCase(attendanceId: ''),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('getHistoryUseCase returns past records', () async {
      final history = await getHistoryUseCase(userId: 'usr-employee-001');
      expect(history.length, 4);
    });

    test('getTeamUseCase returns team records for given date', () async {
      final today = DateTime.now();
      final team = await getTeamUseCase(organizationId: 'org-001', date: today);
      expect(team.length, greaterThanOrEqualTo(3));
    });
  });
}
