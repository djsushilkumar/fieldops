import 'package:uuid/uuid.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/visit_model.dart';
import 'visit_remote_datasource.dart';

class MockVisitRemoteDataSource implements VisitRemoteDataSource {
  final Map<String, VisitModel> visits = {};
  Duration simulatedDelay;

  MockVisitRemoteDataSource({this.simulatedDelay = Duration.zero}) {
    _seedData();
  }

  void _seedData() {
    final now = DateTime.now();

    final visit1 = VisitModel(
      id: 'vst-001',
      organizationId: 'org-001',
      taskId: 'tsk-001',
      taskTitle: 'HVAC Air Filter Replacement & System Diagnostic',
      userId: 'usr-employee-001',
      userName: 'Alex River',
      locationId: 'loc-001',
      locationName: 'Main Medical Wing',
      customerName: 'Metro Health Plaza',
      checkInAt: now.subtract(const Duration(hours: 26)),
      checkInLatitude: 37.7749,
      checkInLongitude: -122.4194,
      checkOutAt: now.subtract(const Duration(hours: 25, minutes: 15)),
      checkOutLatitude: 37.7750,
      checkOutLongitude: -122.4193,
      notes: 'Completed HEPA filter replacement on 3rd floor AHU-2 unit.',
      createdAt: now.subtract(const Duration(hours: 26)),
      updatedAt: now.subtract(const Duration(hours: 25, minutes: 15)),
    );

    final visit2 = VisitModel(
      id: 'vst-002',
      organizationId: 'org-001',
      taskId: 'tsk-002',
      taskTitle: 'Emergency Water Leak Repair',
      userId: 'usr-employee-001',
      userName: 'Alex River',
      locationId: 'loc-003',
      locationName: 'Distribution Facility 4',
      customerName: 'Apex Logistics Hub',
      checkInAt: now.subtract(const Duration(hours: 50)),
      checkInLatitude: 37.7651,
      checkInLongitude: -122.4049,
      checkOutAt: now.subtract(const Duration(hours: 48, minutes: 45)),
      checkOutLatitude: 37.7652,
      checkOutLongitude: -122.4048,
      notes: 'Replaced ruptured valve on dock 3 overhead pipeline.',
      createdAt: now.subtract(const Duration(hours: 50)),
      updatedAt: now.subtract(const Duration(hours: 48, minutes: 45)),
    );

    visits[visit1.id] = visit1;
    visits[visit2.id] = visit2;
  }

  @override
  Future<List<VisitModel>> getVisits({
    String? userId,
    String? taskId,
    DateTime? date,
  }) async {
    if (simulatedDelay > Duration.zero) await Future.delayed(simulatedDelay);
    var list = visits.values.toList();
    if (userId != null) {
      list = list.where((v) => v.userId == userId).toList();
    }
    if (taskId != null) {
      list = list.where((v) => v.taskId == taskId).toList();
    }
    if (date != null) {
      list = list.where((v) =>
          v.checkInAt.year == date.year &&
          v.checkInAt.month == date.month &&
          v.checkInAt.day == date.day).toList();
    }
    list.sort((a, b) => b.checkInAt.compareTo(a.checkInAt));
    return list;
  }

  @override
  Future<VisitModel> getVisitDetail(String visitId) async {
    if (simulatedDelay > Duration.zero) await Future.delayed(simulatedDelay);
    final visit = visits[visitId];
    if (visit == null) {
      throw const ServerException('Visit not found');
    }
    return visit;
  }

  @override
  Future<VisitModel?> getActiveVisit({String? userId, String? taskId}) async {
    if (simulatedDelay > Duration.zero) await Future.delayed(simulatedDelay);
    final active = visits.values.where((v) => v.checkOutAt == null);
    if (userId != null && taskId != null) {
      final match = active.where((v) => v.userId == userId && v.taskId == taskId);
      return match.isNotEmpty ? match.first : null;
    } else if (taskId != null) {
      final match = active.where((v) => v.taskId == taskId);
      return match.isNotEmpty ? match.first : null;
    } else if (userId != null) {
      final match = active.where((v) => v.userId == userId);
      return match.isNotEmpty ? match.first : null;
    }
    return active.isNotEmpty ? active.first : null;
  }

  @override
  Future<VisitModel> checkIn({
    required String taskId,
    required String locationId,
    required double latitude,
    required double longitude,
    String? notes,
  }) async {
    if (simulatedDelay > Duration.zero) await Future.delayed(simulatedDelay);
    final now = DateTime.now();
    final newVisit = VisitModel(
      id: 'vst-${const Uuid().v4().substring(0, 8)}',
      organizationId: 'org-001',
      taskId: taskId,
      taskTitle: 'Field Task Visit',
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

    visits[newVisit.id] = newVisit;
    return newVisit;
  }

  @override
  Future<VisitModel> checkOut({
    required String visitId,
    required double latitude,
    required double longitude,
    String? notes,
  }) async {
    if (simulatedDelay > Duration.zero) await Future.delayed(simulatedDelay);
    final existing = visits[visitId];
    if (existing == null) {
      throw const ServerException('Visit not found to check out');
    }

    final updated = existing.copyWith(
      checkOutAt: DateTime.now(),
      checkOutLatitude: latitude,
      checkOutLongitude: longitude,
      notes: notes ?? existing.notes,
      updatedAt: DateTime.now(),
    );

    visits[visitId] = updated;
    return updated;
  }
}
