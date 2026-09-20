import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../customers/domain/entities/location_entity.dart';
import '../../../customers/presentation/controllers/customer_controller.dart';
import '../../../forms/presentation/controllers/forms_controller.dart';
import '../../../forms/presentation/widgets/task_form_execution_card.dart';
import '../../../visits/presentation/widgets/gps_visit_execution_card.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/task_status.dart';
import '../controllers/task_controller.dart';
import '../widgets/task_priority_badge.dart';
import '../widgets/task_status_badge.dart';

final _taskLocationProvider =
    FutureProvider.family<LocationEntity?, String?>((ref, locationId) async {
  if (locationId == null) return null;
  final repo = ref.watch(customerRepositoryProvider);
  try {
    return await repo.getLocationDetail(locationId);
  } catch (_) {
    return null;
  }
});

class TaskDetailScreen extends ConsumerWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  void _showStatusDialog(BuildContext context, WidgetRef ref, TaskEntity task) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Update Task Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: TaskStatus.values.map((status) {
            final isCurrent = status == task.status;
            return ListTile(
              title: Text(status.label),
              leading: Icon(
                isCurrent ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isCurrent ? AppColors.primary : AppColors.textTertiary,
              ),
              onTap: () {
                Navigator.pop(dialogCtx);
                ref
                    .read(taskDetailNotifierProvider(taskId).notifier)
                    .updateStatus(status);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showReassignDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Reassign Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const CircleAvatar(child: Text('DM')),
              title: const Text('David Miller (Technician)'),
              subtitle: const Text('usr-emp-003'),
              onTap: () {
                Navigator.pop(dialogCtx);
                ref
                    .read(taskDetailNotifierProvider(taskId).notifier)
                    .assignTask('usr-emp-003');
              },
            ),
            ListTile(
              leading: const CircleAvatar(child: Text('MV')),
              title: const Text('Marcus Vance (Manager)'),
              subtitle: const Text('usr-manager-002'),
              onTap: () {
                Navigator.pop(dialogCtx);
                ref
                    .read(taskDetailNotifierProvider(taskId).notifier)
                    .assignTask('usr-manager-002');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(taskDetailNotifierProvider(taskId));
    final currentUser = ref.watch(currentUserProvider);
    final dateFormat = DateFormat('EEE, MMM d, yyyy • h:mm a');

    if (detailState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Task Details')),
        body: const LoadingView(message: 'Loading task details...'),
      );
    }

    if (detailState.errorMessage != null && detailState.task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Task Details')),
        body: ErrorStateView(
          title: 'Failed to load task',
          message: detailState.errorMessage!,
          onRetry: () =>
              ref.read(taskDetailNotifierProvider(taskId).notifier).loadTask(),
        ),
      );
    }

    final task = detailState.task!;
    final locationAsync = ref.watch(_taskLocationProvider(task.locationId));
    final formSubmissions = ref.watch(taskFormSubmissionsNotifierProvider(task.id)).submissions;
    final hasCompletedForm = formSubmissions.isNotEmpty;
    final isEmployee = currentUser?.role.isEmployee ?? false;
    final canManage = currentUser?.role.canCreateTasks ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          if (canManage)
            IconButton(
              icon: const Icon(Icons.swap_horiz_rounded),
              tooltip: 'Reassign Task',
              onPressed: () => _showReassignDialog(context, ref),
            ),
          if (canManage)
            IconButton(
              icon: const Icon(Icons.edit_note_rounded),
              tooltip: 'Change Status',
              onPressed: () => _showStatusDialog(context, ref, task),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TaskPriorityBadge(priority: task.priority),
                      TaskStatusBadge(status: task.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (task.description != null && task.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      task.description!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Location & Customer info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.business_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Customer / Client', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            Text(
                              task.customerName ?? 'Not specified',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: AppColors.secondary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Execution Site', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            Text(
                              task.locationName ?? 'Not specified',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Assignee & Schedules
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, color: AppColors.roleManager, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Assigned Field Employee', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            Text(
                              task.assignedToUserName ?? 'Unassigned',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (task.scheduledStart != null) ...[
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded, color: AppColors.textTertiary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Scheduled Window', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              Text(
                                '${dateFormat.format(task.scheduledStart!)}${task.scheduledEnd != null ? ' - ${DateFormat('h:mm a').format(task.scheduledEnd!)}' : ''}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (task.actualStart != null) ...[
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.play_circle_outline, color: AppColors.secondary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Actual Execution Time', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              Text(
                                'Started: ${dateFormat.format(task.actualStart!)}${task.actualEnd != null ? '\nCompleted: ${dateFormat.format(task.actualEnd!)}' : ''}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Proof of Work Verification Box (PRD Section 10)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mandatory Proof Requirements',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildRequirementRow(
                    icon: Icons.pin_drop,
                    title: 'GPS Location Verification',
                    isRequired: task.requiresGps,
                    isSatisfied: task.isInProgress || task.isCompleted,
                  ),
                  const SizedBox(height: 8),
                  _buildRequirementRow(
                    icon: Icons.camera_alt,
                    title: 'Before & After Photos',
                    isRequired: task.requiresPhoto,
                    isSatisfied: task.isCompleted,
                  ),
                  const SizedBox(height: 8),
                  _buildRequirementRow(
                    icon: Icons.description,
                    title: 'Service Checklist Form',
                    isRequired: task.requiresForm,
                    isSatisfied: hasCompletedForm || task.isCompleted,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Service Checklist Form Execution (PRD Sections 9, 24, 25, 27)
            if (task.requiresForm) ...[
              TaskFormExecutionCard(
                taskId: task.id,
                taskTitle: task.title,
                onFormSubmitted: () {
                  ref.read(taskDetailNotifierProvider(taskId).notifier).loadTask();
                },
              ),
              const SizedBox(height: 16),
            ],

            // Field GPS Verification & Site Visit (PRD Sections 6, 8, 10, 27)
            if (task.requiresGps || task.locationId != null || task.locationName != null) ...[
              GpsVisitExecutionCard(
                taskId: task.id,
                targetLocation: locationAsync.valueOrNull,
                onVisitUpdated: () {
                  ref.read(taskDetailNotifierProvider(taskId).notifier).loadTask();
                },
              ),
              const SizedBox(height: 16),
            ],

            // Notes
            if (task.notes != null && task.notes!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF7E0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.notes_rounded, size: 18, color: AppColors.accent),
                        SizedBox(width: 8),
                        Text('Dispatch & Site Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(task.notes!, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Action Buttons
            if (task.canStart && (isEmployee || canManage)) ...[
              AppButton(
                label: 'Start Field Task',
                icon: Icons.play_arrow_rounded,
                variant: AppButtonVariant.primary,
                isLoading: detailState.isUpdating,
                onPressed: () {
                  ref.read(taskDetailNotifierProvider(taskId).notifier).startTask();
                },
              ),
              const SizedBox(height: 12),
            ],

            if (task.canComplete && (isEmployee || canManage)) ...[
              AppButton(
                label: 'Complete Task & Submit Proof',
                icon: Icons.check_circle_outline_rounded,
                variant: AppButtonVariant.secondary,
                isLoading: detailState.isUpdating,
                onPressed: () {
                  ref.read(taskDetailNotifierProvider(taskId).notifier).completeTask();
                },
              ),
              const SizedBox(height: 12),
            ],

            if (task.isCompleted) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified, color: AppColors.secondary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Task Successfully Completed',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
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

  Widget _buildRequirementRow({
    required IconData icon,
    required String title,
    required bool isRequired,
    required bool isSatisfied,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isRequired ? AppColors.primary : AppColors.textTertiary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: isRequired ? AppColors.textPrimary : AppColors.textTertiary,
              decoration: isRequired ? null : TextDecoration.lineThrough,
            ),
          ),
        ),
        if (isRequired) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isSatisfied ? AppColors.secondaryLight : const Color(0xFFF1F3F4),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isSatisfied ? 'Satisfied' : 'Mandatory',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isSatisfied ? AppColors.secondary : AppColors.textSecondary,
              ),
            ),
          ),
        ] else ...[
          const Text('Optional', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
        ],
      ],
    );
  }
}
