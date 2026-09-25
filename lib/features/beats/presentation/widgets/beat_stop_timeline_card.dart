import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/beat_stop_entity.dart';

class BeatStopTimelineCard extends StatelessWidget {
  final BeatStopEntity stop;
  final bool isLast;
  final VoidCallback? onCheckIn;
  final VoidCallback? onBookOrder;
  final VoidCallback? onSkip;

  const BeatStopTimelineCard({
    super.key,
    required this.stop,
    this.isLast = false,
    this.onCheckIn,
    this.onBookOrder,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = stop.isVisited;
    final isSkipped = stop.skipReason != null && stop.skipReason!.isNotEmpty;
    final statusColor = isDone
        ? AppColors.success
        : isSkipped
            ? AppColors.warning
            : AppColors.primary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline indicator column
          SizedBox(
            width: 44,
            child: Column(
              children: [
                // Sequence circle badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppColors.success
                        : isSkipped
                            ? AppColors.warning.withOpacity(0.2)
                            : AppColors.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDone
                          ? AppColors.success
                          : isSkipped
                              ? AppColors.warning
                              : AppColors.primary,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : isSkipped
                            ? const Icon(Icons.redo, size: 16, color: AppColors.warning)
                            : Text(
                                '${stop.sequenceOrder}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.primary,
                                ),
                              ),
                  ),
                ),
                // Timeline connecting line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isDone ? AppColors.success : AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Main Card Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDone
                      ? AppColors.success.withOpacity(0.3)
                      : AppColors.border,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row: Customer Name & Status Badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          stop.customerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isDone
                              ? 'Visited'
                              : isSkipped
                                  ? 'Skipped'
                                  : 'Pending',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Address
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          stop.locationAddress,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Time and Meta Info
                  Row(
                    children: [
                      if (stop.targetArrivalTime != null) ...[
                        const Icon(Icons.access_time, size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'Target: ${stop.targetArrivalTime}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 12),
                      ],
                      const Icon(Icons.timer_outlined, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '~${stop.estimatedVisitMinutes} mins',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      if (stop.checkInTime != null) ...[
                        const Spacer(),
                        Text(
                          'Checked in: ${stop.checkInTime!.hour.toString().padLeft(2, '0')}:${stop.checkInTime!.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Action Buttons
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (!isDone)
                        ElevatedButton.icon(
                          onPressed: onCheckIn,
                          icon: const Icon(Icons.location_pin, size: 15),
                          label: const Text('Check In', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      OutlinedButton.icon(
                        onPressed: onBookOrder,
                        icon: const Icon(Icons.shopping_cart_checkout, size: 15),
                        label: const Text('Book Order', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.secondary,
                          side: const BorderSide(color: AppColors.secondary),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      if (!isDone && onSkip != null)
                        TextButton(
                          onPressed: onSkip,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Skip', style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
