import 'package:flutter_test/flutter_test.dart';
import 'package:field_ops/core/errors/exceptions.dart';
import 'package:field_ops/features/attachments/data/datasources/attachment_local_datasource.dart';
import 'package:field_ops/features/attachments/data/datasources/attachment_remote_datasource.dart';
import 'package:field_ops/features/attachments/data/models/attachment_model.dart';
import 'package:field_ops/features/attachments/data/repositories/attachment_repository_impl.dart';
import 'package:field_ops/features/attachments/domain/entities/attachment_entity.dart';
import 'package:field_ops/features/attachments/domain/entities/attachment_type.dart';
import 'package:field_ops/features/attachments/domain/entities/digital_signature_data.dart';
import 'package:field_ops/features/sync/domain/entities/sync_entity_type.dart';
import 'package:field_ops/features/sync/domain/entities/sync_operation.dart';
import 'package:field_ops/features/sync/domain/entities/sync_queue_item.dart';
import 'package:field_ops/features/sync/domain/entities/sync_status.dart';
import 'package:field_ops/features/sync/domain/repositories/sync_queue_repository.dart';

class MockLocalDataSource implements AttachmentLocalDataSource {
  final Map<String, AttachmentModel> items = {};

  @override
  Future<List<AttachmentModel>> getCachedTaskAttachments(String taskId) async {
    return items.values.where((a) => a.taskId == taskId).toList();
  }

  @override
  Future<AttachmentModel?> getCachedAttachmentById(String attachmentId) async {
    return items[attachmentId];
  }

  @override
  Future<void> cacheAttachment(AttachmentModel attachment) async {
    items[attachment.id] = attachment;
  }

  @override
  Future<void> cacheAttachments(List<AttachmentModel> attachments) async {
    for (final a in attachments) {
      items[a.id] = a;
    }
  }

  @override
  Future<void> deleteCachedAttachment(String attachmentId) async {
    items.remove(attachmentId);
  }

  @override
  Future<void> clearAll() async {
    items.clear();
  }
}

class StubRemoteDataSource implements AttachmentRemoteDataSource {
  final Map<String, AttachmentModel> remoteItems = {};
  bool shouldThrow = false;

  @override
  Future<List<AttachmentModel>> getTaskAttachments(String taskId) async {
    if (shouldThrow) throw const ServerException('Network down');
    return remoteItems.values.where((a) => a.taskId == taskId).toList();
  }

  @override
  Future<AttachmentModel> uploadAttachment(AttachmentModel attachment) async {
    if (shouldThrow) throw const ServerException('Network down');
    remoteItems[attachment.id] = attachment;
    return attachment;
  }

  @override
  Future<void> deleteAttachment(String attachmentId) async {
    if (shouldThrow) throw const ServerException('Network down');
    remoteItems.remove(attachmentId);
  }
}

class MockSyncQueueRepository implements SyncQueueRepository {
  final List<SyncQueueItem> queued = [];

  @override
  Future<SyncQueueItem> enqueue(SyncQueueItem item) async {
    queued.add(item);
    return item;
  }

  @override
  Future<void> clearAll() async => queued.clear();

  @override
  Future<void> clearSyncedItems() async {}

  @override
  Future<List<SyncQueueItem>> getAllItems({String? userId, SyncStatus? status}) async => queued;

  @override
  Future<int> getPendingCount({String? userId}) async => queued.length;

  @override
  Future<List<SyncQueueItem>> getPendingItems({String? userId}) async => queued;

  @override
  Future<void> markFailed(String id, String error, {DateTime? nextRetryAt}) async {}

  @override
  Future<void> markSynced(String id) async {}

