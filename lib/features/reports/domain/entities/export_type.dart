enum ExportType {
  tasks,
  visits,
  attendance,
  technicians,
  executiveSummary;

  String get displayName {
    switch (this) {
      case ExportType.tasks:
        return 'Tasks & Work Orders';
      case ExportType.visits:
        return 'Visits & GPS Check-ins';
      case ExportType.attendance:
        return 'Timesheets & Attendance';
      case ExportType.technicians:
        return 'Technician Performance';
      case ExportType.executiveSummary:
        return 'Executive Operations Summary';
    }
  }

  String get filePrefix {
    switch (this) {
      case ExportType.tasks:
        return 'tasks_report';
      case ExportType.visits:
        return 'visits_report';
      case ExportType.attendance:
        return 'attendance_report';
      case ExportType.technicians:
        return 'technician_performance';
      case ExportType.executiveSummary:
        return 'executive_summary';
    }
  }

  String get description {
    switch (this) {
      case ExportType.tasks:
        return 'All tasks matching selected date range with priority, assignees, scheduled vs actual timings.';
      case ExportType.visits:
        return 'Customer site check-ins and check-outs with GPS coordinates and durations.';
      case ExportType.attendance:
        return 'Daily staff check-ins, check-outs, total shift hours, and working status.';
      case ExportType.technicians:
        return 'Per-technician ranking, task completion %, on-time arrival %, and field hours.';
      case ExportType.executiveSummary:
        return 'Aggregated KPIs and operational performance metrics across the entire organization.';
    }
  }
}
