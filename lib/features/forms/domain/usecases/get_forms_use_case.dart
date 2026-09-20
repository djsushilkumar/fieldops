import '../entities/custom_form_entity.dart';
import '../repositories/forms_repository.dart';

class GetFormsUseCase {
  final FormsRepository repository;

  GetFormsUseCase(this.repository);

  Future<List<CustomFormEntity>> execute({bool forceRefresh = false}) {
    return repository.getForms(forceRefresh: forceRefresh);
  }
}
