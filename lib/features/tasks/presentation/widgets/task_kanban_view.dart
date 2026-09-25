import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/task_status.dart';
import '../controllers/task_controller.dart';
import 'task_priority_badge.dart';

class TaskKanbanView extends ConsumerWidget {
  final List<TaskEntity> tasks;
  final void Function(TaskEntity task)? onTaskTap;

  const TaskKanbanView({
    super.key,
    required this.tasks,
    this.onTaskTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todoTasks = tasks
        .where((t) => t.status == TaskStatus.assigned || t.status == TaskStatus.draft)
        .toList();
    final inProgressTasks = tasks
        .where((t) => t.status == TaskStatus.inProgress || t.status == TaskStatus.accepted)
        .toList();
    final completedTasks =
        tasks.where((t) => t.status == TaskStatus.completed).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKanbanColumn(
            context: context,
            ref: ref,
            title: 'To Do',
            statusTarget: TaskStatus.assigned,
            tasks: todoTasks,
            headerColor: AppColors.primary,
          ),
          const SizedBox(width: 12),
          _buildKanbanColumn(
            context: context,
            ref: ref,
            title: 'In Progress',
            statusTarget: TaskStatus.inProgress,
            tasks: inProgressTasks,
            headerColor: AppColors.secondary,
          ),
          const SizedBox(width: 12),
          _buildKanbanColumn(
            context: context,
            ref: ref,
            title: 'Completed',
            statusTarget: TaskStatus.completed,
            tasks: completedTasks,
            headerColor: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanColumn({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required TaskStatus statusTarget,
    required List<TaskEntity> tasks,
    required Color headerColor,
  }) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Column Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: headerColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: headerColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: TextStyle(
                      color: headerColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Cards List
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 520),
            child: tasks.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Text(
                        'No $title tasks',
                        style: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(8),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return _buildKanbanCard(context, ref, task);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanCard(BuildContext context, WidgetRef ref, TaskEntity task) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => onTaskTap?.call(task),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TaskPriorityBadge(priority: task.priority),
                  PopupMenuButton<TaskStatus>(
                    icon: const Icon(Icons.more_horiz, size: 18, color: AppColors.textTertiary),
                    tooltip: 'Move status',
                    onSelected: (newStatus) {
                      ref
                          .read(taskListNotifierProvider.notifier)
                          .updateTaskStatus(task.id, newStatus);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: TaskStatus.assigned,
                        child: Text('Move to To Do'),
                      ),
                      const PopupMenuItem(
                        value: TaskStatus.inProgress,
                        child: Text('Move to In Progress'),
                      ),
                      const PopupMenuItem(
                        value: TaskStatus.completed,
                        child: Text('Mark as Completed'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                task.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (task.customerName != null) ...[
                const SizedBox(height: 4),
                Text(
                  task.customerName!,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(
                        task.assignedToUserName ?? 'Unassigned',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  if (task.requiresGps || task.requiresPhoto)
                    Row(
                      children: [
                        if (task.requiresGps)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.gps_fixed, size: 12, color: AppColors.primary),
                          ),
                        if (task.requiresPhoto)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.camera_alt, size: 12, color: AppColors.secondary),
                          ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
