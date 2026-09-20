class OrganizationEntity {
  final String id;
  final String name;
  final String timezone;
  final String currency;
  final String industry;
  final int geofenceDefaultRadius;
  final int autoCheckoutHours;
  final bool requirePhotoOnCompletion;
  final bool requireGpsOnCheckin;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OrganizationEntity({
    required this.id,
    required this.name,
    this.timezone = 'UTC',
    this.currency = 'USD',
    this.industry = 'Field Services',
    this.geofenceDefaultRadius = 100,
    this.autoCheckoutHours = 10,
    this.requirePhotoOnCompletion = false,
    this.requireGpsOnCheckin = true,
    required this.createdAt,
    required this.updatedAt,
  });

  OrganizationEntity copyWith({
    String? id,
    String? name,
    String? timezone,
    String? currency,
    String? industry,
    int? geofenceDefaultRadius,
    int? autoCheckoutHours,
    bool? requirePhotoOnCompletion,
    bool? requireGpsOnCheckin,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrganizationEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      timezone: timezone ?? this.timezone,
      currency: currency ?? this.currency,
      industry: industry ?? this.industry,
      geofenceDefaultRadius: geofenceDefaultRadius ?? this.geofenceDefaultRadius,
      autoCheckoutHours: autoCheckoutHours ?? this.autoCheckoutHours,
      requirePhotoOnCompletion: requirePhotoOnCompletion ?? this.requirePhotoOnCompletion,
      requireGpsOnCheckin: requireGpsOnCheckin ?? this.requireGpsOnCheckin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrganizationEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          industry == other.industry &&
          geofenceDefaultRadius == other.geofenceDefaultRadius &&
          requirePhotoOnCompletion == other.requirePhotoOnCompletion &&
          requireGpsOnCheckin == other.requireGpsOnCheckin;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      industry.hashCode ^
      geofenceDefaultRadius.hashCode ^
      requirePhotoOnCompletion.hashCode ^
      requireGpsOnCheckin.hashCode;

  @override
  String toString() {
    return 'OrganizationEntity(id: $id, name: $name, industry: $industry, geofence: ${geofenceDefaultRadius}m)';
  }
}
