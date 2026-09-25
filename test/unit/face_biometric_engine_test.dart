import 'package:flutter_test/flutter_test.dart';
import 'package:field_ops/features/attendance/domain/services/face_biometric_engine.dart';

void main() {
  group('FaceBiometricEngine Unit Tests', () {
    test('calculateCosineSimilarity returns 1.0 for identical unit vectors', () {
      final v1 = [1.0, 0.0, 0.0, 0.0];
      final similarity = FaceBiometricEngine.calculateCosineSimilarity(v1, v1);
      expect(similarity, 1.0);
    });

    test('calculateCosineSimilarity returns 0.0 for orthogonal vectors', () {
      final v1 = [1.0, 0.0, 0.0, 0.0];
      final v2 = [0.0, 1.0, 0.0, 0.0];
      final similarity = FaceBiometricEngine.calculateCosineSimilarity(v1, v2);
      expect(similarity, 0.0);
    });

    test('generateSyntheticTemplate produces 128-dimensional unit vector', () {
      final template = FaceBiometricEngine.generateSyntheticTemplate('emp-test-01');
      expect(template.length, 128);

      // Verify unit length (sum of squares = 1.0)
      final sumSquares = template.fold<double>(0.0, (sum, val) => sum + (val * val));
      expect(sumSquares, closeTo(1.0, 0.001));
    });

    test('verifyFaceMatch matches face when similarity >= 0.80 and liveness passes', () {
      final enrolled = FaceBiometricEngine.generateSyntheticTemplate('emp-alex-chen');
      // Simulated capture with very slight noise (e.g. lighting variation)
      final captured = FaceBiometricEngine.generateSyntheticTemplate('emp-alex-chen', noiseLevel: 0.03);

      final result = FaceBiometricEngine.verifyFaceMatch(
        capturedEmbedding: captured,
        enrolledEmbedding: enrolled,
        blinkDetected: true,
        headPoseDetected: true,
      );

      expect(result.isMatched, isTrue);
      expect(result.similarityScore, greaterThanOrEqualTo(0.85));
      expect(result.livenessPassed, isTrue);
      expect(result.inferenceDurationMs, lessThan(200)); // <150ms target
      expect(result.errorMessage, isNull);
    });

    test('verifyFaceMatch rejects different person embeddings', () {
      final enrolled = FaceBiometricEngine.generateSyntheticTemplate('emp-alex-chen');
      final impostor = FaceBiometricEngine.generateSyntheticTemplate('emp-jordan-miller');

      final result = FaceBiometricEngine.verifyFaceMatch(
        capturedEmbedding: impostor,
        enrolledEmbedding: enrolled,
      );

      expect(result.isMatched, isFalse);
      expect(result.similarityScore, lessThan(0.50));
      expect(result.errorMessage, contains('Face match failed'));
    });

    test('verifyFaceMatch fails if liveness check is not passed (anti-spoofing)', () {
      final enrolled = FaceBiometricEngine.generateSyntheticTemplate('emp-alex-chen');
      final captured = enrolled; // identical photo spoof

      final result = FaceBiometricEngine.verifyFaceMatch(
        capturedEmbedding: captured,
        enrolledEmbedding: enrolled,
        blinkDetected: false, // failed blink
        headPoseDetected: true,
      );

      expect(result.isMatched, isFalse);
      expect(result.livenessPassed, isFalse);
      expect(result.errorMessage, contains('Liveness check failed'));
    });
  });
}
