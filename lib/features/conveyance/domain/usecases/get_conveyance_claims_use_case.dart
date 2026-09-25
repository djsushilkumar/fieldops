import '../entities/conveyance_claim_entity.dart';
import '../entities/conveyance_status.dart';
import '../repositories/conveyance_repository.dart';

class GetConveyanceClaimsUseCase {
  final ConveyanceRepository _repository;

  GetConveyanceClaimsUseCase(this._repository);

  Future<List<ConveyanceClaimEntity>> call({
    String? userId,
    ConveyanceStatus? status,
    bool? flaggedOnly,
    String? searchQuery,
  }) async {
    if (userId != null && userId.isNotEmpty) {
      return await _repository.getUserClaims(userId);
    }
    return await _repository.getAllClaims(
      status: status,
      flaggedOnly: flaggedOnly,
      searchQuery: searchQuery,
    );
  }
}
