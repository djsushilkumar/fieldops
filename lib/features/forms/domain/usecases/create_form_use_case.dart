import '../../../../core/errors/failures.dart';
import '../entities/custom_form_entity.dart';
import '../repositories/forms_repository.dart';

class CreateFormUseCase {
  final FormsRepository repository;

  CreateFormUseCase(this.repository);

  Future<CustomFormEntity> execute(CustomFormEntity form) {
    if (form.name.trim().isEmpty) {
      throw const ValidationFailure('Form name cannot be empty');
    }
    if (form.schema.fields.isEmpty) {
      throw const ValidationFailure('A form must contain at least one field');
    }

    final fieldIds = <String>{};
    for (final field in form.schema.fields) {
      if (field.label.trim().isEmpty) {
        throw const ValidationFailure('All form fields must have a label');
      }
      if (field.id.trim().isEmpty) {
        throw const ValidationFailure('All form fields must have a valid identifier');
      }
      if (fieldIds.contains(field.id)) {
        throw ValidationFailure('Duplicate field identifier detected: ${field.id}');
      }
      fieldIds.add(field.id);
    }

    return repository.createForm(form);
  }
}
