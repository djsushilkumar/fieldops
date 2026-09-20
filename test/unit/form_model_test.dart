import 'package:flutter_test/flutter_test.dart';
import 'package:field_ops/features/forms/data/models/custom_form_model.dart';
import 'package:field_ops/features/forms/data/models/form_submission_model.dart';
import 'package:field_ops/features/forms/domain/entities/form_field_definition.dart';
import 'package:field_ops/features/forms/domain/entities/form_field_type.dart';
import 'package:field_ops/features/forms/domain/entities/form_schema_entity.dart';

void main() {
  group('CustomFormModel & Schema Unit Tests', () {
    test('FormFieldType fromString maps all types accurately', () {
      expect(FormFieldType.fromString('text'), FormFieldType.text);
      expect(FormFieldType.fromString('multiline'), FormFieldType.multiline);
      expect(FormFieldType.fromString('textarea'), FormFieldType.multiline);
      expect(FormFieldType.fromString('number'), FormFieldType.number);
      expect(FormFieldType.fromString('numeric'), FormFieldType.number);
      expect(FormFieldType.fromString('date'), FormFieldType.date);
      expect(FormFieldType.fromString('select'), FormFieldType.select);
      expect(FormFieldType.fromString('dropdown'), FormFieldType.select);
      expect(FormFieldType.fromString('checkbox'), FormFieldType.checkbox);
      expect(FormFieldType.fromString('bool'), FormFieldType.checkbox);
    });

    test('CustomFormModel serializes to and from JSON correctly', () {
      final json = {
        'id': 'form-test-001',
        'organization_id': 'org-001',
        'name': 'Air Conditioning Audit',
        'description': 'Comprehensive chiller check',
        'schema': {
          'version': 1,
          'fields': [
            {
              'id': 'serial_no',
              'label': 'Serial Number',
              'type': 'text',
              'required': true,
              'placeholder': 'e.g. SN-1234',
            },
            {
              'id': 'temp_c',
              'label': 'Exhaust Temp (C)',
              'type': 'number',
              'required': false,
            },
            {
              'id': 'status',
              'label': 'Unit Status',
              'type': 'select',
              'required': true,
              'options': ['Good', 'Needs Service', 'Failed'],
            },
            {
              'id': 'filter_changed',
              'label': 'Filter Replaced',
              'type': 'checkbox',
              'required': true,
            },
          ],
        },
        'submissions_count': 3,
        'created_at': '2026-09-20T10:00:00.000Z',
        'updated_at': '2026-09-20T11:00:00.000Z',
      };

      final model = CustomFormModel.fromJson(json);

      expect(model.id, 'form-test-001');
      expect(model.organizationId, 'org-001');
      expect(model.name, 'Air Conditioning Audit');
      expect(model.fieldCount, 4);
      expect(model.submissionsCount, 3);
      expect(model.schema.fields[0].type, FormFieldType.text);
      expect(model.schema.fields[1].type, FormFieldType.number);
      expect(model.schema.fields[2].type, FormFieldType.select);
      expect(model.schema.fields[2].options, ['Good', 'Needs Service', 'Failed']);
      expect(model.schema.fields[3].type, FormFieldType.checkbox);

      final exported = model.toJson();
      expect(exported['id'], 'form-test-001');
      expect(exported['name'], 'Air Conditioning Audit');
      expect((exported['schema'] as Map)['fields'].length, 4);
    });

    test('FormSchemaEntity validation catches missing required fields and invalid types', () {
      const schema = FormSchemaEntity(
        version: 1,
        fields: [
          FormFieldDefinition(
            id: 'serial_no',
            label: 'Serial Number',
            type: FormFieldType.text,
            required: true,
          ),
          FormFieldDefinition(
            id: 'operating_psi',
            label: 'Pressure PSI',
            type: FormFieldType.number,
            required: true,
          ),
          FormFieldDefinition(
            id: 'result',
            label: 'Inspection Result',
            type: FormFieldType.select,
            required: true,
            options: ['Pass', 'Fail'],
          ),
          FormFieldDefinition(
            id: 'agreed',
            label: 'Customer Acceptance',
            type: FormFieldType.checkbox,
            required: true,
          ),
        ],
      );

      // 1. Missing all required fields
      final errors1 = schema.validate({});
      expect(errors1.containsKey('serial_no'), isTrue);
      expect(errors1.containsKey('operating_psi'), isTrue);
      expect(errors1.containsKey('result'), isTrue);
      expect(errors1.containsKey('agreed'), isTrue);

      // 2. Invalid number format
      final errors2 = schema.validate({
        'serial_no': 'SN-909',
        'operating_psi': 'not-a-number',
        'result': 'Pass',
        'agreed': true,
      });
      expect(errors2.containsKey('operating_psi'), isTrue);
      expect(errors2['operating_psi'], contains('must be a valid number'));

      // 3. Invalid select option
      final errors3 = schema.validate({
        'serial_no': 'SN-909',
        'operating_psi': '125.4',
        'result': 'UnknownOption',
        'agreed': true,
      });
      expect(errors3.containsKey('result'), isTrue);

      // 4. Valid payload passes
      final errors4 = schema.validate({
        'serial_no': 'SN-909',
        'operating_psi': 125.4,
        'result': 'Pass',
        'agreed': true,
      });
      expect(errors4.isEmpty, isTrue);
    });

    test('FormSubmissionModel serializes to and from JSON correctly', () {
      final json = {
        'id': 'sub-test-001',
        'form_id': 'form-test-001',
        'form_name': 'AC Audit',
        'task_id': 'task-001',
        'task_title': 'Repair AC',
        'user_id': 'user-001',
        'user_name': 'Eddie Technician',
        'latitude': 37.7749,
        'longitude': -122.4194,
        'data': {
          'serial_no': 'SN-8822',
          'operating_psi': 112.5,
          'agreed': true,
        },
        'submitted_at': '2026-09-20T11:30:00.000Z',
      };

      final model = FormSubmissionModel.fromJson(json);

      expect(model.id, 'sub-test-001');
      expect(model.formId, 'form-test-001');
      expect(model.formName, 'AC Audit');
      expect(model.taskId, 'task-001');
      expect(model.hasGps, isTrue);
      expect(model.latitude, 37.7749);
      expect(model.longitude, -122.4194);
      expect(model.data['serial_no'], 'SN-8822');

      final exported = model.toJson();
      expect(exported['id'], 'sub-test-001');
      expect(exported['latitude'], 37.7749);
      expect((exported['data'] as Map)['serial_no'], 'SN-8822');
    });
  });
}
