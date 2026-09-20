import 'package:flutter_test/flutter_test.dart';
import 'package:field_ops/features/auth/data/models/user_model.dart';
import 'package:field_ops/features/auth/domain/entities/user_role.dart';

void main() {
  group('UserModel Serialization & Entity Mapping', () {
    final testJson = {
      'id': 'usr-test-123',
      'organization_id': 'org-test-456',
      'name': 'Alex Technician',
      'email': 'alex@example.com',
      'phone': '+1234567890',
      'role': 'employee',
      'avatar_url': 'https://example.com/avatar.jpg',
      'status': 'active',
      'created_at': '2025-01-01T10:00:00.000Z',
      'updated_at': '2025-01-02T12:00:00.000Z',
    };

    test('fromJson parses correctly', () {
      final model = UserModel.fromJson(testJson);
      expect(model.id, equals('usr-test-123'));
      expect(model.organizationId, equals('org-test-456'));
      expect(model.name, equals('Alex Technician'));
      expect(model.email, equals('alex@example.com'));
      expect(model.role, equals('employee'));
      expect(model.status, equals('active'));
    });

    test('toJson serializes correctly', () {
      final model = UserModel.fromJson(testJson);
      final json = model.toJson();
      expect(json['id'], equals('usr-test-123'));
      expect(json['organization_id'], equals('org-test-456'));
      expect(json['role'], equals('employee'));
    });

    test('toEntity maps to UserEntity with UserRole enum', () {
      final model = UserModel.fromJson(testJson);
      final entity = model.toEntity();
      expect(entity.id, equals('usr-test-123'));
      expect(entity.role, equals(UserRole.employee));
      expect(entity.role.isEmployee, isTrue);
    });
  });
}
