import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../navigation/presentation/widgets/app_top_nav_bar.dart';
import '../../../reports/presentation/widgets/csv_export_preview_dialog.dart';
import '../../../reports/domain/entities/export_type.dart';
import '../../domain/entities/conveyance_status.dart';
import '../../domain/entities/odometer_reading_entity.dart';
import '../../domain/entities/vehicle_type.dart';
import '../controllers/conveyance_controller.dart';
import '../widgets/conveyance_claim_card.dart';
import '../widgets/odometer_scanner_dialog.dart';
import 'conveyance_claim_detail_screen.dart';

class ConveyanceClaimsScreen extends ConsumerStatefulWidget {
  const ConveyanceClaimsScreen({super.key});

  @override
  ConsumerState<ConveyanceClaimsScreen> createState() => _ConveyanceClaimsScreenState();
}

class _ConveyanceClaimsScreenState extends ConsumerState<ConveyanceClaimsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleCsvExport() async {
    final notifier = ref.read(conveyanceListNotifierProvider.notifier);
    final csv = await notifier.exportCsv();
    if (csv != null && mounted) {
      CsvExportPreviewDialog.show(
        context,
        exportType: ExportType.attendance,
        csvContent: csv,
        filename: 'conveyance_claims_${DateTime.now().millisecondsSinceEpoch}.csv',
      );
    }
  }

  void _showStartOdometerDialog() {
    final auth = ref.read(authNotifierProvider);
    final user = auth.user;
    if (user == null) return;

    VehicleType selectedVehicle = VehicleType.twoWheelerBike;
    double rate = selectedVehicle.defaultRatePerKm;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.two_wheeler, color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Start Shift Conveyance',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<VehicleType>(
                      value: selectedVehicle,
                      decoration: InputDecoration(
                        labelText: 'Vehicle Type',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: VehicleType.values.map((v) {
                        return DropdownMenuItem(
                          value: v,
                          child: Text('${v.displayName} (₹${v.defaultRatePerKm}/km)'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() {
                            selectedVehicle = val;
                            rate = val.defaultRatePerKm;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Capture Start Odometer (OCR)'),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.of(sheetContext).pop();
                        final reading = await OdometerScannerDialog.show(
                          context,
                          readingType: OdometerReadingType.start,
                        );

                        if (reading != null && mounted) {
                          final success = await ref
                              .read(activeShiftClaimNotifierProvider.notifier)
                              .recordStartOdometer(
                                organizationId: user.organizationId,
                                userName: user.name,
                                vehicleType: selectedVehicle,
                                ratePerKm: rate,
                                reading: reading,
                              );

                          if (success && mounted) {
                            ref.read(conveyanceListNotifierProvider.notifier).loadClaims();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Start odometer recorded: ${reading.reading} km'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(conveyanceListNotifierProvider);
    final notifier = ref.read(conveyanceListNotifierProvider.notifier);

    return Scaffold(
      appBar: AppTopNavBar(
        title: 'Conveyance & Mileage OCR',
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, size: 20),
            tooltip: 'Export RFC-4180 CSV',
            onPressed: _handleCsvExport,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh',
            onPressed: () => notifier.loadClaims(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Record Odometer'),
        onPressed: _showStartOdometerDialog,
      ),
      body: Column(
        children: [
          // KPI Metric Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  onChanged: (val) => notifier.setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: 'Search by technician, date, vehicle...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // KPI Counter Strip
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Claims', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            Text(
                              '${state.claims.length}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.error.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Audit Flags', style: TextStyle(fontSize: 11, color: AppColors.error)),
                            Text(
                              '${state.flaggedCount}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Approved', style: TextStyle(fontSize: 11, color: AppColors.success)),
                            Text(
                              '₹${state.totalPayoutApproved.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.success),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All Claims'),
                        selected: state.filterStatus == null && !state.filterFlaggedOnly,
                        onSelected: (_) {
                          notifier.setStatusFilter(null);
                          if (state.filterFlaggedOnly) notifier.toggleFlaggedOnly(false);
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        avatar: const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.error),
                        label: const Text('Flagged for Fraud (>15%)'),
                        selected: state.filterFlaggedOnly,
                        selectedColor: AppColors.error.withOpacity(0.15),
                        onSelected: (val) => notifier.toggleFlaggedOnly(val),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Pending Approval'),
                        selected: state.filterStatus == ConveyanceStatus.pendingApproval,
                        onSelected: (_) => notifier.setStatusFilter(ConveyanceStatus.pendingApproval),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Approved'),
                        selected: state.filterStatus == ConveyanceStatus.approved,
                        onSelected: (_) => notifier.setStatusFilter(ConveyanceStatus.approved),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main List View
          Expanded(
            child: state.isLoading
                ? const LoadingView(message: 'Loading conveyance claims...')
                : state.filteredClaims.isEmpty
                    ? const EmptyStateView(
                        title: 'No Conveyance Claims',
                        description: 'No claims match your selected filter. Start a shift to record an odometer reading.',
                        icon: Icons.directions_car_outlined,
                      )
                    : RefreshIndicator(
                        onRefresh: () => notifier.loadClaims(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: state.filteredClaims.length,
                          itemBuilder: (context, index) {
                            final claim = state.filteredClaims[index];
                            return ConveyanceClaimCard(
                              claim: claim,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ConveyanceClaimDetailScreen(claim: claim),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
