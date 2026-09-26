import '../datasources/attendance_local_datasource.dart';
import '../datasources/attendance_remote_datasource.dart';
import '../models/attendance_model.dart';
import '../../domain/entities/attendance_entity.dart';
import '../../domain/entities/attendance_status.dart';
import '../../domain/repositories/attendance_repository.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceRemoteDataSource remoteDataSource;
  final AttendanceLocalDataSource localDataSource;

  AttendanceRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<AttendanceEntity?> getTodayAttendance({required String userId}) async {
    try {
      final remote = await remoteDataSource.getTodayAttendance(userId: userId);
      if (remote != null) {
        await localDataSource.cacheTodayAttendance(remote);
      }
      return remote;
    } catch (_) {
      return localDataSource.getCachedTodayAttendance(userId);
    }
  }

  @override
  Future<List<AttendanceEntity>> getMyAttendanceHistory({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final remote = await remoteDataSource.getAttendanceHistory(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );
      await localDataSource.cacheHistory(userId, remote);
      return remote;
    } catch (_) {
      return localDataSource.getCachedHistory(userId);
    }
  }

  @override
  Future<List<AttendanceEntity>> getTeamAttendance({
    required String organizationId,
    required DateTime date,
  }) async {
    final dateKey = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    try {
      final remote = await remoteDataSource.getTeamAttendance(
        organizationId: organizationId,
        date: date,
      );
      await localDataSource.cacheTeamAttendance(organizationId, dateKey, remote);
      return remote;
    } catch (_) {
      return localDataSource.getCachedTeamAttendance(organizationId, dateKey);
    }
  }

  @override
  Future<AttendanceEntity> checkIn({
    required String userId,
    required String organizationId,
    required double latitude,
    required double longitude,
    DateTime? checkInTime,
  }) async {
    try {
      final remote = await remoteDataSource.checkIn(
        userId: userId,
        organizationId: organizationId,
        latitude: latitude,
        longitude: longitude,
        checkInTime: checkInTime,
      );
      await localDataSource.cacheTodayAttendance(remote);
      return remote;
    } catch (_) {
      // Offline fallback
      final now = checkInTime ?? DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final local = AttendanceModel(
        id: 'local-att-${DateTime.now().millisecondsSinceEpoch}',
        organizationId: organizationId,
        userId: userId,
        userName: 'Field Technician',
        userEmail: '',
        date: today,
        checkInAt: now,
        checkInLatitude: latitude,
        checkInLongitude: longitude,
        status: AttendanceStatus.present,
      );
      await localDataSource.cacheTodayAttendance(local);
      return local;
    }
  }

  @override
  Future<AttendanceEntity> checkOut({
    required String attendanceId,
    required double latitude,
    required double longitude,
    DateTime? checkOutTime,
  }) async {
    try {
      final remote = await remoteDataSource.checkOut(
        attendanceId: attendanceId,
        latitude: latitude,
        longitude: longitude,
        checkOutTime: checkOutTime,
      );
      await localDataSource.cacheTodayAttendance(remote);
      return remote;
    } catch (_) {
      // Offline fallback: load cached record and mark checked out
      final cached = await localDataSource.getCachedTodayAttendance('usr-employee-001');
      final now = checkOutTime ?? DateTime.now();
      final totalMins = cached != null ? now.difference(cached.checkInAt).inMinutes : 480;

      final updated = (cached ??
              AttendanceModel(
                id: attendanceId,
                organizationId: 'org-001',
                userId: 'usr-employee-001',
                date: DateTime(now.year, now.month, now.day),
                checkInAt: now.subtract(const Duration(hours: 8)),
                checkInLatitude: latitude,
                checkInLongitude: longitude,
                status: AttendanceStatus.present,
              ))
          .copyWith(
        checkOutAt: now,
        checkOutLatitude: latitude,
        checkOutLongitude: longitude,
        totalMinutes: totalMins > 0 ? totalMins : 1,
      );

      await localDataSource.cacheTodayAttendance(updated);
      return updated;
    }
  }
}
