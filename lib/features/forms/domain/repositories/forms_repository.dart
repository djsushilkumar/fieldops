import '../../../../core/location/location_coordinates.dart';
import '../entities/custom_form_entity.dart';
import '../entities/form_submission_entity.dart';

abstract class FormsRepository {
  Future<List<CustomFormEntity>> getForms({bool forceRefresh = false});
  Future<CustomFormEntity> getFormById(String id);
  Future<CustomFormEntity> createForm(CustomFormEntity form);
  Future<CustomFormEntity> updateForm(CustomFormEntity form);
  Future<void> deleteForm(String id);

  Future<List<FormSubmissionEntity>> getSubmissions({String? formId, String? taskId});
  Future<FormSubmissionEntity> getSubmissionById(String id);
  Future<FormSubmissionEntity> submitForm({
    required String formId,
    String? taskId,
    required Map<String, dynamic> data,
    LocationCoordinates? location,
  });
}
