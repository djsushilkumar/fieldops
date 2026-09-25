class FaceBiometricProfile {
  final String userId;
  final List<double> embedding; // 128-dimensional floating point embedding vector
  final DateTime registeredAt;
  final bool isEnrolled;
  final double livenessThreshold;

  const FaceBiometricProfile({
    required this.userId,
    required this.embedding,
    required this.registeredAt,
    this.isEnrolled = true,
    this.livenessThreshold = 0.75,
  });

  factory FaceBiometricProfile.fromJson(Map<String, dynamic> json) {
    return FaceBiometricProfile(
      userId: json['user_id'] as String,
      embedding: (json['embedding'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      registeredAt: json['registered_at'] != null
          ? DateTime.parse(json['registered_at'] as String)
          : DateTime.now(),
      isEnrolled: json['is_enrolled'] as bool? ?? true,
      livenessThreshold: (json['liveness_threshold'] as num?)?.toDouble() ?? 0.75,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'embedding': embedding,
      'registered_at': registeredAt.toIso8601String(),
      'is_enrolled': isEnrolled,
      'liveness_threshold': livenessThreshold,
    };
  }
}
