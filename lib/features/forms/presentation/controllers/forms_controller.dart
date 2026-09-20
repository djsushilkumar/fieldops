import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/location/location_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/datasources/forms_local_datasource.dart';
import '../../data/datasources/forms_remote_datasource.dart';
import '../../data/datasources/mock_forms_remote_datasource.dart';
import '../../data/repositories/forms_repository_impl.dart';
import '../../domain/entities/custom_form_entity.dart';
import '../../domain/entities/form_field_definition.dart';
import '../../domain/entities/form_field_type.dart';
import '../../domain/entities/form_schema_entity.dart';
import '../../domain/entities/form_submission_entity.dart';
import '../../domain/repositories/forms_repository.dart';
import '../../domain/usecases/create_form_use_case.dart';
import '../../domain/usecases/delete_form_use_case.dart';
import '../../domain/usecases/get_form_detail_use_case.dart';
import '../../domain/usecases/get_form_submissions_use_case.dart';
import '../../domain/usecases/get_forms_use_case.dart';
import '../../domain/usecases/submit_form_use_case.dart';
import '../../domain/usecases/update_form_use_case.dart';

// ============================================================================
// Dependency Injection Providers
// ============================================================================

final formsLocalDataSourceProvider = Provider<FormsLocalDataSource>((ref) {
  return FormsLocalDataSourceImpl();
});

final formsRemoteDataSourceProvider = Provider<FormsRemoteDataSource>((ref) {
  final supabase = SupabaseConfig.client;
  if (supabase != null) {
    return SupabaseFormsRemoteDataSource(supabase);
  }
  return MockFormsRemoteDataSource();
});

final formsRepositoryProvider = Provider<FormsRepository>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return FormsRepositoryImpl(
    remoteDataSource: ref.watch(formsRemoteDataSourceProvider),
    localDataSource: ref.watch(formsLocalDataSourceProvider),
    getOrgId: () => authState.user?.organizationId ?? 'org-acme-ops-001',
    getUserId: () => authState.user?.id ?? 'user-emp-001',
    getUserName: () => authState.user?.name ?? 'Field Officer',
  );
});

final getFormsUseCaseProvider = Provider<GetFormsUseCase>((ref) {
  return GetFormsUseCase(ref.watch(formsRepositoryProvider));
});

final getFormDetailUseCaseProvider = Provider<GetFormDetailUseCase>((ref) {
  return GetFormDetailUseCase(ref.watch(formsRepositoryProvider));
});

final createFormUseCaseProvider = Provider<CreateFormUseCase>((ref) {
  return CreateFormUseCase(ref.watch(formsRepositoryProvider));
});

final updateFormUseCaseProvider = Provider<UpdateFormUseCase>((ref) {
  return UpdateFormUseCase(ref.watch(formsRepositoryProvider));
});

final deleteFormUseCaseProvider = Provider<DeleteFormUseCase>((ref) {
  return DeleteFormUseCase(ref.watch(formsRepositoryProvider));
});

final getFormSubmissionsUseCaseProvider = Provider<GetFormSubmissionsUseCase>((ref) {
  return GetFormSubmissionsUseCase(ref.watch(formsRepositoryProvider));
});

final submitFormUseCaseProvider = Provider<SubmitFormUseCase>((ref) {
  return SubmitFormUseCase(
    repository: ref.watch(formsRepositoryProvider),
    locationService: ref.watch(locationServiceProvider),
  );
});

// ============================================================================
// Forms List State & Notifier
// ============================================================================

class FormsListState {
  final bool isLoading;
  final List<CustomFormEntity> forms;
  final String searchQuery;
  final String? errorMessage;

  const FormsListState({
    this.isLoading = false,
    this.forms = const [],
    this.searchQuery = '',
    this.errorMessage,
  });

  List<CustomFormEntity> get filteredForms {
    if (searchQuery.trim().isEmpty) return forms;
    final q = searchQuery.toLowerCase().trim();
    return forms.where((f) {
      final nameMatches = f.name.toLowerCase().contains(q);
      final descMatches = f.description?.toLowerCase().contains(q) ?? false;
      return nameMatches || descMatches;
    }).toList();
  }

