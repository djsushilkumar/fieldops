class LocationEntity {
  final String id;
  final String organizationId;
  final String? customerId;
  final String name;
  final String? address;
  final double latitude;
  final double longitude;
  final int radiusMeters;
  final String type; // 'site', 'branch', 'client_office', 'warehouse'
  final DateTime createdAt;
  final DateTime updatedAt;

  const LocationEntity({
    required this.id,
    required this.organizationId,
    this.customerId,
    required this.name,
    this.address,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 100,
    this.type = 'site',
    required this.createdAt,
    required this.updatedAt,
  });

  LocationEntity copyWith({
    String? id,
    String? organizationId,
    String? customerId,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    int? radiusMeters,
    String? type,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LocationEntity(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      customerId: customerId ?? this.customerId,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
