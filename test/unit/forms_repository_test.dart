import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:field_ops/core/location/location_coordinates.dart';
import 'package:field_ops/features/forms/data/datasources/forms_local_datasource.dart';
import 'package:field_ops/features/forms/data/datasources/mock_forms_remote_datasource.dart';
import 'package:field_ops/features/forms/data/repositories/forms_repository_impl.dart';
import 'package:field_ops/features/forms/domain/entities/custom_form_entity.dart';
import 'package:field_ops/features/forms/domain/entities/form_field_definition.dart';
import 'package:field_ops/features/forms/domain/entities/form_field_type.dart';
import 'package:field_ops/features/forms/domain/entities/form_schema_entity.dart';

void main() {
  late MockFormsRemoteDataSource remoteDataSource;
  late FormsLocalDataSource localDataSource;
  late FormsRepositoryImpl repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    remoteDataSource = MockFormsRemoteDataSource();
    localDataSource = FormsLocalDataSourceImpl(sharedPreferences: prefs);

    repository = FormsRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
      getOrgId: () => 'org-acme-ops-001',
      getUserId: () => 'user-emp-001',
      getUserName: () => 'Eddie Employee',
    );
  });

  group('FormsRepositoryImpl Tests', () {
    test('getForms returns seeded forms list', () async {
      final forms = await repository.getForms();
      expect(forms.isNotEmpty, isTrue);
      expect(forms.any((f) => f.id == 'form-acme-hvac-001'), isTrue);
    });

    test('getFormById returns matching form', () async {
      final form = await repository.getFormById('form-acme-hvac-001');
      expect(form.id, 'form-acme-hvac-001');
      expect(form.name, contains('HVAC'));
      expect(form.schema.fields.isNotEmpty, isTrue);
    });

    test('createForm persists new custom form', () async {
      final newForm = CustomFormEntity(
        id: '',
        organizationId: 'org-acme-ops-001',
        name: 'Daily Van Inspection',
        description: 'Check tire pressure and oil level before dispatch',
        schema: const FormSchemaEntity(
          fields: [
            FormFieldDefinition(
              id: 'mileage',
              label: 'Odometer Mileage',
              type: FormFieldType.number,
              required: true,
            ),
            FormFieldDefinition(
              id: 'tires_ok',
              label: 'Tires in Good Condition',
              type: FormFieldType.checkbox,
              required: true,
            ),
          ],
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created = await repository.createForm(newForm);
      expect(created.id.isNotEmpty, isTrue);
      expect(created.name, 'Daily Van Inspection');

      final fetched = await repository.getFormById(created.id);
      expect(fetched.name, 'Daily Van Inspection');
    });

    test('updateForm updates existing form schema', () async {
      final existing = await repository.getFormById('form-acme-safety-002');
      final updated = existing.copyWith(
        name: 'Site Safety & PPE Audit V2',
        description: 'Updated guidelines for 2026',
      );

      final saved = await repository.updateForm(updated);
      expect(saved.name, 'Site Safety & PPE Audit V2');

      final fetched = await repository.getFormById('form-acme-safety-002');
      expect(fetched.name, 'Site Safety & PPE Audit V2');
    });

    test('deleteForm removes form from repository', () async {
      final formsBefore = await repository.getForms();
      expect(formsBefore.any((f) => f.id == 'form-acme-signoff-003'), isTrue);

      await repository.deleteForm('form-acme-signoff-003');

      final formsAfter = await repository.getForms();
      expect(formsAfter.any((f) => f.id == 'form-acme-signoff-003'), isFalse);
    });

    test('submitForm stores submission with GPS audit and clears local draft', () async {
      // Save draft first
      await localDataSource.saveFormDraft('form-acme-hvac-001', {'equipment_serial': 'draft-sn'});
      final draftBefore = await localDataSource.getFormDraft('form-acme-hvac-001');
      expect(draftBefore, isNotNull);

      final location = LocationCoordinates(
        latitude: 37.7749,
        longitude: -122.4194,
        accuracy: 5.0,
        timestamp: DateTime.now(),
      );

      final submission = await repository.submitForm(
        formId: 'form-acme-hvac-001',
        taskId: 'task-test-01',
        data: {
          'equipment_serial': 'SN-554433',
          'operating_pressure': 120.0,
          'inspection_status': 'Optimal / Pass',
          'filter_replaced': true,
        },
        location: location,
      );

      expect(submission.id.isNotEmpty, isTrue);
      expect(submission.formId, 'form-acme-hvac-001');
      expect(submission.taskId, 'task-test-01');
      expect(submission.latitude, 37.7749);
      expect(submission.longitude, -122.4194);
      expect(submission.hasGps, isTrue);

      // Verify draft cleared
      final draftAfter = await localDataSource.getFormDraft('form-acme-hvac-001');
      expect(draftAfter, isNull);

      // Verify queryable via getSubmissions
      final submissions = await repository.getSubmissions(taskId: 'task-test-01');
      expect(submissions.any((s) => s.id == submission.id), isTrue);
    });

    test('offline fallback serves cached forms when remote encounters server error', () async {
      // 1. Populate cache
      await repository.getForms();

      // 2. Enable remote error
      remoteDataSource.simulateError = true;

      // 3. Should still succeed from local cache
      final cachedForms = await repository.getForms();
      expect(cachedForms.isNotEmpty, isTrue);
    });
  });
}
