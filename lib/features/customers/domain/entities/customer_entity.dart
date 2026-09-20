import 'location_entity.dart';

class CustomerEntity {
  final String id;
  final String organizationId;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<LocationEntity> locations;

  const CustomerEntity({
    required this.id,
    required this.organizationId,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.notes,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.locations = const [],
  });

  CustomerEntity copyWith({
    String? id,
    String? organizationId,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<LocationEntity>? locations,
  }) {
    return CustomerEntity(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      locations: locations ?? this.locations,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomerEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
