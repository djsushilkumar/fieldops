class VisitEntity {
  final String id;
  final String organizationId;
  final String? taskId;
  final String? taskTitle;
  final String userId;
  final String? userName;
  final String? locationId;
  final String? locationName;
  final String? customerName;
  final DateTime checkInAt;
  final double checkInLatitude;
  final double checkInLongitude;
  final DateTime? checkOutAt;
  final double? checkOutLatitude;
  final double? checkOutLongitude;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VisitEntity({
    required this.id,
    required this.organizationId,
    this.taskId,
    this.taskTitle,
    required this.userId,
    this.userName,
    this.locationId,
    this.locationName,
    this.customerName,
    required this.checkInAt,
    required this.checkInLatitude,
    required this.checkInLongitude,
    this.checkOutAt,
    this.checkOutLatitude,
    this.checkOutLongitude,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isCompleted => checkOutAt != null;
  bool get isActive => checkOutAt == null;

  int? get durationMinutes {
    if (checkOutAt == null) return null;
    return checkOutAt!.difference(checkInAt).inMinutes;
  }

  VisitEntity copyWith({
    String? id,
    String? organizationId,
    String? taskId,
    String? taskTitle,
    String? userId,
    String? userName,
    String? locationId,
    String? locationName,
    String? customerName,
    DateTime? checkInAt,
    double? checkInLatitude,
    double? checkInLongitude,
    DateTime? checkOutAt,
    double? checkOutLatitude,
    double? checkOutLongitude,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VisitEntity(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      taskId: taskId ?? this.taskId,
      taskTitle: taskTitle ?? this.taskTitle,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      locationId: locationId ?? this.locationId,
      locationName: locationName ?? this.locationName,
      customerName: customerName ?? this.customerName,
      checkInAt: checkInAt ?? this.checkInAt,
      checkInLatitude: checkInLatitude ?? this.checkInLatitude,
      checkInLongitude: checkInLongitude ?? this.checkInLongitude,
      checkOutAt: checkOutAt ?? this.checkOutAt,
      checkOutLatitude: checkOutLatitude ?? this.checkOutLatitude,
      checkOutLongitude: checkOutLongitude ?? this.checkOutLongitude,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VisitEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
