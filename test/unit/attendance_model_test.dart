import 'package:flutter_test/flutter_test.dart';
import 'package:field_ops/features/attendance/data/models/attendance_model.dart';
import 'package:field_ops/features/attendance/domain/entities/attendance_status.dart';

void main() {
  group('AttendanceStatus Tests', () {
    test('converts from string code correctly', () {
      expect(AttendanceStatus.fromCode('PRESENT'), AttendanceStatus.present);
      expect(AttendanceStatus.fromCode('ABSENT'), AttendanceStatus.absent);
      expect(AttendanceStatus.fromCode('HALF_DAY'), AttendanceStatus.halfDay);
      expect(AttendanceStatus.fromCode('ON_LEAVE'), AttendanceStatus.onLeave);
      expect(AttendanceStatus.fromCode('UNKNOWN'), AttendanceStatus.present);
    });

    test('exposes correct label and code', () {
      expect(AttendanceStatus.present.label, 'Present');
      expect(AttendanceStatus.present.code, 'PRESENT');
      expect(AttendanceStatus.halfDay.label, 'Half Day');
      expect(AttendanceStatus.halfDay.code, 'HALF_DAY');
    });
  });

  group('AttendanceModel Tests', () {
    final testDate = DateTime(2026, 9, 20);
    final checkIn = DateTime(2026, 9, 20, 8, 30);
    final checkOut = DateTime(2026, 9, 20, 17, 15);

    test('serializes to and from JSON correctly', () {
      final json = {
        'id': 'att-101',
        'organization_id': 'org-001',
        'user_id': 'usr-001',
        'user_name': 'Taylor Swift',
        'user_email': 'taylor@fieldops.com',
        'date': '2026-09-20',
        'check_in_at': checkIn.toIso8601String(),
        'check_in_latitude': 37.7749,
        'check_in_longitude': -122.4194,
        'check_out_at': checkOut.toIso8601String(),
        'check_out_latitude': 37.7750,
        'check_out_longitude': -122.4195,
        'total_minutes': 525,
        'status': 'PRESENT',
      };

      final model = AttendanceModel.fromJson(json);

      expect(model.id, 'att-101');
      expect(model.organizationId, 'org-001');
      expect(model.userId, 'usr-001');
      expect(model.userName, 'Taylor Swift');
      expect(model.userEmail, 'taylor@fieldops.com');
      expect(model.checkInLatitude, 37.7749);
      expect(model.checkInLongitude, -122.4194);
      expect(model.totalMinutes, 525);
      expect(model.status, AttendanceStatus.present);
      expect(model.isCheckedIn, false);
      expect(model.isCheckedOut, true);

      final serialized = model.toJson();
      expect(serialized['id'], 'att-101');
      expect(serialized['date'], '2026-09-20');
      expect(serialized['total_minutes'], 525);
      expect(serialized['status'], 'PRESENT');
    });

    test('parses joined Supabase user structure', () {
      final json = {
        'id': 'att-102',
        'organization_id': 'org-001',
        'user_id': 'usr-002',
        'users': {
          'name': 'Alex River',
          'email': 'alex@fieldops.com',
        },
        'date': '2026-09-20',
        'check_in_at': checkIn.toIso8601String(),
        'check_in_latitude': 37.7749,
        'check_in_longitude': -122.4194,
        'status': 'PRESENT',
      };

      final model = AttendanceModel.fromJson(json);

      expect(model.userName, 'Alex River');
      expect(model.userEmail, 'alex@fieldops.com');
      expect(model.isCheckedIn, true);
      expect(model.isCheckedOut, false);
      expect(model.checkOutAt, isNull);
    });

    test('calculates duration and formatted strings correctly', () {
      final model = AttendanceModel(
        id: 'att-103',
        organizationId: 'org-001',
        userId: 'usr-001',
        date: testDate,
        checkInAt: checkIn,
        checkInLatitude: 37.7749,
        checkInLongitude: -122.4194,
        checkOutAt: checkOut,
        checkOutLatitude: 37.7750,
        checkOutLongitude: -122.4195,
        totalMinutes: 525, // 8h 45m
        status: AttendanceStatus.present,
      );

      expect(model.workingDuration.inMinutes, 525);
      expect(model.formattedDuration, '8h 45m');
      expect(model.formattedCheckInTime, isNotEmpty);
      expect(model.formattedCheckOutTime, isNotEmpty);
    });

    test('copyWith produces an exact clone with modified properties', () {
      final original = AttendanceModel(
        id: 'att-104',
        organizationId: 'org-001',
        userId: 'usr-001',
        date: testDate,
        checkInAt: checkIn,
        checkInLatitude: 37.7749,
        checkInLongitude: -122.4194,
        status: AttendanceStatus.present,
      );

      final updated = original.copyWith(
        checkOutAt: checkOut,
        totalMinutes: 525,
        status: AttendanceStatus.halfDay,
      );

      expect(updated.id, original.id);
      expect(updated.checkOutAt, checkOut);
      expect(updated.totalMinutes, 525);
      expect(updated.status, AttendanceStatus.halfDay);
    });
  });
}
