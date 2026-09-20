import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../domain/entities/attendance_status.dart';
import '../controllers/attendance_controller.dart';
import '../widgets/attendance_history_card.dart';

class TeamAttendanceScreen extends ConsumerWidget {
  const TeamAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(teamAttendanceNotifierProvider);
    final notifier = ref.read(teamAttendanceNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
      ),
      body: RefreshIndicator(
        onRefresh: () => notifier.loadTeamAttendance(),
        child: Column(
          children: [
            // Date Selector Bar
            _DateSelectorBar(
              selectedDate: state.selectedDate,
              onPrevious: () {
                notifier.selectDate(
                  state.selectedDate.subtract(const Duration(days: 1)),
                );
              },
              onNext: () {
                notifier.selectDate(
                  state.selectedDate.add(const Duration(days: 1)),
                );
              },
              onPickDate: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: state.selectedDate,
                  firstDate: DateTime(2025),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  notifier.selectDate(picked);
                }
              },
            ),

            // Statistics Metrics Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _StatusCountCard(
                      label: 'Present',
                      count: state.presentCount,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatusCountCard(
                      label: 'Half Day',
                      count: state.halfDayCount,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatusCountCard(
                      label: 'On Leave',
                      count: state.onLeaveCount,
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatusCountCard(
                      label: 'Total',
                      count: state.totalEmployees,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Status Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _FilterChipItem(
                    label: 'All (${state.records.length})',
                    isSelected: state.statusFilter == null,
                    onSelected: () => notifier.setFilter(null),
                  ),
                  _FilterChipItem(
                    label: 'Present (${state.presentCount})',
                    isSelected: state.statusFilter == AttendanceStatus.present,
                    onSelected: () => notifier.setFilter(AttendanceStatus.present),
                  ),
                  _FilterChipItem(
                    label: 'Half Day (${state.halfDayCount})',
                    isSelected: state.statusFilter == AttendanceStatus.halfDay,
                    onSelected: () => notifier.setFilter(AttendanceStatus.halfDay),
                  ),
                  _FilterChipItem(
                    label: 'On Leave (${state.onLeaveCount})',
                    isSelected: state.statusFilter == AttendanceStatus.onLeave,
                    onSelected: () => notifier.setFilter(AttendanceStatus.onLeave),
                  ),
                ],
              ),
            ),
            const Divider(height: 16),

            // Main Records Body
            Expanded(
              child: _buildList(context, state, notifier),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    TeamAttendanceState state,
    TeamAttendanceNotifier notifier,
  ) {
    if (state.status == TeamAttendanceStatus.loading && state.records.isEmpty) {
      return const LoadingView(message: 'Loading team attendance records...');
    }

    if (state.status == TeamAttendanceStatus.error && state.records.isEmpty) {
      return ErrorStateView(
        message: state.errorMessage ?? 'Failed to load team attendance',
        onRetry: () => notifier.loadTeamAttendance(),
      );
    }

    final filtered = state.filteredRecords;

    if (filtered.isEmpty) {
      return const EmptyStateView(
        icon: Icons.group_outlined,
        title: 'No Team Attendance',
        description: 'No employee attendance logged for the selected date or filter.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final attendance = filtered[index];
        return AttendanceHistoryCard(
          attendance: attendance,
          showEmployeeName: true,
        );
      },
    );
  }
}

class _DateSelectorBar extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPickDate;

  const _DateSelectorBar({
    required this.selectedDate,
    required this.onPrevious,
    required this.onNext,
    required this.onPickDate,
  });

  bool get _isToday {
    final now = DateTime.now();
    return selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final formatted = _isToday
        ? 'Today, ${DateFormat('MMM d').format(selectedDate)}'
        : DateFormat('EEE, MMM d, yyyy').format(selectedDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous Day',
            onPressed: onPrevious,
          ),
          InkWell(
            onTap: onPickDate,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    formatted,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next Day',
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _StatusCountCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatusCountCard({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChipItem({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
