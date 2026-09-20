import 'attachment_metadata.dart';
import 'attachment_type.dart';

class AttachmentEntity {
  final String id;
  final String organizationId;
  final String? taskId;
  final String? visitId;
  final String uploadedBy;
  final String? uploadedByName;
  final AttachmentType type;
  final String storagePath;
  final String fileName;
  final int fileSize;
  final String mimeType;
  final AttachmentMetadata metadata;
  final DateTime createdAt;
  final String? rawData; // Optional base64 or inline data for local preview

  const AttachmentEntity({
    required this.id,
    required this.organizationId,
    this.taskId,
    this.visitId,
    required this.uploadedBy,
    this.uploadedByName,
    required this.type,
    required this.storagePath,
    required this.fileName,
    this.fileSize = 0,
    this.mimeType = 'image/jpeg',
    this.metadata = const AttachmentMetadata(),
    required this.createdAt,
    this.rawData,
  });

  bool get isPhoto => type == AttachmentType.photo;
  bool get isSignature => type == AttachmentType.signature;
  bool get isDocument => type == AttachmentType.document;

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  AttachmentEntity copyWith({
    String? id,
    String? organizationId,
    String? taskId,
    String? visitId,
    String? uploadedBy,
    String? uploadedByName,
    AttachmentType? type,
    String? storagePath,
    String? fileName,
    int? fileSize,
    String? mimeType,
    AttachmentMetadata? metadata,
    DateTime? createdAt,
    String? rawData,
  }) {
    return AttachmentEntity(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      taskId: taskId ?? this.taskId,
      visitId: visitId ?? this.visitId,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      uploadedByName: uploadedByName ?? this.uploadedByName,
      type: type ?? this.type,
      storagePath: storagePath ?? this.storagePath,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      rawData: rawData ?? this.rawData,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttachmentEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'AttachmentEntity(id: $id, type: ${type.code}, file: $fileName, task: $taskId)';
}
