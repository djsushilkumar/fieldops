import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../domain/entities/visit_entity.dart';
import '../controllers/visit_controller.dart';

final visitDetailProvider =
    FutureProvider.family<VisitEntity, String>((ref, visitId) async {
  final repo = ref.watch(visitRepositoryProvider);
  return repo.getVisitDetail(visitId);
});

class VisitDetailScreen extends ConsumerWidget {
  final String visitId;

  const VisitDetailScreen({super.key, required this.visitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitAsync = ref.watch(visitDetailProvider(visitId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visit Details'),
      ),
      body: visitAsync.when(
        loading: () => const LoadingView(message: 'Loading visit details...'),
        error: (err, stack) => ErrorStateView(
          message: err.toString(),
          onRetry: () => ref.refresh(visitDetailProvider(visitId)),
        ),
        data: (visit) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card with Status
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              visit.locationName ?? 'Client Site',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          _StatusBadge(isActive: visit.isActive),
                        ],
                      ),
                      if (visit.customerName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          visit.customerName!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (visit.taskTitle != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.assignment_outlined,
                                  size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  visit.taskTitle!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // GPS Verification Audit Card
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
                      Text(
                        'GPS Execution Audit',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _AuditItem(
                        icon: Icons.login,
                        title: 'Check-In',
                        time: DateFormat('MMM dd, yyyy • hh:mm:ss a')
                            .format(visit.checkInAt),
                        coordinates:
                            'Lat: ${visit.checkInLatitude.toStringAsFixed(6)}, Lon: ${visit.checkInLongitude.toStringAsFixed(6)}',
                        isVerified: true,
                      ),
                      const Divider(height: 24),
                      if (visit.checkOutAt != null) ...[
                        _AuditItem(
                          icon: Icons.logout,
                          title: 'Check-Out',
                          time: DateFormat('MMM dd, yyyy • hh:mm:ss a')
                              .format(visit.checkOutAt!),
                          coordinates: visit.checkOutLatitude != null &&
                                  visit.checkOutLongitude != null
                              ? 'Lat: ${visit.checkOutLatitude!.toStringAsFixed(6)}, Lon: ${visit.checkOutLongitude!.toStringAsFixed(6)}'
                              : 'Coordinates not recorded',
                          isVerified: visit.checkOutLatitude != null,
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Duration',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '${visit.durationMinutes ?? 0} minutes',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        const Row(
                          children: [
                            Icon(Icons.hourglass_top,
                                size: 16, color: AppColors.warning),
                            SizedBox(width: 8),
                            Text(
                              'Visit still active in the field',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Visit Notes
              if (visit.notes != null && visit.notes!.isNotEmpty) ...[
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
                        Text(
                          'Visit Notes',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          visit.notes!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;

  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.warning.withOpacity(0.15)
            : AppColors.success.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isActive ? 'ACTIVE' : 'COMPLETED',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isActive ? AppColors.warning : AppColors.success,
        ),
      ),
    );
  }
}

class _AuditItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String time;
  final String coordinates;
  final bool isVerified;

  const _AuditItem({
    required this.icon,
    required this.title,
    required this.time,
    required this.coordinates,
    required this.isVerified,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    isVerified ? Icons.verified : Icons.error_outline,
                    size: 12,
                    color: isVerified ? AppColors.success : AppColors.warning,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      coordinates,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
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
}
