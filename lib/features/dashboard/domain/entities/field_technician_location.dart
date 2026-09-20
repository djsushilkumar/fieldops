import 'technician_duty_status.dart';

class FieldTechnicianLocation {
  final String userId;
  final String userName;
  final String? userPhone;
  final double latitude;
  final double longitude;
  final double? accuracyMeters;
  final double? speedKmh;
  final int batteryLevel; // 0 - 100
  final bool isCharging;
  final TechnicianDutyStatus dutyStatus;
  final String? activeTaskId;
  final String? activeTaskTitle;
  final String? activeVisitId;
  final String? activeCustomerName;
  final DateTime lastPingAt;

  const FieldTechnicianLocation({
    required this.userId,
    required this.userName,
    this.userPhone,
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
    this.speedKmh,
    this.batteryLevel = 100,
    this.isCharging = false,
    required this.dutyStatus,
    this.activeTaskId,
    this.activeTaskTitle,
    this.activeVisitId,
    this.activeCustomerName,
    required this.lastPingAt,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(lastPingAt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  FieldTechnicianLocation copyWith({
    String? userId,
    String? userName,
    String? userPhone,
    double? latitude,
    double? longitude,
    double? accuracyMeters,
    double? speedKmh,
    int? batteryLevel,
    bool? isCharging,
    TechnicianDutyStatus? dutyStatus,
    String? activeTaskId,
    String? activeTaskTitle,
    String? activeVisitId,
    String? activeCustomerName,
    DateTime? lastPingAt,
  }) {
    return FieldTechnicianLocation(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      speedKmh: speedKmh ?? this.speedKmh,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isCharging: isCharging ?? this.isCharging,
      dutyStatus: dutyStatus ?? this.dutyStatus,
      activeTaskId: activeTaskId ?? this.activeTaskId,
      activeTaskTitle: activeTaskTitle ?? this.activeTaskTitle,
      activeVisitId: activeVisitId ?? this.activeVisitId,
      activeCustomerName: activeCustomerName ?? this.activeCustomerName,
      lastPingAt: lastPingAt ?? this.lastPingAt,
    );
  }
}
