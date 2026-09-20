import 'package:flutter/material.dart';

enum FormFieldType {
  text,
  multiline,
  number,
  date,
  select,
  checkbox;

  String get label {
    switch (this) {
      case FormFieldType.text:
        return 'Short Text';
      case FormFieldType.multiline:
        return 'Paragraph / Long Text';
      case FormFieldType.number:
        return 'Number';
      case FormFieldType.date:
        return 'Date Picker';
      case FormFieldType.select:
        return 'Dropdown Selection';
      case FormFieldType.checkbox:
        return 'Checkbox (Yes / No)';
    }
  }

  IconData get icon {
    switch (this) {
      case FormFieldType.text:
        return Icons.short_text_rounded;
      case FormFieldType.multiline:
        return Icons.notes_rounded;
      case FormFieldType.number:
        return Icons.pin_rounded;
      case FormFieldType.date:
        return Icons.calendar_today_rounded;
      case FormFieldType.select:
        return Icons.arrow_drop_down_circle_outlined;
      case FormFieldType.checkbox:
        return Icons.check_box_outlined;
    }
  }

  static FormFieldType fromString(String val) {
    final normalized = val.trim().toLowerCase();
    switch (normalized) {
      case 'multiline':
      case 'textarea':
      case 'paragraph':
        return FormFieldType.multiline;
      case 'number':
      case 'numeric':
      case 'integer':
        return FormFieldType.number;
      case 'date':
      case 'datetime':
        return FormFieldType.date;
      case 'select':
      case 'dropdown':
      case 'choice':
        return FormFieldType.select;
      case 'checkbox':
      case 'bool':
      case 'boolean':
        return FormFieldType.checkbox;
      case 'text':
      default:
        return FormFieldType.text;
    }
  }
}
