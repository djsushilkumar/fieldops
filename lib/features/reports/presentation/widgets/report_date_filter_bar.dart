import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/report_date_range.dart';
import '../../domain/entities/technician_performance.dart';

class ReportDateFilterBar extends StatelessWidget {
  final ReportDateRange selectedRange;
  final String? selectedTechnicianId;
  final List<TechnicianPerformance> technicians;
  final ValueChanged<DateRangePreset> onPresetSelected;
  final void Function(DateTime start, DateTime end) onCustomRangeSelected;
  final ValueChanged<String?> onTechnicianSelected;

  const ReportDateFilterBar({
    super.key,
    required this.selectedRange,
    this.selectedTechnicianId,
    required this.technicians,
    required this.onPresetSelected,
    required this.onCustomRangeSelected,
    required this.onTechnicianSelected,
  });

  Future<void> _pickCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange: DateTimeRange(
        start: selectedRange.startDate,
        end: selectedRange.endDate,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.roleManager,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onCustomRangeSelected(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Preset Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: DateRangePreset.values.map((preset) {
                final isSelected = selectedRange.preset == preset;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(
                      preset.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.roleManager,
                    backgroundColor: const Color(0xFFF1F3F4),
                    checkmarkColor: Colors.white,
                    onSelected: (selected) {
                      if (selected) {
                        if (preset == DateRangePreset.custom) {
                          _pickCustomRange(context);
                        } else {
                          onPresetSelected(preset);
                        }
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),

          // Row 2: Date Range Label & Technician Filter
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.roleManager),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  selectedRange.formattedRange,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

              // Technician dropdown filter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: selectedTechnicianId,
                    isDense: true,
                    hint: const Text(
                      'All Technicians',
                      style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                    ),
                    icon: const Icon(Icons.arrow_drop_down_rounded, size: 18, color: AppColors.textSecondary),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Technicians', style: TextStyle(fontSize: 12)),
                      ),
                      ...technicians.map((tech) {
                        return DropdownMenuItem<String?>(
                          value: tech.userId,
                          child: Text(tech.userName, style: const TextStyle(fontSize: 12)),
                        );
                      }),
                    ],
                    onChanged: onTechnicianSelected,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
