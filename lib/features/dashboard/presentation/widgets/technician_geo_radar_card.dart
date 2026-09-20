import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/field_technician_location.dart';
import '../../domain/entities/technician_duty_status.dart';

class TechnicianGeoRadarCard extends StatelessWidget {
  final List<FieldTechnicianLocation> technicians;
  final VoidCallback? onRefresh;

  const TechnicianGeoRadarCard({
    super.key,
    required this.technicians,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final onDutyCount = technicians.where((t) => t.dutyStatus != TechnicianDutyStatus.offDuty).length;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 0.8),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Live Field Fleet Tracker',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '$onDutyCount Active Now',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (technicians.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No active technicians transmitting telemetry',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: technicians.length,
                separatorBuilder: (context, index) => const Divider(height: 16, color: AppColors.border),
                itemBuilder: (context, index) {
                  final tech = technicians[index];
                  return _buildTechnicianRow(context, tech);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicianRow(BuildContext context, FieldTechnicianLocation tech) {
    final statusColor = tech.dutyStatus.color;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Duty Status Icon Avatar
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            tech.dutyStatus.icon,
            size: 20,
            color: statusColor,
          ),
        ),
        const SizedBox(width: 12),

        // Main info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name + Duty Badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tech.userName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tech.dutyStatus.displayName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Active Assignment or Customer
              if (tech.activeTaskTitle != null || tech.activeCustomerName != null)
                Row(
                  children: [
                    Icon(
                      tech.activeCustomerName != null
                          ? Icons.business_rounded
                          : Icons.task_alt_rounded,
                      size: 13,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        tech.activeTaskTitle ?? tech.activeCustomerName ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 4),

              // GPS Coordinates & Telemetry
              Row(
                children: [
                  const Icon(Icons.gps_fixed_rounded, size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${tech.latitude.toStringAsFixed(4)}, ${tech.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),

                  // Battery Indicator
                  _buildBatteryWidget(tech.batteryLevel, tech.isCharging),
                  const SizedBox(width: 8),

                  // Last ping
                  Text(
                    tech.timeAgo,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBatteryWidget(int level, bool isCharging) {
    Color batColor = AppColors.secondary;
    if (level <= 20) {
      batColor = AppColors.error;
    } else if (level <= 50) {
      batColor = AppColors.warning;
    }

    IconData batIcon = Icons.battery_full_rounded;
    if (isCharging) {
      batIcon = Icons.battery_charging_full_rounded;
    } else if (level <= 20) {
      batIcon = Icons.battery_alert_rounded;
    } else if (level <= 50) {
      batIcon = Icons.battery_3_bar_rounded;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(batIcon, size: 14, color: batColor),
        const SizedBox(width: 2),
        Text(
          '$level%',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: batColor,
          ),
        ),
      ],
    );
  }
}
