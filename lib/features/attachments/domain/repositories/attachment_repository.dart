import '../entities/attachment_entity.dart';
import '../entities/digital_signature_data.dart';

abstract class AttachmentRepository {
  Future<List<AttachmentEntity>> getTaskAttachments(String taskId);
  Future<AttachmentEntity> uploadAttachment(AttachmentEntity attachment);
  Future<AttachmentEntity> saveSignature({
    required String taskId,
    required DigitalSignatureData signature,
    String? visitId,
    required String userId,
    String? userName,
    required String orgId,
  });
  Future<void> deleteAttachment(String attachmentId);
}
