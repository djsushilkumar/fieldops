enum BeatFrequency {
  daily,
  weekly,
  biweekly,
  monthly;

  String get displayName {
    switch (this) {
      case BeatFrequency.daily:
        return 'Daily Beat';
      case BeatFrequency.weekly:
        return 'Weekly Beat';
      case BeatFrequency.biweekly:
        return 'Bi-Weekly Beat';
      case BeatFrequency.monthly:
        return 'Monthly Beat';
    }
  }

  static BeatFrequency fromString(String? val) {
    if (val == null) return BeatFrequency.daily;
    switch (val.toLowerCase()) {
      case 'weekly':
        return BeatFrequency.weekly;
      case 'biweekly':
        return BeatFrequency.biweekly;
      case 'monthly':
        return BeatFrequency.monthly;
      default:
        return BeatFrequency.daily;
    }
  }
}
