import '../../domain/entities/field_technician_location.dart';
import '../../domain/entities/technician_duty_status.dart';

class FieldTechnicianLocationModel {
  final String userId;
  final String userName;
  final String? userPhone;
  final double latitude;
  final double longitude;
  final double? accuracyMeters;
  final double? speedKmh;
  final int batteryLevel;
  final bool isCharging;
  final String dutyStatus;
  final String? activeTaskId;
  final String? activeTaskTitle;
  final String? activeVisitId;
  final String? activeCustomerName;
  final DateTime lastPingAt;

  const FieldTechnicianLocationModel({
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

  factory FieldTechnicianLocationModel.fromJson(Map<String, dynamic> json) {
    return FieldTechnicianLocationModel(
      userId: json['user_id'] as String,
      userName: json['user_name'] as String? ?? 'Technician',
      userPhone: json['user_phone'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracyMeters: (json['accuracy_meters'] as num?)?.toDouble(),
      speedKmh: (json['speed_kmh'] as num?)?.toDouble(),
      batteryLevel: json['battery_level'] as int? ?? 100,
      isCharging: json['is_charging'] as bool? ?? false,
      dutyStatus: json['duty_status'] as String? ?? 'ON_DUTY',
      activeTaskId: json['active_task_id'] as String?,
      activeTaskTitle: json['active_task_title'] as String?,
      activeVisitId: json['active_visit_id'] as String?,
      activeCustomerName: json['active_customer_name'] as String?,
      lastPingAt: json['last_ping_at'] != null
          ? DateTime.tryParse(json['last_ping_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'user_phone': userPhone,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy_meters': accuracyMeters,
      'speed_kmh': speedKmh,
      'battery_level': batteryLevel,
      'is_charging': isCharging,
      'duty_status': dutyStatus,
      'active_task_id': activeTaskId,
      'active_task_title': activeTaskTitle,
      'active_visit_id': activeVisitId,
      'active_customer_name': activeCustomerName,
      'last_ping_at': lastPingAt.toIso8601String(),
    };
  }

  FieldTechnicianLocation toEntity() {
    return FieldTechnicianLocation(
      userId: userId,
      userName: userName,
      userPhone: userPhone,
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: accuracyMeters,
      speedKmh: speedKmh,
      batteryLevel: batteryLevel,
      isCharging: isCharging,
      dutyStatus: TechnicianDutyStatus.fromString(dutyStatus),
      activeTaskId: activeTaskId,
      activeTaskTitle: activeTaskTitle,
      activeVisitId: activeVisitId,
      activeCustomerName: activeCustomerName,
      lastPingAt: lastPingAt,
    );
  }

  factory FieldTechnicianLocationModel.fromEntity(FieldTechnicianLocation entity) {
    return FieldTechnicianLocationModel(
      userId: entity.userId,
      userName: entity.userName,
      userPhone: entity.userPhone,
      latitude: entity.latitude,
      longitude: entity.longitude,
      accuracyMeters: entity.accuracyMeters,
      speedKmh: entity.speedKmh,
      batteryLevel: entity.batteryLevel,
      isCharging: entity.isCharging,
      dutyStatus: entity.dutyStatus.name,
      activeTaskId: entity.activeTaskId,
      activeTaskTitle: entity.activeTaskTitle,
      activeVisitId: entity.activeVisitId,
      activeCustomerName: entity.activeCustomerName,
      lastPingAt: entity.lastPingAt,
    );
  }
}
