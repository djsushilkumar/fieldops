import '../../../../core/errors/failures.dart';
import '../../../../core/location/location_coordinates.dart';
import '../../../../core/location/location_service.dart';
import '../entities/form_submission_entity.dart';
import '../repositories/forms_repository.dart';

class SubmitFormUseCase {
  final FormsRepository repository;
  final LocationService locationService;

  SubmitFormUseCase({
    required this.repository,
    required this.locationService,
  });

  Future<FormSubmissionEntity> execute({
    required String formId,
    String? taskId,
    required Map<String, dynamic> data,
    LocationCoordinates? providedLocation,
  }) async {
    if (formId.trim().isEmpty) {
      throw const ValidationFailure('Form ID cannot be empty');
    }

    // 1. Fetch form definition to validate schema
    final form = await repository.getFormById(formId);

    // 2. Validate data against schema
    final errors = form.schema.validate(data);
    if (errors.isNotEmpty) {
      final firstError = errors.values.first;
      throw ValidationFailure(firstError);
    }

    // 3. Acquire location stamp (use provided or auto-capture)
    LocationCoordinates? location = providedLocation;
    if (location == null) {
      try {
        location = await locationService.getCurrentLocation();
      } catch (_) {
        // Form submission can succeed with null coordinates if GPS is unavailable
        location = null;
      }
    }

    // 4. Submit
    return repository.submitForm(
      formId: formId,
      taskId: taskId,
      data: data,
      location: location,
    );
  }
}
