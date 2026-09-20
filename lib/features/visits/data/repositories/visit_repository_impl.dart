import 'package:uuid/uuid.dart';
import '../../domain/entities/visit_entity.dart';
import '../../domain/repositories/visit_repository.dart';
import '../datasources/visit_local_datasource.dart';
import '../datasources/visit_remote_datasource.dart';
import '../models/visit_model.dart';

class VisitRepositoryImpl implements VisitRepository {
  final VisitRemoteDataSource remoteDataSource;
  final VisitLocalDataSource localDataSource;

  VisitRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<VisitEntity>> getVisits({
    String? userId,
    String? taskId,
    DateTime? date,
  }) async {
    try {
      final remoteList = await remoteDataSource.getVisits(
        userId: userId,
        taskId: taskId,
        date: date,
      );
      await localDataSource.cacheVisits(remoteList);
      return remoteList;
    } catch (_) {
      // Fallback to local cache
      return localDataSource.getCachedVisits(
        userId: userId,
        taskId: taskId,
      );
    }
  }

  @override
  Future<VisitEntity> getVisitDetail(String visitId) async {
    try {
      final remote = await remoteDataSource.getVisitDetail(visitId);
      await localDataSource.cacheVisit(remote);
      return remote;
    } catch (_) {
      final cached = await localDataSource.getCachedVisit(visitId);
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  Future<VisitEntity?> getActiveVisit({String? userId, String? taskId}) async {
    try {
      final remote = await remoteDataSource.getActiveVisit(
        userId: userId,
        taskId: taskId,
      );
      if (remote != null) {
        await localDataSource.cacheVisit(remote);
      }
      return remote;
    } catch (_) {
      return localDataSource.getActiveVisit(userId: userId, taskId: taskId);
    }
  }

  @override
  Future<VisitEntity> checkIn({
    required String taskId,
    required String locationId,
    required double latitude,
    required double longitude,
    String? notes,
  }) async {
    try {
      final remote = await remoteDataSource.checkIn(
        taskId: taskId,
        locationId: locationId,
        latitude: latitude,
        longitude: longitude,
        notes: notes,
      );
      await localDataSource.cacheVisit(remote);
      return remote;
    } catch (_) {
      // Offline fallback: create local visit record
      final now = DateTime.now();
      final offlineVisit = VisitModel(
        id: 'vst-offline-${const Uuid().v4().substring(0, 8)}',
        organizationId: 'org-001',
        taskId: taskId,
        taskTitle: 'Offline Task Visit',
        userId: 'usr-employee-001',
        userName: 'Alex River',
        locationId: locationId,
        locationName: 'Site Location',
        customerName: 'Customer Site',
        checkInAt: now,
        checkInLatitude: latitude,
        checkInLongitude: longitude,
        notes: notes,
        createdAt: now,
        updatedAt: now,
      );
      await localDataSource.cacheVisit(offlineVisit);
      return offlineVisit;
    }
  }

  @override
  Future<VisitEntity> checkOut({
    required String visitId,
    required double latitude,
    required double longitude,
    String? notes,
  }) async {
    try {
      final remote = await remoteDataSource.checkOut(
        visitId: visitId,
        latitude: latitude,
        longitude: longitude,
        notes: notes,
      );
      await localDataSource.cacheVisit(remote);
      return remote;
    } catch (_) {
      // Offline fallback: update local visit record
      final cached = await localDataSource.getCachedVisit(visitId);
      final now = DateTime.now();
      final updated = (cached ??
              VisitModel(
                id: visitId,
                organizationId: 'org-001',
                userId: 'usr-employee-001',
                checkInAt: now.subtract(const Duration(minutes: 30)),
                checkInLatitude: latitude,
                checkInLongitude: longitude,
                createdAt: now,
                updatedAt: now,
              ))
          .copyWith(
            checkOutAt: now,
            checkOutLatitude: latitude,
            checkOutLongitude: longitude,
            notes: notes ?? cached?.notes,
            updatedAt: now,
          );

      await localDataSource.cacheVisit(updated);
      return updated;
    }
  }
}
