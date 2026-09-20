import '../entities/attachment_entity.dart';
import '../repositories/attachment_repository.dart';

class GetTaskAttachmentsUseCase {
  final AttachmentRepository _repository;

  GetTaskAttachmentsUseCase(this._repository);

  Future<List<AttachmentEntity>> execute(String taskId) async {
    return await _repository.getTaskAttachments(taskId);
  }
}
