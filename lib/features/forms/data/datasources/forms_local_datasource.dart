import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/custom_form_model.dart';
import '../models/form_submission_model.dart';

abstract class FormsLocalDataSource {
  Future<List<CustomFormModel>> getCachedForms();
  Future<void> cacheForms(List<CustomFormModel> forms);
  Future<CustomFormModel?> getCachedFormById(String id);
  Future<void> cacheForm(CustomFormModel form);
  Future<void> deleteCachedForm(String id);

  Future<List<FormSubmissionModel>> getCachedSubmissions({String? formId, String? taskId});
  Future<void> cacheSubmissions(List<FormSubmissionModel> submissions);
  Future<void> cacheSubmission(FormSubmissionModel submission);

  Future<Map<String, dynamic>?> getFormDraft(String formId);
  Future<void> saveFormDraft(String formId, Map<String, dynamic> draft);
  Future<void> clearFormDraft(String formId);

  Future<void> clearAll();
}

class FormsLocalDataSourceImpl implements FormsLocalDataSource {
  final SharedPreferences? sharedPreferences;

  static const String _formsKey = 'cached_custom_forms';
  static const String _submissionsKey = 'cached_form_submissions';
  static const String _draftPrefix = 'form_draft_';

  // In-memory cache for fast sync access
  final Map<String, CustomFormModel> _memoryForms = {};
  final Map<String, FormSubmissionModel> _memorySubmissions = {};
  final Map<String, Map<String, dynamic>> _memoryDrafts = {};

  FormsLocalDataSourceImpl({this.sharedPreferences});

  @override
  Future<List<CustomFormModel>> getCachedForms() async {
    if (_memoryForms.isNotEmpty) {
      return _memoryForms.values.toList();
    }
    final raw = sharedPreferences?.getString(_formsKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final models = list.map((e) => CustomFormModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      for (final m in models) {
        _memoryForms[m.id] = m;
      }
      return models;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> cacheForms(List<CustomFormModel> forms) async {
    _memoryForms.clear();
    for (final f in forms) {
      _memoryForms[f.id] = f;
    }
    final list = forms.map((f) => f.toJson()).toList();
    await sharedPreferences?.setString(_formsKey, jsonEncode(list));
  }

  @override
  Future<CustomFormModel?> getCachedFormById(String id) async {
    if (_memoryForms.containsKey(id)) {
      return _memoryForms[id];
    }
    final forms = await getCachedForms();
    try {
      return forms.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> cacheForm(CustomFormModel form) async {
    _memoryForms[form.id] = form;
    final all = await getCachedForms();
    final index = all.indexWhere((f) => f.id == form.id);
    if (index >= 0) {
      all[index] = form;
    } else {
      all.add(form);
    }
    await cacheForms(all);
  }

  @override
  Future<void> deleteCachedForm(String id) async {
    _memoryForms.remove(id);
    final all = await getCachedForms();
    all.removeWhere((f) => f.id == id);
    await cacheForms(all);
  }

  @override
  Future<List<FormSubmissionModel>> getCachedSubmissions({String? formId, String? taskId}) async {
    List<FormSubmissionModel> all;
    if (_memorySubmissions.isNotEmpty) {
      all = _memorySubmissions.values.toList();
    } else {
      final raw = sharedPreferences?.getString(_submissionsKey);
      if (raw == null || raw.isEmpty) {
        all = [];
      } else {
        try {
          final list = jsonDecode(raw) as List<dynamic>;
          all = list.map((e) => FormSubmissionModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
          for (final s in all) {
            _memorySubmissions[s.id] = s;
          }
        } catch (_) {
          all = [];
        }
      }
    }

    return all.where((s) {
      if (formId != null && s.formId != formId) return false;
      if (taskId != null && s.taskId != taskId) return false;
      return true;
    }).toList();
  }

  @override
  Future<void> cacheSubmissions(List<FormSubmissionModel> submissions) async {
    for (final s in submissions) {
      _memorySubmissions[s.id] = s;
    }
    final list = _memorySubmissions.values.map((s) => s.toJson()).toList();
    await sharedPreferences?.setString(_submissionsKey, jsonEncode(list));
  }

  @override
  Future<void> cacheSubmission(FormSubmissionModel submission) async {
    _memorySubmissions[submission.id] = submission;
    final list = _memorySubmissions.values.map((s) => s.toJson()).toList();
    await sharedPreferences?.setString(_submissionsKey, jsonEncode(list));
  }

  @override
  Future<Map<String, dynamic>?> getFormDraft(String formId) async {
    if (_memoryDrafts.containsKey(formId)) {
      return _memoryDrafts[formId];
    }
    final raw = sharedPreferences?.getString('$_draftPrefix$formId');
    if (raw == null) return null;
    try {
      final parsed = jsonDecode(raw) as Map<String, dynamic>;
      _memoryDrafts[formId] = parsed;
      return parsed;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveFormDraft(String formId, Map<String, dynamic> draft) async {
    _memoryDrafts[formId] = draft;
    await sharedPreferences?.setString('$_draftPrefix$formId', jsonEncode(draft));
  }

  @override
  Future<void> clearFormDraft(String formId) async {
    _memoryDrafts.remove(formId);
    await sharedPreferences?.remove('$_draftPrefix$formId');
  }

  @override
  Future<void> clearAll() async {
    _memoryForms.clear();
    _memorySubmissions.clear();
    _memoryDrafts.clear();
    await sharedPreferences?.remove(_formsKey);
    await sharedPreferences?.remove(_submissionsKey);
  }
}
