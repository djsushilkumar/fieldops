import 'package:uuid/uuid.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/location/location_coordinates.dart';
import '../../domain/entities/custom_form_entity.dart';
import '../../domain/entities/form_submission_entity.dart';
import '../../domain/repositories/forms_repository.dart';
import '../datasources/forms_local_datasource.dart';
import '../datasources/forms_remote_datasource.dart';
import '../models/custom_form_model.dart';
import '../models/form_submission_model.dart';

class FormsRepositoryImpl implements FormsRepository {
  final FormsRemoteDataSource remoteDataSource;
  final FormsLocalDataSource localDataSource;
  final String Function() getOrgId;
  final String Function() getUserId;
  final String Function()? getUserName;

  FormsRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.getOrgId,
    required this.getUserId,
    this.getUserName,
  });

  @override
  Future<List<CustomFormEntity>> getForms({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await localDataSource.getCachedForms();
      if (cached.isNotEmpty) {
        // Background refresh without blocking
        _refreshRemoteFormsSilently();
        return cached;
      }
    }

    try {
      final orgId = getOrgId();
      final remoteForms = await remoteDataSource.getForms(orgId);
      await localDataSource.cacheForms(remoteForms);
      return remoteForms;
    } catch (_) {
      final cached = await localDataSource.getCachedForms();
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  void _refreshRemoteFormsSilently() async {
    try {
      final orgId = getOrgId();
      final remoteForms = await remoteDataSource.getForms(orgId);
      await localDataSource.cacheForms(remoteForms);
    } catch (_) {}
  }

  @override
  Future<CustomFormEntity> getFormById(String id) async {
    try {
      final form = await remoteDataSource.getFormById(id);
      await localDataSource.cacheForm(form);
      return form;
    } catch (_) {
      final cached = await localDataSource.getCachedFormById(id);
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  Future<CustomFormEntity> createForm(CustomFormEntity form) async {
    final orgId = form.organizationId.isNotEmpty ? form.organizationId : getOrgId();
    final model = CustomFormModel.fromEntity(form.copyWith(organizationId: orgId));

    try {
      final created = await remoteDataSource.createForm(model);
      await localDataSource.cacheForm(created);
      return created;
    } catch (e) {
      // Offline fallback: generate client-side ID and store locally
      final fallbackId = model.id.isNotEmpty ? model.id : 'form-local-${const Uuid().v4().substring(0, 8)}';
      final localModel = CustomFormModel(
        id: fallbackId,
        organizationId: orgId,
        name: model.name,
        description: model.description,
        schema: model.schema,
        submissionsCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await localDataSource.cacheForm(localModel);
      return localModel;
    }
  }

  @override
  Future<CustomFormEntity> updateForm(CustomFormEntity form) async {
    final model = CustomFormModel.fromEntity(form);
    try {
      final updated = await remoteDataSource.updateForm(model);
      await localDataSource.cacheForm(updated);
      return updated;
    } catch (e) {
      await localDataSource.cacheForm(model);
      return model;
    }
  }

  @override
  Future<void> deleteForm(String id) async {
    try {
      await remoteDataSource.deleteForm(id);
    } catch (_) {}
    await localDataSource.deleteCachedForm(id);
  }

  @override
  Future<List<FormSubmissionEntity>> getSubmissions({String? formId, String? taskId}) async {
    try {
      final remoteSubmissions = await remoteDataSource.getSubmissions(formId: formId, taskId: taskId);
      await localDataSource.cacheSubmissions(remoteSubmissions);
      return remoteSubmissions;
    } catch (_) {
      final cached = await localDataSource.getCachedSubmissions(formId: formId, taskId: taskId);
      return cached;
    }
  }

  @override
  Future<FormSubmissionEntity> getSubmissionById(String id) async {
    try {
      final submission = await remoteDataSource.getSubmissionById(id);
      await localDataSource.cacheSubmission(submission);
      return submission;
    } catch (_) {
      final cached = await localDataSource.getCachedSubmissions();
      final match = cached.where((s) => s.id == id);
      if (match.isNotEmpty) return match.first;
      throw const NotFoundFailure('Form submission not found');
    }
  }

  @override
  Future<FormSubmissionEntity> submitForm({
    required String formId,
    String? taskId,
    required Map<String, dynamic> data,
    LocationCoordinates? location,
  }) async {
    final userId = getUserId();
    final userName = getUserName?.call();

    final submissionModel = FormSubmissionModel(
      id: '',
      formId: formId,
      taskId: taskId,
      userId: userId,
      userName: userName,
      latitude: location?.latitude,
      longitude: location?.longitude,
      data: data,
      submittedAt: DateTime.now(),
    );

    try {
      final result = await remoteDataSource.insertSubmission(submissionModel);
      await localDataSource.cacheSubmission(result);
      await localDataSource.clearFormDraft(formId);
      return result;
    } catch (e) {
      // Offline fallback: save locally
      final localId = 'sub-local-${const Uuid().v4().substring(0, 8)}';
      final localResult = FormSubmissionModel(
        id: localId,
        formId: formId,
        taskId: taskId,
        userId: userId,
        userName: userName ?? 'Current User',
        latitude: location?.latitude,
        longitude: location?.longitude,
        data: data,
        submittedAt: DateTime.now(),
      );
      await localDataSource.cacheSubmission(localResult);
      await localDataSource.clearFormDraft(formId);
      return localResult;
    }
  }
}
