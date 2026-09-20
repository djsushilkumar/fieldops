import '../../../../core/errors/failures.dart';
import '../repositories/forms_repository.dart';

class DeleteFormUseCase {
  final FormsRepository repository;

  DeleteFormUseCase(this.repository);

  Future<void> execute(String formId) {
    if (formId.trim().isEmpty) {
      throw const ValidationFailure('Form ID cannot be empty');
    }
    return repository.deleteForm(formId);
  }
}
