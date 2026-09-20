import '../../../auth/domain/entities/user_role.dart';
import '../entities/team_member_entity.dart';
import '../repositories/organization_repository.dart';

class GetMembersUseCase {
  final OrganizationRepository repository;

  GetMembersUseCase(this.repository);

  Future<List<TeamMemberEntity>> call(String orgId) {
    return repository.getMembers(orgId);
  }
}

class InviteMemberUseCase {
  final OrganizationRepository repository;

  InviteMemberUseCase(this.repository);

  Future<TeamMemberEntity> call({
    required String orgId,
    required String name,
    required String email,
    required UserRole role,
    String? teamId,
  }) {
    return repository.inviteMember(
      orgId: orgId,
      name: name,
      email: email,
      role: role,
      teamId: teamId,
    );
  }
}

class UpdateMemberRoleUseCase {
  final OrganizationRepository repository;

  UpdateMemberRoleUseCase(this.repository);

  Future<TeamMemberEntity> call({
    required String memberId,
    required UserRole role,
    String? teamId,
    MemberStatus? status,
  }) {
    return repository.updateMemberRole(
      memberId: memberId,
      role: role,
      teamId: teamId,
      status: status,
    );
  }
}
