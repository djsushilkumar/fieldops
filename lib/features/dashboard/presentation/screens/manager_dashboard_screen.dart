import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../notifications/presentation/widgets/notification_badge_icon.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/activity_stream_card.dart';
import '../widgets/metric_summary_card.dart';
import '../widgets/task_distribution_card.dart';
import '../widgets/technician_geo_radar_card.dart';

class ManagerDashboardScreen extends ConsumerWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardControllerProvider);
    final controller = ref.read(dashboardControllerProvider.notifier);
    final metrics = state.metrics;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Team Field Dispatch',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Active Shift & Technician Operations',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          const NotificationBadgeIcon(),
          IconButton(
            key: const Key('manager_dashboard_refresh_button'),
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
            tooltip: 'Refresh',
            onPressed: () => controller.refresh(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: state.isLoading && state.technicians.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => controller.refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overdue alert banner if any
                    if (metrics.overdueTasks > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.error.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.alarm_on_rounded, color: AppColors.error, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${metrics.overdueTasks} tasks require attention or re-assignment.',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Top 3 Manager KPI Cards
                    Row(
                      children: [
                        Expanded(
                          child: MetricSummaryCard(
                            title: 'Active Techs',
                            value: '${metrics.onDutyTechnicians}',
                            subtitle: '${metrics.idleTechnicians} on standby',
                            icon: Icons.engineering_rounded,
                            color: AppColors.roleManager,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: MetricSummaryCard(
                            title: 'In Progress',
                            value: '${metrics.inProgressTasks}',
                            subtitle: '${metrics.completedTasksToday} done today',
                            icon: Icons.pending_actions_rounded,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: MetricSummaryCard(
                            title: 'Proofs Logged',
                            value: '${metrics.totalProofsUploadedToday}',
                            subtitle: '${metrics.proofComplianceRate.round()}% pass',
                            icon: Icons.verified_rounded,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Quick Dispatch Actions
                    Card(
                      elevation: 0.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildQuickActionButton(
                              icon: Icons.add_task_rounded,
                              label: 'Assign Task',
                              color: AppColors.primary,
                              onTap: () => context.push('/tasks/create'),
                            ),
                            _buildQuickActionButton(
                              icon: Icons.person_add_rounded,
                              label: 'Add Client',
                              color: AppColors.secondary,
                              onTap: () => context.push('/customers/create'),
                            ),
                            _buildQuickActionButton(
                              icon: Icons.sync_rounded,
                              label: 'Sync Status',
                              color: AppColors.roleAdmin,
                              onTap: () => context.push('/sync'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Live Fleet Geo Radar
                    TechnicianGeoRadarCard(
                      technicians: state.technicians,
                      onRefresh: () => controller.refresh(),
                    ),
                    const SizedBox(height: 16),

                    // Task Distribution
                    TaskDistributionCard(metrics: metrics),
                    const SizedBox(height: 16),

                    // Activity Audit Stream
                    ActivityStreamCard(logs: state.activityLogs),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
