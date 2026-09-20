import '../../../../core/errors/failures.dart';
import '../entities/custom_form_entity.dart';
import '../repositories/forms_repository.dart';

class GetFormDetailUseCase {
  final FormsRepository repository;

  GetFormDetailUseCase(this.repository);

  Future<CustomFormEntity> execute(String formId) {
    if (formId.trim().isEmpty) {
      throw const ValidationFailure('Form ID cannot be empty');
    }
    return repository.getFormById(formId);
  }
}
