import 'conveyance_status.dart';
import 'odometer_reading_entity.dart';
import 'vehicle_type.dart';

class ConveyanceClaimEntity {
  final String id;
  final String organizationId;
  final String userId;
  final String userName;
  final String shiftDate; // yyyy-MM-dd
  final VehicleType vehicleType;
  final double ratePerKm;
  final OdometerReadingEntity? startReading;
  final OdometerReadingEntity? endReading;
  final double claimedDistanceKm;
  final double gpsDistanceKm;
  final double discrepancyPercentage;
  final bool isFlaggedForFraud;
  final String? fraudReason;
  final ConveyanceStatus status;
  final double approvedPayoutAmount;
  final String? managerNotes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ConveyanceClaimEntity({
    required this.id,
    required this.organizationId,
    required this.userId,
    required this.userName,
    required this.shiftDate,
    required this.vehicleType,
    required this.ratePerKm,
    this.startReading,
    this.endReading,
    this.claimedDistanceKm = 0.0,
    this.gpsDistanceKm = 0.0,
    this.discrepancyPercentage = 0.0,
    this.isFlaggedForFraud = false,
    this.fraudReason,
    this.status = ConveyanceStatus.draft,
    this.approvedPayoutAmount = 0.0,
    this.managerNotes,
    required this.createdAt,
    this.updatedAt,
  });

  /// True if both start and end odometer readings have been recorded
  bool get isComplete => startReading != null && endReading != null;

  /// Calculated reimbursement estimate based on claimed distance
  double get estimatedPayout => (claimedDistanceKm * ratePerKm).clamp(0.0, double.infinity);

  ConveyanceClaimEntity copyWith({
    String? id,
    String? organizationId,
    String? userId,
    String? userName,
    String? shiftDate,
    VehicleType? vehicleType,
    double? ratePerKm,
    OdometerReadingEntity? startReading,
    OdometerReadingEntity? endReading,
    double? claimedDistanceKm,
    double? gpsDistanceKm,
    double? discrepancyPercentage,
    bool? isFlaggedForFraud,
    String? fraudReason,
    ConveyanceStatus? status,
    double? approvedPayoutAmount,
    String? managerNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConveyanceClaimEntity(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      shiftDate: shiftDate ?? this.shiftDate,
      vehicleType: vehicleType ?? this.vehicleType,
      ratePerKm: ratePerKm ?? this.ratePerKm,
      startReading: startReading ?? this.startReading,
      endReading: endReading ?? this.endReading,
      claimedDistanceKm: claimedDistanceKm ?? this.claimedDistanceKm,
      gpsDistanceKm: gpsDistanceKm ?? this.gpsDistanceKm,
      discrepancyPercentage: discrepancyPercentage ?? this.discrepancyPercentage,
      isFlaggedForFraud: isFlaggedForFraud ?? this.isFlaggedForFraud,
      fraudReason: fraudReason ?? this.fraudReason,
      status: status ?? this.status,
      approvedPayoutAmount: approvedPayoutAmount ?? this.approvedPayoutAmount,
      managerNotes: managerNotes ?? this.managerNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
