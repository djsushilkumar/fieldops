import '../../../../core/database/app_database.dart';
import '../../../../core/database/sqlite_database.dart';
import '../../../attendance/data/models/attendance_model.dart';
import '../../../attendance/domain/entities/attendance_entity.dart';
import '../../../tasks/data/models/task_model.dart';
import '../../../tasks/domain/entities/task_entity.dart';
import '../../../tasks/domain/entities/task_status.dart';
import '../../../visits/data/models/visit_model.dart';
import '../../../visits/domain/entities/visit_entity.dart';
import '../../domain/entities/field_operations_report.dart';
import '../../domain/entities/report_date_range.dart';
import '../../domain/entities/technician_performance.dart';

abstract class ReportsLocalDataSource {
  Future<FieldOperationsReport> getOperationsReport({
    required String organizationId,
    required DateTime startDate,
    required DateTime endDate,
    String? technicianId,
  });

  Future<List<TaskEntity>> getTasksForRange({
    required String organizationId,
    required DateTime startDate,
    required DateTime endDate,
    String? technicianId,
  });

  Future<List<VisitEntity>> getVisitsForRange({
    required String organizationId,
    required DateTime startDate,
    required DateTime endDate,
    String? technicianId,
  });

  Future<List<AttendanceEntity>> getAttendanceForRange({
    required String organizationId,
    required DateTime startDate,
    required DateTime endDate,
    String? technicianId,
  });
}

class ReportsLocalDataSourceImpl implements ReportsLocalDataSource {
  final SqliteDatabase db;

  ReportsLocalDataSourceImpl({required this.db});

  @override
  Future<List<TaskEntity>> getTasksForRange({
    required String organizationId,
    required DateTime startDate,
    required DateTime endDate,
    String? technicianId,
  }) async {
    final rows = await db.query(
      AppDatabase.tasksTable.name,
      where: 'organization_id = ?',
      whereArgs: [organizationId],
    );

    final tasks = rows.map((r) => TaskModel.fromJson(r).toEntity()).where((task) {
      final relevantDate = task.scheduledStart ?? task.createdAt;
      final inDate = relevantDate.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
          relevantDate.isBefore(endDate.add(const Duration(seconds: 1)));
      if (!inDate) return false;
      if (technicianId != null && task.assignedToUserId != technicianId) return false;
      return true;
    }).toList();

    return tasks;
  }

  @override
  Future<List<VisitEntity>> getVisitsForRange({
    required String organizationId,
    required DateTime startDate,
    required DateTime endDate,
    String? technicianId,
  }) async {
    final rows = await db.query(
      AppDatabase.visitsTable.name,
      where: 'organization_id = ?',
      whereArgs: [organizationId],
    );

    final visits = rows.map((r) => VisitModel.fromJson(r)).where((visit) {
      final inDate = visit.checkInAt.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
          visit.checkInAt.isBefore(endDate.add(const Duration(seconds: 1)));
      if (!inDate) return false;
      if (technicianId != null && visit.userId != technicianId) return false;
      return true;
    }).toList();

    return visits;
  }

  @override
  Future<List<AttendanceEntity>> getAttendanceForRange({
    required String organizationId,
    required DateTime startDate,
    required DateTime endDate,
    String? technicianId,
  }) async {
    final rows = await db.query(
      AppDatabase.attendanceTable.name,
      where: 'organization_id = ?',
      whereArgs: [organizationId],
    );

    final records = rows.map((r) => AttendanceModel.fromJson(r)).where((att) {
      final inDate = att.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          att.date.isBefore(endDate.add(const Duration(days: 1)));
      if (!inDate) return false;
      if (technicianId != null && att.userId != technicianId) return false;
      return true;
    }).toList();

    return records;
  }

