import '../../domain/entities/customer_entity.dart';
import '../../domain/entities/location_entity.dart';
import 'location_model.dart';

class CustomerModel extends CustomerEntity {
  const CustomerModel({
    required super.id,
    required super.organizationId,
    required super.name,
    super.phone,
    super.email,
    super.address,
    super.notes,
    super.createdBy,
    required super.createdAt,
    required super.updatedAt,
    super.locations = const [],
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    List<LocationEntity> locs = [];
    if (json['locations'] != null && json['locations'] is List) {
      locs = (json['locations'] as List)
          .map((loc) => LocationModel.fromJson(loc as Map<String, dynamic>))
          .toList();
    }

    return CustomerModel(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      locations: locs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'locations': locations
          .map((l) => LocationModel.fromEntity(l).toJson())
          .toList(),
    };
  }

  factory CustomerModel.fromEntity(CustomerEntity entity) {
    return CustomerModel(
      id: entity.id,
      organizationId: entity.organizationId,
      name: entity.name,
      phone: entity.phone,
      email: entity.email,
      address: entity.address,
      notes: entity.notes,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      locations: entity.locations,
    );
  }

  @override
  CustomerModel copyWith({
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
    return CustomerModel(
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
}
