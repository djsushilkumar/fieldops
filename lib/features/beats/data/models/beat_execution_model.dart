import 'dart:convert';
import '../../domain/entities/beat_execution_entity.dart';
import 'beat_stop_model.dart';

class BeatExecutionModel extends BeatExecutionEntity {
  const BeatExecutionModel({
    required super.id,
    required super.beatPlanId,
    required super.beatName,
    required super.userId,
    required super.userName,
    required super.date,
    super.status,
    required super.totalStops,
    super.visitedStops,
    super.skippedStops,
    super.complianceRate,
    super.startTime,
    super.endTime,
    super.stops,
    required super.createdAt,
  });

  factory BeatExecutionModel.fromEntity(BeatExecutionEntity entity) {
    return BeatExecutionModel(
      id: entity.id,
      beatPlanId: entity.beatPlanId,
      beatName: entity.beatName,
      userId: entity.userId,
      userName: entity.userName,
      date: entity.date,
      status: entity.status,
      totalStops: entity.totalStops,
      visitedStops: entity.visitedStops,
      skippedStops: entity.skippedStops,
      complianceRate: entity.complianceRate,
      startTime: entity.startTime,
      endTime: entity.endTime,
      stops: entity.stops,
      createdAt: entity.createdAt,
    );
  }

  factory BeatExecutionModel.fromJson(Map<String, dynamic> json) {
    List<BeatStopModel> parsedStops = [];
    if (json['stops'] != null) {
      if (json['stops'] is List) {
        parsedStops = (json['stops'] as List)
            .map((s) => BeatStopModel.fromJson(s as Map<String, dynamic>))
            .toList();
      } else if (json['stops'] is String) {
        try {
          final decoded = jsonDecode(json['stops'] as String) as List;
          parsedStops = decoded
              .map((s) => BeatStopModel.fromJson(s as Map<String, dynamic>))
              .toList();
        } catch (_) {}
      }
    }

    return BeatExecutionModel(
      id: json['id'] as String,
      beatPlanId: json['beat_plan_id'] as String,
      beatName: json['beat_name'] as String? ?? 'Daily Beat Itinerary',
      userId: json['user_id'] as String,
      userName: json['user_name'] as String? ?? 'Field Executive',
      date: json['date'] as String,
      status: BeatExecutionStatus.fromString(json['status'] as String?),
      totalStops: json['total_stops'] as int? ?? parsedStops.length,
      visitedStops: json['visited_stops'] as int? ?? 0,
      skippedStops: json['skipped_stops'] as int? ?? 0,
      complianceRate: (json['compliance_rate'] as num?)?.toDouble() ?? 0.0,
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'] as String)
          : null,
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      stops: parsedStops,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'beat_plan_id': beatPlanId,
      'beat_name': beatName,
      'user_id': userId,
      'user_name': userName,
      'date': date,
      'status': status.name,
      'total_stops': totalStops,
      'visited_stops': visitedStops,
      'skipped_stops': skippedStops,
      'compliance_rate': complianceRate,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'stops': stops.map((s) => BeatStopModel.fromEntity(s).toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toSqlMap() {
    return {
      'id': id,
      'beat_plan_id': beatPlanId,
      'beat_name': beatName,
      'user_id': userId,
      'user_name': userName,
      'date': date,
      'status': status.name,
      'total_stops': totalStops,
      'visited_stops': visitedStops,
      'skipped_stops': skippedStops,
      'compliance_rate': complianceRate,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'stops_json': jsonEncode(stops.map((s) => BeatStopModel.fromEntity(s).toJson()).toList()),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory BeatExecutionModel.fromSqlMap(Map<String, dynamic> map) {
    List<BeatStopModel> parsedStops = [];
    if (map['stops_json'] != null) {
      try {
        final decoded = jsonDecode(map['stops_json'] as String) as List;
        parsedStops = decoded
            .map((s) => BeatStopModel.fromJson(s as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    return BeatExecutionModel(
      id: map['id'] as String,
      beatPlanId: map['beat_plan_id'] as String,
      beatName: map['beat_name'] as String? ?? 'Daily Beat Itinerary',
      userId: map['user_id'] as String,
      userName: map['user_name'] as String? ?? 'Field Executive',
      date: map['date'] as String,
      status: BeatExecutionStatus.fromString(map['status'] as String?),
      totalStops: map['total_stops'] as int? ?? parsedStops.length,
      visitedStops: map['visited_stops'] as int? ?? 0,
      skippedStops: map['skipped_stops'] as int? ?? 0,
      complianceRate: (map['compliance_rate'] as num?)?.toDouble() ?? 0.0,
      startTime: map['start_time'] != null
          ? DateTime.parse(map['start_time'] as String)
          : null,
      endTime: map['end_time'] != null
          ? DateTime.parse(map['end_time'] as String)
          : null,
      stops: parsedStops,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }
}
