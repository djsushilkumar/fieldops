import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/services/route_optimization_engine.dart';

class BeatComplianceGauge extends StatelessWidget {
  final double complianceRate;
  final int visitedStops;
  final int totalStops;

  const BeatComplianceGauge({
    super.key,
    required this.complianceRate,
    required this.visitedStops,
    required this.totalStops,
  });

  Color _gaugeColor(double pct) {
    if (pct >= 85.0) return AppColors.success;
    if (pct >= 60.0) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final color = _gaugeColor(complianceRate);
    final rating = RouteOptimizationEngine.getComplianceRating(complianceRate);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Circular Progress Indicator
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: (complianceRate / 100.0).clamp(0.0, 1.0),
                  strokeWidth: 6,
                  backgroundColor: color.withOpacity(0.15),
                  color: color,
                ),
                Text(
                  '${complianceRate.toInt()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Compliance Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'PJP Beat Compliance',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        rating,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$visitedStops of $totalStops planned store visits completed today',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: totalStops > 0 ? (visitedStops / totalStops).clamp(0.0, 1.0) : 0.0,
                    backgroundColor: AppColors.border,
                    color: color,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
