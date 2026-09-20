import 'package:intl/intl.dart';

class FormSubmissionEntity {
  final String id;
  final String formId;
  final String? formName;
  final String? taskId;
  final String? taskTitle;
  final String userId;
  final String? userName;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic> data;
  final DateTime submittedAt;

  const FormSubmissionEntity({
    required this.id,
    required this.formId,
    this.formName,
    this.taskId,
    this.taskTitle,
    required this.userId,
    this.userName,
    this.latitude,
    this.longitude,
    required this.data,
    required this.submittedAt,
  });

  bool get hasGps => latitude != null && longitude != null;

  String get formattedSubmittedAt => DateFormat('MMM d, yyyy • h:mm a').format(submittedAt);

  FormSubmissionEntity copyWith({
    String? id,
    String? formId,
    String? formName,
    String? taskId,
    String? taskTitle,
    String? userId,
    String? userName,
    double? latitude,
    double? longitude,
    Map<String, dynamic>? data,
    DateTime? submittedAt,
  }) {
    return FormSubmissionEntity(
      id: id ?? this.id,
      formId: formId ?? this.formId,
      formName: formName ?? this.formName,
      taskId: taskId ?? this.taskId,
      taskTitle: taskTitle ?? this.taskTitle,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      data: data ?? this.data,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }
}
