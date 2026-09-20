import '../entities/visit_entity.dart';

abstract class VisitRepository {
  Future<List<VisitEntity>> getVisits({
    String? userId,
    String? taskId,
    DateTime? date,
  });

  Future<VisitEntity> getVisitDetail(String visitId);

  Future<VisitEntity?> getActiveVisit({String? userId, String? taskId});

  Future<VisitEntity> checkIn({
    required String taskId,
    required String locationId,
    required double latitude,
    required double longitude,
    String? notes,
  });

  Future<VisitEntity> checkOut({
    required String visitId,
    required double latitude,
    required double longitude,
    String? notes,
  });
}
