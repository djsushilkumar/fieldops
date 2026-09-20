import 'notification_type.dart';

class NotificationEntity {
  final String id;
  final String organizationId;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime? readAt;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.organizationId,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.readAt,
    this.data = const {},
    required this.createdAt,
  });

  bool get isRead => readAt != null;
  bool get isUnread => readAt == null;
  String? get taskId => data['task_id'] as String?;
  String? get visitId => data['visit_id'] as String?;

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${createdAt.month}/${createdAt.day}/${createdAt.year}';
  }

  NotificationEntity copyWith({
    String? id,
    String? organizationId,
    String? userId,
    NotificationType? type,
    String? title,
    String? body,
    DateTime? readAt,
    Map<String, dynamic>? data,
    DateTime? createdAt,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      readAt: readAt ?? this.readAt,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
