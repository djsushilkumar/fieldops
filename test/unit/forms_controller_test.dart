import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:field_ops/core/location/location_coordinates.dart';
import 'package:field_ops/core/location/location_service.dart';
import 'package:field_ops/features/forms/data/datasources/forms_local_datasource.dart';
import 'package:field_ops/features/forms/data/datasources/mock_forms_remote_datasource.dart';
import 'package:field_ops/features/forms/data/repositories/forms_repository_impl.dart';
import 'package:field_ops/features/forms/domain/entities/form_field_type.dart';
import 'package:field_ops/features/forms/domain/usecases/create_form_use_case.dart';
import 'package:field_ops/features/forms/domain/usecases/delete_form_use_case.dart';
import 'package:field_ops/features/forms/domain/usecases/get_form_detail_use_case.dart';
import 'package:field_ops/features/forms/domain/usecases/get_forms_use_case.dart';
import 'package:field_ops/features/forms/domain/usecases/submit_form_use_case.dart';
import 'package:field_ops/features/forms/domain/usecases/update_form_use_case.dart';
import 'package:field_ops/features/forms/presentation/controllers/forms_controller.dart';

void main() {
  late MockFormsRemoteDataSource remoteDataSource;
  late FormsLocalDataSource localDataSource;
  late FormsRepositoryImpl repository;
  late MockLocationService locationService;

  late GetFormsUseCase getFormsUseCase;
  late GetFormDetailUseCase getFormDetailUseCase;
  late CreateFormUseCase createFormUseCase;
  late UpdateFormUseCase updateFormUseCase;
  late DeleteFormUseCase deleteFormUseCase;
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
        accuracy: 5.0,
        timestamp: DateTime.now(),
      ),
    );

    getFormsUseCase = GetFormsUseCase(repository);
    getFormDetailUseCase = GetFormDetailUseCase(repository);
    createFormUseCase = CreateFormUseCase(repository);
    updateFormUseCase = UpdateFormUseCase(repository);
    deleteFormUseCase = DeleteFormUseCase(repository);
    submitFormUseCase = SubmitFormUseCase(
      repository: repository,
      locationService: locationService,
    );
  });

  group('Forms Controllers Unit Tests', () {
    test('FormsListNotifier loads forms and filters by search query', () async {
      final notifier = FormsListNotifier(
        getFormsUseCase: getFormsUseCase,
        deleteFormUseCase: deleteFormUseCase,
      );

      // Wait for initial load
      await Future.delayed(const Duration(milliseconds: 50));

      expect(notifier.state.forms.isNotEmpty, isTrue);
      expect(notifier.state.filteredForms.length, notifier.state.forms.length);

      notifier.setSearchQuery('HVAC');
      expect(notifier.state.filteredForms.length, 1);
      expect(notifier.state.filteredForms.first.name, contains('HVAC'));

      notifier.setSearchQuery('NonExistent');
      expect(notifier.state.filteredForms.isEmpty, isTrue);

      notifier.setSearchQuery('');
      expect(notifier.state.filteredForms.length, notifier.state.forms.length);
    });

    test('FormBuilderNotifier manages fields addition, reordering and save', () async {
      final notifier = FormBuilderNotifier(
        createFormUseCase: createFormUseCase,
        updateFormUseCase: updateFormUseCase,
      );

      notifier.initialize();
      expect(notifier.state.fields.length, 1);

      notifier.setName('Electrical Inspection');
      notifier.setDescription('Check high-voltage panels and breakers');

      notifier.addField(FormFieldType.number);
      expect(notifier.state.fields.length, 2);
      expect(notifier.state.fields.last.type, FormFieldType.number);

      notifier.addField(FormFieldType.checkbox);
      expect(notifier.state.fields.length, 3);
      expect(notifier.state.fields.last.type, FormFieldType.checkbox);

      // Reorder
      notifier.reorderField(2, 0);
      expect(notifier.state.fields.first.type, FormFieldType.checkbox);

      // Remove field
      notifier.removeField(1);
      expect(notifier.state.fields.length, 2);

      // Save
      final saved = await notifier.saveForm(organizationId: 'org-acme-ops-001');
      expect(saved, isNotNull);
      expect(saved!.name, 'Electrical Inspection');
      expect(notifier.state.isSuccess, isTrue);
    });

    test('FormFillerNotifier manages answers, validation, and submission', () async {
      final notifier = FormFillerNotifier(
        formId: 'form-acme-hvac-001',
        taskId: 'task-101',
        getFormDetailUseCase: getFormDetailUseCase,
        submitFormUseCase: submitFormUseCase,
        localDataSource: localDataSource,
      );

      await notifier.loadForm();
      expect(notifier.state.form, isNotNull);
      expect(notifier.state.taskId, 'task-101');

      // Validation fails when required fields are empty
      final isValidInitial = notifier.validate();
      expect(isValidInitial, isFalse);
      expect(notifier.state.errors.isNotEmpty, isTrue);

      // Fill required fields
      notifier.setAnswer('equipment_serial', 'SN-TEST-44');
      notifier.setAnswer('operating_pressure', 115.0);
      notifier.setAnswer('inspection_status', 'Optimal / Pass');
      notifier.setAnswer('filter_replaced', true);

      final isValidAfter = notifier.validate();
      expect(isValidAfter, isTrue);
      expect(notifier.state.errors.isEmpty, isTrue);

      // Submit
      final submission = await notifier.submit();
      expect(submission, isNotNull);
      expect(submission!.hasGps, isTrue);
      expect(submission.taskId, 'task-101');
    });
  });
}
