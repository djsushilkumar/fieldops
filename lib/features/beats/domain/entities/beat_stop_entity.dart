class BeatStopEntity {
  final String id;
  final String beatPlanId;
  final int sequenceOrder; // 1, 2, 3...
  final String customerId;
  final String customerName;
  final String locationId;
  final String locationAddress;
  final double latitude;
  final double longitude;
  final String? targetArrivalTime; // HH:mm
  final int estimatedVisitMinutes;
  final bool isMandatory;
  final bool isVisited;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String? skipReason;

  const BeatStopEntity({
    required this.id,
    required this.beatPlanId,
    required this.sequenceOrder,
    required this.customerId,
    required this.customerName,
    required this.locationId,
    required this.locationAddress,
    required this.latitude,
    required this.longitude,
    this.targetArrivalTime,
    this.estimatedVisitMinutes = 30,
    this.isMandatory = true,
    this.isVisited = false,
    this.checkInTime,
    this.checkOutTime,
    this.skipReason,
  });

  BeatStopEntity copyWith({
    String? id,
    String? beatPlanId,
    int? sequenceOrder,
    String? customerId,
    String? customerName,
    String? locationId,
    String? locationAddress,
    double? latitude,
    double? longitude,
    String? targetArrivalTime,
    int? estimatedVisitMinutes,
    bool? isMandatory,
    bool? isVisited,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    String? skipReason,
  }) {
    return BeatStopEntity(
      id: id ?? this.id,
      beatPlanId: beatPlanId ?? this.beatPlanId,
      sequenceOrder: sequenceOrder ?? this.sequenceOrder,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      locationId: locationId ?? this.locationId,
      locationAddress: locationAddress ?? this.locationAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      targetArrivalTime: targetArrivalTime ?? this.targetArrivalTime,
      estimatedVisitMinutes: estimatedVisitMinutes ?? this.estimatedVisitMinutes,
      isMandatory: isMandatory ?? this.isMandatory,
      isVisited: isVisited ?? this.isVisited,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      skipReason: skipReason ?? this.skipReason,
    );
  }
}
