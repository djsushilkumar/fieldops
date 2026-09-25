import 'package:flutter_test/flutter_test.dart';
import 'package:field_ops/features/conveyance/domain/services/odometer_ocr_engine.dart';

void main() {
  group('OdometerOcrEngine Unit Tests', () {
    test('extracts clean 5-digit odometer reading from standard dashboard string', () {
      const raw = 'TOTAL ODO 45210 KM TRIP A 12.4';
      final result = OdometerOcrEngine.extractOdometerReading(raw);

      expect(result.isValid, isTrue);
      expect(result.reading, 45210.0);
      expect(result.confidence, greaterThanOrEqualTo(0.90));
    });

    test('extracts decimal odometer reading accurately', () {
      const raw = 'ODO 12450.5 km';
      final result = OdometerOcrEngine.extractOdometerReading(raw);

      expect(result.isValid, isTrue);
      expect(result.reading, 12450.5);
    });

    test('disambiguates common OCR character-for-digit confusions (O, l, S, B)', () {
      // 'O' -> '0', 'l' -> '1', 'S' -> '5', 'B' -> '8'
      // 'Ol580' -> '01580' = 1580
      const confusedOcr = 'METER Ol580';
      final result = OdometerOcrEngine.extractOdometerReading(confusedOcr);

      expect(result.isValid, isTrue);
      expect(result.reading, 1580.0);
    });

    test('validates that ending odometer is not less than start odometer', () {
      const rawEnd = 'ODO 12000 KM';
      const startReading = 12500.0;

      final result = OdometerOcrEngine.extractOdometerReading(
        rawEnd,
        previousReading: startReading,
      );

      expect(result.isValid, isFalse);
      expect(result.validationError, contains('cannot be less than start odometer'));
    });

    test('accepts valid progression from previous start reading', () {
      const rawEnd = 'ODO 12542.8 KM';
      const startReading = 12500.0;

      final result = OdometerOcrEngine.extractOdometerReading(
        rawEnd,
        previousReading: startReading,
      );

      expect(result.isValid, isTrue);
      expect(result.reading, 12542.8);
    });

    test('handles empty and non-numeric OCR strings gracefully', () {
      final emptyResult = OdometerOcrEngine.extractOdometerReading('');
      expect(emptyResult.isValid, isFalse);
      expect(emptyResult.reading, isNull);

      final textOnlyResult = OdometerOcrEngine.extractOdometerReading('NO NUMBERS HERE CHECK ENGINE');
      expect(textOnlyResult.isValid, isFalse);
      expect(textOnlyResult.reading, isNull);
    });
  });
}
