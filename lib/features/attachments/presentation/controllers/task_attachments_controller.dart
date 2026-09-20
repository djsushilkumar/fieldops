import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/location/location_coordinates.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../sync/presentation/controllers/sync_controller.dart';
import '../../../tasks/domain/entities/task_entity.dart';
import '../../data/datasources/attachment_local_datasource.dart';
import '../../data/datasources/attachment_remote_datasource.dart';
import '../../data/repositories/attachment_repository_impl.dart';
import '../../domain/entities/attachment_entity.dart';
import '../../domain/entities/attachment_metadata.dart';
import '../../domain/entities/attachment_type.dart';
import '../../domain/entities/digital_signature_data.dart';
import '../../domain/entities/task_proof_status.dart';
import '../../domain/repositories/attachment_repository.dart';
import '../../domain/usecases/delete_attachment_use_case.dart';
import '../../domain/usecases/get_task_attachments_use_case.dart';
import '../../domain/usecases/save_signature_use_case.dart';
import '../../domain/usecases/upload_attachment_use_case.dart';

// ============================================================================
// Providers
// ============================================================================

final attachmentLocalDataSourceProvider = Provider<AttachmentLocalDataSource>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return AttachmentLocalDataSourceImpl(database: db);
});

final attachmentRemoteDataSourceProvider = Provider<AttachmentRemoteDataSource>((ref) {
  final supabase = SupabaseConfig.client;
  if (supabase != null) {
    return SupabaseAttachmentRemoteDataSource(supabase);
  }
  return MockAttachmentRemoteDataSource();
});

final attachmentRepositoryProvider = Provider<AttachmentRepository>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final syncRepo = ref.watch(syncQueueRepositoryProvider);
  return AttachmentRepositoryImpl(
    remoteDataSource: ref.watch(attachmentRemoteDataSourceProvider),
    localDataSource: ref.watch(attachmentLocalDataSourceProvider),
    syncQueueRepository: syncRepo,
    getOrgId: () => authState.user?.organizationId ?? 'org-acme-ops-001',
    getUserId: () => authState.user?.id ?? 'usr-emp-003',
    getUserName: () => authState.user?.name ?? 'David Miller (Technician)',
  );
});

final getTaskAttachmentsUseCaseProvider = Provider<GetTaskAttachmentsUseCase>((ref) {
  return GetTaskAttachmentsUseCase(ref.watch(attachmentRepositoryProvider));
});

final uploadAttachmentUseCaseProvider = Provider<UploadAttachmentUseCase>((ref) {
  return UploadAttachmentUseCase(ref.watch(attachmentRepositoryProvider));
});

final saveSignatureUseCaseProvider = Provider<SaveSignatureUseCase>((ref) {
  return SaveSignatureUseCase(ref.watch(attachmentRepositoryProvider));
});

final deleteAttachmentUseCaseProvider = Provider<DeleteAttachmentUseCase>((ref) {
  return DeleteAttachmentUseCase(ref.watch(attachmentRepositoryProvider));
});

// ============================================================================
// State
// ============================================================================

class TaskAttachmentsState {
  final bool isLoading;
  final bool isUploading;
  final List<AttachmentEntity> attachments;
  final String? errorMessage;
  final String? successMessage;

  const TaskAttachmentsState({
    this.isLoading = false,
    this.isUploading = false,
    this.attachments = const [],
    this.errorMessage,
    this.successMessage,
  });

  List<AttachmentEntity> get photos =>
      attachments.where((a) => a.isPhoto).toList();

  List<AttachmentEntity> get signatures =>
      attachments.where((a) => a.isSignature).toList();

  AttachmentEntity? get latestSignature =>
      signatures.isNotEmpty ? signatures.first : null;

  int get photoCount => photos.length;

  bool get hasSignature => signatures.isNotEmpty;

  TaskProofStatus evaluateProof(
    TaskEntity task, {
    bool hasActiveOrCompletedVisit = false,
    bool hasSubmittedForm = false,
  }) {
    return TaskProofStatus.evaluate(
      task: task,
      attachments: attachments,
      hasActiveOrCompletedVisit: hasActiveOrCompletedVisit,
      hasSubmittedForm: hasSubmittedForm,
    );
  }

