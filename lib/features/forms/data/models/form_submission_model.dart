import 'dart:convert';
import '../../domain/entities/form_submission_entity.dart';

class FormSubmissionModel extends FormSubmissionEntity {
  const FormSubmissionModel({
    required super.id,
    required super.formId,
    super.formName,
    super.taskId,
    super.taskTitle,
    required super.userId,
    super.userName,
    super.latitude,
    super.longitude,
    required super.data,
    required super.submittedAt,
  });

  factory FormSubmissionModel.fromJson(Map<String, dynamic> json) {
    dynamic rawData = json['data'];
    if (rawData is String) {
      try {
        rawData = jsonDecode(rawData);
      } catch (_) {
        rawData = <String, dynamic>{};
      }
    }

    final dataMap = rawData is Map<String, dynamic>
        ? rawData
        : rawData is Map
            ? Map<String, dynamic>.from(rawData)
            : <String, dynamic>{};

    String? formName = json['form_name']?.toString();
    if (formName == null && json['forms'] is Map) {
      formName = (json['forms'] as Map)['name']?.toString();
    }

    String? taskTitle = json['task_title']?.toString();
    if (taskTitle == null && json['tasks'] is Map) {
      taskTitle = (json['tasks'] as Map)['title']?.toString();
    }

    String? userName = json['user_name']?.toString();
    if (userName == null && json['users'] is Map) {
      userName = (json['users'] as Map)['name']?.toString();
    }

    return FormSubmissionModel(
      id: json['id']?.toString() ?? '',
      formId: json['form_id']?.toString() ?? '',
      formName: formName,
      taskId: json['task_id']?.toString(),
      taskTitle: taskTitle,
      userId: json['user_id']?.toString() ?? '',
      userName: userName,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      data: dataMap,
      submittedAt: json['submitted_at'] != null
          ? DateTime.tryParse(json['submitted_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'form_id': formId,
      if (taskId != null) 'task_id': taskId,
      'user_id': userId,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'data': data,
      'submitted_at': submittedAt.toIso8601String(),
    };
  }

  factory FormSubmissionModel.fromEntity(FormSubmissionEntity entity) {
    return FormSubmissionModel(
      id: entity.id,
      formId: entity.formId,
      formName: entity.formName,
      taskId: entity.taskId,
      taskTitle: entity.taskTitle,
      userId: entity.userId,
      userName: entity.userName,
      latitude: entity.latitude,
      longitude: entity.longitude,
      data: entity.data,
      submittedAt: entity.submittedAt,
    );
  }
}
