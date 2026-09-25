import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/conveyance_claim_entity.dart';
import '../../domain/entities/conveyance_status.dart';
import '../controllers/conveyance_controller.dart';
import '../widgets/conveyance_discrepancy_badge.dart';

class ConveyanceClaimDetailScreen extends ConsumerStatefulWidget {
  final ConveyanceClaimEntity claim;

  const ConveyanceClaimDetailScreen({
    super.key,
    required this.claim,
  });

  @override
  ConsumerState<ConveyanceClaimDetailScreen> createState() => _ConveyanceClaimDetailScreenState();
}

class _ConveyanceClaimDetailScreenState extends ConsumerState<ConveyanceClaimDetailScreen> {
  late ConveyanceClaimEntity _currentClaim;
  final _managerNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentClaim = widget.claim;
    if (_currentClaim.managerNotes != null) {
      _managerNotesController.text = _currentClaim.managerNotes!;
    }
  }

  @override
  void dispose() {
    _managerNotesController.dispose();
    super.dispose();
  }

  Future<void> _handleReview(ConveyanceStatus status) async {
    final notifier = ref.read(conveyanceListNotifierProvider.notifier);
    final approvedAmount = status == ConveyanceStatus.approved
        ? (_currentClaim.approvedPayoutAmount > 0
            ? _currentClaim.approvedPayoutAmount
            : _currentClaim.estimatedPayout)
        : 0.0;

    final success = await notifier.reviewClaim(
      claimId: _currentClaim.id,
      newStatus: status,
      approvedPayout: approvedAmount,
      managerNotes: _managerNotesController.text.trim(),
    );

    if (success && mounted) {
      setState(() {
        _currentClaim = _currentClaim.copyWith(
          status: status,
          approvedPayoutAmount: approvedAmount,
          managerNotes: _managerNotesController.text.trim(),
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Claim ${status.displayName} successfully.'),
          backgroundColor: status == ConveyanceStatus.approved ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final isManager = auth.role?.isManager == true || auth.role?.isAdmin == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conveyance Claim Audit'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: ConveyanceDiscrepancyBadge(
                isFlagged: _currentClaim.isFlaggedForFraud,
                discrepancyPercentage: _currentClaim.discrepancyPercentage,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Fraud Warning Banner if flagged
            if (_currentClaim.isFlaggedForFraud) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withOpacity(0.5), width: 1.5),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_rounded, color: AppColors.error, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Audit Discrepancy Flag (>15%)',
                            style: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentClaim.fraudReason ??
                                'Claimed odometer mileage deviates significantly from actual GPS route tracking.',
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // General Info Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Claim Overview',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const Divider(height: 20),
                    _infoRow('Technician', _currentClaim.userName),
                    _infoRow('Shift Date', _currentClaim.shiftDate),
                    _infoRow('Vehicle Type', _currentClaim.vehicleType.displayName),
                    _infoRow('Reimbursement Rate', '₹${_currentClaim.ratePerKm.toStringAsFixed(2)} / km'),
                    _infoRow('Claim Status', _currentClaim.status.displayName),
                    _infoRow(
                      'Approved Payout',
                      '₹${_currentClaim.approvedPayoutAmount.toStringAsFixed(2)}',
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // AI Reconciliation Breakdown Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.calculate_outlined, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Distance & Fraud Reconciliation Formula',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('ΔD Claimed (Odo End - Start):', style: TextStyle(fontSize: 13)),
                              Text(
                                '${_currentClaim.claimedDistanceKm.toStringAsFixed(1)} km',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('ΔD GPS (Haversine Route):', style: TextStyle(fontSize: 13)),
                              Text(
                                '${_currentClaim.gpsDistanceKm.toStringAsFixed(1)} km',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Discrepancy Percentage:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              Text(
                                '${_currentClaim.discrepancyPercentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: _currentClaim.isFlaggedForFraud ? AppColors.error : AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Start vs End Odometer Photo Proofs
            Row(
              children: [
                Expanded(
                  child: _odometerProofCard(
                    title: 'Start Shift Odometer',
                    reading: _currentClaim.startReading?.reading,
                    rawOcr: _currentClaim.startReading?.rawOcrText ?? '',
                    time: _currentClaim.startReading?.timestamp,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _odometerProofCard(
                    title: 'End Shift Odometer',
                    reading: _currentClaim.endReading?.reading,
                    rawOcr: _currentClaim.endReading?.rawOcrText ?? '',
                    time: _currentClaim.endReading?.timestamp,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Manager Review Section
            if (isManager) ...[
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Manager Audit Decision',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _managerNotesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Audit Notes / Explanation',
                          hintText: 'e.g. Approved after reviewing job route waypoints',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              icon: const Icon(Icons.cancel_outlined, size: 18),
                              label: const Text('Reject Claim'),
                              onPressed: () => _handleReview(ConveyanceStatus.rejected),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              icon: const Icon(Icons.check_circle_outline, size: 18),
                              label: const Text('Approve Payout'),
                              onPressed: () => _handleReview(ConveyanceStatus.approved),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isBold ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _odometerProofCard({
    required String title,
    required double? reading,
    required String rawOcr,
    required DateTime? time,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          Container(
            height: 90,
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.speed, color: Colors.white70, size: 24),
                const SizedBox(height: 4),
                Text(
                  reading != null ? '${reading.toStringAsFixed(1)} km' : 'Not Recorded',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            rawOcr.isNotEmpty ? 'OCR: "$rawOcr"' : 'No OCR stream',
            style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (time != null) ...[
            const SizedBox(height: 2),
            Text(
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
