import '../../domain/entities/team_entity.dart';

class TeamModel extends TeamEntity {
  const TeamModel({
    required super.id,
    required super.organizationId,
    required super.name,
    super.description,
    super.leadManagerId,
    super.leadManagerName,
    super.colorHex = '#0288D1',
    super.memberCount = 0,
    super.memberIds = const [],
    required super.createdAt,
    required super.updatedAt,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    String? leadName;
    if (json['lead_manager'] != null && json['lead_manager'] is Map) {
      leadName = json['lead_manager']['full_name'] as String?;
    } else {
      leadName = json['lead_manager_name'] as String?;
    }

    List<String> memberIds = [];
    if (json['team_members'] != null && json['team_members'] is List) {
      memberIds = (json['team_members'] as List)
          .map((m) => (m is Map ? m['user_id'] : m).toString())
          .toList();
    } else if (json['member_ids'] != null && json['member_ids'] is List) {
      memberIds = (json['member_ids'] as List).map((m) => m.toString()).toList();
    }

    final memberCount = json['member_count'] != null
        ? json['member_count'] as int
        : memberIds.length;

    return TeamModel(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      name: json['name'] as String? ?? 'Team',
      description: json['description'] as String?,
      leadManagerId: json['lead_manager_id'] as String?,
      leadManagerName: leadName,
      colorHex: json['color_hex'] as String? ?? '#0288D1',
      memberCount: memberCount,
      memberIds: memberIds,
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
      'name': name,
      'description': description,
      'lead_manager_id': leadManagerId,
      'lead_manager_name': leadManagerName,
      'color_hex': colorHex,
      'member_count': memberCount,
      'member_ids': memberIds,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory TeamModel.fromEntity(TeamEntity entity) {
    return TeamModel(
      id: entity.id,
      organizationId: entity.organizationId,
      name: entity.name,
      description: entity.description,
      leadManagerId: entity.leadManagerId,
      leadManagerName: entity.leadManagerName,
      colorHex: entity.colorHex,
      memberCount: entity.memberCount,
      memberIds: entity.memberIds,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
