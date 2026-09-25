import '../../domain/entities/odometer_reading_entity.dart';

class OdometerReadingModel extends OdometerReadingEntity {
  const OdometerReadingModel({
    required super.reading,
    required super.readingType,
    required super.photoPath,
    super.rawOcrText,
    super.confidence,
    required super.timestamp,
    super.latitude,
    super.longitude,
    super.isManualOverride,
    super.overrideReason,
  });

  factory OdometerReadingModel.fromEntity(OdometerReadingEntity entity) {
    return OdometerReadingModel(
      reading: entity.reading,
      readingType: entity.readingType,
      photoPath: entity.photoPath,
      rawOcrText: entity.rawOcrText,
      confidence: entity.confidence,
      timestamp: entity.timestamp,
      latitude: entity.latitude,
      longitude: entity.longitude,
      isManualOverride: entity.isManualOverride,
      overrideReason: entity.overrideReason,
    );
  }

  factory OdometerReadingModel.fromJson(Map<String, dynamic> json) {
    return OdometerReadingModel(
      reading: (json['reading'] as num?)?.toDouble() ?? 0.0,
      readingType: json['reading_type'] == 'end'
          ? OdometerReadingType.end
          : OdometerReadingType.start,
      photoPath: json['photo_path'] as String? ?? '',
      rawOcrText: json['raw_ocr_text'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      isManualOverride: json['is_manual_override'] == true || json['is_manual_override'] == 1,
      overrideReason: json['override_reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reading': reading,
      'reading_type': readingType == OdometerReadingType.start ? 'start' : 'end',
      'photo_path': photoPath,
      'raw_ocr_text': rawOcrText,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'is_manual_override': isManualOverride ? 1 : 0,
      'override_reason': overrideReason,
    };
  }
}
