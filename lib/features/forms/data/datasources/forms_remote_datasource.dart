import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/custom_form_model.dart';
import '../models/form_submission_model.dart';

abstract class FormsRemoteDataSource {
  Future<List<CustomFormModel>> getForms(String organizationId);
  Future<CustomFormModel> getFormById(String id);
  Future<CustomFormModel> createForm(CustomFormModel form);
  Future<CustomFormModel> updateForm(CustomFormModel form);
  Future<void> deleteForm(String id);

  Future<List<FormSubmissionModel>> getSubmissions({String? formId, String? taskId});
  Future<FormSubmissionModel> getSubmissionById(String id);
  Future<FormSubmissionModel> insertSubmission(FormSubmissionModel submission);
}

class SupabaseFormsRemoteDataSource implements FormsRemoteDataSource {
  final SupabaseClient _client;

  SupabaseFormsRemoteDataSource(this._client);

  @override
  Future<List<CustomFormModel>> getForms(String organizationId) async {
    try {
      final response = await _client
          .from('forms')
          .select('*, form_submissions(id)')
          .eq('organization_id', organizationId)
          .order('created_at', ascending: false);

      final list = response as List<dynamic>;
      return list.map((json) => CustomFormModel.fromJson(Map<String, dynamic>.from(json as Map))).toList();
    } catch (e) {
      throw ServerException('Failed to fetch forms: $e');
    }
  }

  @override
  Future<CustomFormModel> getFormById(String id) async {
    try {
      final response = await _client
          .from('forms')
          .select('*, form_submissions(id)')
          .eq('id', id)
          .single();

      return CustomFormModel.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      throw ServerException('Failed to fetch form: $e');
    }
  }

  @override
  Future<CustomFormModel> createForm(CustomFormModel form) async {
    try {
      final payload = {
        'organization_id': form.organizationId,
        'name': form.name,
        if (form.description != null) 'description': form.description,
        'schema': form.schema.toMap(),
      };

      final response = await _client
          .from('forms')
          .insert(payload)
          .select()
          .single();

      return CustomFormModel.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      throw ServerException('Failed to create form: $e');
    }
  }

  @override
  Future<CustomFormModel> updateForm(CustomFormModel form) async {
    try {
      final payload = {
        'name': form.name,
        if (form.description != null) 'description': form.description,
        'schema': form.schema.toMap(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from('forms')
          .update(payload)
          .eq('id', form.id)
          .select()
          .single();

      return CustomFormModel.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      throw ServerException('Failed to update form: $e');
    }
  }

  @override
  Future<void> deleteForm(String id) async {
    try {
      await _client.from('forms').delete().eq('id', id);
    } catch (e) {
      throw ServerException('Failed to delete form: $e');
    }
  }

  @override
  Future<List<FormSubmissionModel>> getSubmissions({String? formId, String? taskId}) async {
    try {
      var query = _client
          .from('form_submissions')
          .select('*, forms(name), tasks(title), users(name)');

      if (formId != null) {
        query = query.eq('form_id', formId);
      }
      if (taskId != null) {
        query = query.eq('task_id', taskId);
      }

      final response = await query.order('submitted_at', ascending: false);
      final list = response as List<dynamic>;
      return list.map((json) => FormSubmissionModel.fromJson(Map<String, dynamic>.from(json as Map))).toList();
    } catch (e) {
      throw ServerException('Failed to fetch submissions: $e');
    }
  }

  @override
  Future<FormSubmissionModel> getSubmissionById(String id) async {
    try {
      final response = await _client
          .from('form_submissions')
          .select('*, forms(name), tasks(title), users(name)')
          .eq('id', id)
          .single();

      return FormSubmissionModel.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      throw ServerException('Failed to fetch submission: $e');
    }
  }

  @override
  Future<FormSubmissionModel> insertSubmission(FormSubmissionModel submission) async {
    try {
      final payload = {
        'form_id': submission.formId,
        if (submission.taskId != null) 'task_id': submission.taskId,
        'user_id': submission.userId,
        if (submission.latitude != null) 'latitude': submission.latitude,
        if (submission.longitude != null) 'longitude': submission.longitude,
        'data': submission.data,
      };

      final response = await _client
          .from('form_submissions')
          .insert(payload)
          .select('*, forms(name), tasks(title), users(name)')
          .single();

      return FormSubmissionModel.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      throw ServerException('Failed to insert form submission: $e');
    }
  }
}
