import 'dart:convert';
import '../../domain/entities/attachment_entity.dart';
import '../../domain/entities/attachment_metadata.dart';
import '../../domain/entities/attachment_type.dart';

class AttachmentModel {
  final String id;
  final String organizationId;
  final String? taskId;
  final String? visitId;
  final String uploadedBy;
  final String? uploadedByName;
  final String type;
  final String storagePath;
  final String fileName;
  final int fileSize;
  final String mimeType;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final String? rawData;

  const AttachmentModel({
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
    this.metadata = const {},
    required this.createdAt,
    this.rawData,
  });

  AttachmentEntity toEntity() {
    return AttachmentEntity(
      id: id,
      organizationId: organizationId,
      taskId: taskId,
      visitId: visitId,
      uploadedBy: uploadedBy,
      uploadedByName: uploadedByName,
      type: AttachmentType.fromString(type),
      storagePath: storagePath,
      fileName: fileName,
      fileSize: fileSize,
      mimeType: mimeType,
      metadata: AttachmentMetadata.fromMap(metadata),
      createdAt: createdAt,
      rawData: rawData ?? (metadata['raw_data'] as String?),
    );
  }

  factory AttachmentModel.fromEntity(AttachmentEntity entity) {
    final meta = entity.metadata.toMap();
    if (entity.rawData != null) {
      meta['raw_data'] = entity.rawData;
    }
    return AttachmentModel(
      id: entity.id,
      organizationId: entity.organizationId,
      taskId: entity.taskId,
      visitId: entity.visitId,
      uploadedBy: entity.uploadedBy,
      uploadedByName: entity.uploadedByName,
      type: entity.type.code,
      storagePath: entity.storagePath,
      fileName: entity.fileName,
      fileSize: entity.fileSize,
      mimeType: entity.mimeType,
      metadata: meta,
      createdAt: entity.createdAt,
      rawData: entity.rawData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'task_id': taskId,
      'visit_id': visitId,
      'uploaded_by': uploadedBy,
      if (uploadedByName != null) 'uploaded_by_name': uploadedByName,
      'type': type,
      'storage_path': storagePath,
      'file_name': fileName,
      'file_size': fileSize,
      'mime_type': mimeType,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      if (rawData != null) 'raw_data': rawData,
    };
  }

  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> parsedMetadata = {};
    if (json['metadata'] != null) {
      if (json['metadata'] is Map<String, dynamic>) {
        parsedMetadata = Map<String, dynamic>.from(json['metadata'] as Map);
      } else if (json['metadata'] is String) {
        try {
          parsedMetadata = jsonDecode(json['metadata'] as String) as Map<String, dynamic>;
        } catch (_) {
          parsedMetadata = {};
        }
      }
    }

    String? rawData = json['raw_data'] as String?;
    if (rawData == null && parsedMetadata.containsKey('raw_data')) {
      rawData = parsedMetadata['raw_data'] as String?;
    }

    return AttachmentModel(
      id: json['id'] as String? ?? '',
      organizationId: json['organization_id'] as String? ?? '',
      taskId: json['task_id'] as String?,
      visitId: json['visit_id'] as String?,
      uploadedBy: json['uploaded_by'] as String? ?? '',
      uploadedByName: json['uploaded_by_name'] as String?,
      type: json['type'] as String? ?? 'PHOTO',
      storagePath: json['storage_path'] as String? ?? '',
      fileName: json['file_name'] as String? ?? 'attachment_${DateTime.now().millisecondsSinceEpoch}',
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
      mimeType: json['mime_type'] as String? ?? 'image/jpeg',
      metadata: parsedMetadata,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      rawData: rawData,
    );
  }

  Map<String, dynamic> toSqlMap() {
    final meta = Map<String, dynamic>.from(metadata);
    if (rawData != null) {
      meta['raw_data'] = rawData;
    }
    return {
      'id': id,
      'organization_id': organizationId,
      'task_id': taskId,
      'visit_id': visitId,
      'uploaded_by': uploadedBy,
      'uploaded_by_name': uploadedByName,
      'type': type,
      'storage_path': storagePath,
      'file_name': fileName,
      'file_size': fileSize,
      'mime_type': mimeType,
      'metadata': jsonEncode(meta),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AttachmentModel.fromSqlMap(Map<String, dynamic> map) {
    Map<String, dynamic> meta = {};
    if (map['metadata'] != null) {
      if (map['metadata'] is String) {
        try {
          meta = jsonDecode(map['metadata'] as String) as Map<String, dynamic>;
        } catch (_) {}
      } else if (map['metadata'] is Map<String, dynamic>) {
        meta = Map<String, dynamic>.from(map['metadata'] as Map);
      }
    }

    return AttachmentModel(
      id: map['id'] as String,
      organizationId: map['organization_id'] as String,
      taskId: map['task_id'] as String?,
      visitId: map['visit_id'] as String?,
      uploadedBy: map['uploaded_by'] as String,
      uploadedByName: map['uploaded_by_name'] as String?,
      type: map['type'] as String,
      storagePath: map['storage_path'] as String,
      fileName: map['file_name'] as String? ?? 'attachment',
      fileSize: (map['file_size'] as num?)?.toInt() ?? 0,
      mimeType: map['mime_type'] as String? ?? 'image/jpeg',
      metadata: meta,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      rawData: meta['raw_data'] as String?,
    );
  }

  AttachmentModel copyWith({
    String? id,
    String? organizationId,
    String? taskId,
    String? visitId,
    String? uploadedBy,
    String? uploadedByName,
    String? type,
    String? storagePath,
    String? fileName,
    int? fileSize,
    String? mimeType,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    String? rawData,
  }) {
    return AttachmentModel(
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
}
