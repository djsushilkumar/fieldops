import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../domain/entities/attachment_entity.dart';
import '../../domain/entities/attachment_type.dart';
import '../../domain/entities/digital_signature_data.dart';
import '../../domain/repositories/attachment_repository.dart';
import '../datasources/attachment_local_datasource.dart';
import '../datasources/attachment_remote_datasource.dart';
import '../models/attachment_model.dart';
import '../../../sync/domain/entities/sync_entity_type.dart';
import '../../../sync/domain/entities/sync_operation.dart';
import '../../../sync/domain/entities/sync_queue_item.dart';
import '../../../sync/domain/repositories/sync_queue_repository.dart';

class AttachmentRepositoryImpl implements AttachmentRepository {
  final AttachmentRemoteDataSource remoteDataSource;
  final AttachmentLocalDataSource localDataSource;
  final SyncQueueRepository? syncQueueRepository;
  final String Function() getOrgId;
  final String Function() getUserId;
  final String Function()? getUserName;

  AttachmentRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    this.syncQueueRepository,
    required this.getOrgId,
    required this.getUserId,
    this.getUserName,
  });

  @override
  Future<List<AttachmentEntity>> getTaskAttachments(String taskId) async {
    // 1. Try local cache first
    final cached = await localDataSource.getCachedTaskAttachments(taskId);
    if (cached.isNotEmpty) {
      _refreshRemoteSilently(taskId);
      return cached.map((m) => m.toEntity()).toList();
    }

    // 2. Fetch from remote
    try {
      final remoteList = await remoteDataSource.getTaskAttachments(taskId);
      await localDataSource.cacheAttachments(remoteList);
      return remoteList.map((m) => m.toEntity()).toList();
    } catch (_) {
      final fallback = await localDataSource.getCachedTaskAttachments(taskId);
      return fallback.map((m) => m.toEntity()).toList();
    }
  }

  void _refreshRemoteSilently(String taskId) async {
    try {
      final remoteList = await remoteDataSource.getTaskAttachments(taskId);
      await localDataSource.cacheAttachments(remoteList);
    } catch (_) {}
  }

  @override
  Future<AttachmentEntity> uploadAttachment(AttachmentEntity attachment) async {
    final attachmentId = attachment.id.isNotEmpty
        ? attachment.id
        : 'att-${const Uuid().v4()}';
    final orgId = attachment.organizationId.isNotEmpty
        ? attachment.organizationId
        : getOrgId();
    final userId = attachment.uploadedBy.isNotEmpty
        ? attachment.uploadedBy
        : getUserId();
    final userName = attachment.uploadedByName ?? getUserName?.call();

    final prepared = attachment.copyWith(
      id: attachmentId,
      organizationId: orgId,
      uploadedBy: userId,
      uploadedByName: userName,
    );

    final model = AttachmentModel.fromEntity(prepared);

    // Save locally first
    await localDataSource.cacheAttachment(model);

    // Attempt remote upload
    try {
      final uploaded = await remoteDataSource.uploadAttachment(model);
      await localDataSource.cacheAttachment(uploaded);
      return uploaded.toEntity();
    } catch (e) {
      // Offline fallback: enqueue in sync queue
      if (syncQueueRepository != null) {
        final syncItem = SyncQueueItem(
          id: const Uuid().v4(),
          userId: userId,
          operation: SyncOperation.create,
          entityType: SyncEntityType.attachment,
          entityId: model.id,
          payload: model.toJson(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await syncQueueRepository!.enqueue(syncItem);
      }
      return model.toEntity();
    }
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
    final id = 'sig-${const Uuid().v4()}';
    final now = DateTime.now();
    final cleanSigner = signature.signerName.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    final fileName = 'signature_${cleanSigner}_${now.millisecondsSinceEpoch}.json';
    final storagePath = 'tasks/$taskId/signatures/$fileName';

    final attachment = AttachmentEntity(
      id: id,
      organizationId: orgId.isNotEmpty ? orgId : getOrgId(),
      taskId: taskId,
      visitId: visitId,
      uploadedBy: userId.isNotEmpty ? userId : getUserId(),
      uploadedByName: userName ?? getUserName?.call(),
      type: AttachmentType.signature,
      storagePath: storagePath,
      fileName: fileName,
      fileSize: utf8.encode(jsonEncode(signature.toMap())).length,
      mimeType: 'application/json',
      metadata: signature.toMetadata(),
      createdAt: now,
      rawData: jsonEncode(signature.toMap()),
    );

    return await uploadAttachment(attachment);
  }

  @override
  Future<void> deleteAttachment(String attachmentId) async {
    await localDataSource.deleteCachedAttachment(attachmentId);
    try {
      await remoteDataSource.deleteAttachment(attachmentId);
    } catch (_) {
      if (syncQueueRepository != null) {
        final syncItem = SyncQueueItem(
          id: const Uuid().v4(),
          userId: getUserId(),
          operation: SyncOperation.delete,
          entityType: SyncEntityType.attachment,
          entityId: attachmentId,
          payload: {'id': attachmentId},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await syncQueueRepository!.enqueue(syncItem);
      }
    }
  }
}
