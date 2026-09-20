import 'package:flutter_test/flutter_test.dart';
import 'package:field_ops/core/location/gps_distance_engine.dart';
import 'package:field_ops/core/location/location_service.dart';
import 'package:field_ops/core/location/location_coordinates.dart';

void main() {
  group('GpsDistanceEngine Unit Tests', () {
    test('calculateDistanceMeters returns 0 for identical points', () {
      final dist = GpsDistanceEngine.calculateDistanceMeters(
        lat1: 37.7749,
        lon1: -122.4194,
        lat2: 37.7749,
        lon2: -122.4194,
      );
      expect(dist, equals(0.0));
    });

    test('calculateDistanceMeters accurately calculates distance between known points', () {
      // SF Union Square: 37.7879, -122.4074
      // SF Ferry Building: 37.7955, -122.3937
      // Expected distance: ~1.46 km (between 1400m and 1500m)
      final dist = GpsDistanceEngine.calculateDistanceMeters(
        lat1: 37.7879,
        lon1: -122.4074,
        lat2: 37.7955,
        lon2: -122.3937,
      );
      expect(dist, greaterThan(1400));
      expect(dist, lessThan(1550));
    });

    test('checkRadius correctly identifies point within radius', () {
      // User is at same location
      final result = GpsDistanceEngine.checkRadius(
        currentLatitude: 37.7749,
        currentLongitude: -122.4194,
        targetLatitude: 37.7749,
        targetLongitude: -122.4194,
        radiusMeters: 100,
      );

      expect(result.isWithinRadius, isTrue);
      expect(result.distanceMeters, equals(0.0));
      expect(result.allowedRadiusMeters, equals(100));
      expect(result.deltaMeters, lessThanOrEqualTo(0));
    });

    test('checkRadius correctly identifies point outside radius', () {
      // User is ~1.46 km away, with 200m allowed radius
      final result = GpsDistanceEngine.checkRadius(
        currentLatitude: 37.7879,
        currentLongitude: -122.4074,
        targetLatitude: 37.7955,
        targetLongitude: -122.3937,
        radiusMeters: 200,
      );

      expect(result.isWithinRadius, isFalse);
      expect(result.distanceMeters, greaterThan(1400));
      expect(result.deltaMeters, greaterThan(1200));
    });

    test('formatDistance formats meters and kilometers appropriately', () {
      expect(GpsDistanceEngine.formatDistance(50), equals('50 m'));
      expect(GpsDistanceEngine.formatDistance(999), equals('999 m'));
      expect(GpsDistanceEngine.formatDistance(1000), equals('1.0 km'));
      expect(GpsDistanceEngine.formatDistance(2450), equals('2.5 km'));
    });
  });

  group('MockLocationService Unit Tests', () {
    test('returns mock coordinates and supports coordinate updates', () async {
      final service = MockLocationService(
        initialCoordinates: const LocationCoordinates(
          latitude: 37.7749,
          longitude: -122.4194,
          accuracy: 5.0,
        ),
      );

      final initial = await service.getCurrentLocation();
      expect(initial.latitude, equals(37.7749));
      expect(initial.longitude, equals(-122.4194));

      service.setCoordinates(34.0522, -118.2437, accuracy: 8.0);
      final updated = await service.getCurrentLocation();
      expect(updated.latitude, equals(34.0522));
      expect(updated.longitude, equals(-118.2437));
      expect(updated.accuracy, equals(8.0));
    });

    test('reports permission status correctly', () async {
      final service = MockLocationService(mockHasPermission: true);
      expect(await service.hasPermission(), isTrue);
      expect(await service.requestPermission(), isTrue);

      service.mockHasPermission = false;
      expect(await service.hasPermission(), isFalse);
      expect(await service.requestPermission(), isFalse);
    });
  });
}
