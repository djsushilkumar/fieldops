import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/operations_metrics.dart';

class TaskDistributionCard extends StatelessWidget {
  final OperationsMetrics metrics;

  const TaskDistributionCard({
    super.key,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    final total = metrics.totalTasksToday;
    final assigned = metrics.assignedTasks;
    final inProgress = metrics.inProgressTasks;
    final completed = metrics.completedTasksToday;
    final overdue = metrics.overdueTasks;

    final assignedPct = total > 0 ? (assigned / total) : 0.0;
    final inProgressPct = total > 0 ? (inProgress / total) : 0.0;
    final completedPct = total > 0 ? (completed / total) : 0.0;
    final overduePct = total > 0 ? (overdue / total) : 0.0;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 0.8),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.pie_chart_rounded, size: 20, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Task Status Distribution',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '$total Total Tasks',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Segmented Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 12,
                child: total == 0
                    ? Container(color: AppColors.border)
                    : Row(
                        children: [
                          if (completed > 0)
                            Expanded(
                              flex: (completedPct * 1000).round(),
                              child: Container(color: AppColors.secondary),
                            ),
                          if (inProgress > 0)
                            Expanded(
                              flex: (inProgressPct * 1000).round(),
                              child: Container(color: AppColors.accent),
                            ),
                          if (assigned > 0)
                            Expanded(
                              flex: (assignedPct * 1000).round(),
                              child: Container(color: AppColors.primary),
                            ),
                          if (overdue > 0)
                            Expanded(
                              flex: (overduePct * 1000).round(),
                              child: Container(color: AppColors.error),
                            ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Legend Grid
            Row(
              children: [
                Expanded(
                  child: _buildLegendItem(
                    label: 'Completed',
                    count: completed,
                    percent: (completedPct * 100).round(),
                    color: AppColors.secondary,
                  ),
                ),
                Expanded(
                  child: _buildLegendItem(
                    label: 'In Progress',
                    count: inProgress,
                    percent: (inProgressPct * 100).round(),
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildLegendItem(
                    label: 'Assigned',
                    count: assigned,
                    percent: (assignedPct * 100).round(),
                    color: AppColors.primary,
                  ),
                ),
                Expanded(
                  child: _buildLegendItem(
                    label: 'Overdue',
                    count: overdue,
                    percent: (overduePct * 100).round(),
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem({
    required String label,
    required int count,
    required int percent,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          '$count ($percent%)',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
