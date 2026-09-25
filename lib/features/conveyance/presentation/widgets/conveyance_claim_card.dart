import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/conveyance_claim_entity.dart';
import '../../domain/entities/conveyance_status.dart';
import '../../domain/entities/vehicle_type.dart';
import 'conveyance_discrepancy_badge.dart';

class ConveyanceClaimCard extends StatelessWidget {
  final ConveyanceClaimEntity claim;
  final VoidCallback? onTap;

  const ConveyanceClaimCard({
    super.key,
    required this.claim,
    this.onTap,
  });

  IconData _vehicleIcon(VehicleType type) {
    switch (type) {
      case VehicleType.twoWheelerBike:
        return Icons.two_wheeler_rounded;
      case VehicleType.fourWheelerCar:
        return Icons.directions_car_rounded;
      case VehicleType.electricVehicle:
        return Icons.electric_car_rounded;
      case VehicleType.publicTransit:
        return Icons.directions_bus_rounded;
    }
  }

  Color _statusColor(ConveyanceStatus status) {
    switch (status) {
      case ConveyanceStatus.draft:
        return AppColors.textSecondary;
      case ConveyanceStatus.pendingApproval:
        return AppColors.warning;
      case ConveyanceStatus.approved:
        return AppColors.success;
      case ConveyanceStatus.rejected:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(claim.status);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: claim.isFlaggedForFraud
              ? AppColors.error.withOpacity(0.4)
              : AppColors.border,
          width: claim.isFlaggedForFraud ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Date, Vehicle & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _vehicleIcon(claim.vehicleType),
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        claim.shiftDate,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      claim.status.displayName,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Technician Name
              Text(
                claim.userName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),

              // Distance Breakdown Grid
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Claimed Distance',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${claim.claimedDistanceKm.toStringAsFixed(1)} km',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'GPS Tracked',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${claim.gpsDistanceKm.toStringAsFixed(1)} km',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Payout',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          claim.status == ConveyanceStatus.approved
                              ? '₹${claim.approvedPayoutAmount.toStringAsFixed(2)}'
                              : 'Est. ₹${claim.estimatedPayout.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: claim.status == ConveyanceStatus.approved
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Bottom Row: Discrepancy indicator & chevron
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ConveyanceDiscrepancyBadge(
                    isFlagged: claim.isFlaggedForFraud,
                    discrepancyPercentage: claim.discrepancyPercentage,
                    compact: false,
                  ),
                  const Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
