import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:field_ops/core/errors/failures.dart';
import 'package:field_ops/core/location/location_coordinates.dart';
import 'package:field_ops/core/location/location_service.dart';
import 'package:field_ops/features/forms/data/datasources/forms_local_datasource.dart';
import 'package:field_ops/features/forms/data/datasources/mock_forms_remote_datasource.dart';
import 'package:field_ops/features/forms/data/repositories/forms_repository_impl.dart';
import 'package:field_ops/features/forms/domain/entities/custom_form_entity.dart';
import 'package:field_ops/features/forms/domain/entities/form_field_definition.dart';
import 'package:field_ops/features/forms/domain/entities/form_field_type.dart';
import 'package:field_ops/features/forms/domain/entities/form_schema_entity.dart';
import 'package:field_ops/features/forms/domain/usecases/create_form_use_case.dart';
import 'package:field_ops/features/forms/domain/usecases/delete_form_use_case.dart';
import 'package:field_ops/features/forms/domain/usecases/get_form_detail_use_case.dart';
import 'package:field_ops/features/forms/domain/usecases/get_forms_use_case.dart';
import 'package:field_ops/features/forms/domain/usecases/submit_form_use_case.dart';
import 'package:field_ops/features/forms/domain/usecases/update_form_use_case.dart';

void main() {
  late MockFormsRemoteDataSource remoteDataSource;
  late FormsLocalDataSource localDataSource;
  late FormsRepositoryImpl repository;
  late MockLocationService locationService;

  late CreateFormUseCase createFormUseCase;
  late UpdateFormUseCase updateFormUseCase;
  late DeleteFormUseCase deleteFormUseCase;
  late GetFormsUseCase getFormsUseCase;
  late GetFormDetailUseCase getFormDetailUseCase;
  late SubmitFormUseCase submitFormUseCase;

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

    locationService = MockLocationService(
      initialCoordinates: LocationCoordinates(
        latitude: 37.7749,
        longitude: -122.4194,
        accuracy: 4.5,
        timestamp: DateTime.now(),
      ),
    );

    createFormUseCase = CreateFormUseCase(repository);
    updateFormUseCase = UpdateFormUseCase(repository);
    deleteFormUseCase = DeleteFormUseCase(repository);
    getFormsUseCase = GetFormsUseCase(repository);
    getFormDetailUseCase = GetFormDetailUseCase(repository);
    submitFormUseCase = SubmitFormUseCase(
      repository: repository,
      locationService: locationService,
    );
  });

  group('Forms Use Cases Tests', () {
    test('CreateFormUseCase throws ValidationFailure on invalid inputs', () async {
      // Empty name
      expect(
        () => createFormUseCase.execute(
          CustomFormEntity(
            id: '',
            organizationId: 'org-01',
            name: '   ',
            schema: const FormSchemaEntity(fields: [
              FormFieldDefinition(id: 'f1', label: 'Field 1', type: FormFieldType.text),
            ]),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
        throwsA(isA<ValidationFailure>().having((e) => e.message, 'message', contains('cannot be empty'))),
      );

      // Empty fields
      expect(
        () => createFormUseCase.execute(
          CustomFormEntity(
            id: '',
            organizationId: 'org-01',
            name: 'Valid Name',
            schema: const FormSchemaEntity(fields: []),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
        throwsA(isA<ValidationFailure>().having((e) => e.message, 'message', contains('at least one field'))),
      );

      // Duplicate field IDs
      expect(
        () => createFormUseCase.execute(
          CustomFormEntity(
            id: '',
            organizationId: 'org-01',
            name: 'Valid Name',
            schema: const FormSchemaEntity(fields: [
              FormFieldDefinition(id: 'same_id', label: 'Field A', type: FormFieldType.text),
              FormFieldDefinition(id: 'same_id', label: 'Field B', type: FormFieldType.text),
            ]),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
        throwsA(isA<ValidationFailure>().having((e) => e.message, 'message', contains('Duplicate field identifier'))),
      );
    });

    test('GetFormDetailUseCase throws ValidationFailure when ID is empty', () async {
      expect(
        () => getFormDetailUseCase.execute(''),
        throwsA(isA<ValidationFailure>().having((e) => e.message, 'message', contains('cannot be empty'))),
      );
    });

    test('UpdateFormUseCase updates form attributes', () async {
      final form = await getFormDetailUseCase.execute('form-acme-safety-002');
      final updated = form.copyWith(name: 'Updated Safety Audit Title');
      final result = await updateFormUseCase.execute(updated);
      expect(result.name, 'Updated Safety Audit Title');
    });

    test('SubmitFormUseCase validates required schema fields before submission', () async {
      // Missing required field 'equipment_serial'
      expect(
        () => submitFormUseCase.execute(
          formId: 'form-acme-hvac-001',
          data: {
            'operating_pressure': 115.0,
            'inspection_status': 'Optimal / Pass',
            'filter_replaced': true,
          },
        ),
        throwsA(isA<ValidationFailure>().having((e) => e.message, 'message', contains('is required'))),
      );
    });

    test('SubmitFormUseCase automatically acquires GPS and submits successfully', () async {
      final submission = await submitFormUseCase.execute(
        formId: 'form-acme-hvac-001',
        taskId: 'task-hvac-99',
        data: {
          'equipment_serial': 'CHL-1029',
          'operating_pressure': 119.5,
          'inspection_status': 'Optimal / Pass',
          'filter_replaced': true,
          'technician_notes': 'All systems within threshold.',
        },
      );

      expect(submission.id.isNotEmpty, isTrue);
      expect(submission.hasGps, isTrue);
      expect(submission.latitude, 37.7749);
      expect(submission.longitude, -122.4194);
      expect(submission.taskId, 'task-hvac-99');
    });

    test('DeleteFormUseCase removes form', () async {
      await deleteFormUseCase.execute('form-acme-hvac-001');
      final remaining = await getFormsUseCase.execute();
      expect(remaining.any((f) => f.id == 'form-acme-hvac-001'), isFalse);
    });
  });
}
