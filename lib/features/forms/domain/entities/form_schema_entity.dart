import 'form_field_definition.dart';
import 'form_field_type.dart';

class FormSchemaEntity {
  final int version;
  final List<FormFieldDefinition> fields;

  const FormSchemaEntity({
    this.version = 1,
    required this.fields,
  });

  Map<String, String> validate(Map<String, dynamic> data) {
    final errors = <String, String>{};

    for (final field in fields) {
      final value = data[field.id];

      // Check required
      if (field.required) {
        if (value == null) {
          errors[field.id] = '${field.label} is required';
          continue;
        }
        if (field.type == FormFieldType.text || field.type == FormFieldType.multiline) {
          if (value.toString().trim().isEmpty) {
            errors[field.id] = '${field.label} is required';
            continue;
          }
        }
        if (field.type == FormFieldType.checkbox) {
          if (value != true) {
            errors[field.id] = '${field.label} must be checked';
            continue;
          }
        }
        if (field.type == FormFieldType.select) {
          if (value.toString().trim().isEmpty) {
            errors[field.id] = 'Please select an option for ${field.label}';
            continue;
          }
        }
        if (field.type == FormFieldType.date) {
          if (value.toString().trim().isEmpty) {
            errors[field.id] = 'Please select a date for ${field.label}';
            continue;
          }
        }
      }

      // Check type specific validation if present
      if (value != null && value.toString().trim().isNotEmpty) {
        if (field.type == FormFieldType.number) {
          final parsed = num.tryParse(value.toString().trim());
          if (parsed == null) {
            errors[field.id] = '${field.label} must be a valid number';
          }
        } else if (field.type == FormFieldType.select && field.options.isNotEmpty) {
          if (!field.options.contains(value.toString())) {
            errors[field.id] = '${value.toString()} is not a valid option';
          }
        }
      }
    }

    return errors;
  }

  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'fields': fields.map((f) => f.toMap()).toList(),
    };
  }

  factory FormSchemaEntity.fromMap(Map<String, dynamic> map) {
    final rawFields = map['fields'] as List<dynamic>? ?? [];
    return FormSchemaEntity(
      version: map['version'] as int? ?? 1,
      fields: rawFields
          .map((f) => FormFieldDefinition.fromMap(Map<String, dynamic>.from(f as Map)))
          .toList(),
    );
  }

  FormSchemaEntity copyWith({
    int? version,
    List<FormFieldDefinition>? fields,
  }) {
    return FormSchemaEntity(
      version: version ?? this.version,
      fields: fields ?? this.fields,
    );
  }
}
