import '../../../tasks/domain/entities/task_entity.dart';
import 'attachment_entity.dart';

class TaskProofStatus {
  final bool requiresGps;
  final bool requiresPhoto;
  final bool requiresForm;
  final bool requiresSignature;
  final bool hasGpsProof;
  final bool hasPhotoProof;
  final bool hasFormProof;
  final bool hasSignatureProof;
  final int photoCount;
  final String? signatureSignerName;
  final DateTime? signatureTime;
  final List<String> missingRequirements;

  const TaskProofStatus({
    required this.requiresGps,
    required this.requiresPhoto,
    required this.requiresForm,
    required this.requiresSignature,
    required this.hasGpsProof,
    required this.hasPhotoProof,
    required this.hasFormProof,
    required this.hasSignatureProof,
    this.photoCount = 0,
    this.signatureSignerName,
    this.signatureTime,
    required this.missingRequirements,
  });

  bool get isAllSatisfied => missingRequirements.isEmpty;

  factory TaskProofStatus.evaluate({
    required TaskEntity task,
    required List<AttachmentEntity> attachments,
    bool hasActiveOrCompletedVisit = false,
    bool hasSubmittedForm = false,
  }) {
    final photos = attachments.where((a) => a.isPhoto).toList();
    final signatures = attachments.where((a) => a.isSignature).toList();

    final hasPhotoProof = !task.requiresPhoto || photos.isNotEmpty;
    final hasSignatureProof = !task.requiresSignature || signatures.isNotEmpty;
    final hasGpsProof = !task.requiresGps || hasActiveOrCompletedVisit || task.isInProgress || task.isCompleted;
    final hasFormProof = !task.requiresForm || hasSubmittedForm || task.isCompleted;

    final missing = <String>[];
    if (task.requiresGps && !hasGpsProof) {
      missing.add('GPS Check-in within site geofence');
    }
    if (task.requiresPhoto && !hasPhotoProof) {
      missing.add('At least 1 photo proof attachment');
    }
    if (task.requiresSignature && !hasSignatureProof) {
      missing.add('Digital customer or supervisor sign-off signature');
    }
    if (task.requiresForm && !hasFormProof) {
      missing.add('Mandatory service inspection form submission');
    }

    final latestSignature = signatures.isNotEmpty ? signatures.first : null;

    return TaskProofStatus(
      requiresGps: task.requiresGps,
      requiresPhoto: task.requiresPhoto,
      requiresForm: task.requiresForm,
      requiresSignature: task.requiresSignature,
      hasGpsProof: hasGpsProof,
      hasPhotoProof: hasPhotoProof,
      hasFormProof: hasFormProof,
      hasSignatureProof: hasSignatureProof,
      photoCount: photos.length,
      signatureSignerName: latestSignature?.metadata.signerName,
      signatureTime: latestSignature?.metadata.capturedAt,
      missingRequirements: missing,
    );
  }
}
