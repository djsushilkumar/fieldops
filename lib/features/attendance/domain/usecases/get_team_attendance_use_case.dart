import '../entities/attendance_entity.dart';
import '../repositories/attendance_repository.dart';

class GetTeamAttendanceUseCase {
  final AttendanceRepository _repository;

  GetTeamAttendanceUseCase(this._repository);

  Future<List<AttendanceEntity>> call({
    required String organizationId,
    required DateTime date,
  }) {
    return _repository.getTeamAttendance(
      organizationId: organizationId,
      date: date,
    );
  }
}
