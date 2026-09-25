import 'dart:convert';
import '../../domain/entities/conveyance_claim_entity.dart';
import '../../domain/entities/conveyance_status.dart';
import '../../domain/entities/odometer_reading_entity.dart';
import '../../domain/entities/vehicle_type.dart';
import 'odometer_reading_model.dart';

class ConveyanceClaimModel extends ConveyanceClaimEntity {
  const ConveyanceClaimModel({
    required super.id,
    required super.organizationId,
    required super.userId,
    required super.userName,
    required super.shiftDate,
    required super.vehicleType,
    required super.ratePerKm,
    super.startReading,
    super.endReading,
    super.claimedDistanceKm,
    super.gpsDistanceKm,
    super.discrepancyPercentage,
    super.isFlaggedForFraud,
    super.fraudReason,
    super.status,
    super.approvedPayoutAmount,
    super.managerNotes,
    required super.createdAt,
    super.updatedAt,
  });

  factory ConveyanceClaimModel.fromEntity(ConveyanceClaimEntity entity) {
    return ConveyanceClaimModel(
      id: entity.id,
      organizationId: entity.organizationId,
      userId: entity.userId,
      userName: entity.userName,
      shiftDate: entity.shiftDate,
      vehicleType: entity.vehicleType,
      ratePerKm: entity.ratePerKm,
      startReading: entity.startReading,
      endReading: entity.endReading,
      claimedDistanceKm: entity.claimedDistanceKm,
      gpsDistanceKm: entity.gpsDistanceKm,
      discrepancyPercentage: entity.discrepancyPercentage,
      isFlaggedForFraud: entity.isFlaggedForFraud,
      fraudReason: entity.fraudReason,
      status: entity.status,
      approvedPayoutAmount: entity.approvedPayoutAmount,
      managerNotes: entity.managerNotes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory ConveyanceClaimModel.fromJson(Map<String, dynamic> json) {
    OdometerReadingEntity? start;
    if (json['start_reading'] != null) {
      if (json['start_reading'] is Map<String, dynamic>) {
        start = OdometerReadingModel.fromJson(json['start_reading'] as Map<String, dynamic>);
      } else if (json['start_reading'] is String && (json['start_reading'] as String).isNotEmpty) {
        start = OdometerReadingModel.fromJson(
            jsonDecode(json['start_reading'] as String) as Map<String, dynamic>);
      }
    }

    OdometerReadingEntity? end;
    if (json['end_reading'] != null) {
      if (json['end_reading'] is Map<String, dynamic>) {
        end = OdometerReadingModel.fromJson(json['end_reading'] as Map<String, dynamic>);
      } else if (json['end_reading'] is String && (json['end_reading'] as String).isNotEmpty) {
        end = OdometerReadingModel.fromJson(
            jsonDecode(json['end_reading'] as String) as Map<String, dynamic>);
      }
    }

    return ConveyanceClaimModel(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String? ?? 'org_default',
      userId: json['user_id'] as String,
      userName: json['user_name'] as String? ?? 'Unknown Technician',
      shiftDate: json['shift_date'] as String,
      vehicleType: VehicleType.fromString(json['vehicle_type'] as String?),
      ratePerKm: (json['rate_per_km'] as num?)?.toDouble() ?? 3.50,
      startReading: start,
      endReading: end,
      claimedDistanceKm: (json['claimed_distance_km'] as num?)?.toDouble() ?? 0.0,
      gpsDistanceKm: (json['gps_distance_km'] as num?)?.toDouble() ?? 0.0,
      discrepancyPercentage: (json['discrepancy_percentage'] as num?)?.toDouble() ??
          (json['discrepancy_pct'] as num?)?.toDouble() ??
          0.0,
      isFlaggedForFraud: json['is_flagged_for_fraud'] == true ||
          json['is_flagged'] == 1 ||
          json['is_flagged'] == true,
      fraudReason: json['fraud_reason'] as String?,
      status: ConveyanceStatus.fromString(json['status'] as String?),
      approvedPayoutAmount: (json['approved_payout_amount'] as num?)?.toDouble() ??
          (json['approved_payout'] as num?)?.toDouble() ??
          0.0,
      managerNotes: json['manager_notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'user_id': userId,
      'user_name': userName,
      'shift_date': shiftDate,
      'vehicle_type': vehicleType.name,
      'rate_per_km': ratePerKm,
      'start_reading': startReading != null
          ? OdometerReadingModel.fromEntity(startReading!).toJson()
          : null,
      'end_reading': endReading != null
          ? OdometerReadingModel.fromEntity(endReading!).toJson()
          : null,
      'claimed_distance_km': claimedDistanceKm,
      'gps_distance_km': gpsDistanceKm,
      'discrepancy_percentage': discrepancyPercentage,
      'is_flagged_for_fraud': isFlaggedForFraud,
      'fraud_reason': fraudReason,
      'status': status.name,
      'approved_payout_amount': approvedPayoutAmount,
      'manager_notes': managerNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Flat map representation for SQLite database
  Map<String, dynamic> toSqlMap() {
    return {
      'id': id,
      'organization_id': organizationId,
      'user_id': userId,
      'user_name': userName,
      'shift_date': shiftDate,
      'vehicle_type': vehicleType.name,
      'rate_per_km': ratePerKm,
      'start_odometer': startReading?.reading,
      'start_odo_photo': startReading?.photoPath,
      'start_time': startReading?.timestamp.toIso8601String(),
      'start_lat': startReading?.latitude,
      'start_lng': startReading?.longitude,
      'end_odometer': endReading?.reading,
      'end_odo_photo': endReading?.photoPath,
      'end_time': endReading?.timestamp.toIso8601String(),
      'end_lat': endReading?.latitude,
      'end_lng': endReading?.longitude,
      'claimed_distance_km': claimedDistanceKm,
      'gps_distance_km': gpsDistanceKm,
      'discrepancy_pct': discrepancyPercentage,
      'is_flagged': isFlaggedForFraud ? 1 : 0,
      'fraud_reason': fraudReason,
      'status': status.name,
      'approved_payout': approvedPayoutAmount,
      'manager_notes': managerNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory ConveyanceClaimModel.fromSqlMap(Map<String, dynamic> map) {
    OdometerReadingEntity? start;
    if (map['start_odometer'] != null) {
      start = OdometerReadingEntity(
        reading: (map['start_odometer'] as num).toDouble(),
        readingType: OdometerReadingType.start,
        photoPath: map['start_odo_photo'] as String? ?? '',
        timestamp: map['start_time'] != null
            ? DateTime.parse(map['start_time'] as String)
            : DateTime.now(),
        latitude: (map['start_lat'] as num?)?.toDouble() ?? 0.0,
        longitude: (map['start_lng'] as num?)?.toDouble() ?? 0.0,
      );
    }

    OdometerReadingEntity? end;
    if (map['end_odometer'] != null) {
      end = OdometerReadingEntity(
        reading: (map['end_odometer'] as num).toDouble(),
        readingType: OdometerReadingType.end,
        photoPath: map['end_odo_photo'] as String? ?? '',
        timestamp: map['end_time'] != null
            ? DateTime.parse(map['end_time'] as String)
            : DateTime.now(),
        latitude: (map['end_lat'] as num?)?.toDouble() ?? 0.0,
        longitude: (map['end_lng'] as num?)?.toDouble() ?? 0.0,
      );
    }

    return ConveyanceClaimModel(
      id: map['id'] as String,
      organizationId: map['organization_id'] as String? ?? 'org_default',
      userId: map['user_id'] as String,
      userName: map['user_name'] as String? ?? 'Field Specialist',
      shiftDate: map['shift_date'] as String,
      vehicleType: VehicleType.fromString(map['vehicle_type'] as String?),
      ratePerKm: (map['rate_per_km'] as num?)?.toDouble() ?? 3.50,
      startReading: start,
      endReading: end,
      claimedDistanceKm: (map['claimed_distance_km'] as num?)?.toDouble() ?? 0.0,
      gpsDistanceKm: (map['gps_distance_km'] as num?)?.toDouble() ?? 0.0,
      discrepancyPercentage: (map['discrepancy_pct'] as num?)?.toDouble() ?? 0.0,
      isFlaggedForFraud: map['is_flagged'] == 1 || map['is_flagged'] == true,
      fraudReason: map['fraud_reason'] as String?,
      status: ConveyanceStatus.fromString(map['status'] as String?),
      approvedPayoutAmount: (map['approved_payout'] as num?)?.toDouble() ?? 0.0,
      managerNotes: map['manager_notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}
