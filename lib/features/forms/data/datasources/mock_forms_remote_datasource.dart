import 'package:uuid/uuid.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/form_field_definition.dart';
import '../../domain/entities/form_field_type.dart';
import '../../domain/entities/form_schema_entity.dart';
import '../models/custom_form_model.dart';
import '../models/form_submission_model.dart';
import 'forms_remote_datasource.dart';

class MockFormsRemoteDataSource implements FormsRemoteDataSource {
  final List<CustomFormModel> _forms = [];
  final List<FormSubmissionModel> _submissions = [];
  bool simulateError = false;

  MockFormsRemoteDataSource() {
    _seedData();
  }

  void _seedData() {
    final now = DateTime.now();

    final form1 = CustomFormModel(
      id: 'form-acme-hvac-001',
      organizationId: 'org-acme-ops-001',
      name: 'HVAC & Mechanical Maintenance Checklist',
      description: 'Standard multi-point inspection for commercial chillers and HVAC compressors.',
      schema: const FormSchemaEntity(
        version: 1,
        fields: [
          FormFieldDefinition(
            id: 'equipment_serial',
            label: 'Equipment Serial / Asset ID',
            type: FormFieldType.text,
            required: true,
            placeholder: 'e.g. CHL-4092-A',
          ),
          FormFieldDefinition(
            id: 'operating_pressure',
            label: 'Refrigerant Suction Pressure (PSI)',
            type: FormFieldType.number,
            required: true,
            placeholder: 'e.g. 115.5',
            helpText: 'Acceptable range: 100 - 130 PSI',
          ),
          FormFieldDefinition(
            id: 'inspection_status',
            label: 'Overall System Condition',
            type: FormFieldType.select,
            required: true,
            options: ['Optimal / Pass', 'Warning / Needs Attention', 'Critical / Shutdown'],
            defaultValue: 'Optimal / Pass',
          ),
          FormFieldDefinition(
            id: 'next_service_date',
            label: 'Next Recommended Service Date',
            type: FormFieldType.date,
            required: false,
            placeholder: 'Select scheduled date',
          ),
          FormFieldDefinition(
            id: 'filter_replaced',
            label: 'Air Filters Replaced During Visit',
            type: FormFieldType.checkbox,
            required: true,
          ),
          FormFieldDefinition(
            id: 'technician_notes',
            label: 'Technician Observations & Remediation',
            type: FormFieldType.multiline,
            required: false,
            placeholder: 'Detailed summary of findings or replaced parts...',
          ),
        ],
      ),
      submissionsCount: 1,
      createdAt: now.subtract(const Duration(days: 14)),
      updatedAt: now.subtract(const Duration(days: 2)),
    );

    final form2 = CustomFormModel(
      id: 'form-acme-safety-002',
      organizationId: 'org-acme-ops-001',
      name: 'Site Safety & PPE Audit',
      description: 'Mandatory OSHA / safety compliance check before executing field repairs.',
      schema: const FormSchemaEntity(
        version: 1,
        fields: [
          FormFieldDefinition(
            id: 'ppe_verified',
            label: 'Personal Protective Equipment (PPE) Verified On-Site',
            type: FormFieldType.checkbox,
            required: true,
          ),
          FormFieldDefinition(
            id: 'site_hazard_level',
            label: 'Site Hazard Rating',
            type: FormFieldType.select,
            required: true,
            options: ['Low Risk', 'Moderate Risk', 'High Risk / Permit Required'],
          ),
          FormFieldDefinition(
            id: 'emergency_contact',
            label: 'Facility Emergency Contact Phone',
            type: FormFieldType.text,
            required: true,
            placeholder: 'e.g. +1-555-0199',
          ),
          FormFieldDefinition(
            id: 'safety_notes',
            label: 'Safety Briefing & Risk Mitigation Notes',
            type: FormFieldType.multiline,
            required: false,
          ),
        ],
      ),
      submissionsCount: 0,
      createdAt: now.subtract(const Duration(days: 10)),
      updatedAt: now.subtract(const Duration(days: 10)),
    );

    final form3 = CustomFormModel(
      id: 'form-acme-signoff-003',
      organizationId: 'org-acme-ops-001',
      name: 'Customer Service Acceptance Sign-Off',
      description: 'Client sign-off upon completing scheduled work orders.',
      schema: const FormSchemaEntity(
        version: 1,
        fields: [
          FormFieldDefinition(
            id: 'customer_rep',
            label: 'Customer Representative Full Name',
            type: FormFieldType.text,
            required: true,
            placeholder: 'e.g. Jane Doe',
          ),
          FormFieldDefinition(
            id: 'service_rating',
            label: 'Overall Satisfaction Level',
            type: FormFieldType.select,
            required: true,
            options: ['5-Star Excellent', '4-Star Good', '3-Star Satisfactory', 'Needs Attention'],
            defaultValue: '5-Star Excellent',
          ),
          FormFieldDefinition(
            id: 'accepted_work',
            label: 'Work Completed to Specification',
            type: FormFieldType.checkbox,
            required: true,
          ),
          FormFieldDefinition(
            id: 'signoff_comments',
            label: 'Customer Feedback & Comments',
            type: FormFieldType.multiline,
            required: false,
          ),
        ],
      ),
      submissionsCount: 0,
      createdAt: now.subtract(const Duration(days: 7)),
      updatedAt: now.subtract(const Duration(days: 7)),
    );

    _forms.addAll([form1, form2, form3]);

    final sub1 = FormSubmissionModel(
      id: 'sub-acme-001',
      formId: form1.id,
      formName: form1.name,
      taskId: 'task-001',
      taskTitle: 'Emergency HVAC Repair - Compressor Unit 3',
      userId: 'user-emp-001',
      userName: 'Eddie Employee',
      latitude: 37.7749,
      longitude: -122.4194,
      data: {
        'equipment_serial': 'CHL-9921-X',
        'operating_pressure': 118.2,
        'inspection_status': 'Optimal / Pass',
        'next_service_date': '2026-12-15',
        'filter_replaced': true,
        'technician_notes': 'Cleaned condenser coils and recharged freon. Unit running nominal.',
      },
      submittedAt: now.subtract(const Duration(hours: 3)),
    );

    _submissions.add(sub1);
  }

