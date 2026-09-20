import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../../attendance/domain/entities/attendance_entity.dart';
import '../../../attendance/domain/entities/attendance_status.dart';
import '../../../tasks/domain/entities/task_entity.dart';
import '../../../tasks/domain/entities/task_priority.dart';
import '../../../tasks/domain/entities/task_status.dart';
import '../../../visits/domain/entities/visit_entity.dart';
import '../../domain/entities/report_date_range.dart';
import '../models/field_operations_report_model.dart';
import '../models/technician_performance_model.dart';

abstract class ReportsRemoteDataSource {
  Future<FieldOperationsReportModel> getOperationsReport({
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

class SupabaseReportsRemoteDataSource implements ReportsRemoteDataSource {
  final supa.SupabaseClient client;

  SupabaseReportsRemoteDataSource(this.client);

  @override
  Future<FieldOperationsReportModel> getOperationsReport({
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

    final completedVisits = visits.where((v) => v.isCompleted).length;
    final activeVisits = visits.where((v) => v.isActive).length;
    final totalVisitMinutes = visits.fold<int>(0, (sum, v) => sum + (v.durationMinutes ?? 0));
    final avgVisitMins = completedVisits > 0 ? (totalVisitMinutes / completedVisits) : 0.0;

    final uniqueCustomers = visits
        .map((v) => v.customerName ?? v.locationName ?? '')
        .where((name) => name.isNotEmpty)
        .toSet()
        .length;

    final totalWorkMinutes = attendance.fold<int>(0, (sum, a) => sum + (a.totalMinutes ?? a.workingDuration.inMinutes));
    final totalHours = totalWorkMinutes / 60.0;

    final techIds = <String>{
      ...tasks.map((t) => t.assignedToUserId).whereType<String>(),
      ...visits.map((v) => v.userId),
      ...attendance.map((a) => a.userId),
    };

    final breakdowns = <TechnicianPerformanceModel>[];
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

      breakdowns.add(TechnicianPerformanceModel(
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

    breakdowns.sort((a, b) => b.completedTasksCount.compareTo(a.completedTasksCount));

    return FieldOperationsReportModel(
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

  @override
  Future<List<TaskEntity>> getTasksForRange({
    required String organizationId,
    required DateTime startDate,
    required DateTime endDate,
    String? technicianId,
  }) async {
    try {
      var query = client
          .from('tasks')
          .select()
          .eq('organization_id', organizationId)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      if (technicianId != null) {
        query = query.eq('assigned_to', technicianId);
      }

      final response = await query;
      final list = response as List<dynamic>;
      return list.map((item) {
        final map = item as Map<String, dynamic>;
        return TaskEntity(
          id: map['id'] as String,
          organizationId: map['organization_id'] as String,
          title: map['title'] as String? ?? 'Untitled Task',
          priority: TaskPriority.fromString(map['priority'] as String? ?? 'MEDIUM'),
          status: TaskStatus.fromString(map['status'] as String? ?? 'ASSIGNED'),
          assignedToUserId: map['assigned_to'] as String?,
          customerName: map['customer_name'] as String?,
          createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
          updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<VisitEntity>> getVisitsForRange({
    required String organizationId,
    required DateTime startDate,
    required DateTime endDate,
    String? technicianId,
  }) async {
    try {
      var query = client
          .from('visits')
          .select()
          .eq('organization_id', organizationId)
          .gte('check_in_at', startDate.toIso8601String())
          .lte('check_in_at', endDate.toIso8601String());

      if (technicianId != null) {
        query = query.eq('user_id', technicianId);
      }

      final response = await query;
      final list = response as List<dynamic>;
      return list.map((item) {
        final map = item as Map<String, dynamic>;
        return VisitEntity(
          id: map['id'] as String,
          organizationId: map['organization_id'] as String,
          taskId: map['task_id'] as String?,
          userId: map['user_id'] as String,
          userName: map['user_name'] as String?,
          customerName: map['customer_name'] as String?,
          checkInAt: DateTime.tryParse(map['check_in_at'] as String? ?? '') ?? DateTime.now(),
          checkInLatitude: (map['check_in_latitude'] as num?)?.toDouble() ?? 0.0,
          checkInLongitude: (map['check_in_longitude'] as num?)?.toDouble() ?? 0.0,
          checkOutAt: map['check_out_at'] != null ? DateTime.tryParse(map['check_out_at'] as String) : null,
          createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
          updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<AttendanceEntity>> getAttendanceForRange({
    required String organizationId,
    required DateTime startDate,
    required DateTime endDate,
    String? technicianId,
  }) async {
    try {
      var query = client
          .from('attendance')
          .select()
          .eq('organization_id', organizationId)
          .gte('date', startDate.toIso8601String())
          .lte('date', endDate.toIso8601String());

      if (technicianId != null) {
        query = query.eq('user_id', technicianId);
      }

      final response = await query;
      final list = response as List<dynamic>;
      return list.map((item) {
        final map = item as Map<String, dynamic>;
        return AttendanceEntity(
          id: map['id'] as String,
          organizationId: map['organization_id'] as String,
          userId: map['user_id'] as String,
          userName: map['user_name'] as String?,
          userEmail: map['user_email'] as String?,
          date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
          checkInAt: DateTime.tryParse(map['check_in_at'] as String? ?? '') ?? DateTime.now(),
          checkInLatitude: (map['check_in_latitude'] as num?)?.toDouble() ?? 0.0,
          checkInLongitude: (map['check_in_longitude'] as num?)?.toDouble() ?? 0.0,
          checkOutAt: map['check_out_at'] != null ? DateTime.tryParse(map['check_out_at'] as String) : null,
          totalMinutes: map['total_minutes'] as int?,
          status: AttendanceStatus.fromCode(map['status'] as String? ?? 'PRESENT'),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}

class MockReportsRemoteDataSource implements ReportsRemoteDataSource {
  final List<TechnicianPerformanceModel> _mockTechs = const [
    TechnicianPerformanceModel(
      userId: 'tech-001',
      userName: 'Alex Rivera',
      assignedTasksCount: 16,
      completedTasksCount: 15,
      cancelledTasksCount: 0,
      inProgressTasksCount: 1,
      onTimeTasksCount: 14,
      completionRate: 93.8,
      onTimeRate: 93.3,
      totalVisitsCount: 18,
      avgVisitDurationMinutes: 42.5,
      totalWorkMinutes: 2280, // 38 hours
      attendanceDaysCount: 5,
    ),
    TechnicianPerformanceModel(
      userId: 'tech-002',
      userName: 'Elena Rostova',
      assignedTasksCount: 14,
      completedTasksCount: 13,
      cancelledTasksCount: 0,
      inProgressTasksCount: 1,
      onTimeTasksCount: 12,
      completionRate: 92.9,
      onTimeRate: 92.3,
      totalVisitsCount: 15,
      avgVisitDurationMinutes: 38.0,
      totalWorkMinutes: 2400, // 40 hours
      attendanceDaysCount: 5,
    ),
    TechnicianPerformanceModel(
      userId: 'tech-003',
      userName: 'Marcus Vance',
      assignedTasksCount: 12,
      completedTasksCount: 10,
      cancelledTasksCount: 1,
      inProgressTasksCount: 1,
      onTimeTasksCount: 9,
      completionRate: 83.3,
      onTimeRate: 90.0,
      totalVisitsCount: 13,
      avgVisitDurationMinutes: 50.2,
      totalWorkMinutes: 2160, // 36 hours
      attendanceDaysCount: 5,
    ),
    TechnicianPerformanceModel(
      userId: 'tech-004',
      userName: 'Chloe Bennett',
      assignedTasksCount: 11,
      completedTasksCount: 9,
      cancelledTasksCount: 0,
      inProgressTasksCount: 2,
      onTimeTasksCount: 8,
      completionRate: 81.8,
      onTimeRate: 88.9,
      totalVisitsCount: 11,
      avgVisitDurationMinutes: 44.6,
      totalWorkMinutes: 2100, // 35 hours
      attendanceDaysCount: 5,
    ),
    TechnicianPerformanceModel(
      userId: 'tech-005',
      userName: 'Samira Khan',
      assignedTasksCount: 10,
      completedTasksCount: 8,
      cancelledTasksCount: 1,
      inProgressTasksCount: 1,
      onTimeTasksCount: 7,
      completionRate: 80.0,
      onTimeRate: 87.5,
      totalVisitsCount: 9,
      avgVisitDurationMinutes: 47.3,
      totalWorkMinutes: 1920, // 32 hours
      attendanceDaysCount: 4,
    ),
  ];

  @override
  Future<FieldOperationsReportModel> getOperationsReport({
    required String organizationId,
    required DateTime startDate,
    required DateTime endDate,
    String? technicianId,
  }) async {
    // Simulate brief network latency
    await Future.delayed(const Duration(milliseconds: 150));

    var techs = _mockTechs;
    if (technicianId != null) {
      techs = techs.where((t) => t.userId == technicianId).toList();
    }

    final totalCreated = techs.fold<int>(0, (sum, t) => sum + t.assignedTasksCount);
    final totalCompleted = techs.fold<int>(0, (sum, t) => sum + t.completedTasksCount);
    final totalInProgress = techs.fold<int>(0, (sum, t) => sum + t.inProgressTasksCount);
    final totalCancelled = techs.fold<int>(0, (sum, t) => sum + t.cancelledTasksCount);
    final onTimeTasks = techs.fold<int>(0, (sum, t) => sum + t.onTimeTasksCount);
    final totalVisits = techs.fold<int>(0, (sum, t) => sum + t.totalVisitsCount);
    final totalWorkMins = techs.fold<int>(0, (sum, t) => sum + t.totalWorkMinutes);

    final completionRate = totalCreated > 0 ? (totalCompleted / totalCreated) * 100 : 0.0;
    final onTimeRate = totalCompleted > 0 ? (onTimeTasks / totalCompleted) * 100 : 0.0;
    final avgVisitMins = totalVisits > 0
        ? techs.fold<double>(0.0, (sum, t) => sum + (t.avgVisitDurationMinutes * t.totalVisitsCount)) / totalVisits
        : 0.0;

    return FieldOperationsReportModel(
      dateRange: ReportDateRange(preset: DateRangePreset.custom, startDate: startDate, endDate: endDate),
      totalTasksCreated: totalCreated,
      totalTasksCompleted: totalCompleted,
      totalTasksInProgress: totalInProgress,
      totalTasksCancelled: totalCancelled,
      taskCompletionRate: completionRate,
      onTimeCompletionRate: onTimeRate,
      totalVisits: totalVisits,
      completedVisits: totalVisits - 3,
      activeVisits: 3,
      avgVisitDurationMinutes: avgVisitMins,
      uniqueCustomersVisited: 14,
      totalAttendanceHours: totalWorkMins / 60.0,
      activeTechniciansCount: techs.length,
      technicianBreakdowns: techs,
      generatedAt: DateTime.now(),
    );
  }

  @override
  Future<List<TaskEntity>> getTasksForRange({
    required String organizationId,
    required DateTime startDate,
    required DateTime endDate,
    String? technicianId,
  }) async {
    final now = DateTime.now();
    final tasks = [
      TaskEntity(
        id: 'task-101',
        organizationId: organizationId,
        title: 'HVAC Air Handler Coil Replacement',
        priority: TaskPriority.high,
        status: TaskStatus.completed,
        assignedToUserId: 'tech-001',
        assignedToUserName: 'Alex Rivera',
        customerName: 'St. Jude Medical Center',
        scheduledStart: now.subtract(const Duration(hours: 6)),
        scheduledEnd: now.subtract(const Duration(hours: 4)),
        actualStart: now.subtract(const Duration(hours: 5, minutes: 55)),
        actualEnd: now.subtract(const Duration(hours: 4, minutes: 10)),
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(hours: 4)),
        notes: 'Coil replaced and pressure test passed at 120 PSI.',
      ),
      TaskEntity(
        id: 'task-102',
        organizationId: organizationId,
        title: 'Industrial Chiller Annual Audit',
        priority: TaskPriority.urgent,
        status: TaskStatus.completed,
        assignedToUserId: 'tech-002',
        assignedToUserName: 'Elena Rostova',
        customerName: 'Global Logistics Hub',
        scheduledStart: now.subtract(const Duration(hours: 8)),
        scheduledEnd: now.subtract(const Duration(hours: 5)),
        actualStart: now.subtract(const Duration(hours: 7, minutes: 50)),
        actualEnd: now.subtract(const Duration(hours: 5, minutes: 15)),
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(hours: 5)),
        notes: 'Chiller refrigerant levels optimal. No leaks detected.',
      ),
      TaskEntity(
        id: 'task-103',
        organizationId: organizationId,
        title: 'Emergency Generator Transfer Switch Inspection',
        priority: TaskPriority.urgent,
        status: TaskStatus.completed,
        assignedToUserId: 'tech-003',
        assignedToUserName: 'Marcus Vance',
        customerName: 'Apex Data Center',
        scheduledStart: now.subtract(const Duration(hours: 4)),
        scheduledEnd: now.subtract(const Duration(hours: 2)),
        actualStart: now.subtract(const Duration(hours: 3, minutes: 45)),
        actualEnd: now.subtract(const Duration(hours: 2, minutes: 05)),
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(hours: 2)),
        notes: 'Automatic transfer simulated successfully in under 8 seconds.',
      ),
      TaskEntity(
        id: 'task-104',
        organizationId: organizationId,
        title: 'Commercial Refrigeration Sensor Calibration',
        priority: TaskPriority.medium,
        status: TaskStatus.inProgress,
        assignedToUserId: 'tech-001',
        assignedToUserName: 'Alex Rivera',
        customerName: 'Fresh Farms Distribution',
        scheduledStart: now.subtract(const Duration(hours: 1)),
        scheduledEnd: now.add(const Duration(hours: 1)),
        actualStart: now.subtract(const Duration(minutes: 50)),
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(minutes: 50)),
        notes: 'Currently tuning temperature calibration offsets on bay 3.',
      ),
      TaskEntity(
        id: 'task-105',
        organizationId: organizationId,
        title: 'Rooftop Condenser Fan Motor Wiring',
        priority: TaskPriority.high,
        status: TaskStatus.completed,
        assignedToUserId: 'tech-004',
        assignedToUserName: 'Chloe Bennett',
        customerName: 'Summit Office Tower',
        scheduledStart: now.subtract(const Duration(hours: 9)),
        scheduledEnd: now.subtract(const Duration(hours: 7)),
        actualStart: now.subtract(const Duration(hours: 8, minutes: 50)),
        actualEnd: now.subtract(const Duration(hours: 7, minutes: 00)),
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(hours: 7)),
        notes: 'Motor wiring inspected and re-terminated. Thermal run ok.',
      ),
      TaskEntity(
        id: 'task-106',
        organizationId: organizationId,
        title: 'Fire Damper Actuator Battery Backup Test',
        priority: TaskPriority.low,
        status: TaskStatus.completed,
        assignedToUserId: 'tech-005',
        assignedToUserName: 'Samira Khan',
        customerName: 'Metro Transit Terminal',
        scheduledStart: now.subtract(const Duration(hours: 12)),
        scheduledEnd: now.subtract(const Duration(hours: 10)),
        actualStart: now.subtract(const Duration(hours: 11, minutes: 45)),
        actualEnd: now.subtract(const Duration(hours: 10, minutes: 15)),
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(hours: 10)),
        notes: 'All 12 fire dampers passed 90-minute battery backup release cycle.',
      ),
    ];

    if (technicianId != null) {
      return tasks.where((t) => t.assignedToUserId == technicianId).toList();
    }
    return tasks;
  }

  @override
  Future<List<VisitEntity>> getVisitsForRange({
    required String organizationId,
    required DateTime startDate,
    required DateTime endDate,
    String? technicianId,
  }) async {
    final now = DateTime.now();
    final visits = [
      VisitEntity(
        id: 'visit-201',
        organizationId: organizationId,
        taskId: 'task-101',
        userId: 'tech-001',
        userName: 'Alex Rivera',
        customerName: 'St. Jude Medical Center',
        locationName: 'Main Facility - Mechanical Room B',
        checkInAt: now.subtract(const Duration(hours: 5, minutes: 55)),
        checkInLatitude: 37.7749,
        checkInLongitude: -122.4194,
        checkOutAt: now.subtract(const Duration(hours: 4, minutes: 10)),
        checkOutLatitude: 37.7751,
        checkOutLongitude: -122.4190,
        notes: 'Coil replaced and signed by facility supervisor Mark.',
        createdAt: now.subtract(const Duration(hours: 6)),
        updatedAt: now.subtract(const Duration(hours: 4)),
      ),
      VisitEntity(
        id: 'visit-202',
        organizationId: organizationId,
        taskId: 'task-102',
        userId: 'tech-002',
        userName: 'Elena Rostova',
        customerName: 'Global Logistics Hub',
        locationName: 'Warehouse 4 Loading Dock',
        checkInAt: now.subtract(const Duration(hours: 7, minutes: 50)),
        checkInLatitude: 37.7833,
        checkInLongitude: -122.4167,
        checkOutAt: now.subtract(const Duration(hours: 5, minutes: 15)),
        checkOutLatitude: 37.7835,
        checkOutLongitude: -122.4165,
        notes: 'Full vibration analysis complete. Compressor bearings within spec.',
        createdAt: now.subtract(const Duration(hours: 8)),
        updatedAt: now.subtract(const Duration(hours: 5)),
      ),
      VisitEntity(
        id: 'visit-203',
        organizationId: organizationId,
        taskId: 'task-103',
        userId: 'tech-003',
        userName: 'Marcus Vance',
        customerName: 'Apex Data Center',
        locationName: 'Server Vault Level -1',
        checkInAt: now.subtract(const Duration(hours: 3, minutes: 45)),
        checkInLatitude: 37.7690,
        checkInLongitude: -122.4467,
        checkOutAt: now.subtract(const Duration(hours: 2, minutes: 05)),
        checkOutLatitude: 37.7692,
        checkOutLongitude: -122.4465,
        notes: 'Transfer switch relay timing confirmed at 7.4 seconds.',
        createdAt: now.subtract(const Duration(hours: 4)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
      VisitEntity(
        id: 'visit-204',
        organizationId: organizationId,
        taskId: 'task-104',
        userId: 'tech-001',
        userName: 'Alex Rivera',
        customerName: 'Fresh Farms Distribution',
        locationName: 'Cold Storage Room 2',
        checkInAt: now.subtract(const Duration(minutes: 50)),
        checkInLatitude: 37.7580,
        checkInLongitude: -122.4050,
        notes: 'Onsite currently running diagnostics.',
        createdAt: now.subtract(const Duration(hours: 1)),
        updatedAt: now.subtract(const Duration(minutes: 50)),
      ),
    ];

    if (technicianId != null) {
      return visits.where((v) => v.userId == technicianId).toList();
    }
    return visits;
  }

  @override
  Future<List<AttendanceEntity>> getAttendanceForRange({
    required String organizationId,
    required DateTime startDate,
    required DateTime endDate,
    String? technicianId,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final records = [
      AttendanceEntity(
        id: 'att-301',
        organizationId: organizationId,
        userId: 'tech-001',
        userName: 'Alex Rivera',
        userEmail: 'alex.rivera@fieldops.com',
        date: today,
        checkInAt: today.add(const Duration(hours: 7, minutes: 55)),
        checkInLatitude: 37.7749,
        checkInLongitude: -122.4194,
        checkOutAt: today.add(const Duration(hours: 16, minutes: 30)),
        totalMinutes: 515,
        status: AttendanceStatus.present,
      ),
      AttendanceEntity(
        id: 'att-302',
        organizationId: organizationId,
        userId: 'tech-002',
        userName: 'Elena Rostova',
        userEmail: 'elena.rostova@fieldops.com',
        date: today,
        checkInAt: today.add(const Duration(hours: 8, minutes: 02)),
        checkInLatitude: 37.7833,
        checkInLongitude: -122.4167,
        checkOutAt: today.add(const Duration(hours: 17, minutes: 00)),
        totalMinutes: 538,
        status: AttendanceStatus.present,
      ),
      AttendanceEntity(
        id: 'att-303',
        organizationId: organizationId,
        userId: 'tech-003',
        userName: 'Marcus Vance',
        userEmail: 'marcus.vance@fieldops.com',
        date: today,
        checkInAt: today.add(const Duration(hours: 8, minutes: 30)),
        checkInLatitude: 37.7690,
        checkInLongitude: -122.4467,
        totalMinutes: 480,
        status: AttendanceStatus.halfDay,
      ),
      AttendanceEntity(
        id: 'att-304',
        organizationId: organizationId,
        userId: 'tech-004',
        userName: 'Chloe Bennett',
        userEmail: 'chloe.bennett@fieldops.com',
        date: today,
        checkInAt: today.add(const Duration(hours: 7, minutes: 45)),
        checkInLatitude: 37.7580,
        checkInLongitude: -122.4050,
        checkOutAt: today.add(const Duration(hours: 16, minutes: 00)),
        totalMinutes: 495,
        status: AttendanceStatus.present,
      ),
    ];

    if (technicianId != null) {
      return records.where((a) => a.userId == technicianId).toList();
    }
    return records;
  }
}
