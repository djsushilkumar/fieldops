import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/field_operations_report.dart';

class ReportKpiCard extends StatelessWidget {
  final FieldOperationsReport report;

  const ReportKpiCard({
    super.key,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Row 1: Task Completion & On-Time SLA
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Task Completion',
                value: report.formattedCompletionRate,
                subtitle: '${report.totalTasksCompleted} / ${report.totalTasksCreated} Tasks',
                icon: Icons.task_alt_rounded,
                color: AppColors.roleManager,
                bgColor: AppColors.roleManagerBg,
                progress: report.totalTasksCreated > 0
                    ? (report.totalTasksCompleted / report.totalTasksCreated).clamp(0.0, 1.0)
                    : 0.0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                title: 'On-Time SLA',
                value: report.formattedOnTimeRate,
                subtitle: 'Scheduled window compliance',
                icon: Icons.timer_outlined,
                color: Colors.teal,
                bgColor: Colors.teal.shade50,
                progress: (report.onTimeCompletionRate / 100).clamp(0.0, 1.0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Row 2: Customer Visits & Active Field Hours
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Customer Visits',
                value: report.totalVisits.toString(),
                subtitle: 'Avg ${report.formattedAvgVisitDuration}',
                icon: Icons.pin_drop_rounded,
                color: Colors.deepPurple,
                bgColor: Colors.deepPurple.shade50,
                badgeText: '${report.uniqueCustomersVisited} Sites',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                title: 'Field Hours',
                value: report.formattedTotalHours,
                subtitle: '${report.activeTechniciansCount} active techs',
                icon: Icons.access_time_filled_rounded,
                color: Colors.blueAccent,
                bgColor: Colors.blue.shade50,
                badgeText: 'Timesheets',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    double? progress,
    String? badgeText,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const Spacer(),
              if (badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textTertiary,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: color.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
