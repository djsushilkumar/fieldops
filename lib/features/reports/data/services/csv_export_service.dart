import 'package:intl/intl.dart';
import '../../../attendance/domain/entities/attendance_entity.dart';
import '../../../tasks/domain/entities/task_entity.dart';
import '../../../visits/domain/entities/visit_entity.dart';
import '../../domain/entities/field_operations_report.dart';
import '../../domain/entities/technician_performance.dart';

class CsvExportService {
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  final DateFormat _dayFormat = DateFormat('yyyy-MM-dd');

  /// Escapes a single CSV cell according to RFC-4180 standard.
  static String escapeCell(dynamic value) {
    if (value == null) return '';
    final str = value.toString();

    // If string contains quote, comma, or newline, wrap in quotes and double internal quotes
    if (str.contains('"') || str.contains(',') || str.contains('\n') || str.contains('\r')) {
      final escaped = str.replaceAll('"', '""');
      return '"$escaped"';
    }
    return str;
  }

  /// Builds a CSV string from headers and rows with CRLF or LF line endings.
  String buildCsv({
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) {
    final buffer = StringBuffer();

    // Write header line
    buffer.writeln(headers.map(escapeCell).join(','));

    // Write row lines
    for (final row in rows) {
      buffer.writeln(row.map(escapeCell).join(','));
    }

    return buffer.toString();
  }

  /// Generates CSV for field tasks and work orders.
  String generateTasksCsv(List<TaskEntity> tasks) {
    final headers = [
      'Task ID',
      'Title',
      'Status',
      'Priority',
      'Assigned Technician',
      'Customer',
      'Location',
      'Scheduled Start',
      'Scheduled End',
      'Actual Start',
      'Actual End',
      'Duration (Mins)',
      'On Time',
      'Created At',
      'Notes',
    ];

    final rows = tasks.map((task) {
      int? durationMins;
      if (task.actualStart != null && task.actualEnd != null) {
        durationMins = task.actualEnd!.difference(task.actualStart!).inMinutes;
      }

      String onTime = 'N/A';
      if (task.actualEnd != null && task.scheduledEnd != null) {
        onTime = task.actualEnd!.isBefore(task.scheduledEnd!) ||
                task.actualEnd!.isAtSameMomentAs(task.scheduledEnd!)
            ? 'Yes'
            : 'No';
      }

      return [
        task.id,
        task.title,
        task.status.label,
        task.priority.label,
        task.assignedToUserName ?? task.assignedToUserId ?? 'Unassigned',
        task.customerName ?? task.customerId ?? '',
        task.locationName ?? task.locationId ?? '',
        task.scheduledStart != null ? _dateFormat.format(task.scheduledStart!) : '',
        task.scheduledEnd != null ? _dateFormat.format(task.scheduledEnd!) : '',
        task.actualStart != null ? _dateFormat.format(task.actualStart!) : '',
        task.actualEnd != null ? _dateFormat.format(task.actualEnd!) : '',
        durationMins?.toString() ?? '',
        onTime,
        _dateFormat.format(task.createdAt),
        task.notes ?? '',
      ];
    }).toList();

    return buildCsv(headers: headers, rows: rows);
  }

  /// Generates CSV for customer visits and GPS tracking check-ins.
  String generateVisitsCsv(List<VisitEntity> visits) {
    final headers = [
      'Visit ID',
      'Task ID',
      'Technician',
      'Customer / Site',
      'Check-in Time',
      'Check-in Latitude',
      'Check-in Longitude',
      'Check-out Time',
      'Check-out Latitude',
      'Check-out Longitude',
      'Duration (Mins)',
      'Status',
      'Notes',
    ];

    final rows = visits.map((visit) {
      return [
        visit.id,
        visit.taskId ?? '',
        visit.userName ?? visit.userId,
        visit.customerName ?? visit.locationName ?? '',
        _dateFormat.format(visit.checkInAt),
        visit.checkInLatitude.toStringAsFixed(6),
        visit.checkInLongitude.toStringAsFixed(6),
        visit.checkOutAt != null ? _dateFormat.format(visit.checkOutAt!) : '',
        visit.checkOutLatitude?.toStringAsFixed(6) ?? '',
        visit.checkOutLongitude?.toStringAsFixed(6) ?? '',
        visit.durationMinutes?.toString() ?? '',
        visit.isCompleted ? 'Completed' : 'In Progress',
        visit.notes ?? '',
      ];
    }).toList();

    return buildCsv(headers: headers, rows: rows);
  }

  /// Generates CSV for attendance and shift timesheets.
  String generateAttendanceCsv(List<AttendanceEntity> records) {
    final headers = [
      'Record ID',
      'Technician Name',
      'Technician Email',
      'Date',
      'Check-in Time',
      'Check-in Latitude',
      'Check-in Longitude',
      'Check-out Time',
      'Check-out Latitude',
      'Check-out Longitude',
      'Working Hours',
      'Total Minutes',
      'Status',
    ];

    final rows = records.map((record) {
      final hoursFormatted = record.formattedDuration;
      final totalMins = record.totalMinutes ?? record.workingDuration.inMinutes;

      return [
        record.id,
        record.userName ?? record.userId,
        record.userEmail ?? '',
        _dayFormat.format(record.date),
        _dateFormat.format(record.checkInAt),
        record.checkInLatitude.toStringAsFixed(6),
        record.checkInLongitude.toStringAsFixed(6),
        record.checkOutAt != null ? _dateFormat.format(record.checkOutAt!) : '',
        record.checkOutLatitude?.toStringAsFixed(6) ?? '',
        record.checkOutLongitude?.toStringAsFixed(6) ?? '',
        hoursFormatted,
        totalMins.toString(),
        record.status.label,
      ];
    }).toList();

    return buildCsv(headers: headers, rows: rows);
  }

  /// Generates CSV for technician performance ranking and metrics.
  String generateTechniciansCsv(List<TechnicianPerformance> technicians) {
    final headers = [
      'Technician ID',
      'Technician Name',
      'Assigned Tasks',
      'Completed Tasks',
      'In Progress Tasks',
      'Cancelled Tasks',
      'Completion Rate (%)',
      'On-Time Rate (%)',
      'Total Visits',
      'Avg Visit Duration (Mins)',
      'Total Field Hours',
      'Days Active',
    ];

    final rows = technicians.map((tech) {
      final hours = (tech.totalWorkMinutes / 60).toStringAsFixed(1);
      return [
        tech.userId,
        tech.userName,
        tech.assignedTasksCount.toString(),
        tech.completedTasksCount.toString(),
        tech.inProgressTasksCount.toString(),
        tech.cancelledTasksCount.toString(),
        tech.completionRate.toStringAsFixed(1),
        tech.onTimeRate.toStringAsFixed(1),
        tech.totalVisitsCount.toString(),
        tech.avgVisitDurationMinutes.toStringAsFixed(1),
        hours,
        tech.attendanceDaysCount.toString(),
      ];
    }).toList();

    return buildCsv(headers: headers, rows: rows);
  }

  /// Generates CSV for high-level executive operations summary.
  String generateExecutiveSummaryCsv(FieldOperationsReport report) {
    final headers = [
      'Metric',
      'Value',
      'Date Range',
      'Generated At',
    ];

    final dateRangeStr = report.dateRange.formattedRange;
    final generatedAtStr = _dateFormat.format(report.generatedAt);

    final rows = [
      ['Date Range Preset', report.dateRange.preset.displayName, dateRangeStr, generatedAtStr],
      ['Total Tasks Created', report.totalTasksCreated.toString(), dateRangeStr, generatedAtStr],
      ['Total Tasks Completed', report.totalTasksCompleted.toString(), dateRangeStr, generatedAtStr],
      ['Total Tasks In Progress', report.totalTasksInProgress.toString(), dateRangeStr, generatedAtStr],
      ['Total Tasks Cancelled', report.totalTasksCancelled.toString(), dateRangeStr, generatedAtStr],
      ['Task Completion Rate (%)', report.formattedCompletionRate, dateRangeStr, generatedAtStr],
      ['On-Time Completion Rate (%)', report.formattedOnTimeRate, dateRangeStr, generatedAtStr],
      ['Total Customer Visits', report.totalVisits.toString(), dateRangeStr, generatedAtStr],
      ['Completed Visits', report.completedVisits.toString(), dateRangeStr, generatedAtStr],
      ['Active / In-Flight Visits', report.activeVisits.toString(), dateRangeStr, generatedAtStr],
      ['Avg Visit Duration', report.formattedAvgVisitDuration, dateRangeStr, generatedAtStr],
      ['Unique Customers Visited', report.uniqueCustomersVisited.toString(), dateRangeStr, generatedAtStr],
      ['Active Field Technicians', report.activeTechniciansCount.toString(), dateRangeStr, generatedAtStr],
      ['Total Staff Clocked Hours', report.formattedTotalHours, dateRangeStr, generatedAtStr],
    ];

    return buildCsv(headers: headers, rows: rows);
  }
}
