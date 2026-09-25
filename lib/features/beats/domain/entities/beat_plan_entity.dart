import 'beat_frequency.dart';
import 'beat_stop_entity.dart';

class BeatPlanEntity {
  final String id;
  final String organizationId;
  final String code; // e.g. "BEAT-NORTH-01"
  final String name;
  final String? description;
  final String assignedTechnicianId;
  final String assignedTechnicianName;
  final BeatFrequency frequency;
  final int dayOfWeek; // 1 = Monday, 7 = Sunday
  final List<BeatStopEntity> stops;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BeatPlanEntity({
    required this.id,
    required this.organizationId,
    required this.code,
    required this.name,
    this.description,
    required this.assignedTechnicianId,
    required this.assignedTechnicianName,
    this.frequency = BeatFrequency.daily,
    this.dayOfWeek = 1,
    this.stops = const [],
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  int get totalStopsCount => stops.length;

  int get estimatedTotalMinutes =>
      stops.fold<int>(0, (sum, stop) => sum + stop.estimatedVisitMinutes);

  BeatPlanEntity copyWith({
    String? id,
    String? organizationId,
    String? code,
    String? name,
    String? description,
    String? assignedTechnicianId,
    String? assignedTechnicianName,
    BeatFrequency? frequency,
    int? dayOfWeek,
    List<BeatStopEntity>? stops,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BeatPlanEntity(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      assignedTechnicianId: assignedTechnicianId ?? this.assignedTechnicianId,
      assignedTechnicianName: assignedTechnicianName ?? this.assignedTechnicianName,
      frequency: frequency ?? this.frequency,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      stops: stops ?? this.stops,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