  @override
  Future<List<CustomFormModel>> getForms(String organizationId) async {
    if (simulateError) throw const ServerException('Simulated network error');
    return List.from(_forms);
  }

  @override
  Future<CustomFormModel> getFormById(String id) async {
    if (simulateError) throw const ServerException('Simulated network error');
    final match = _forms.where((f) => f.id == id);
    if (match.isEmpty) throw ServerException('Form with ID $id not found');
    return match.first;
  }

  @override
  Future<CustomFormModel> createForm(CustomFormModel form) async {
    if (simulateError) throw const ServerException('Simulated network error');
    final newId = form.id.isNotEmpty ? form.id : 'form-${const Uuid().v4().substring(0, 8)}';
    final created = CustomFormModel(
      id: newId,
      organizationId: form.organizationId,
      name: form.name,
      description: form.description,
      schema: form.schema,
      submissionsCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _forms.insert(0, created);
    return created;
  }

  @override
  Future<CustomFormModel> updateForm(CustomFormModel form) async {
    if (simulateError) throw const ServerException('Simulated network error');
    final index = _forms.indexWhere((f) => f.id == form.id);
    if (index == -1) throw ServerException('Form with ID ${form.id} not found');

    final existing = _forms[index];
    final updated = CustomFormModel(
      id: form.id,
      organizationId: form.organizationId.isNotEmpty ? form.organizationId : existing.organizationId,
      name: form.name,
      description: form.description,
      schema: form.schema,
      submissionsCount: existing.submissionsCount,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );
    _forms[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteForm(String id) async {
    if (simulateError) throw const ServerException('Simulated network error');
    _forms.removeWhere((f) => f.id == id);
    _submissions.removeWhere((s) => s.formId == id);
  }

  @override
  Future<List<FormSubmissionModel>> getSubmissions({String? formId, String? taskId}) async {
    if (simulateError) throw const ServerException('Simulated network error');
    return _submissions.where((s) {
      if (formId != null && s.formId != formId) return false;
      if (taskId != null && s.taskId != taskId) return false;
      return true;
    }).toList();
  }

  @override
  Future<FormSubmissionModel> getSubmissionById(String id) async {
    if (simulateError) throw const ServerException('Simulated network error');
    final match = _submissions.where((s) => s.id == id);
    if (match.isEmpty) throw ServerException('Submission with ID $id not found');
    return match.first;
  }

  @override
  Future<FormSubmissionModel> insertSubmission(FormSubmissionModel submission) async {
    if (simulateError) throw const ServerException('Simulated network error');
    final newId = submission.id.isNotEmpty ? submission.id : 'sub-${const Uuid().v4().substring(0, 8)}';

    // Find form name
    String? formName = submission.formName;
    if (formName == null) {
      final formMatch = _forms.where((f) => f.id == submission.formId);
      if (formMatch.isNotEmpty) {
        formName = formMatch.first.name;
      }
    }

    final saved = FormSubmissionModel(
      id: newId,
      formId: submission.formId,
      formName: formName,
      taskId: submission.taskId,
      taskTitle: submission.taskTitle,
      userId: submission.userId,
      userName: submission.userName ?? 'Field Officer',
      latitude: submission.latitude,
      longitude: submission.longitude,
      data: submission.data,
      submittedAt: submission.submittedAt,
    );

    _submissions.insert(0, saved);

    // Update submissionsCount in form
    final formIndex = _forms.indexWhere((f) => f.id == submission.formId);
    if (formIndex >= 0) {
      final f = _forms[formIndex];
      _forms[formIndex] = f.copyWith(submissionsCount: f.submissionsCount + 1);
    }

    return saved;
  }
}
