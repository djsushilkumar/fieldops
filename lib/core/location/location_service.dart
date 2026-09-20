import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'location_coordinates.dart';

abstract class LocationService {
  Future<bool> hasPermission();
  Future<bool> requestPermission();
  Future<LocationCoordinates> getCurrentLocation();
}

class GeolocatorLocationService implements LocationService {
  // Default coordinates fallback (e.g. City Center) if device GPS cannot be acquired
  static const double defaultLatitude = 37.7749;
  static const double defaultLongitude = -122.4194;

  @override
  Future<bool> hasPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      debugPrint('Geolocator hasPermission error: $e');
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      debugPrint('Geolocator requestPermission error: $e');
      return false;
    }
  }

  @override
  Future<LocationCoordinates> getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        final requested = await requestPermission();
        if (!requested) {
          return const LocationCoordinates(
            latitude: defaultLatitude,
            longitude: defaultLongitude,
            accuracy: 10.0,
          );
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return LocationCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        timestamp: position.timestamp,
      );
    } catch (e) {
      debugPrint('Error getting current location with geolocator: $e');
      return const LocationCoordinates(
        latitude: defaultLatitude,
        longitude: defaultLongitude,
        accuracy: 15.0,
      );
    }
  }
}

class MockLocationService implements LocationService {
  LocationCoordinates mockCoordinates;
  bool mockHasPermission;

  MockLocationService({
    LocationCoordinates? initialCoordinates,
    this.mockHasPermission = true,
  }) : mockCoordinates = initialCoordinates ??
            const LocationCoordinates(
              latitude: 37.7749,
              longitude: -122.4194,
              accuracy: 5.0,
            );

  void setCoordinates(double latitude, double longitude, {double? accuracy}) {
    mockCoordinates = LocationCoordinates(
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy ?? 5.0,
    );
  }

  @override
  Future<bool> hasPermission() async => mockHasPermission;

  @override
  Future<bool> requestPermission() async => mockHasPermission;

  @override
  Future<LocationCoordinates> getCurrentLocation() async => mockCoordinates;
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return GeolocatorLocationService();
});
