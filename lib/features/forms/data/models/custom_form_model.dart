import 'dart:convert';
import '../../domain/entities/custom_form_entity.dart';
import '../../domain/entities/form_schema_entity.dart';

class CustomFormModel extends CustomFormEntity {
  const CustomFormModel({
    required super.id,
    required super.organizationId,
    required super.name,
    super.description,
    required super.schema,
    super.submissionsCount = 0,
    required super.createdAt,
    required super.updatedAt,
  });

  factory CustomFormModel.fromJson(Map<String, dynamic> json) {
    dynamic rawSchema = json['schema'];
    if (rawSchema is String) {
      try {
        rawSchema = jsonDecode(rawSchema);
      } catch (_) {
        rawSchema = <String, dynamic>{};
      }
    }

    final schemaMap = rawSchema is Map<String, dynamic>
        ? rawSchema
        : rawSchema is Map
            ? Map<String, dynamic>.from(rawSchema)
            : <String, dynamic>{};

    int subCount = 0;
    if (json['submissions_count'] != null) {
      subCount = (json['submissions_count'] as num).toInt();
    } else if (json['form_submissions'] is List) {
      subCount = (json['form_submissions'] as List).length;
    }

    return CustomFormModel(
      id: json['id']?.toString() ?? '',
      organizationId: json['organization_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      schema: FormSchemaEntity.fromMap(schemaMap),
      submissionsCount: subCount,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'name': name,
      if (description != null) 'description': description,
      'schema': schema.toMap(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory CustomFormModel.fromEntity(CustomFormEntity entity) {
    return CustomFormModel(
      id: entity.id,
      organizationId: entity.organizationId,
      name: entity.name,
      description: entity.description,
      schema: entity.schema,
      submissionsCount: entity.submissionsCount,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  @override
  CustomFormModel copyWith({
    String? id,
    String? organizationId,
    String? name,
    String? description,
    FormSchemaEntity? schema,
    int? submissionsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomFormModel(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      name: name ?? this.name,
      description: description ?? this.description,
      schema: schema ?? this.schema,
      submissionsCount: submissionsCount ?? this.submissionsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

