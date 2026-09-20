import '../entities/attachment_entity.dart';
import '../repositories/attachment_repository.dart';

class UploadAttachmentUseCase {
  final AttachmentRepository _repository;

  UploadAttachmentUseCase(this._repository);

  Future<AttachmentEntity> execute(AttachmentEntity attachment) async {
    return await _repository.uploadAttachment(attachment);
  }
}
