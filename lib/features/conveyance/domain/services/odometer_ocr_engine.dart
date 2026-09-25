class OcrExtractionResult {
  final double? reading;
  final double confidence;
  final String cleanedText;
  final String? detectedPattern;
  final bool isValid;
  final String? validationError;

  const OcrExtractionResult({
    this.reading,
    this.confidence = 0.0,
    required this.cleanedText,
    this.detectedPattern,
    this.isValid = false,
    this.validationError,
  });
}

/// Intelligent Odometer OCR Text Parser and Normalization Engine
/// Employs heuristic character disambiguation and odometer mileage extraction.
class OdometerOcrEngine {
  /// Common OCR digit confusion map
  static const Map<String, String> _charToDigit = {
    'O': '0',
    'o': '0',
    'D': '0',
    'I': '1',
    'l': '1',
    '|': '1',
    'Z': '2',
    'z': '2',
    'S': '5',
    's': '5',
    'B': '8',
    'g': '9',
    'q': '9',
  };

  /// Normalizes and cleans raw OCR text from camera stream or photo
  static String normalizeOcrText(String rawText) {
    if (rawText.isEmpty) return '';

    // Remove common prefixes/suffixes like km, KM, mi, ODO, TRIP
    var text = rawText
        .replaceAll(RegExp(r'\b(km/h|kmh|km|KM|odo|ODO|trip|TRIP|miles|mi)\b', caseSensitive: false), ' ')
        .trim();

    return text;
  }

  /// Parses raw OCR output and extracts the most probable numeric odometer reading.
  /// Optionally validates against a previous reading (e.g. shift start).
  static OcrExtractionResult extractOdometerReading(
    String rawText, {
    double? previousReading,
    double maxShiftDistanceKm = 1000.0,
  }) {
    if (rawText.trim().isEmpty) {
      return const OcrExtractionResult(
        reading: null,
        confidence: 0.0,
        cleanedText: '',
        isValid: false,
        validationError: 'Empty OCR text provided',
      );
    }

    final normalized = normalizeOcrText(rawText);

    // Extract all candidate numeric tokens (including decimals)
    final candidates = _findNumericCandidates(rawText, normalized);

    if (candidates.isEmpty) {
      return OcrExtractionResult(
        reading: null,
        confidence: 0.0,
        cleanedText: normalized,
        isValid: false,
        validationError: 'No numeric odometer reading detected in image',
      );
    }

    // Rank candidates: prioritize numbers that have 4 to 7 digits
    // and if previousReading is provided, must be >= previousReading
    candidates.sort((a, b) {
      final scoreA = _scoreCandidate(a, previousReading);
      final scoreB = _scoreCandidate(b, previousReading);
      return scoreB.compareTo(scoreA);
    });

    final bestCandidate = candidates.first;
    final value = bestCandidate.value;
    final confidence = bestCandidate.confidence;

    // Check plausibility against previous reading
    if (previousReading != null && previousReading > 0) {
      if (value < previousReading) {
        return OcrExtractionResult(
          reading: value,
          confidence: confidence * 0.5,
          cleanedText: normalized,
          detectedPattern: bestCandidate.rawPattern,
          isValid: false,
          validationError:
              'Ending odometer ($value) cannot be less than start odometer ($previousReading)',
        );
      }

      final diff = value - previousReading;
      if (diff > maxShiftDistanceKm) {
        return OcrExtractionResult(
          reading: value,
          confidence: confidence * 0.7,
          cleanedText: normalized,
          detectedPattern: bestCandidate.rawPattern,
          isValid: true,
          validationError:
              'Notice: Travel distance ($diff km) exceeds typical daily shift limits ($maxShiftDistanceKm km)',
        );
      }
    }

    return OcrExtractionResult(
      reading: value,
      confidence: confidence,
      cleanedText: normalized,
      detectedPattern: bestCandidate.rawPattern,
      isValid: true,
    );
  }

  static List<_CandidateReading> _findNumericCandidates(String original, String normalized) {
    final List<_CandidateReading> results = [];
    final seen = <double>{};

    // Regex 1: Explicit 4-7 digit numbers, optional 1 decimal place (e.g. 12450, 104523, 14205.4)
    final pattern1 = RegExp(r'\b\d{4,7}(?:\.\d{1,2})?\b');
    for (final match in pattern1.allMatches(original)) {
      final val = double.tryParse(match.group(0)!);
      if (val != null && val > 0 && !seen.contains(val)) {
        seen.add(val);
        results.add(_CandidateReading(
          value: val,
          rawPattern: match.group(0)!,
          confidence: 0.95,
        ));
      }
    }

    // Regex 2: Try OCR letter disambiguation on alphanumeric tokens
    final tokenPattern = RegExp(r'\b[A-Za-z0-9\.]{4,8}\b');
    for (final match in tokenPattern.allMatches(original)) {
      final token = match.group(0)!;
      final disambiguated = _disambiguateChars(token);
      final val = double.tryParse(disambiguated);
      if (val != null && val > 0 && !seen.contains(val)) {
        seen.add(val);
        results.add(_CandidateReading(
          value: val,
          rawPattern: token,
          confidence: 0.82,
        ));
      }
    }

    // Regex 3: Fallback - any floating point or integer with at least 3 digits
    if (results.isEmpty) {
      final fallbackPattern = RegExp(r'\b\d{3,8}(?:\.\d+)?\b');
      for (final match in fallbackPattern.allMatches(original)) {
        final val = double.tryParse(match.group(0)!);
        if (val != null && val > 0 && !seen.contains(val)) {
          seen.add(val);
          results.add(_CandidateReading(
            value: val,
            rawPattern: match.group(0)!,
            confidence: 0.65,
          ));
        }
      }
    }

    return results;
  }

  static String _disambiguateChars(String input) {
    final buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      if (_charToDigit.containsKey(char)) {
        buffer.write(_charToDigit[char]);
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  static double _scoreCandidate(_CandidateReading candidate, double? previousReading) {
    double score = candidate.confidence * 100;

    // Prefer numbers in typical vehicle odometer range (1,000 - 999,999)
    if (candidate.value >= 1000 && candidate.value <= 999999) {
      score += 30;
    }

    // If previousReading is known
    if (previousReading != null && previousReading > 0) {
      if (candidate.value >= previousReading) {
        final delta = candidate.value - previousReading;
        if (delta >= 1 && delta <= 300) {
          // Standard day trip between 1km and 300km: high score!
          score += 50;
        } else if (delta == 0) {
          score += 10;
        } else if (delta > 500) {
          score -= 20;
        }
      } else {
        // Less than previous reading is penalized heavily
        score -= 100;
      }
    }

    return score;
  }
}

class _CandidateReading {
  final double value;
  final String rawPattern;
  final double confidence;

  const _CandidateReading({
    required this.value,
    required this.rawPattern,
    required this.confidence,
  });
}
