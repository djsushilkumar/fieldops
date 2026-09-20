import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_ops/core/location/location_coordinates.dart';
import 'package:field_ops/features/attachments/domain/entities/attachment_entity.dart';
import 'package:field_ops/features/attachments/domain/entities/attachment_metadata.dart';
import 'package:field_ops/features/attachments/domain/entities/attachment_type.dart';
import 'package:field_ops/features/attachments/domain/entities/digital_signature_data.dart';
import 'package:field_ops/features/attachments/domain/repositories/attachment_repository.dart';
import 'package:field_ops/features/attachments/presentation/controllers/task_attachments_controller.dart';
import 'package:field_ops/features/auth/domain/entities/user_entity.dart';
import 'package:field_ops/features/auth/domain/entities/user_role.dart';
import 'package:field_ops/features/auth/presentation/controllers/auth_controller.dart';
import 'package:field_ops/features/tasks/domain/entities/task_entity.dart';
import 'package:field_ops/features/tasks/domain/entities/task_status.dart';

class MockAttachmentRepoForController implements AttachmentRepository {
  final List<AttachmentEntity> list = [];

  @override
  Future<List<AttachmentEntity>> getTaskAttachments(String taskId) async {
    return list.where((a) => a.taskId == taskId).toList();
  }

  @override
  Future<AttachmentEntity> uploadAttachment(AttachmentEntity attachment) async {
    final toAdd = attachment.id.isNotEmpty
        ? attachment
        : attachment.copyWith(id: 'att-${list.length + 1}');
    list.add(toAdd);
    return toAdd;
  }

  @override
  Future<AttachmentEntity> saveSignature({
    required String taskId,
    required DigitalSignatureData signature,
    String? visitId,
    required String userId,
    String? userName,
    required String orgId,
  }) async {
    final att = AttachmentEntity(
      id: 'sig-${list.length + 1}',
      organizationId: orgId,
      taskId: taskId,
      uploadedBy: userId,
      uploadedByName: userName,
      type: AttachmentType.signature,
      storagePath: 'path/sig.json',
      fileName: 'sig.json',
      metadata: signature.toMetadata(),
      createdAt: DateTime.now(),
    );
    list.add(att);
    return att;
  }

  @override
  Future<void> deleteAttachment(String attachmentId) async {
    list.removeWhere((a) => a.id == attachmentId);
  }
}

void main() {
  final testUser = UserEntity(
    id: 'usr-1',
    organizationId: 'org-1',
    name: 'David Miller',
    email: 'david@fieldops.com',
    role: UserRole.employee,
    status: 'active',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  test('TaskAttachmentsNotifier lifecycle, photo upload, and signature saving', () async {
    final repo = MockAttachmentRepoForController();
    repo.list.add(
      AttachmentEntity(
        id: 'initial-photo',
        organizationId: 'org-1',
        taskId: 'tsk-1',
        uploadedBy: 'usr-1',
        type: AttachmentType.photo,
        storagePath: 'path.jpg',
        fileName: 'photo1.jpg',
        metadata: const AttachmentMetadata(category: 'before'),
        createdAt: DateTime.now(),
      ),
    );

    final container = ProviderContainer(
      overrides: [
        attachmentRepositoryProvider.overrideWithValue(repo),
        currentUserProvider.overrideWithValue(testUser),
      ],
    );
    addTearDown(container.dispose);

    // Initial load
    final notifier = container.read(taskAttachmentsNotifierProvider('tsk-1').notifier);
    await notifier.loadAttachments();

    var state = container.read(taskAttachmentsNotifierProvider('tsk-1'));
    expect(state.isLoading, isFalse);
    expect(state.attachments.length, equals(1));
    expect(state.photos.length, equals(1));
    expect(state.signatures.isEmpty, isTrue);

    // Upload another photo
    final uploaded = await notifier.uploadPhotoProof(
      category: 'after',
      fileName: 'after_work.jpg',
      notes: 'Job done',
      location: const LocationCoordinates(latitude: 37.77, longitude: -122.41, accuracy: 3.0),
    );
    expect(uploaded, isTrue);

    state = container.read(taskAttachmentsNotifierProvider('tsk-1'));
    expect(state.photos.length, equals(2));
    expect(state.photoCount, equals(2));

    // Save signature
    final sigData = DigitalSignatureData(
      strokes: [
        const DigitalSignatureStroke(
          points: [DigitalSignaturePoint(10, 10)],
        ),
      ],
      signerName: 'Marcus Vance',
      signerRole: 'Director',
      signedAt: DateTime.now(),
    );

    final sigSaved = await notifier.saveDigitalSignature(signature: sigData);
    expect(sigSaved, isTrue);

    state = container.read(taskAttachmentsNotifierProvider('tsk-1'));
    expect(state.signatures.length, equals(1));
    expect(state.hasSignature, isTrue);
    expect(state.latestSignature?.metadata.signerName, equals('Marcus Vance'));

    // Evaluate proof requirements on a task
    final task = TaskEntity(
      id: 'tsk-1',
      organizationId: 'org-1',
      title: 'AC Service',
      status: TaskStatus.inProgress,
      requiresPhoto: true,
      requiresSignature: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final proofStatus = state.evaluateProof(task);
    expect(proofStatus.isAllSatisfied, isTrue);
    expect(proofStatus.hasPhotoProof, isTrue);
    expect(proofStatus.hasSignatureProof, isTrue);

    // Delete attachment
    final deleted = await notifier.deleteAttachment('initial-photo');
    expect(deleted, isTrue);

    state = container.read(taskAttachmentsNotifierProvider('tsk-1'));
    expect(state.photos.length, equals(1));
  });
}
