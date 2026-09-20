import '../entities/form_submission_entity.dart';
import '../repositories/forms_repository.dart';

class GetFormSubmissionsUseCase {
  final FormsRepository repository;

  GetFormSubmissionsUseCase(this.repository);

  Future<List<FormSubmissionEntity>> execute({String? formId, String? taskId}) {
    return repository.getSubmissions(formId: formId, taskId: taskId);
  }
}
