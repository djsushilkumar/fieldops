class OrganizationEntity {
  final String id;
  final String name;
  final String timezone;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OrganizationEntity({
    required this.id,
    required this.name,
    this.timezone = 'UTC',
    this.currency = 'USD',
    required this.createdAt,
    required this.updatedAt,
  });

  OrganizationEntity copyWith({
    String? id,
    String? name,
    String? timezone,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrganizationEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      timezone: timezone ?? this.timezone,
      currency: currency ?? this.currency,
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
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;

  @override
  String toString() {
    return 'OrganizationEntity(id: $id, name: $name, timezone: $timezone)';
  }
}
