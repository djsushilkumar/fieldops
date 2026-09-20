import '../repositories/attachment_repository.dart';

class DeleteAttachmentUseCase {
  final AttachmentRepository _repository;

  DeleteAttachmentUseCase(this._repository);

  Future<void> execute(String attachmentId) async {
    await _repository.deleteAttachment(attachmentId);
  }
}
