import 'form_field_type.dart';

class FormFieldDefinition {
  final String id;
  final String label;
  final FormFieldType type;
  final bool required;
  final String? placeholder;
  final List<String> options;
  final dynamic defaultValue;
  final String? helpText;

  const FormFieldDefinition({
    required this.id,
    required this.label,
    required this.type,
    this.required = false,
    this.placeholder,
    this.options = const [],
    this.defaultValue,
    this.helpText,
  });

  FormFieldDefinition copyWith({
    String? id,
    String? label,
    FormFieldType? type,
    bool? required,
    String? placeholder,
    List<String>? options,
    dynamic defaultValue,
    String? helpText,
  }) {
    return FormFieldDefinition(
      id: id ?? this.id,
      label: label ?? this.label,
      type: type ?? this.type,
      required: required ?? this.required,
      placeholder: placeholder ?? this.placeholder,
      options: options ?? this.options,
      defaultValue: defaultValue ?? this.defaultValue,
      helpText: helpText ?? this.helpText,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'type': type.name,
      'required': required,
      if (placeholder != null) 'placeholder': placeholder,
      if (options.isNotEmpty) 'options': options,
      if (defaultValue != null) 'defaultValue': defaultValue,
      if (helpText != null) 'helpText': helpText,
    };
  }

  factory FormFieldDefinition.fromMap(Map<String, dynamic> map) {
    return FormFieldDefinition(
      id: map['id']?.toString() ?? '',
      label: map['label']?.toString() ?? '',
      type: FormFieldType.fromString(map['type']?.toString() ?? 'text'),
      required: map['required'] == true,
      placeholder: map['placeholder']?.toString(),
      options: (map['options'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      defaultValue: map['defaultValue'],
      helpText: map['helpText']?.toString(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FormFieldDefinition &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          label == other.label &&
          type == other.type &&
          required == other.required;

  @override
  int get hashCode => id.hashCode ^ label.hashCode ^ type.hashCode ^ required.hashCode;
}