  @override
  Future<FieldOperationsReport> getOperationsReport({
    required String organizationId,
    required DateTime startDate,
    required DateTime endDate,
    String? technicianId,
  }) async {
    final tasks = await getTasksForRange(
      organizationId: organizationId,
      startDate: startDate,
      endDate: endDate,
      technicianId: technicianId,
    );

    final visits = await getVisitsForRange(
      organizationId: organizationId,
      startDate: startDate,
      endDate: endDate,
      technicianId: technicianId,
    );

    final attendance = await getAttendanceForRange(
      organizationId: organizationId,
      startDate: startDate,
      endDate: endDate,
      technicianId: technicianId,
    );

    // Compute task counts
    final totalCreated = tasks.length;
    final totalCompleted = tasks.where((t) => t.status == TaskStatus.completed).length;
    final totalInProgress = tasks.where((t) => t.status == TaskStatus.inProgress).length;
    final totalCancelled = tasks.where((t) => t.status == TaskStatus.cancelled).length;

    final onTimeTasks = tasks.where((t) {
      if (t.actualEnd != null && t.scheduledEnd != null) {
        return t.actualEnd!.isBefore(t.scheduledEnd!) || t.actualEnd!.isAtSameMomentAs(t.scheduledEnd!);
      }
      return false;
    }).length;

    final completionRate = totalCreated > 0 ? (totalCompleted / totalCreated) * 100 : 0.0;
    final onTimeRate = totalCompleted > 0 ? (onTimeTasks / totalCompleted) * 100 : 0.0;

    // Compute visits
    final completedVisits = visits.where((v) => v.isCompleted).length;
    final activeVisits = visits.where((v) => v.isActive).length;
    final totalVisitMinutes = visits.fold<int>(0, (sum, v) => sum + (v.durationMinutes ?? 0));
    final avgVisitMins = completedVisits > 0 ? (totalVisitMinutes / completedVisits) : 0.0;

    final uniqueCustomers = visits
        .map((v) => v.customerName ?? v.locationName ?? '')
        .where((name) => name.isNotEmpty)
        .toSet()
        .length;

    // Compute attendance hours
    final totalWorkMinutes = attendance.fold<int>(0, (sum, a) => sum + (a.totalMinutes ?? a.workingDuration.inMinutes));
    final totalHours = totalWorkMinutes / 60.0;

    // Group by technician
    final techIds = <String>{
      ...tasks.map((t) => t.assignedToUserId).whereType<String>(),
      ...visits.map((v) => v.userId),
      ...attendance.map((a) => a.userId),
    };

    final breakdowns = <TechnicianPerformance>[];
    for (final id in techIds) {
      final techTasks = tasks.where((t) => t.assignedToUserId == id).toList();
      final techVisits = visits.where((v) => v.userId == id).toList();
      final techAtt = attendance.where((a) => a.userId == id).toList();

      final techCompleted = techTasks.where((t) => t.status == TaskStatus.completed).length;
      final techInProgress = techTasks.where((t) => t.status == TaskStatus.inProgress).length;
      final techCancelled = techTasks.where((t) => t.status == TaskStatus.cancelled).length;
      final techOnTime = techTasks.where((t) {
        if (t.actualEnd != null && t.scheduledEnd != null) {
          return t.actualEnd!.isBefore(t.scheduledEnd!) || t.actualEnd!.isAtSameMomentAs(t.scheduledEnd!);
        }
        return false;
      }).length;

      final techTotalVisitMins = techVisits.fold<int>(0, (sum, v) => sum + (v.durationMinutes ?? 0));
      final techCompletedVisits = techVisits.where((v) => v.isCompleted).length;
      final techWorkMins = techAtt.fold<int>(0, (sum, a) => sum + (a.totalMinutes ?? a.workingDuration.inMinutes));

      final name = techTasks.firstWhere((t) => t.assignedToUserName != null, orElse: () => techTasks.firstOrNull ?? tasks.first).assignedToUserName ??
          techVisits.firstOrNull?.userName ??
          techAtt.firstOrNull?.userName ??
          'Technician $id';

      breakdowns.add(TechnicianPerformance(
        userId: id,
        userName: name,
        assignedTasksCount: techTasks.length,
        completedTasksCount: techCompleted,
        inProgressTasksCount: techInProgress,
        cancelledTasksCount: techCancelled,
        onTimeTasksCount: techOnTime,
        completionRate: techTasks.isNotEmpty ? (techCompleted / techTasks.length) * 100 : 0.0,
        onTimeRate: techCompleted > 0 ? (techOnTime / techCompleted) * 100 : 0.0,
        totalVisitsCount: techVisits.length,
        avgVisitDurationMinutes: techCompletedVisits > 0 ? (techTotalVisitMins / techCompletedVisits) : 0.0,
        totalWorkMinutes: techWorkMins,
        attendanceDaysCount: techAtt.length,
      ));
    }

    // Sort technicians by completion count descending
    breakdowns.sort((a, b) => b.completedTasksCount.compareTo(a.completedTasksCount));

    return FieldOperationsReport(
      dateRange: ReportDateRange(preset: DateRangePreset.custom, startDate: startDate, endDate: endDate),
      totalTasksCreated: totalCreated,
      totalTasksCompleted: totalCompleted,
      totalTasksInProgress: totalInProgress,
      totalTasksCancelled: totalCancelled,
      taskCompletionRate: completionRate,
      onTimeCompletionRate: onTimeRate,
      totalVisits: visits.length,
      completedVisits: completedVisits,
      activeVisits: activeVisits,
      avgVisitDurationMinutes: avgVisitMins,
      uniqueCustomersVisited: uniqueCustomers,
      totalAttendanceHours: totalHours,
      activeTechniciansCount: techIds.length,
      technicianBreakdowns: breakdowns,
      generatedAt: DateTime.now(),
    );
  }
}
