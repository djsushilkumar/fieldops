import 'package:intl/intl.dart';

enum DateRangePreset {
  today,
  thisWeek,
  thisMonth,
  last30Days,
  custom;

  String get displayName {
    switch (this) {
      case DateRangePreset.today:
        return 'Today';
      case DateRangePreset.thisWeek:
        return 'This Week';
      case DateRangePreset.thisMonth:
        return 'This Month';
      case DateRangePreset.last30Days:
        return 'Last 30 Days';
      case DateRangePreset.custom:
        return 'Custom';
    }
  }
}

class ReportDateRange {
  final DateRangePreset preset;
  final DateTime startDate;
  final DateTime endDate;

  const ReportDateRange({
    required this.preset,
    required this.startDate,
    required this.endDate,
  });

  factory ReportDateRange.fromPreset(DateRangePreset preset, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final today = DateTime(reference.year, reference.month, reference.day);

    switch (preset) {
      case DateRangePreset.today:
        return ReportDateRange(
          preset: preset,
          startDate: today,
          endDate: today.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1)),
        );

      case DateRangePreset.thisWeek:
        // Week starting Monday
        final weekday = reference.weekday; // 1 = Mon, 7 = Sun
        final startOfWeek = today.subtract(Duration(days: weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 7)).subtract(const Duration(milliseconds: 1));
        return ReportDateRange(
          preset: preset,
          startDate: startOfWeek,
          endDate: endOfWeek,
        );

      case DateRangePreset.thisMonth:
        final startOfMonth = DateTime(reference.year, reference.month, 1);
        final nextMonth = (reference.month == 12)
            ? DateTime(reference.year + 1, 1, 1)
            : DateTime(reference.year, reference.month + 1, 1);
        final endOfMonth = nextMonth.subtract(const Duration(milliseconds: 1));
        return ReportDateRange(
          preset: preset,
          startDate: startOfMonth,
          endDate: endOfMonth,
        );

      case DateRangePreset.last30Days:
        final start = today.subtract(const Duration(days: 30));
        final end = today.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
        return ReportDateRange(
          preset: preset,
          startDate: start,
          endDate: end,
        );

      case DateRangePreset.custom:
        return ReportDateRange(
          preset: preset,
          startDate: today.subtract(const Duration(days: 7)),
          endDate: today.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1)),
        );
    }
  }

  factory ReportDateRange.custom(DateTime start, DateTime end) {
    return ReportDateRange(
      preset: DateRangePreset.custom,
      startDate: DateTime(start.year, start.month, start.day),
      endDate: DateTime(end.year, end.month, end.day, 23, 59, 59, 999),
    );
  }

  String get formattedRange {
    final format = DateFormat('MMM d, yyyy');
    return '${format.format(startDate)} – ${format.format(endDate)}';
  }

  ReportDateRange copyWith({
    DateRangePreset? preset,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return ReportDateRange(
      preset: preset ?? this.preset,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportDateRange &&
          runtimeType == other.runtimeType &&
          preset == other.preset &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode => preset.hashCode ^ startDate.hashCode ^ endDate.hashCode;
}
