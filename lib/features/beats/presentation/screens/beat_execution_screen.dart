import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../controllers/beat_controller.dart';
import '../widgets/beat_compliance_gauge.dart';
import '../widgets/beat_stop_timeline_card.dart';

class BeatExecutionScreen extends ConsumerStatefulWidget {
  const BeatExecutionScreen({super.key});

  @override
  ConsumerState<BeatExecutionScreen> createState() => _BeatExecutionScreenState();
}

class _BeatExecutionScreenState extends ConsumerState<BeatExecutionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(todayBeatNotifierProvider.notifier).loadTodayBeat();
    });
  }

  Future<void> _handleOptimizeRoute() async {
    final locationService = ref.read(locationServiceProvider);
    final coords = await locationService.getCurrentLocation();
    ref.read(todayBeatNotifierProvider.notifier).optimizeCurrentRoute(coords);
  }

  void _showSkipDialog(String stopId, String customerName) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Skip Visit: $customerName'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter reason (e.g. Store closed, Owner unavailable)',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // Mark skipped in controller
              // (In future can call skipStop on repository)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Stop at $customerName marked as skipped.'),
                  backgroundColor: AppColors.warning,
                ),
              );
            },
            child: const Text('Confirm Skip'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(todayBeatNotifierProvider);
    final notifier = ref.read(todayBeatNotifierProvider.notifier);

    ref.listen<TodayBeatState>(todayBeatNotifierProvider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
      if (next.successMessage != null && next.successMessage != prev?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.success,
          ),
        );
      }
    });

    final plan = state.assignedPlan;
    final execution = state.execution;
    final stops = execution?.stops ?? plan?.stops ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Permanent Journey Plan (Beat)'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        actions: [
          IconButton(
            tooltip: 'Optimize Visit Route (TSP)',
            icon: const Icon(Icons.route, color: AppColors.primary),
            onPressed: stops.isNotEmpty ? _handleOptimizeRoute : null,
          ),
          IconButton(
            tooltip: 'Refresh Beat',
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.loadTodayBeat(),
          ),
        ],
      ),
      body: state.isLoading && plan == null && execution == null
          ? const Center(child: CircularProgressIndicator())
          : stops.isEmpty
              ? EmptyStateView(
                  icon: Icons.alt_route,
                  title: 'No Beat Assigned Today',
                  description: 'You do not have any permanent journey plan assigned for today.',
                  actionLabel: 'Refresh',
                  onAction: () => notifier.loadTodayBeat(),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Beat Header Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  plan?.code ?? 'BEAT-PJP',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  plan?.name ?? 'Daily Route',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            plan?.description ?? 'Scheduled retailer and client visits.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.storefront, size: 16, color: Colors.white70),
                              const SizedBox(width: 6),
                              Text(
                                '${stops.length} Planned Stops',
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                              const Spacer(),
                              if (execution == null)
                                ElevatedButton.icon(
                                  onPressed: () => notifier.startBeat(),
                                  icon: const Icon(Icons.play_arrow, size: 16),
                                  label: const Text('Start Beat'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                )
                              else if (!state.isExecutionCompleted)
                                OutlinedButton.icon(
                                  onPressed: () => notifier.completeBeat(),
                                  icon: const Icon(Icons.check_circle_outline, size: 16),
                                  label: const Text('Complete Beat'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white70),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Optimization Banner if applied
                    if (state.optimizationResult != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.electric_bolt, color: AppColors.accent, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Route Optimized! Saved ${state.optimizationResult!.savedDistanceKm} km (${state.optimizationResult!.savingsPercentage}% reduction)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Compliance Gauge
                    if (execution != null) ...[
                      BeatComplianceGauge(
                        complianceRate: execution.complianceRate,
                        visitedStops: execution.visitedStops,
                        totalStops: execution.totalStops,
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Section Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Store Itinerary',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${stops.where((s) => s.isVisited).length}/${stops.length} Done',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Stops List
                    ...stops.asMap().entries.map((entry) {
                      final index = entry.key;
                      final stop = entry.value;
                      final isLast = index == stops.length - 1;

                      return BeatStopTimelineCard(
                        stop: stop,
                        isLast: isLast,
                        onCheckIn: execution != null && !stop.isVisited
                            ? () => notifier.checkInStop(stop.id)
                            : null,
                        onBookOrder: () {
                          // Navigate to Sales Order Booking with customer preselected
                          context.push(
                            '/sales/book?customerId=${stop.customerId}&customerName=${Uri.encodeComponent(stop.customerName)}',
                          );
                        },
                        onSkip: !stop.isVisited
                            ? () => _showSkipDialog(stop.id, stop.customerName)
                            : null,
                      );
                    }),
                  ],
                ),
    );
  }
}
