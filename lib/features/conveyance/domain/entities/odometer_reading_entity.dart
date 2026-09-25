enum OdometerReadingType {
  start,
  end;

  String get displayName => this == OdometerReadingType.start ? 'Shift Start' : 'Shift End';
}

class OdometerReadingEntity {
  final double reading;
  final OdometerReadingType readingType;
  final String photoPath;
  final String rawOcrText;
  final double confidence;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final bool isManualOverride;
  final String? overrideReason;

  const OdometerReadingEntity({
    required this.reading,
    required this.readingType,
    required this.photoPath,
    this.rawOcrText = '',
    this.confidence = 1.0,
    required this.timestamp,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.isManualOverride = false,
    this.overrideReason,
  });

  OdometerReadingEntity copyWith({
    double? reading,
    OdometerReadingType? readingType,
    String? photoPath,
    String? rawOcrText,
    double? confidence,
    DateTime? timestamp,
    double? latitude,
    double? longitude,
    bool? isManualOverride,
    String? overrideReason,
  }) {
    return OdometerReadingEntity(
      reading: reading ?? this.reading,
      readingType: readingType ?? this.readingType,
      photoPath: photoPath ?? this.photoPath,
      rawOcrText: rawOcrText ?? this.rawOcrText,
      confidence: confidence ?? this.confidence,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isManualOverride: isManualOverride ?? this.isManualOverride,
      overrideReason: overrideReason ?? this.overrideReason,
    );
  }
}
