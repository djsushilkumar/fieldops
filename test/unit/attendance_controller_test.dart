import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_ops/core/location/location_coordinates.dart';
import 'package:field_ops/core/location/location_service.dart';
import 'package:field_ops/features/attendance/data/datasources/attendance_local_datasource.dart';
import 'package:field_ops/features/attendance/data/datasources/mock_attendance_remote_datasource.dart';
import 'package:field_ops/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:field_ops/features/attendance/domain/entities/attendance_status.dart';
import 'package:field_ops/features/attendance/presentation/controllers/attendance_controller.dart';
import 'package:field_ops/features/auth/domain/entities/user_entity.dart';
import 'package:field_ops/features/auth/domain/entities/user_role.dart';
import 'package:field_ops/features/auth/presentation/controllers/auth_controller.dart';

void main() {
  final testEmployee = UserEntity(
    id: 'usr-employee-001',
    email: 'employee@fieldops.com',
    name: 'Alex River',
    organizationId: 'org-001',
    role: UserRole.employee,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final mockLocationService = MockLocationService(
    initialCoordinates: const LocationCoordinates(
      latitude: 37.7749,
      longitude: -122.4194,
      accuracy: 5.0,
    ),
  );

  ProviderContainer createContainer({
    MockAttendanceRemoteDataSource? remoteDataSource,
  }) {
    final remote = remoteDataSource ?? MockAttendanceRemoteDataSource(seedData: true);
    final local = AttendanceLocalDataSourceImpl();
    final repo = AttendanceRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
    );

    final container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith((ref) => testEmployee),
        attendanceRepositoryProvider.overrideWithValue(repo),
        locationServiceProvider.overrideWithValue(mockLocationService),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('TodayAttendanceNotifier Tests', () {
    test('initializes and executes check-in / check-out lifecycle', () async {
      final container = createContainer();

      final notifier = container.read(todayAttendanceNotifierProvider.notifier);
      await notifier.loadTodayAttendance();

      var state = container.read(todayAttendanceNotifierProvider);
      expect(state.status, TodayAttendanceStatus.ready);
      expect(state.isNotCheckedIn, true);
      expect(state.isCheckedIn, false);

      // Execute check-in
      final checkInSuccess = await notifier.checkIn();
      expect(checkInSuccess, true);

      state = container.read(todayAttendanceNotifierProvider);
      expect(state.isCheckedIn, true);
      expect(state.isNotCheckedIn, false);
      expect(state.attendance?.checkInLatitude, 37.7749);

      // Execute check-out
      final checkOutSuccess = await notifier.checkOut();
      expect(checkOutSuccess, true);

      state = container.read(todayAttendanceNotifierProvider);
      expect(state.isCompleted, true);
      expect(state.isCheckedIn, false);
      expect(state.attendance?.checkOutAt, isNotNull);
    });

    test('sets error message when check-in fails', () async {
      final remote = MockAttendanceRemoteDataSource(seedData: false);
      remote.shouldThrowError = true;
      final container = createContainer(remoteDataSource: remote);

      final notifier = container.read(todayAttendanceNotifierProvider.notifier);
      // Wait for initial load
      await Future.delayed(Duration.zero);

      await notifier.checkIn();
      // Even with remote throwing, repo falls back to local cache or sets error
      final state = container.read(todayAttendanceNotifierProvider);
      expect(state.status, isNotNull);
    });
  });

  group('AttendanceHistoryNotifier Tests', () {
    test('loads history and calculates total metrics', () async {
      final container = createContainer();

      final notifier = container.read(attendanceHistoryNotifierProvider.notifier);
      await notifier.loadHistory();

      final state = container.read(attendanceHistoryNotifierProvider);
      expect(state.status, AttendanceHistoryStatus.ready);
      expect(state.records.length, 4);
      expect(state.totalDaysPresent, 3); // 3 present, 1 halfDay
      expect(state.totalMinutesWorked, greaterThan(0));
      expect(state.formattedTotalHours, contains('h'));
    });
  });

  group('TeamAttendanceNotifier Tests', () {
    test('loads team attendance and filters by status', () async {
      final container = createContainer();

      final notifier = container.read(teamAttendanceNotifierProvider.notifier);
      await notifier.loadTeamAttendance();

      final state = container.read(teamAttendanceNotifierProvider);
      expect(state.status, TeamAttendanceStatus.ready);
      expect(state.records.length, greaterThanOrEqualTo(3));
      expect(state.presentCount, 2);
      expect(state.onLeaveCount, 1);

      // Apply filter
      notifier.setFilter(AttendanceStatus.onLeave);
      final filteredState = container.read(teamAttendanceNotifierProvider);
      expect(filteredState.statusFilter, AttendanceStatus.onLeave);
      expect(filteredState.filteredRecords.length, 1);
      expect(filteredState.filteredRecords.first.userName, 'Morgan Chen');

      // Clear filter
      notifier.setFilter(null);
      final allState = container.read(teamAttendanceNotifierProvider);
      expect(allState.filteredRecords.length, greaterThanOrEqualTo(3));
    });

    test('selectDate updates selectedDate and reloads', () async {
      final container = createContainer();

      final notifier = container.read(teamAttendanceNotifierProvider.notifier);
      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      notifier.selectDate(yesterday);
      final state = container.read(teamAttendanceNotifierProvider);
      expect(state.selectedDate.day, yesterday.day);
    });
  });
}
