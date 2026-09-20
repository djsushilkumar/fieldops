import '../entities/attendance_entity.dart';
import '../repositories/attendance_repository.dart';

class GetAttendanceHistoryUseCase {
  final AttendanceRepository _repository;

  GetAttendanceHistoryUseCase(this._repository);

  Future<List<AttendanceEntity>> call({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _repository.getMyAttendanceHistory(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