  FormsListState copyWith({
    bool? isLoading,
    List<CustomFormEntity>? forms,
    String? searchQuery,
    String? errorMessage,
  }) {
    return FormsListState(
      isLoading: isLoading ?? this.isLoading,
      forms: forms ?? this.forms,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
    );
  }
}

class FormsListNotifier extends StateNotifier<FormsListState> {
  final GetFormsUseCase _getFormsUseCase;
  final DeleteFormUseCase _deleteFormUseCase;

  FormsListNotifier({
    required GetFormsUseCase getFormsUseCase,
    required DeleteFormUseCase deleteFormUseCase,
  })  : _getFormsUseCase = getFormsUseCase,
        _deleteFormUseCase = deleteFormUseCase,
        super(const FormsListState()) {
    loadForms();
  }

  Future<void> loadForms({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final forms = await _getFormsUseCase.execute(forceRefresh: forceRefresh);
      state = state.copyWith(forms: forms, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<bool> deleteForm(String id) async {
    try {
      await _deleteFormUseCase.execute(id);
      final updated = state.forms.where((f) => f.id != id).toList();
      state = state.copyWith(forms: updated);
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
}

final formsListNotifierProvider = StateNotifierProvider<FormsListNotifier, FormsListState>((ref) {
  return FormsListNotifier(
    getFormsUseCase: ref.watch(getFormsUseCaseProvider),
    deleteFormUseCase: ref.watch(deleteFormUseCaseProvider),
  );
});

// ============================================================================
// Form Builder State & Notifier
// ============================================================================

class FormBuilderState {
  final String? id;
  final String name;
  final String description;
  final List<FormFieldDefinition> fields;
  final bool isSaving;
  final String? errorMessage;
  final bool isSuccess;

  const FormBuilderState({
    this.id,
    this.name = '',
    this.description = '',
    this.fields = const [],
    this.isSaving = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  bool get isValid => name.trim().isNotEmpty && fields.isNotEmpty;

  FormBuilderState copyWith({
    String? id,
    String? name,
    String? description,
    List<FormFieldDefinition>? fields,
    bool? isSaving,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return FormBuilderState(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      fields: fields ?? this.fields,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class FormBuilderNotifier extends StateNotifier<FormBuilderState> {
  final CreateFormUseCase _createFormUseCase;
  final UpdateFormUseCase _updateFormUseCase;

  FormBuilderNotifier({
    required CreateFormUseCase createFormUseCase,
    required UpdateFormUseCase updateFormUseCase,
  })  : _createFormUseCase = createFormUseCase,
        _updateFormUseCase = updateFormUseCase,
        super(const FormBuilderState());

  void initialize([CustomFormEntity? form]) {
    if (form != null) {
      state = FormBuilderState(
        id: form.id,
        name: form.name,
        description: form.description ?? '',
        fields: List.from(form.schema.fields),
      );
    } else {
      state = const FormBuilderState(
        fields: [
          FormFieldDefinition(
            id: 'field_1',
            label: 'Inspection Summary',
            type: FormFieldType.text,
            required: true,
          ),
        ],
      );
    }
  }

  void setName(String val) => state = state.copyWith(name: val, errorMessage: null);
  void setDescription(String val) => state = state.copyWith(description: val, errorMessage: null);

  void addField(FormFieldType type) {
    final nextNum = state.fields.length + 1;
    final newField = FormFieldDefinition(
      id: 'field_${const Uuid().v4().substring(0, 6)}',
      label: 'New ${type.label} #$nextNum',
      type: type,
      required: false,
      options: type == FormFieldType.select ? ['Option 1', 'Option 2'] : const [],
    );
    state = state.copyWith(
      fields: [...state.fields, newField],
      errorMessage: null,
    );
  }

  void updateField(int index, FormFieldDefinition updated) {
    if (index < 0 || index >= state.fields.length) return;
    final updatedList = List<FormFieldDefinition>.from(state.fields);
    updatedList[index] = updated;
    state = state.copyWith(fields: updatedList, errorMessage: null);
  }

  void removeField(int index) {
    if (index < 0 || index >= state.fields.length) return;
    final updatedList = List<FormFieldDefinition>.from(state.fields)..removeAt(index);
    state = state.copyWith(fields: updatedList, errorMessage: null);
  }

  void reorderField(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.fields.length) return;
    final list = List<FormFieldDefinition>.from(state.fields);
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = state.copyWith(fields: list);
  }

  Future<CustomFormEntity?> saveForm({required String organizationId}) async {
    if (state.name.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Please provide a form title');
      return null;
    }
    if (state.fields.isEmpty) {
      state = state.copyWith(errorMessage: 'Please add at least one form field');
      return null;
    }

    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      final schema = FormSchemaEntity(
        version: 1,
        fields: state.fields,
      );

      final form = CustomFormEntity(
        id: state.id ?? '',
        organizationId: organizationId,
        name: state.name.trim(),
        description: state.description.trim().isNotEmpty ? state.description.trim() : null,
        schema: schema,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      CustomFormEntity saved;
      if (state.id != null && state.id!.isNotEmpty) {
        saved = await _updateFormUseCase.execute(form);
      } else {
        saved = await _createFormUseCase.execute(form);
      }

      state = state.copyWith(isSaving: false, isSuccess: true);
      return saved;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }
}

final formBuilderNotifierProvider = StateNotifierProvider<FormBuilderNotifier, FormBuilderState>((ref) {
  return FormBuilderNotifier(
    createFormUseCase: ref.watch(createFormUseCaseProvider),
    updateFormUseCase: ref.watch(updateFormUseCaseProvider),
  );
});

// ============================================================================
// Form Filler State & Notifier
// ============================================================================

class FormFillerState {
  final CustomFormEntity? form;
  final String? taskId;
  final Map<String, dynamic> answers;
  final Map<String, String> errors;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final FormSubmissionEntity? submissionSuccess;

  const FormFillerState({
    this.form,
    this.taskId,
    this.answers = const {},
    this.errors = const {},
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.submissionSuccess,
  });

  FormFillerState copyWith({
    CustomFormEntity? form,
    String? taskId,
    Map<String, dynamic>? answers,
    Map<String, String>? errors,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    FormSubmissionEntity? submissionSuccess,
  }) {
    return FormFillerState(
      form: form ?? this.form,
      taskId: taskId ?? this.taskId,
      answers: answers ?? this.answers,
      errors: errors ?? this.errors,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      submissionSuccess: submissionSuccess,
    );
  }
}

class FormFillerNotifier extends StateNotifier<FormFillerState> {
  final String formId;
  final GetFormDetailUseCase _getFormDetailUseCase;
  final SubmitFormUseCase _submitFormUseCase;
  final FormsLocalDataSource _localDataSource;

  FormFillerNotifier({
    required this.formId,
    required GetFormDetailUseCase getFormDetailUseCase,
    required SubmitFormUseCase submitFormUseCase,
    required FormsLocalDataSource localDataSource,
    String? taskId,
  })  : _getFormDetailUseCase = getFormDetailUseCase,
        _submitFormUseCase = submitFormUseCase,
        _localDataSource = localDataSource,
        super(FormFillerState(isLoading: true, taskId: taskId)) {
    loadForm();
  }

  void setTaskId(String? id) {
    state = state.copyWith(taskId: id);
  }

  Future<void> initializeWithForm(CustomFormEntity form, {String? taskId}) async {
    state = FormFillerState(form: form, taskId: taskId, isLoading: false);
    await _loadDraft(form.id);
  }

  Future<void> loadForm() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final form = await _getFormDetailUseCase.execute(formId);
      state = state.copyWith(form: form, isLoading: false);
      await _loadDraft(formId);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _loadDraft(String targetFormId) async {
    final draft = await _localDataSource.getFormDraft(targetFormId);
    if (draft != null && draft.isNotEmpty) {
      state = state.copyWith(answers: Map<String, dynamic>.from(draft));
    } else if (state.form != null) {
      // Set default values if configured
      final defaultAnswers = <String, dynamic>{};
      for (final f in state.form!.schema.fields) {
        if (f.defaultValue != null) {
          defaultAnswers[f.id] = f.defaultValue;
        } else if (f.type == FormFieldType.checkbox) {
          defaultAnswers[f.id] = false;
        }
      }
      if (defaultAnswers.isNotEmpty) {
        state = state.copyWith(answers: defaultAnswers);
      }
    }
  }

  void setAnswer(String fieldId, dynamic value) {
    final updated = Map<String, dynamic>.from(state.answers);
    updated[fieldId] = value;

    // Clear error on this field if resolved
    final updatedErrors = Map<String, String>.from(state.errors)..remove(fieldId);

    state = state.copyWith(answers: updated, errors: updatedErrors);

    // Auto-save draft in background
    if (state.form != null) {
      _localDataSource.saveFormDraft(state.form!.id, updated);
    }
  }

  bool validate() {
    if (state.form == null) return false;
    final errors = state.form!.schema.validate(state.answers);
    state = state.copyWith(errors: errors);
    return errors.isEmpty;
  }

  Future<FormSubmissionEntity?> submit() async {
    if (state.form == null) return null;

    final isValid = validate();
    if (!isValid) {
      state = state.copyWith(errorMessage: 'Please resolve highlighted errors');
      return null;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final submission = await _submitFormUseCase.execute(
        formId: state.form!.id,
        taskId: state.taskId,
        data: state.answers,
      );

      state = state.copyWith(
        isSubmitting: false,
        submissionSuccess: submission,
      );

      return submission;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }
}

final formFillerNotifierProvider = StateNotifierProvider.family<FormFillerNotifier, FormFillerState, String>((ref, formId) {
  return FormFillerNotifier(
    formId: formId,
    getFormDetailUseCase: ref.watch(getFormDetailUseCaseProvider),
    submitFormUseCase: ref.watch(submitFormUseCaseProvider),
    localDataSource: ref.watch(formsLocalDataSourceProvider),
  );
});

// ============================================================================
// Form Submissions State & Notifier
// ============================================================================

class FormSubmissionsState {
  final bool isLoading;
  final List<FormSubmissionEntity> submissions;
  final String? errorMessage;

  const FormSubmissionsState({
    this.isLoading = false,
    this.submissions = const [],
    this.errorMessage,
  });

  FormSubmissionsState copyWith({
    bool? isLoading,
    List<FormSubmissionEntity>? submissions,
    String? errorMessage,
  }) {
    return FormSubmissionsState(
      isLoading: isLoading ?? this.isLoading,
      submissions: submissions ?? this.submissions,
      errorMessage: errorMessage,
    );
  }
}

class FormSubmissionsNotifier extends StateNotifier<FormSubmissionsState> {
  final GetFormSubmissionsUseCase _getSubmissionsUseCase;
  final String? formId;
  final String? taskId;

  FormSubmissionsNotifier({
    required GetFormSubmissionsUseCase getSubmissionsUseCase,
    this.formId,
    this.taskId,
  })  : _getSubmissionsUseCase = getSubmissionsUseCase,
        super(const FormSubmissionsState()) {
    loadSubmissions();
  }

  Future<void> loadSubmissions() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final items = await _getSubmissionsUseCase.execute(formId: formId, taskId: taskId);
      state = state.copyWith(submissions: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

final formSubmissionsNotifierProvider = StateNotifierProvider.family<FormSubmissionsNotifier, FormSubmissionsState, String?>((ref, formOrTaskId) {
  return FormSubmissionsNotifier(
    getSubmissionsUseCase: ref.watch(getFormSubmissionsUseCaseProvider),
    formId: formOrTaskId,
  );
});

final taskFormSubmissionsNotifierProvider = StateNotifierProvider.family<FormSubmissionsNotifier, FormSubmissionsState, String>((ref, taskId) {
  return FormSubmissionsNotifier(
    getSubmissionsUseCase: ref.watch(getFormSubmissionsUseCaseProvider),
    taskId: taskId,
  );
});
