import 'package:flutter/material.dart';
import '../../domain/entities/task_priority.dart';

class TaskPriorityBadge extends StatelessWidget {
  final TaskPriority priority;

  const TaskPriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: priority.backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: priority.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            priority.isUrgent
                ? Icons.warning_rounded
                : (priority.isHigh ? Icons.arrow_upward_rounded : Icons.label_outline_rounded),
            size: 12,
            color: priority.color,
          ),
          const SizedBox(width: 4),
          Text(
            priority.label,
            style: TextStyle(
              color: priority.color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
