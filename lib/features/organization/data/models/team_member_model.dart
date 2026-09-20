import '../../../auth/domain/entities/user_role.dart';
import '../../domain/entities/team_member_entity.dart';

class TeamMemberModel extends TeamMemberEntity {
  const TeamMemberModel({
    required super.id,
    super.teamId,
    super.teamName,
    required super.userId,
    required super.name,
    required super.email,
    required super.role,
    super.status = MemberStatus.active,
    required super.joinedAt,
  });

  factory TeamMemberModel.fromJson(Map<String, dynamic> json) {
    String? teamName;
    if (json['teams'] != null && json['teams'] is Map) {
      teamName = json['teams']['name'] as String?;
    } else {
      teamName = json['team_name'] as String?;
    }

    return TeamMemberModel(
      id: json['id'] as String? ?? json['user_id'] as String,
      teamId: json['team_id'] as String?,
      teamName: teamName,
      userId: json['user_id'] as String? ?? json['id'] as String,
      name: json['full_name'] as String? ?? json['name'] as String? ?? 'Team Member',
      email: json['email'] as String? ?? '',
      role: UserRole.fromString(json['role'] as String?),
      status: MemberStatus.fromString(json['status'] as String?),
      joinedAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team_id': teamId,
      'team_name': teamName,
      'user_id': userId,
      'full_name': name,
      'email': email,
      'role': role.value,
      'status': status.name.toUpperCase(),
      'created_at': joinedAt.toIso8601String(),
    };
  }

  factory TeamMemberModel.fromEntity(TeamMemberEntity entity) {
    return TeamMemberModel(
      id: entity.id,
      teamId: entity.teamId,
      teamName: entity.teamName,
      userId: entity.userId,
      name: entity.name,
      email: entity.email,
      role: entity.role,
      status: entity.status,
      joinedAt: entity.joinedAt,
    );
  }
}
