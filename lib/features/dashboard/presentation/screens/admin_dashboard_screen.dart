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

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

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
              'FieldOps Command Center',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Executive Operations & Fleet Telemetry',
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
            key: const Key('admin_dashboard_refresh_button'),
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
            tooltip: 'Refresh Telemetry',
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
                    // Alerts banner if there are overdue tasks
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
                            const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${metrics.overdueTasks} Critical Tasks Overdue',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.error,
                                    ),
                                  ),
                                  const Text(
                                    'Immediate field supervisor intervention recommended.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Top 4 High-Impact KPI Cards in a 2x2 Grid
                    Row(
                      children: [
                        Expanded(
                          child: MetricSummaryCard(
                            title: 'Active Workforce',
                            value: '${metrics.onDutyTechnicians} / ${metrics.totalTechnicians}',
                            subtitle: '${metrics.idleTechnicians} idle staging',
                            icon: Icons.people_alt_rounded,
                            color: AppColors.roleManager,
                            badgeText: '${metrics.onDutyPercentage.round()}%',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MetricSummaryCard(
                            title: 'Tasks Today',
                            value: '${metrics.completedTasksToday} / ${metrics.totalTasksToday}',
                            subtitle: '${metrics.inProgressTasks} currently in progress',
                            icon: Icons.task_alt_rounded,
                            color: AppColors.secondary,
                            badgeText: '${metrics.taskCompletionRate.round()}%',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: MetricSummaryCard(
                            title: 'Completed Visits',
                            value: '${metrics.completedVisitsToday}',
                            subtitle: '100% geofence radius verified',
                            icon: Icons.place_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MetricSummaryCard(
                            title: 'Proof Compliance',
                            value: '${metrics.proofComplianceRate.toStringAsFixed(1)}%',
                            subtitle: '${metrics.totalProofsUploadedToday} photos & signatures',
                            icon: Icons.verified_rounded,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Quick Action Dispatch Bar
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
                              label: 'New Task',
                              color: AppColors.primary,
                              onTap: () => context.push('/tasks/create'),
                            ),
                            _buildQuickActionButton(
                              icon: Icons.person_add_rounded,
                              label: 'New Client',
                              color: AppColors.secondary,
                              onTap: () => context.push('/customers/create'),
                            ),
                            _buildQuickActionButton(
                              icon: Icons.assignment_outlined,
                              label: 'Forms',
                              color: AppColors.roleEmployee,
                              onTap: () => context.push('/forms'),
                            ),
                            _buildQuickActionButton(
                              icon: Icons.sync_rounded,
                              label: 'Sync Hub',
                              color: AppColors.roleAdmin,
                              onTap: () => context.push('/sync'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Task Status Distribution
                    TaskDistributionCard(metrics: metrics),
                    const SizedBox(height: 16),

                    // Live Fleet Geo-Radar Card
                    TechnicianGeoRadarCard(
                      technicians: state.technicians,
                      onRefresh: () => controller.refresh(),
                    ),
                    const SizedBox(height: 16),

                    // Live Operations Activity Stream
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
