import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/location/gps_distance_engine.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../customers/domain/entities/location_entity.dart';
import '../../../tasks/presentation/controllers/task_controller.dart';
import '../controllers/visit_controller.dart';

class GpsVisitExecutionCard extends ConsumerStatefulWidget {
  final String taskId;
  final LocationEntity? targetLocation;
  final VoidCallback? onVisitUpdated;

  const GpsVisitExecutionCard({
    super.key,
    required this.taskId,
    this.targetLocation,
    this.onVisitUpdated,
  });

  @override
  ConsumerState<GpsVisitExecutionCard> createState() =>
      _GpsVisitExecutionCardState();
}

class _GpsVisitExecutionCardState extends ConsumerState<GpsVisitExecutionCard> {
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleCheckIn(VisitExecutionNotifier notifier) async {
    try {
      await notifier.checkIn();
      // Also update task status to in-progress if needed
      await ref
          .read(taskDetailNotifierProvider(widget.taskId).notifier)
          .startTask();
      widget.onVisitUpdated?.call();
    } catch (_) {
      // Error handled in notifier state
    }
  }

  Future<void> _showCheckOutDialog(VisitExecutionNotifier notifier) async {
    _notesController.clear();
    final notes = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('GPS Check-Out'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add optional notes or remarks before completing this site visit.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Work completed, customer sign-off details...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('confirm_checkout_button'),
            onPressed: () => Navigator.of(ctx).pop(_notesController.text.trim()),
            child: const Text('Complete Visit'),
          ),
        ],
      ),
    );

    if (notes != null) {
      try {
        await notifier.checkOut(notes: notes.isNotEmpty ? notes : null);
        widget.onVisitUpdated?.call();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final params = VisitExecutionParams(
      taskId: widget.taskId,
      targetLocation: widget.targetLocation,
    );
    final state = ref.watch(visitExecutionNotifierProvider(params));
    final notifier = ref.read(visitExecutionNotifierProvider(params).notifier);

    final target = widget.targetLocation;
    final radiusResult = state.radiusResult;
    final hasActiveVisit = state.activeVisit != null;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        hasActiveVisit ? Icons.timer : Icons.radar,
                        color: hasActiveVisit ? AppColors.warning : AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          hasActiveVisit ? 'Active Site Visit' : 'Field GPS Verification',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: 'Update GPS distance',
                  onPressed: () => notifier.refreshGps(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Target Location Info
            if (target != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      target.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Target: ${target.latitude.toStringAsFixed(4)}, ${target.longitude.toStringAsFixed(4)} • Radius: ${target.radiusMeters}m',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Geofence Radius Banner
            if (radiusResult != null && !hasActiveVisit) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: radiusResult.isWithinRadius
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: radiusResult.isWithinRadius
                        ? AppColors.success.withOpacity(0.3)
                        : AppColors.warning.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      radiusResult.isWithinRadius
                          ? Icons.check_circle_outline
                          : Icons.location_off_outlined,
                      color: radiusResult.isWithinRadius
                          ? AppColors.success
                          : AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            radiusResult.isWithinRadius
                                ? 'Within Allowed Site Geofence'
                                : 'Outside Site Geofence',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: radiusResult.isWithinRadius
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            radiusResult.isWithinRadius
                                ? 'Distance to site: ${GpsDistanceEngine.formatDistance(radiusResult.distanceMeters)} (allowed: ${radiusResult.allowedRadiusMeters}m)'
                                : 'Distance to site: ${GpsDistanceEngine.formatDistance(radiusResult.distanceMeters)} (must be within ${radiusResult.allowedRadiusMeters}m)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Messages
            if (state.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  state.errorMessage!,
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (state.successMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  state.successMessage!,
                  style: const TextStyle(color: AppColors.success, fontSize: 12),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Action Button
            if (hasActiveVisit) ...[
              AppButton(
                key: const Key('gps_checkout_button'),
                label: 'GPS Check-Out & Complete Visit',
                customColor: AppColors.warning,
                isLoading: state.isCheckingOut,
                onPressed: () => _showCheckOutDialog(notifier),
              ),
            ] else ...[
              AppButton(
                key: const Key('gps_checkin_button'),
                label: 'GPS Check-In',
                icon: Icons.my_location,
                isLoading: state.isCheckingIn,
                onPressed: () => _handleCheckIn(notifier),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