  @override
  Future<void> removeItem(String id) async {
    queued.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> updateItemStatus(String id, SyncStatus status, {String? error, DateTime? scheduledRetryAt}) async {}
}

void main() {
  late MockLocalDataSource localDataSource;
  late StubRemoteDataSource remoteDataSource;
  late MockSyncQueueRepository syncQueueRepository;
  late AttachmentRepositoryImpl repository;

  final testAttachment = AttachmentEntity(
    id: 'att-1',
    organizationId: 'org-1',
    taskId: 'tsk-1',
    uploadedBy: 'usr-1',
    type: AttachmentType.photo,
    storagePath: 'tasks/tsk-1/photo.jpg',
    fileName: 'photo.jpg',
    createdAt: DateTime.now(),
  );

  setUp(() {
    localDataSource = MockLocalDataSource();
    remoteDataSource = StubRemoteDataSource();
    syncQueueRepository = MockSyncQueueRepository();
    repository = AttachmentRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
      syncQueueRepository: syncQueueRepository,
      getOrgId: () => 'org-1',
      getUserId: () => 'usr-1',
      getUserName: () => 'David Miller',
    );
  });

  group('AttachmentRepositoryImpl', () {
    test('getTaskAttachments fetches from remote and caches locally', () async {
      final model = AttachmentModel.fromEntity(testAttachment);
      remoteDataSource.remoteItems[model.id] = model;

      final results = await repository.getTaskAttachments('tsk-1');
      expect(results.length, equals(1));
      expect(results.first.id, equals('att-1'));
      expect(localDataSource.items.containsKey('att-1'), isTrue);
    });

    test('getTaskAttachments falls back to local cache if remote fails', () async {
      final model = AttachmentModel.fromEntity(testAttachment);
      localDataSource.items[model.id] = model;
      remoteDataSource.shouldThrow = true;

      final results = await repository.getTaskAttachments('tsk-1');
      expect(results.length, equals(1));
      expect(results.first.id, equals('att-1'));
    });

    test('uploadAttachment uploads to remote and updates local cache', () async {
      final uploaded = await repository.uploadAttachment(testAttachment);

      expect(uploaded.id, isNotEmpty);
      expect(localDataSource.items.containsKey(uploaded.id), isTrue);
      expect(remoteDataSource.remoteItems.containsKey(uploaded.id), isTrue);
      expect(syncQueueRepository.queued, isEmpty);
    });

    test('uploadAttachment enqueues to sync queue when remote fails offline', () async {
      remoteDataSource.shouldThrow = true;

      final uploaded = await repository.uploadAttachment(testAttachment);

      expect(uploaded.id, isNotEmpty);
      expect(localDataSource.items.containsKey(uploaded.id), isTrue);
      expect(syncQueueRepository.queued.length, equals(1));
      expect(syncQueueRepository.queued.first.entityType, equals(SyncEntityType.attachment));
      expect(syncQueueRepository.queued.first.operation, equals(SyncOperation.create));
    });

    test('saveSignature generates signature attachment and saves', () async {
      final sigData = DigitalSignatureData(
        strokes: [
          const DigitalSignatureStroke(
            points: [DigitalSignaturePoint(1, 2), DigitalSignaturePoint(3, 4)],
          ),
        ],
        signerName: 'Jane Boss',
        signerRole: 'Inspector',
        signedAt: DateTime.now(),
      );

      final result = await repository.saveSignature(
        taskId: 'tsk-1',
        signature: sigData,
        userId: 'usr-1',
        userName: 'David Miller',
        orgId: 'org-1',
      );

      expect(result.isSignature, isTrue);
      expect(result.metadata.signerName, equals('Jane Boss'));
      expect(result.metadata.signerRole, equals('Inspector'));
      expect(result.rawData, isNotNull);
      expect(localDataSource.items.containsKey(result.id), isTrue);
    });

    test('deleteAttachment deletes from local and calls remote', () async {
      final model = AttachmentModel.fromEntity(testAttachment);
      localDataSource.items[model.id] = model;
      remoteDataSource.remoteItems[model.id] = model;

      await repository.deleteAttachment('att-1');

      expect(localDataSource.items.containsKey('att-1'), isFalse);
      expect(remoteDataSource.remoteItems.containsKey('att-1'), isFalse);
    });
  });
}
