import 'package:flutter_test/flutter_test.dart';
import 'package:field_ops/features/visits/data/models/visit_model.dart';

void main() {
  final checkInTime = DateTime.parse('2026-09-20T09:00:00Z');
  final checkOutTime = DateTime.parse('2026-09-20T09:45:00Z');

  group('VisitModel & VisitEntity Unit Tests', () {
    final activeVisitJson = {
      'id': 'vst-101',
      'organization_id': 'org-001',
      'task_id': 'tsk-001',
      'task_title': 'HVAC Filter Replacement',
      'user_id': 'usr-emp-001',
      'user_name': 'Alex River',
      'location_id': 'loc-001',
      'location_name': 'Building A Server Room',
      'customer_name': 'Apex Logistics',
      'check_in_at': checkInTime.toIso8601String(),
      'check_in_latitude': 37.7749,
      'check_in_longitude': -122.4194,
      'notes': 'Arrived on site',
      'created_at': checkInTime.toIso8601String(),
      'updated_at': checkInTime.toIso8601String(),
    };

    final completedVisitJson = {
      ...activeVisitJson,
      'id': 'vst-102',
      'check_out_at': checkOutTime.toIso8601String(),
      'check_out_latitude': 37.7750,
      'check_out_longitude': -122.4195,
    };

    test('fromJson deserializes active visit correctly', () {
      final visit = VisitModel.fromJson(activeVisitJson);

      expect(visit.id, equals('vst-101'));
      expect(visit.taskTitle, equals('HVAC Filter Replacement'));
      expect(visit.userName, equals('Alex River'));
      expect(visit.locationName, equals('Building A Server Room'));
      expect(visit.customerName, equals('Apex Logistics'));
      expect(visit.checkInLatitude, equals(37.7749));
      expect(visit.checkInLongitude, equals(-122.4194));
      expect(visit.isActive, isTrue);
      expect(visit.isCompleted, isFalse);
      expect(visit.durationMinutes, isNull);
    });

    test('fromJson deserializes completed visit and calculates duration', () {
      final visit = VisitModel.fromJson(completedVisitJson);

      expect(visit.id, equals('vst-102'));
      expect(visit.isActive, isFalse);
      expect(visit.isCompleted, isTrue);
      expect(visit.durationMinutes, equals(45));
      expect(visit.checkOutLatitude, equals(37.7750));
    });

    test('toJson serializes visit entity correctly', () {
      final visit = VisitModel.fromJson(completedVisitJson);
      final json = visit.toJson();

      expect(json['id'], equals('vst-102'));
      expect(json['task_id'], equals('tsk-001'));
      expect(json['check_in_latitude'], equals(37.7749));
      expect(json['check_out_latitude'], equals(37.7750));
      expect(json['check_out_at'], isNotNull);
    });

    test('copyWith produces updated visit instance', () {
      final visit = VisitModel.fromJson(activeVisitJson);
      final updated = visit.copyWith(
        checkOutAt: checkOutTime,
        checkOutLatitude: 37.7750,
        checkOutLongitude: -122.4195,
        notes: 'Service work completed successfully',
      );

      expect(updated.isCompleted, isTrue);
      expect(updated.durationMinutes, equals(45));
      expect(updated.notes, equals('Service work completed successfully'));
      expect(updated.id, equals('vst-101'));
    });
  });
}
