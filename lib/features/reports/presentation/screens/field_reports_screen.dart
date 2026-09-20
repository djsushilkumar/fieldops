import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../navigation/presentation/widgets/app_top_nav_bar.dart';
import '../../domain/entities/export_type.dart';
import '../controllers/reports_controller.dart';
import '../widgets/csv_export_preview_dialog.dart';
import '../widgets/report_date_filter_bar.dart';
import '../widgets/report_kpi_card.dart';
import '../widgets/technician_performance_list.dart';

class FieldReportsScreen extends ConsumerStatefulWidget {
  const FieldReportsScreen({super.key});

  @override
  ConsumerState<FieldReportsScreen> createState() => _FieldReportsScreenState();
}

class _FieldReportsScreenState extends ConsumerState<FieldReportsScreen> {
  final DateFormat _fileDateFormat = DateFormat('yyyyMMdd');

  Future<void> _handleExport(ExportType type) async {
    final controller = ref.read(reportsControllerProvider.notifier);
    final state = ref.read(reportsControllerProvider);
    final csv = await controller.exportCsv(type);

    if (csv != null && mounted) {
      final dateStr = _fileDateFormat.format(state.dateRange.startDate);
      final filename = 'fieldops_${type.filePrefix}_$dateStr.csv';

      CsvExportPreviewDialog.show(
        context,
        exportType: type,
        csvContent: csv,
        filename: filename,
      );
    }
  }

  void _showExportSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.roleManagerBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.file_download_rounded, color: AppColors.roleManager),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Select Export Format',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(bottomSheetContext).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...ExportType.values.map((type) {
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F3F4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(_getExportIcon(type), size: 20, color: AppColors.roleManager),
                    ),
                    title: Text(
                      type.displayName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      type.description,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      maxLines: 2,
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textTertiary),
                    onTap: () {
                      Navigator.of(bottomSheetContext).pop();
                      _handleExport(type);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getExportIcon(ExportType type) {
    switch (type) {
      case ExportType.tasks:
        return Icons.task_alt_rounded;
      case ExportType.visits:
        return Icons.pin_drop_rounded;
      case ExportType.attendance:
        return Icons.event_available_rounded;
      case ExportType.technicians:
        return Icons.leaderboard_rounded;
      case ExportType.executiveSummary:
        return Icons.analytics_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportsControllerProvider);
    final controller = ref.read(reportsControllerProvider.notifier);
    final report = state.report;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppTopNavBar(
        title: 'Field Reports',
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            icon: const Icon(Icons.download_rounded, color: AppColors.roleManager),
            onPressed: () => _showExportSelectionSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          ReportDateFilterBar(
            selectedRange: state.dateRange,
            selectedTechnicianId: state.selectedTechnicianId,
            technicians: report?.technicianBreakdowns ?? const [],
            onPresetSelected: (preset) => controller.setDateRangePreset(preset),
            onCustomRangeSelected: (start, end) => controller.setCustomDateRange(start, end),
            onTechnicianSelected: (id) => controller.setTechnicianFilter(id),
          ),

          // Main Content
          Expanded(
            child: state.isLoading && report == null
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => controller.loadReport(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (state.errorMessage != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.errorLight,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.error.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      state.errorMessage!,
                                      style: const TextStyle(color: AppColors.error, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Section 1: Operations KPIs
                          const Text(
                            'Operational Performance Overview',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (report != null) ReportKpiCard(report: report),

                          const SizedBox(height: 24),

                          // Section 2: CSV Export Quick Actions
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.roleManagerBg,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(Icons.file_present_rounded, size: 18, color: AppColors.roleManager),
                                    ),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Text(
                                        'Instant CSV Export Center',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (state.isExporting)
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Generate standard RFC-4180 CSV spreadsheets matching selected date filters for billing, timesheets, and auditing.',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _buildExportChip(
                                      label: 'Tasks CSV',
                                      icon: Icons.task_alt_rounded,
                                      type: ExportType.tasks,
                                    ),
                                    _buildExportChip(
                                      label: 'Visits CSV',
                                      icon: Icons.pin_drop_rounded,
                                      type: ExportType.visits,
                                    ),
                                    _buildExportChip(
                                      label: 'Timesheets CSV',
                                      icon: Icons.event_available_rounded,
                                      type: ExportType.attendance,
                                    ),
                                    _buildExportChip(
                                      label: 'Tech Rankings CSV',
                                      icon: Icons.leaderboard_rounded,
                                      type: ExportType.technicians,
                                    ),
                                    _buildExportChip(
                                      label: 'Executive Summary CSV',
                                      icon: Icons.analytics_rounded,
                                      type: ExportType.executiveSummary,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Section 3: Technician Performance Leaderboard
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Technician Performance Ranking',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (report != null && report.technicianBreakdowns.isNotEmpty)
                                Text(
                                  '${report.technicianBreakdowns.length} Technicians',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (report != null)
                            TechnicianPerformanceList(
                              technicians: report.technicianBreakdowns,
                              onTechnicianTap: (techId) {
                                controller.setTechnicianFilter(techId);
                              },
                            ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportChip({
    required String label,
    required IconData icon,
    required ExportType type,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: AppColors.roleManager),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.roleManager),
      ),
      backgroundColor: AppColors.roleManagerBg,
      side: BorderSide(color: AppColors.roleManager.withOpacity(0.2)),
      onPressed: () => _handleExport(type),
    );
  }
}
