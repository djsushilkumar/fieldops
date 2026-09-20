class AttachmentMetadata {
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final DateTime? capturedAt;
  final String? deviceModel;
  final String? signerName;
  final String? signerRole;
  final String? signerEmail;
  final String? category; // 'before', 'after', 'site', 'customer_signoff'
  final String? notes;
  final bool isWatermarked;

  const AttachmentMetadata({
    this.latitude,
    this.longitude,
    this.accuracy,
    this.capturedAt,
    this.deviceModel,
    this.signerName,
    this.signerRole,
    this.signerEmail,
    this.category,
    this.notes,
    this.isWatermarked = false,
  });

  bool get hasGps => latitude != null && longitude != null;

  String get formattedGpsCoordinates {
    if (!hasGps) return 'No GPS fix';
    final latStr = latitude!.toStringAsFixed(6);
    final lngStr = longitude!.toStringAsFixed(6);
    final accStr = accuracy != null ? ' (±${accuracy!.toStringAsFixed(1)}m)' : '';
    return '$latStr, $lngStr$accStr';
  }

  String get watermarkText {
    final buffer = StringBuffer();
    if (hasGps) {
      buffer.writeln('GPS: $formattedGpsCoordinates');
    }
    if (capturedAt != null) {
      buffer.writeln('TIME: ${capturedAt!.toUtc().toIso8601String()}');
    }
    if (signerName != null && signerName!.isNotEmpty) {
      final roleStr = signerRole != null ? ' ($signerRole)' : '';
      buffer.writeln('SIGNED BY: $signerName$roleStr');
    }
    if (notes != null && notes!.isNotEmpty) {
      buffer.writeln('NOTE: $notes');
    }
    return buffer.toString().trim();
  }

  Map<String, dynamic> toMap() {
    return {
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (accuracy != null) 'accuracy': accuracy,
      if (capturedAt != null) 'captured_at': capturedAt!.toIso8601String(),
      if (deviceModel != null) 'device_model': deviceModel,
      if (signerName != null) 'signer_name': signerName,
      if (signerRole != null) 'signer_role': signerRole,
      if (signerEmail != null) 'signer_email': signerEmail,
      if (category != null) 'category': category,
      if (notes != null) 'notes': notes,
      'is_watermarked': isWatermarked,
    };
  }

  factory AttachmentMetadata.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const AttachmentMetadata();
    return AttachmentMetadata(
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      accuracy: (map['accuracy'] as num?)?.toDouble(),
      capturedAt: map['captured_at'] != null
          ? DateTime.tryParse(map['captured_at'] as String)
          : null,
      deviceModel: map['device_model'] as String?,
      signerName: map['signer_name'] as String?,
      signerRole: map['signer_role'] as String?,
      signerEmail: map['signer_email'] as String?,
      category: map['category'] as String?,
      notes: map['notes'] as String?,
      isWatermarked: map['is_watermarked'] as bool? ?? false,
    );
  }

  AttachmentMetadata copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    DateTime? capturedAt,
    String? deviceModel,
    String? signerName,
    String? signerRole,
    String? signerEmail,
    String? category,
    String? notes,
    bool? isWatermarked,
  }) {
    return AttachmentMetadata(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      capturedAt: capturedAt ?? this.capturedAt,
      deviceModel: deviceModel ?? this.deviceModel,
      signerName: signerName ?? this.signerName,
      signerRole: signerRole ?? this.signerRole,
      signerEmail: signerEmail ?? this.signerEmail,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      isWatermarked: isWatermarked ?? this.isWatermarked,
    );
  }
}
