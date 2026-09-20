import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Platform Packaging & Release Configuration Verification', () {
    test('AndroidManifest.xml contains all mandatory permissions and FieldOps label', () {
      final manifestFile = File('/workspace/quiet-lovelace/android/app/src/main/AndroidManifest.xml');
      expect(manifestFile.existsSync(), isTrue, reason: 'AndroidManifest.xml must exist');

      final content = manifestFile.readAsStringSync();

      // Application Name
      expect(content, contains('android:label="FieldOps"'));

      // Core Permissions
      expect(content, contains('android.permission.INTERNET'));
      expect(content, contains('android.permission.ACCESS_NETWORK_STATE'));
      expect(content, contains('android.permission.ACCESS_FINE_LOCATION'));
      expect(content, contains('android.permission.ACCESS_COARSE_LOCATION'));
      expect(content, contains('android.permission.ACCESS_BACKGROUND_LOCATION'));
      expect(content, contains('android.permission.CAMERA'));
      expect(content, contains('android.permission.READ_EXTERNAL_STORAGE'));
      expect(content, contains('android.permission.WRITE_EXTERNAL_STORAGE'));
      expect(content, contains('android.permission.READ_MEDIA_IMAGES'));
      expect(content, contains('android.permission.POST_NOTIFICATIONS'));
    });

    test('ios/Runner/Info.plist contains all required privacy and location keys', () {
      final infoPlistFile = File('/workspace/quiet-lovelace/ios/Runner/Info.plist');
      expect(infoPlistFile.existsSync(), isTrue, reason: 'Info.plist must exist');

      final content = infoPlistFile.readAsStringSync();

      expect(content, contains('<string>FieldOps</string>'));
      expect(content, contains('NSLocationWhenInUseUsageDescription'));
      expect(content, contains('NSLocationAlwaysAndWhenInUseUsageDescription'));
      expect(content, contains('NSCameraUsageDescription'));
      expect(content, contains('NSPhotoLibraryUsageDescription'));
    });

    test('android/app/proguard-rules.pro preserves SQLite3, Flutter, and Camera symbols', () {
      final proguardFile = File('/workspace/quiet-lovelace/android/app/proguard-rules.pro');
      expect(proguardFile.existsSync(), isTrue, reason: 'proguard-rules.pro must exist');

      final content = proguardFile.readAsStringSync();

      expect(content, contains('io.flutter'));
      expect(content, contains('org.sqlite'));
      expect(content, contains('com.baseflow.geolocator'));
    });

    test('android/app/build.gradle configures release build with ProGuard optimization', () {
      final buildGradleFile = File('/workspace/quiet-lovelace/android/app/build.gradle');
      expect(buildGradleFile.existsSync(), isTrue, reason: 'build.gradle must exist');

      final content = buildGradleFile.readAsStringSync();

      expect(content, contains('proguardFiles'));
      expect(content, contains('proguard-rules.pro'));
    });
  });
}
