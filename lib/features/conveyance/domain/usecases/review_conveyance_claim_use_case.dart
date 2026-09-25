import '../entities/conveyance_claim_entity.dart';
import '../entities/conveyance_status.dart';
import '../repositories/conveyance_repository.dart';

class ReviewConveyanceClaimUseCase {
  final ConveyanceRepository _repository;

  ReviewConveyanceClaimUseCase(this._repository);

  Future<ConveyanceClaimEntity> call({
    required String claimId,
    required ConveyanceStatus newStatus,
    required double approvedPayout,
    String? managerNotes,
  }) async {
    if (claimId.isEmpty) {
      throw ArgumentError('Claim ID cannot be empty');
    }
    return await _repository.reviewClaim(
      claimId: claimId,
      newStatus: newStatus,
      approvedPayout: approvedPayout,
      managerNotes: managerNotes,
    );
  }
}
