import 'dart:ui';
import 'attachment_metadata.dart';

class DigitalSignaturePoint {
  final double x;
  final double y;

  const DigitalSignaturePoint(this.x, this.y);

  Offset toOffset() => Offset(x, y);

  Map<String, dynamic> toMap() => {'x': x, 'y': y};

  factory DigitalSignaturePoint.fromMap(Map<String, dynamic> map) {
    return DigitalSignaturePoint(
      (map['x'] as num).toDouble(),
      (map['y'] as num).toDouble(),
    );
  }
}

class DigitalSignatureStroke {
  final List<DigitalSignaturePoint> points;
  final int colorValue;
  final double strokeWidth;

  const DigitalSignatureStroke({
    required this.points,
    this.colorValue = 0xFF1A1A2E, // default dark ink
    this.strokeWidth = 3.0,
  });

  Map<String, dynamic> toMap() => {
        'points': points.map((p) => p.toMap()).toList(),
        'color': colorValue,
        'width': strokeWidth,
      };

  factory DigitalSignatureStroke.fromMap(Map<String, dynamic> map) {
    final rawPoints = map['points'] as List<dynamic>? ?? [];
    return DigitalSignatureStroke(
      points: rawPoints
          .map((p) => DigitalSignaturePoint.fromMap(p as Map<String, dynamic>))
          .toList(),
      colorValue: map['color'] as int? ?? 0xFF1A1A2E,
      strokeWidth: (map['width'] as num?)?.toDouble() ?? 3.0,
    );
  }
}

class DigitalSignatureData {
  final List<DigitalSignatureStroke> strokes;
  final String signerName;
  final String signerRole;
  final String? signerEmail;
  final DateTime signedAt;
  final double? latitude;
  final double? longitude;
  final double? accuracy;

  const DigitalSignatureData({
    required this.strokes,
    required this.signerName,
    this.signerRole = 'Customer / Site Contact',
    this.signerEmail,
    required this.signedAt,
    this.latitude,
    this.longitude,
    this.accuracy,
  });

  bool get isEmpty => strokes.isEmpty || strokes.every((s) => s.points.isEmpty);
  bool get isNotEmpty => !isEmpty;
  int get totalPoints => strokes.fold(0, (acc, s) => acc + s.points.length);

  AttachmentMetadata toMetadata() {
    return AttachmentMetadata(
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      capturedAt: signedAt,
      signerName: signerName,
      signerRole: signerRole,
      signerEmail: signerEmail,
      category: 'customer_signoff',
      isWatermarked: true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'strokes': strokes.map((s) => s.toMap()).toList(),
      'signer_name': signerName,
      'signer_role': signerRole,
      if (signerEmail != null) 'signer_email': signerEmail,
      'signed_at': signedAt.toIso8601String(),
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (accuracy != null) 'accuracy': accuracy,
    };
  }

  factory DigitalSignatureData.fromMap(Map<String, dynamic> map) {
    final rawStrokes = map['strokes'] as List<dynamic>? ?? [];
    return DigitalSignatureData(
      strokes: rawStrokes
          .map((s) => DigitalSignatureStroke.fromMap(s as Map<String, dynamic>))
          .toList(),
      signerName: map['signer_name'] as String? ?? 'Signer',
      signerRole: map['signer_role'] as String? ?? 'Customer / Site Contact',
      signerEmail: map['signer_email'] as String?,
      signedAt: map['signed_at'] != null
          ? DateTime.tryParse(map['signed_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      accuracy: (map['accuracy'] as num?)?.toDouble(),
    );
  }
}
