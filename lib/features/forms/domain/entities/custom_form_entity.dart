import 'form_schema_entity.dart';

class CustomFormEntity {
  final String id;
  final String organizationId;
  final String name;
  final String? description;
  final FormSchemaEntity schema;
  final int submissionsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomFormEntity({
    required this.id,
    required this.organizationId,
    required this.name,
    this.description,
    required this.schema,
    this.submissionsCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  int get fieldCount => schema.fields.length;

  CustomFormEntity copyWith({
    String? id,
    String? organizationId,
    String? name,
    String? description,
    FormSchemaEntity? schema,
    int? submissionsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomFormEntity(
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
