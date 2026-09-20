import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/team_entity.dart';
import '../../domain/entities/team_member_entity.dart';
import '../../domain/usecases/manage_members_use_cases.dart';
import '../../domain/usecases/manage_teams_use_cases.dart';
import 'organization_settings_controller.dart';

// ============================================================================
// Providers
// ============================================================================

final getTeamsUseCaseProvider = Provider<GetTeamsUseCase>((ref) {
  return GetTeamsUseCase(ref.watch(organizationRepositoryProvider));
});

final createTeamUseCaseProvider = Provider<CreateTeamUseCase>((ref) {
  return CreateTeamUseCase(ref.watch(organizationRepositoryProvider));
});

final updateTeamUseCaseProvider = Provider<UpdateTeamUseCase>((ref) {
  return UpdateTeamUseCase(ref.watch(organizationRepositoryProvider));
});

final deleteTeamUseCaseProvider = Provider<DeleteTeamUseCase>((ref) {
  return DeleteTeamUseCase(ref.watch(organizationRepositoryProvider));
});

final getMembersUseCaseProvider = Provider<GetMembersUseCase>((ref) {
  return GetMembersUseCase(ref.watch(organizationRepositoryProvider));
});

final inviteMemberUseCaseProvider = Provider<InviteMemberUseCase>((ref) {
  return InviteMemberUseCase(ref.watch(organizationRepositoryProvider));
});

final updateMemberRoleUseCaseProvider = Provider<UpdateMemberRoleUseCase>((ref) {
  return UpdateMemberRoleUseCase(ref.watch(organizationRepositoryProvider));
});

// ============================================================================
// State & Controller
// ============================================================================

class TeamsState {
  final List<TeamEntity> teams;
  final List<TeamMemberEntity> members;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;

  const TeamsState({
    this.teams = const [],
    this.members = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
  });

  TeamsState copyWith({
    List<TeamEntity>? teams,
    List<TeamMemberEntity>? members,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return TeamsState(
      teams: teams ?? this.teams,
      members: members ?? this.members,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage ?? (clearMessages ? null : this.errorMessage),
      successMessage: successMessage ?? (clearMessages ? null : this.successMessage),
    );
  }
}

class TeamsController extends StateNotifier<TeamsState> {
  final GetTeamsUseCase _getTeamsUseCase;
  final CreateTeamUseCase _createTeamUseCase;
  final UpdateTeamUseCase _updateTeamUseCase;
  final DeleteTeamUseCase _deleteTeamUseCase;
  final GetMembersUseCase _getMembersUseCase;
  final InviteMemberUseCase _inviteMemberUseCase;
  final UpdateMemberRoleUseCase _updateMemberRoleUseCase;
  final Ref _ref;

  TeamsController({
    required GetTeamsUseCase getTeamsUseCase,
    required CreateTeamUseCase createTeamUseCase,
    required UpdateTeamUseCase updateTeamUseCase,
    required DeleteTeamUseCase deleteTeamUseCase,
    required GetMembersUseCase getMembersUseCase,
    required InviteMemberUseCase inviteMemberUseCase,
    required UpdateMemberRoleUseCase updateMemberRoleUseCase,
    required Ref ref,
  })  : _getTeamsUseCase = getTeamsUseCase,
        _createTeamUseCase = createTeamUseCase,
        _updateTeamUseCase = updateTeamUseCase,
        _deleteTeamUseCase = deleteTeamUseCase,
        _getMembersUseCase = getMembersUseCase,
        _inviteMemberUseCase = inviteMemberUseCase,
        _updateMemberRoleUseCase = updateMemberRoleUseCase,
        _ref = ref,
        super(const TeamsState()) {
    loadTeamsAndMembers();
  }

  String _resolveOrgId() {
    final user = _ref.read(currentUserProvider);
    return user?.organizationId ?? 'org-acme-ops-001';
  }

