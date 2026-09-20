import '../entities/team_entity.dart';
import '../repositories/organization_repository.dart';

class GetTeamsUseCase {
  final OrganizationRepository repository;

  GetTeamsUseCase(this.repository);

  Future<List<TeamEntity>> call(String orgId) {
    return repository.getTeams(orgId);
  }
}

class CreateTeamUseCase {
  final OrganizationRepository repository;

  CreateTeamUseCase(this.repository);

  Future<TeamEntity> call({
    required String orgId,
    required String name,
    String? description,
    String? leadManagerId,
    String? colorHex,
  }) {
    return repository.createTeam(
      orgId: orgId,
      name: name,
      description: description,
      leadManagerId: leadManagerId,
      colorHex: colorHex,
    );
  }
}

class UpdateTeamUseCase {
  final OrganizationRepository repository;

  UpdateTeamUseCase(this.repository);

  Future<TeamEntity> call({
    required String teamId,
    String? name,
    String? description,
    String? leadManagerId,
    String? colorHex,
  }) {
    return repository.updateTeam(
      teamId: teamId,
      name: name,
      description: description,
      leadManagerId: leadManagerId,
      colorHex: colorHex,
    );
  }
}

class DeleteTeamUseCase {
  final OrganizationRepository repository;

  DeleteTeamUseCase(this.repository);

  Future<void> call(String teamId) {
    return repository.deleteTeam(teamId);
  }
}
