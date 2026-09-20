import '../../../auth/domain/entities/user_role.dart';

enum MemberStatus {
  active,
  pending,
  suspended;

  String get displayName {
    switch (this) {
      case MemberStatus.active:
        return 'Active';
      case MemberStatus.pending:
        return 'Invite Pending';
      case MemberStatus.suspended:
        return 'Suspended';
    }
  }

  static MemberStatus fromString(String? val) {
    if (val == null) return MemberStatus.active;
    switch (val.toUpperCase()) {
      case 'PENDING':
        return MemberStatus.pending;
      case 'SUSPENDED':
        return MemberStatus.suspended;
      case 'ACTIVE':
      default:
        return MemberStatus.active;
    }
  }
}

class TeamMemberEntity {
  final String id;
  final String? teamId;
  final String? teamName;
  final String userId;
  final String name;
  final String email;
  final UserRole role;
  final MemberStatus status;
  final DateTime joinedAt;

  const TeamMemberEntity({
    required this.id,
    this.teamId,
    this.teamName,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    this.status = MemberStatus.active,
    required this.joinedAt,
  });

  TeamMemberEntity copyWith({
    String? id,
    String? teamId,
    String? teamName,
    String? userId,
    String? name,
    String? email,
    UserRole? role,
    MemberStatus? status,
    DateTime? joinedAt,
  }) {
    return TeamMemberEntity(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}