  Future<void> loadTeamsAndMembers() async {
    final orgId = _resolveOrgId();
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final teams = await _getTeamsUseCase(orgId);
      final members = await _getMembersUseCase(orgId);
      state = state.copyWith(
        isLoading: false,
        teams: teams,
        members: members,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load teams & members: $e',
      );
    }
  }

  Future<bool> createTeam({
    required String name,
    String? description,
    String? leadManagerId,
    String? colorHex,
  }) async {
    final orgId = _resolveOrgId();
    state = state.copyWith(isSubmitting: true, clearMessages: true);
    try {
      final newTeam = await _createTeamUseCase(
        orgId: orgId,
        name: name,
        description: description,
        leadManagerId: leadManagerId,
        colorHex: colorHex,
      );
      state = state.copyWith(
        isSubmitting: false,
        teams: [...state.teams, newTeam],
        successMessage: 'Team "${newTeam.name}" created successfully!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to create team: $e',
      );
      return false;
    }
  }

  Future<bool> updateTeam({
    required String teamId,
    String? name,
    String? description,
    String? leadManagerId,
    String? colorHex,
  }) async {
    state = state.copyWith(isSubmitting: true, clearMessages: true);
    try {
      final updated = await _updateTeamUseCase(
        teamId: teamId,
        name: name,
        description: description,
        leadManagerId: leadManagerId,
        colorHex: colorHex,
      );
      final list = state.teams.map((t) => t.id == teamId ? updated : t).toList();
      state = state.copyWith(
        isSubmitting: false,
        teams: list,
        successMessage: 'Team updated successfully!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to update team: $e',
      );
      return false;
    }
  }

  Future<bool> deleteTeam(String teamId) async {
    state = state.copyWith(isSubmitting: true, clearMessages: true);
    try {
      await _deleteTeamUseCase(teamId);
      final list = state.teams.where((t) => t.id != teamId).toList();
      state = state.copyWith(
        isSubmitting: false,
        teams: list,
        successMessage: 'Team removed successfully.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to delete team: $e',
      );
      return false;
    }
  }

  Future<bool> inviteMember({
    required String name,
    required String email,
    required UserRole role,
    String? teamId,
  }) async {
    final orgId = _resolveOrgId();
    state = state.copyWith(isSubmitting: true, clearMessages: true);
    try {
      final member = await _inviteMemberUseCase(
        orgId: orgId,
        name: name,
        email: email,
        role: role,
        teamId: teamId,
      );
      state = state.copyWith(
        isSubmitting: false,
        members: [...state.members, member],
        successMessage: 'Invitation sent to $email!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to invite member: $e',
      );
      return false;
    }
  }

  Future<bool> updateMemberRole({
    required String memberId,
    required UserRole role,
    String? teamId,
    MemberStatus? status,
  }) async {
    state = state.copyWith(isSubmitting: true, clearMessages: true);
    try {
      final updated = await _updateMemberRoleUseCase(
        memberId: memberId,
        role: role,
        teamId: teamId,
        status: status,
      );
      final list = state.members.map((m) => m.id == memberId ? updated : m).toList();
      state = state.copyWith(
        isSubmitting: false,
        members: list,
        successMessage: 'Member permissions updated.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to update member: $e',
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearMessages: true);
  }
}

final teamsControllerProvider = StateNotifierProvider<TeamsController, TeamsState>((ref) {
  return TeamsController(
    getTeamsUseCase: ref.watch(getTeamsUseCaseProvider),
    createTeamUseCase: ref.watch(createTeamUseCaseProvider),
    updateTeamUseCase: ref.watch(updateTeamUseCaseProvider),
    deleteTeamUseCase: ref.watch(deleteTeamUseCaseProvider),
    getMembersUseCase: ref.watch(getMembersUseCaseProvider),
    inviteMemberUseCase: ref.watch(inviteMemberUseCaseProvider),
    updateMemberRoleUseCase: ref.watch(updateMemberRoleUseCaseProvider),
    ref: ref,
  );
});
