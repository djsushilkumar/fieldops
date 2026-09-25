import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ConveyanceDiscrepancyBadge extends StatelessWidget {
  final bool isFlagged;
  final double discrepancyPercentage;
  final bool compact;

  const ConveyanceDiscrepancyBadge({
    super.key,
    required this.isFlagged,
    required this.discrepancyPercentage,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isFlagged ? AppColors.error : AppColors.success;
    final bgColor = isFlagged ? AppColors.error.withOpacity(0.12) : AppColors.success.withOpacity(0.12);
    final icon = isFlagged ? Icons.warning_amber_rounded : Icons.verified_user_outlined;
    final label = isFlagged
        ? 'Flagged: ${discrepancyPercentage.toStringAsFixed(1)}% Discrepancy'
        : 'GPS Verified (${discrepancyPercentage.toStringAsFixed(1)}%)';

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              isFlagged ? '${discrepancyPercentage.toStringAsFixed(0)}% diff' : 'Verified',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
