import 'package:flutter_test/flutter_test.dart';
import 'package:field_ops/features/customers/data/models/customer_model.dart';
import 'package:field_ops/features/customers/data/models/location_model.dart';
import 'package:field_ops/features/customers/domain/entities/customer_entity.dart';
import 'package:field_ops/features/customers/domain/entities/location_entity.dart';

void main() {
  final now = DateTime.parse('2026-09-20T08:00:00Z');

  group('LocationModel Unit Tests', () {
    final testLocationJson = {
      'id': 'loc-100',
      'organization_id': 'org-001',
      'customer_id': 'cust-001',
      'name': 'Downtown Data Center',
      'address': '500 Howard St, San Francisco, CA',
      'latitude': 37.7891,
      'longitude': -122.3982,
      'radius_meters': 150,
      'type': 'datacenter',
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    test('fromJson deserializes correctly', () {
      final model = LocationModel.fromJson(testLocationJson);

      expect(model.id, equals('loc-100'));
      expect(model.organizationId, equals('org-001'));
      expect(model.customerId, equals('cust-001'));
      expect(model.name, equals('Downtown Data Center'));
      expect(model.address, equals('500 Howard St, San Francisco, CA'));
      expect(model.latitude, equals(37.7891));
      expect(model.longitude, equals(-122.3982));
      expect(model.radiusMeters, equals(150));
      expect(model.type, equals('datacenter'));
    });

    test('toJson serializes correctly', () {
      final model = LocationModel.fromJson(testLocationJson);
      final json = model.toJson();

      expect(json['id'], equals('loc-100'));
      expect(json['radius_meters'], equals(150));
      expect(json['latitude'], equals(37.7891));
    });

    test('fromEntity converts correctly', () {
      final entity = LocationEntity(
        id: 'loc-101',
        organizationId: 'org-001',
        name: 'Branch East',
        latitude: 37.77,
        longitude: -122.42,
        createdAt: now,
        updatedAt: now,
      );

      final model = LocationModel.fromEntity(entity);
      expect(model.id, equals('loc-101'));
      expect(model.name, equals('Branch East'));
    });
  });

  group('CustomerModel Unit Tests', () {
    final testCustomerJson = {
      'id': 'cust-200',
      'organization_id': 'org-001',
      'name': 'Acme Global',
      'phone': '+1 555 123 4567',
      'email': 'support@acme.com',
      'address': '100 Mission St, San Francisco, CA',
      'notes': 'Preferred client',
      'created_by': 'usr-admin-001',
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'locations': [
        {
          'id': 'loc-201',
          'organization_id': 'org-001',
          'customer_id': 'cust-200',
          'name': 'Acme HQ',
          'latitude': 37.791,
          'longitude': -122.401,
          'radius_meters': 100,
          'type': 'office',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        }
      ],
    };

    test('fromJson deserializes customer with nested locations', () {
      final customer = CustomerModel.fromJson(testCustomerJson);

      expect(customer.id, equals('cust-200'));
      expect(customer.name, equals('Acme Global'));
      expect(customer.email, equals('support@acme.com'));
      expect(customer.locations.length, equals(1));
      expect(customer.locations.first.name, equals('Acme HQ'));
      expect(customer.locations.first.radiusMeters, equals(100));
    });

    test('toJson serializes correctly', () {
      final customer = CustomerModel.fromJson(testCustomerJson);
      final json = customer.toJson();

      expect(json['id'], equals('cust-200'));
      expect(json['name'], equals('Acme Global'));
      expect((json['locations'] as List).length, equals(1));
    });

    test('copyWith updates customer entity properties', () {
      final entity = CustomerEntity(
        id: 'cust-300',
        organizationId: 'org-001',
        name: 'Beta Corp',
        createdAt: now,
        updatedAt: now,
      );

      final updated = entity.copyWith(name: 'Beta Corporation');
      expect(updated.name, equals('Beta Corporation'));
      expect(updated.id, equals('cust-300'));
    });
  });
}
