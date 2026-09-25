import '../../domain/entities/beat_stop_entity.dart';

class BeatStopModel extends BeatStopEntity {
  const BeatStopModel({
    required super.id,
    required super.beatPlanId,
    required super.sequenceOrder,
    required super.customerId,
    required super.customerName,
    required super.locationId,
    required super.locationAddress,
    required super.latitude,
    required super.longitude,
    super.targetArrivalTime,
    super.estimatedVisitMinutes,
    super.isMandatory,
    super.isVisited,
    super.checkInTime,
    super.checkOutTime,
    super.skipReason,
  });

  factory BeatStopModel.fromEntity(BeatStopEntity entity) {
    return BeatStopModel(
      id: entity.id,
      beatPlanId: entity.beatPlanId,
      sequenceOrder: entity.sequenceOrder,
      customerId: entity.customerId,
      customerName: entity.customerName,
      locationId: entity.locationId,
      locationAddress: entity.locationAddress,
      latitude: entity.latitude,
      longitude: entity.longitude,
      targetArrivalTime: entity.targetArrivalTime,
      estimatedVisitMinutes: entity.estimatedVisitMinutes,
      isMandatory: entity.isMandatory,
      isVisited: entity.isVisited,
      checkInTime: entity.checkInTime,
      checkOutTime: entity.checkOutTime,
      skipReason: entity.skipReason,
    );
  }

  factory BeatStopModel.fromJson(Map<String, dynamic> json) {
    return BeatStopModel(
      id: json['id'] as String,
      beatPlanId: json['beat_plan_id'] as String,
      sequenceOrder: json['sequence_order'] as int? ?? 1,
      customerId: json['customer_id'] as String,
      customerName: json['customer_name'] as String? ?? 'Client Store',
      locationId: json['location_id'] as String? ?? '',
      locationAddress: json['location_address'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      targetArrivalTime: json['target_arrival_time'] as String?,
      estimatedVisitMinutes: json['estimated_visit_minutes'] as int? ?? 30,
      isMandatory: json['is_mandatory'] != false,
      isVisited: json['is_visited'] == true || json['is_visited'] == 1,
      checkInTime: json['check_in_time'] != null
          ? DateTime.parse(json['check_in_time'] as String)
          : null,
      checkOutTime: json['check_out_time'] != null
          ? DateTime.parse(json['check_out_time'] as String)
          : null,
      skipReason: json['skip_reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'beat_plan_id': beatPlanId,
      'sequence_order': sequenceOrder,
      'customer_id': customerId,
      'customer_name': customerName,
      'location_id': locationId,
      'location_address': locationAddress,
      'latitude': latitude,
      'longitude': longitude,
      'target_arrival_time': targetArrivalTime,
      'estimated_visit_minutes': estimatedVisitMinutes,
      'is_mandatory': isMandatory,
      'is_visited': isVisited,
      'check_in_time': checkInTime?.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'skip_reason': skipReason,
    };
  }
}
