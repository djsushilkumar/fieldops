import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../controllers/attendance_controller.dart';
import '../widgets/attendance_history_card.dart';

class MyAttendanceHistoryScreen extends ConsumerWidget {
  const MyAttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(attendanceHistoryNotifierProvider);
    final notifier = ref.read(attendanceHistoryNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Attendance History'),
      ),
      body: RefreshIndicator(
        onRefresh: () => notifier.loadHistory(),
        child: _buildBody(context, state, notifier),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AttendanceHistoryState state,
    AttendanceHistoryNotifier notifier,
  ) {
    if (state.status == AttendanceHistoryStatus.loading && state.records.isEmpty) {
      return const LoadingView(message: 'Loading attendance records...');
    }

    if (state.status == AttendanceHistoryStatus.error && state.records.isEmpty) {
      return ErrorStateView(
        message: state.errorMessage ?? 'Failed to load attendance history',
        onRetry: () => notifier.loadHistory(),
      );
    }

    if (state.records.isEmpty) {
      return const EmptyStateView(
        icon: Icons.event_note_outlined,
        title: 'No Attendance Records Found',
        description: 'Your daily check-in and check-out records will appear here.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary Metrics Bar
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                title: 'Days Present',
                value: '${state.totalDaysPresent}',
                icon: Icons.check_circle_outline,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                title: 'Total Hours',
                value: state.formattedTotalHours,
                icon: Icons.schedule,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        const Text(
          'Recent Activity',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),

        ...state.records.map((r) => AttendanceHistoryCard(attendance: r)),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
