import '../entities/attachment_entity.dart';
import '../entities/digital_signature_data.dart';
import '../repositories/attachment_repository.dart';

class SaveSignatureUseCase {
  final AttachmentRepository _repository;

  SaveSignatureUseCase(this._repository);

  Future<AttachmentEntity> execute({
    required String taskId,
    required DigitalSignatureData signature,
    String? visitId,
    required String userId,
    String? userName,
    required String orgId,
  }) async {
    return await _repository.saveSignature(
      taskId: taskId,
      signature: signature,
      visitId: visitId,
      userId: userId,
      userName: userName,
      orgId: orgId,
    );
  }
}
