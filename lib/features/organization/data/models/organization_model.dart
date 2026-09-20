import '../../domain/entities/organization_entity.dart';

class OrganizationModel {
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

  OrganizationModel({
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

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    return OrganizationModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Field Operations Inc.',
      timezone: json['timezone'] as String? ?? 'UTC',
      currency: json['currency'] as String? ?? 'USD',
      industry: json['industry'] as String? ?? 'Field Services',
      geofenceDefaultRadius: (json['geofence_default_radius'] ?? 100) as int,
      autoCheckoutHours: (json['auto_checkout_hours'] ?? 10) as int,
      requirePhotoOnCompletion: (json['require_photo_on_completion'] ?? false) as bool,
      requireGpsOnCheckin: (json['require_gps_on_checkin'] ?? true) as bool,
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
      'industry': industry,
      'geofence_default_radius': geofenceDefaultRadius,
      'auto_checkout_hours': autoCheckoutHours,
      'require_photo_on_completion': requirePhotoOnCompletion,
      'require_gps_on_checkin': requireGpsOnCheckin,
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
      industry: industry,
      geofenceDefaultRadius: geofenceDefaultRadius,
      autoCheckoutHours: autoCheckoutHours,
      requirePhotoOnCompletion: requirePhotoOnCompletion,
      requireGpsOnCheckin: requireGpsOnCheckin,
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
      industry: entity.industry,
      geofenceDefaultRadius: entity.geofenceDefaultRadius,
      autoCheckoutHours: entity.autoCheckoutHours,
      requirePhotoOnCompletion: entity.requirePhotoOnCompletion,
      requireGpsOnCheckin: entity.requireGpsOnCheckin,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
