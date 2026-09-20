import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/technician_performance.dart';

class TechnicianPerformanceList extends StatelessWidget {
  final List<TechnicianPerformance> technicians;
  final ValueChanged<String>? onTechnicianTap;

  const TechnicianPerformanceList({
    super.key,
    required this.technicians,
    this.onTechnicianTap,
  });

  @override
  Widget build(BuildContext context) {
    if (technicians.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: const Text(
          'No technician activity recorded for selected range.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      );
    }

    return Column(
      children: technicians.asMap().entries.map((entry) {
        final index = entry.key;
        final tech = entry.value;
        return _buildTechCard(context, index + 1, tech);
      }).toList(),
    );
  }

  Widget _buildTechCard(BuildContext context, int rank, TechnicianPerformance tech) {
    final rankColor = rank == 1
        ? const Color(0xFFD4AF37) // Gold
        : rank == 2
            ? const Color(0xFFA0A0A0) // Silver
            : rank == 3
                ? const Color(0xFFCD7F32) // Bronze
                : AppColors.textTertiary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTechnicianTap != null ? () => onTechnicianTap!(tech.userId) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Rank, Avatar, Name & Completion Rate Badge
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: rankColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '#$rank',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: rankColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.roleManagerBg,
                    child: Text(
                      tech.userName.isNotEmpty ? tech.userName[0].toUpperCase() : 'T',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.roleManager,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tech.userName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: tech.completionRate >= 90
                          ? AppColors.successLight
                          : tech.completionRate >= 75
                              ? AppColors.roleManagerBg
                              : AppColors.warningLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${tech.completionRate.toStringAsFixed(1)}% Done',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: tech.completionRate >= 90
                            ? AppColors.success
                            : tech.completionRate >= 75
                                ? AppColors.roleManager
                                : AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Metrics Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSubMetric(
                    label: 'Tasks',
                    value: '${tech.completedTasksCount} / ${tech.assignedTasksCount}',
                    icon: Icons.assignment_outlined,
                  ),
                  _buildSubMetric(
                    label: 'On-Time',
                    value: '${tech.onTimeRate.toStringAsFixed(0)}%',
                    icon: Icons.schedule_rounded,
                  ),
                  _buildSubMetric(
                    label: 'Visits',
                    value: '${tech.totalVisitsCount} (${tech.formattedAvgVisitDuration})',
                    icon: Icons.location_on_outlined,
                  ),
                  _buildSubMetric(
                    label: 'Hours',
                    value: tech.formattedWorkHours,
                    icon: Icons.timelapse_rounded,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubMetric({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: AppColors.textTertiary),
            const SizedBox(width: 3),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
