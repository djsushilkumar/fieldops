import 'beat_stop_entity.dart';

enum BeatExecutionStatus {
  planned,
  inProgress,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case BeatExecutionStatus.planned:
        return 'Planned';
      case BeatExecutionStatus.inProgress:
        return 'In Progress';
      case BeatExecutionStatus.completed:
        return 'Completed';
      case BeatExecutionStatus.cancelled:
        return 'Cancelled';
    }
  }

  static BeatExecutionStatus fromString(String? val) {
    if (val == null) return BeatExecutionStatus.planned;
    switch (val.toLowerCase()) {
      case 'inprogress':
      case 'in_progress':
        return BeatExecutionStatus.inProgress;
      case 'completed':
        return BeatExecutionStatus.completed;
      case 'cancelled':
        return BeatExecutionStatus.cancelled;
      default:
        return BeatExecutionStatus.planned;
    }
  }
}

class BeatExecutionEntity {
  final String id;
  final String beatPlanId;
  final String beatName;
  final String userId;
  final String userName;
  final String date; // yyyy-MM-dd
  final BeatExecutionStatus status;
  final int totalStops;
  final int visitedStops;
  final int skippedStops;
  final double complianceRate; // 0.0 to 100.0 %
  final DateTime? startTime;
  final DateTime? endTime;
  final List<BeatStopEntity> stops;
  final DateTime createdAt;

  const BeatExecutionEntity({
    required this.id,
    required this.beatPlanId,
    required this.beatName,
    required this.userId,
    required this.userName,
    required this.date,
    this.status = BeatExecutionStatus.planned,
    required this.totalStops,
    this.visitedStops = 0,
    this.skippedStops = 0,
    this.complianceRate = 0.0,
    this.startTime,
    this.endTime,
    this.stops = const [],
    required this.createdAt,
  });

  bool get isCompleted => status == BeatExecutionStatus.completed;

  BeatExecutionEntity copyWith({
    String? id,
    String? beatPlanId,
    String? beatName,
    String? userId,
    String? userName,
    String? date,
    BeatExecutionStatus? status,
    int? totalStops,
    int? visitedStops,
    int? skippedStops,
    double? complianceRate,
    DateTime? startTime,
    DateTime? endTime,
    List<BeatStopEntity>? stops,
    DateTime? createdAt,
  }) {
    return BeatExecutionEntity(
      id: id ?? this.id,
      beatPlanId: beatPlanId ?? this.beatPlanId,
      beatName: beatName ?? this.beatName,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      date: date ?? this.date,
      status: status ?? this.status,
      totalStops: totalStops ?? this.totalStops,
      visitedStops: visitedStops ?? this.visitedStops,
      skippedStops: skippedStops ?? this.skippedStops,
      complianceRate: complianceRate ?? this.complianceRate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      stops: stops ?? this.stops,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
