import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/task_entity.dart';
import 'task_priority_badge.dart';
import 'task_status_badge.dart';

class TaskCard extends StatelessWidget {
  final TaskEntity task;
  final VoidCallback onTap;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, h:mm a');

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: task.isOverdue ? AppColors.error.withOpacity(0.5) : AppColors.divider,
          width: task.isOverdue ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Priority & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TaskPriorityBadge(priority: task.priority),
                  TaskStatusBadge(status: task.status),
                ],
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                task.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  task.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // Customer / Location
              if (task.customerName != null || task.locationName != null) ...[
                Row(
                  children: [
                    const Icon(Icons.business_outlined, size: 16, color: AppColors.textTertiary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${task.customerName ?? ''}${task.customerName != null && task.locationName != null ? ' • ' : ''}${task.locationName ?? ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],

              // Scheduled Time
              if (task.scheduledStart != null) ...[
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, size: 16, color: AppColors.textTertiary),
                    const SizedBox(width: 6),
                    Text(
                      dateFormat.format(task.scheduledStart!),
                      style: TextStyle(
                        fontSize: 12,
                        color: task.isOverdue ? AppColors.error : AppColors.textSecondary,
                        fontWeight: task.isOverdue ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],

              const Divider(),
              const SizedBox(height: 6),

              // Bottom row: Assignee & Proof requirements
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Assignee info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.primaryLight,
                        child: Text(
                          (task.assignedToUserName?.isNotEmpty ?? false)
                              ? task.assignedToUserName![0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        task.assignedToUserName ?? 'Unassigned',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: task.assignedToUserName != null
                              ? AppColors.textPrimary
                              : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),

                  // Required proof icons
                  Row(
                    children: [
                      if (task.requiresGps)
                        const Padding(
                          padding: EdgeInsets.only(left: 6.0),
                          child: Tooltip(
                            message: 'GPS Check-in Required',
                            child: Icon(Icons.pin_drop, size: 16, color: AppColors.primary),
                          ),
                        ),
                      if (task.requiresPhoto)
                        const Padding(
                          padding: EdgeInsets.only(left: 6.0),
                          child: Tooltip(
                            message: 'Photo Proof Required',
                            child: Icon(Icons.camera_alt, size: 16, color: AppColors.secondary),
                          ),
                        ),
                      if (task.requiresForm)
                        const Padding(
                          padding: EdgeInsets.only(left: 6.0),
                          child: Tooltip(
                            message: 'Form Submission Required',
                            child: Icon(Icons.description, size: 16, color: AppColors.accent),
                          ),
                        ),
                      if (task.requiresSignature)
                        const Padding(
                          padding: EdgeInsets.only(left: 6.0),
                          child: Tooltip(
                            message: 'Customer Sign-Off Required',
                            child: Icon(Icons.draw_rounded, size: 16, color: AppColors.roleAdmin),
                          ),
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
