import 'dart:convert';
import '../../domain/entities/beat_frequency.dart';
import '../../domain/entities/beat_plan_entity.dart';
import 'beat_stop_model.dart';

class BeatPlanModel extends BeatPlanEntity {
  const BeatPlanModel({
    required super.id,
    required super.organizationId,
    required super.code,
    required super.name,
    super.description,
    required super.assignedTechnicianId,
    required super.assignedTechnicianName,
    super.frequency,
    super.dayOfWeek,
    super.stops,
    super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory BeatPlanModel.fromEntity(BeatPlanEntity entity) {
    return BeatPlanModel(
      id: entity.id,
      organizationId: entity.organizationId,
      code: entity.code,
      name: entity.name,
      description: entity.description,
      assignedTechnicianId: entity.assignedTechnicianId,
      assignedTechnicianName: entity.assignedTechnicianName,
      frequency: entity.frequency,
      dayOfWeek: entity.dayOfWeek,
      stops: entity.stops,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory BeatPlanModel.fromJson(Map<String, dynamic> json) {
    List<BeatStopModel> parsedStops = [];
    if (json['stops'] != null) {
      if (json['stops'] is List) {
        parsedStops = (json['stops'] as List)
            .map((s) => BeatStopModel.fromJson(s as Map<String, dynamic>))
            .toList();
      } else if (json['stops'] is String) {
        try {
          final decoded = jsonDecode(json['stops'] as String) as List;
          parsedStops = decoded
              .map((s) => BeatStopModel.fromJson(s as Map<String, dynamic>))
              .toList();
        } catch (_) {}
      }
    }

    return BeatPlanModel(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String? ?? 'org_default',
      code: json['code'] as String? ?? 'BEAT-01',
      name: json['name'] as String,
      description: json['description'] as String?,
      assignedTechnicianId: json['assigned_technician_id'] as String,
      assignedTechnicianName: json['assigned_technician_name'] as String? ?? 'Field Executive',
      frequency: BeatFrequency.fromString(json['frequency'] as String?),
      dayOfWeek: json['day_of_week'] as int? ?? 1,
      stops: parsedStops,
      isActive: json['is_active'] != false && json['is_active'] != 0,
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
      'organization_id': organizationId,
      'code': code,
      'name': name,
      'description': description,
      'assigned_technician_id': assignedTechnicianId,
      'assigned_technician_name': assignedTechnicianName,
      'frequency': frequency.name,
      'day_of_week': dayOfWeek,
      'stops': stops.map((s) => BeatStopModel.fromEntity(s).toJson()).toList(),
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toSqlMap() {
    return {
      'id': id,
      'organization_id': organizationId,
      'code': code,
      'name': name,
      'description': description,
      'assigned_technician_id': assignedTechnicianId,
      'assigned_technician_name': assignedTechnicianName,
      'frequency': frequency.name,
      'day_of_week': dayOfWeek,
      'stops_json': jsonEncode(stops.map((s) => BeatStopModel.fromEntity(s).toJson()).toList()),
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory BeatPlanModel.fromSqlMap(Map<String, dynamic> map) {
    List<BeatStopModel> parsedStops = [];
    if (map['stops_json'] != null) {
      try {
        final decoded = jsonDecode(map['stops_json'] as String) as List;
        parsedStops = decoded
            .map((s) => BeatStopModel.fromJson(s as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    return BeatPlanModel(
      id: map['id'] as String,
      organizationId: map['organization_id'] as String? ?? 'org_default',
      code: map['code'] as String? ?? 'BEAT-01',
      name: map['name'] as String,
      description: map['description'] as String?,
      assignedTechnicianId: map['assigned_technician_id'] as String,
      assignedTechnicianName: map['assigned_technician_name'] as String? ?? 'Field Executive',
      frequency: BeatFrequency.fromString(map['frequency'] as String?),
      dayOfWeek: map['day_of_week'] as int? ?? 1,
      stops: parsedStops,
      isActive: map['is_active'] == 1 || map['is_active'] == true,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }
}