  TaskAttachmentsState copyWith({
    bool? isLoading,
    bool? isUploading,
    List<AttachmentEntity>? attachments,
    String? errorMessage,
    String? successMessage,
  }) {
    return TaskAttachmentsState(
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      attachments: attachments ?? this.attachments,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

// ============================================================================
// Notifier
// ============================================================================

class TaskAttachmentsNotifier extends StateNotifier<TaskAttachmentsState> {
  final String taskId;
  final GetTaskAttachmentsUseCase _getAttachmentsUseCase;
  final UploadAttachmentUseCase _uploadAttachmentUseCase;
  final SaveSignatureUseCase _saveSignatureUseCase;
  final DeleteAttachmentUseCase _deleteAttachmentUseCase;
  final Ref _ref;

  TaskAttachmentsNotifier({
    required this.taskId,
    required GetTaskAttachmentsUseCase getAttachmentsUseCase,
    required UploadAttachmentUseCase uploadAttachmentUseCase,
    required SaveSignatureUseCase saveSignatureUseCase,
    required DeleteAttachmentUseCase deleteAttachmentUseCase,
    required Ref ref,
  })  : _getAttachmentsUseCase = getAttachmentsUseCase,
        _uploadAttachmentUseCase = uploadAttachmentUseCase,
        _saveSignatureUseCase = saveSignatureUseCase,
        _deleteAttachmentUseCase = deleteAttachmentUseCase,
        _ref = ref,
        super(const TaskAttachmentsState()) {
    loadAttachments();
  }

  Future<void> loadAttachments() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final items = await _getAttachmentsUseCase.execute(taskId);
      state = state.copyWith(isLoading: false, attachments: items);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> uploadPhotoProof({
    required String category, // 'before', 'after', 'site', 'hazard', 'general'
    required String fileName,
    String? notes,
    LocationCoordinates? location,
    String? imageBase64,
    int fileSize = 150000,
  }) async {
    state = state.copyWith(isUploading: true, errorMessage: null);
    try {
      final authState = _ref.read(authNotifierProvider);
      final orgId = authState.user?.organizationId ?? 'org-acme-ops-001';
      final userId = authState.user?.id ?? 'usr-emp-003';
      final userName = authState.user?.name ?? 'David Miller (Technician)';

      final now = DateTime.now();
      final metadata = AttachmentMetadata(
        latitude: location?.latitude,
        longitude: location?.longitude,
        accuracy: location?.accuracy,
        capturedAt: location?.timestamp ?? now,
        category: category,
        notes: notes,
        isWatermarked: true,
      );

      final attachment = AttachmentEntity(
        id: '',
        organizationId: orgId,
        taskId: taskId,
        uploadedBy: userId,
        uploadedByName: userName,
        type: AttachmentType.photo,
        storagePath: 'tasks/$taskId/photos/$fileName',
        fileName: fileName,
        fileSize: fileSize,
        mimeType: 'image/jpeg',
        metadata: metadata,
        createdAt: now,
        rawData: imageBase64,
      );

      final uploaded = await _uploadAttachmentUseCase.execute(attachment);
      final updatedList = [uploaded, ...state.attachments];
      state = state.copyWith(
        isUploading: false,
        attachments: updatedList,
        successMessage: 'Photo proof uploaded successfully',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        errorMessage: 'Failed to upload photo: $e',
      );
      return false;
    }
  }

  Future<bool> saveDigitalSignature({
    required DigitalSignatureData signature,
    String? visitId,
  }) async {
    state = state.copyWith(isUploading: true, errorMessage: null);
    try {
      final authState = _ref.read(authNotifierProvider);
      final orgId = authState.user?.organizationId ?? 'org-acme-ops-001';
      final userId = authState.user?.id ?? 'usr-emp-003';
      final userName = authState.user?.name ?? 'David Miller (Technician)';

      final saved = await _saveSignatureUseCase.execute(
        taskId: taskId,
        signature: signature,
        visitId: visitId,
        userId: userId,
        userName: userName,
        orgId: orgId,
      );

      // Remove previous signature if any, replace with latest
      final filtered = state.attachments.where((a) => !a.isSignature).toList();
      final updatedList = [saved, ...filtered];

      state = state.copyWith(
        isUploading: false,
        attachments: updatedList,
        successMessage: 'Digital signature captured successfully',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        errorMessage: 'Failed to save signature: $e',
      );
      return false;
    }
  }

  Future<bool> deleteAttachment(String attachmentId) async {
    try {
      await _deleteAttachmentUseCase.execute(attachmentId);
      final filtered = state.attachments.where((a) => a.id != attachmentId).toList();
      state = state.copyWith(
        attachments: filtered,
        successMessage: 'Attachment removed',
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete: $e');
      return false;
    }
  }
}

final taskAttachmentsNotifierProvider = StateNotifierProvider.family<
    TaskAttachmentsNotifier, TaskAttachmentsState, String>((ref, taskId) {
  return TaskAttachmentsNotifier(
    taskId: taskId,
    getAttachmentsUseCase: ref.watch(getTaskAttachmentsUseCaseProvider),
    uploadAttachmentUseCase: ref.watch(uploadAttachmentUseCaseProvider),
    saveSignatureUseCase: ref.watch(saveSignatureUseCaseProvider),
    deleteAttachmentUseCase: ref.watch(deleteAttachmentUseCaseProvider),
    ref: ref,
  );
});
