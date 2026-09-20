import '../entities/attendance_entity.dart';
import '../repositories/attendance_repository.dart';

class GetTodayAttendanceUseCase {
  final AttendanceRepository _repository;

  GetTodayAttendanceUseCase(this._repository);

  Future<AttendanceEntity?> call({required String userId}) {
    return _repository.getTodayAttendance(userId: userId);
  }
}
