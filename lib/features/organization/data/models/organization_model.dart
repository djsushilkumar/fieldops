import '../../domain/entities/organization_entity.dart';

class OrganizationModel {
  final String id;
  final String name;
  final String timezone;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrganizationModel({
    required this.id,
    required this.name,
    this.timezone = 'UTC',
    this.currency = 'USD',
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    return OrganizationModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Field Operations Inc.',
      timezone: json['timezone'] as String? ?? 'UTC',
      currency: json['currency'] as String? ?? 'USD',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'timezone': timezone,
      'currency': currency,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  OrganizationEntity toEntity() {
    return OrganizationEntity(
      id: id,
      name: name,
      timezone: timezone,
      currency: currency,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory OrganizationModel.fromEntity(OrganizationEntity entity) {
    return OrganizationModel(
      id: entity.id,
      name: entity.name,
      timezone: entity.timezone,
      currency: entity.currency,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
