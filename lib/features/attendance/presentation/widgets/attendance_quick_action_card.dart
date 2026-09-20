import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../controllers/attendance_controller.dart';
import 'attendance_status_badge.dart';

class AttendanceQuickActionCard extends ConsumerWidget {
  const AttendanceQuickActionCard({super.key});

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(todayAttendanceNotifierProvider);
    final notifier = ref.read(todayAttendanceNotifierProvider.notifier);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: state.isCheckedIn
              ? AppColors.success.withOpacity(0.5)
              : AppColors.border,
          width: state.isCheckedIn ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (state.isCheckedIn
                                  ? AppColors.success
                                  : AppColors.primary)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          state.isCheckedIn
                              ? Icons.timer_outlined
                              : Icons.how_to_reg_outlined,
                          color: state.isCheckedIn
                              ? AppColors.success
                              : AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Daily Attendance',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              state.isCompleted
                                  ? 'Shift Completed'
                                  : state.isCheckedIn
                                      ? 'Active Work Shift'
                                      : 'Not Checked In',
                              style: const TextStyle(
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
                if (state.attendance != null)
                  AttendanceStatusBadge(status: state.attendance!.status),
              ],
            ),
            const SizedBox(height: 16),

            // Error banner if any
            if (state.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 16, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(fontSize: 12, color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Body Content based on state
            if (state.isNotCheckedIn) ...[
              const Text(
                'Start your day by logging your check-in with verified GPS coordinates.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              AppButton(
                key: const Key('attendance_checkin_button'),
                label: state.isActionInProgress ? 'Checking In...' : 'Check In Now',
                isLoading: state.isActionInProgress,
                icon: Icons.login_rounded,
                onPressed: state.isActionInProgress
                    ? null
                    : () async {
                        final success = await notifier.checkIn();
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Checked in successfully with verified GPS!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
              ),
            ] else if (state.isCheckedIn) ...[
              // Active shift counter
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Text(
                      'ELAPSED WORKING TIME',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatDuration(state.elapsedDuration),
                      key: const Key('attendance_timer_display'),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 16,
                      runSpacing: 4,
                      alignment: WrapAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time, size: 14, color: AppColors.textTertiary),
                            const SizedBox(width: 4),
                            Text(
                              'In: ${state.attendance!.formattedCheckInTime}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.gps_fixed, size: 14, color: AppColors.textTertiary),
                            const SizedBox(width: 4),
                            Text(
                              '${state.attendance!.checkInLatitude.toStringAsFixed(4)}, ${state.attendance!.checkInLongitude.toStringAsFixed(4)}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                key: const Key('attendance_checkout_button'),
                label: state.isActionInProgress ? 'Checking Out...' : 'Check Out Now',
                isLoading: state.isActionInProgress,
                icon: Icons.logout_rounded,
                customColor: AppColors.warning,
                onPressed: state.isActionInProgress
                    ? null
                    : () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Confirm Check Out'),
                            content: const Text(
                              'Are you sure you want to end your work shift? Your total working hours will be calculated.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
                                child: const Text('Confirm Check Out'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          final success = await notifier.checkOut();
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Checked out successfully! Shift recorded.'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        }
                      },
              ),
            ] else ...[
              // Shift completed state
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: AppColors.success, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Total Worked: ${state.attendance!.formattedDuration}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      runSpacing: 4,
                      children: [
                        Text(
                          'In: ${state.attendance!.formattedCheckInTime}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        if (state.attendance!.formattedCheckOutTime != null)
                          Text(
                            'Out: ${state.attendance!.formattedCheckOutTime}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
