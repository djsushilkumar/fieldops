import '../../domain/entities/visit_entity.dart';

class VisitModel extends VisitEntity {
  const VisitModel({
    required super.id,
    required super.organizationId,
    super.taskId,
    super.taskTitle,
    required super.userId,
    super.userName,
    super.locationId,
    super.locationName,
    super.customerName,
    required super.checkInAt,
    required super.checkInLatitude,
    required super.checkInLongitude,
    super.checkOutAt,
    super.checkOutLatitude,
    super.checkOutLongitude,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
  });

  factory VisitModel.fromJson(Map<String, dynamic> json) {
    String? taskTitle;
    if (json['tasks'] != null && json['tasks'] is Map) {
      taskTitle = json['tasks']['title'] as String?;
    } else {
      taskTitle = json['task_title'] as String?;
    }

    String? userName;
    if (json['users'] != null && json['users'] is Map) {
      userName = json['users']['name'] as String?;
    } else {
      userName = json['user_name'] as String?;
    }

    String? locationName;
    String? customerName;
    if (json['locations'] != null && json['locations'] is Map) {
      locationName = json['locations']['name'] as String?;
      if (json['locations']['customers'] != null &&
          json['locations']['customers'] is Map) {
        customerName = json['locations']['customers']['name'] as String?;
      }
    } else {
      locationName = json['location_name'] as String?;
      customerName = json['customer_name'] as String?;
    }

    return VisitModel(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      taskId: json['task_id'] as String?,
      taskTitle: taskTitle,
      userId: json['user_id'] as String,
      userName: userName,
      locationId: json['location_id'] as String?,
      locationName: locationName,
      customerName: customerName,
      checkInAt: json['check_in_at'] != null
          ? DateTime.parse(json['check_in_at'] as String)
          : DateTime.now(),
      checkInLatitude: (json['check_in_latitude'] as num).toDouble(),
      checkInLongitude: (json['check_in_longitude'] as num).toDouble(),
      checkOutAt: json['check_out_at'] != null
          ? DateTime.parse(json['check_out_at'] as String)
          : null,
      checkOutLatitude: (json['check_out_latitude'] as num?)?.toDouble(),
      checkOutLongitude: (json['check_out_longitude'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'task_id': taskId,
      'task_title': taskTitle,
      'user_id': userId,
      'user_name': userName,
      'location_id': locationId,
      'location_name': locationName,
      'customer_name': customerName,
      'check_in_at': checkInAt.toIso8601String(),
      'check_in_latitude': checkInLatitude,
      'check_in_longitude': checkInLongitude,
      'check_out_at': checkOutAt?.toIso8601String(),
      'check_out_latitude': checkOutLatitude,
      'check_out_longitude': checkOutLongitude,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory VisitModel.fromEntity(VisitEntity entity) {
    return VisitModel(
      id: entity.id,
      organizationId: entity.organizationId,
      taskId: entity.taskId,
      taskTitle: entity.taskTitle,
      userId: entity.userId,
      userName: entity.userName,
      locationId: entity.locationId,
      locationName: entity.locationName,
      customerName: entity.customerName,
      checkInAt: entity.checkInAt,
      checkInLatitude: entity.checkInLatitude,
      checkInLongitude: entity.checkInLongitude,
      checkOutAt: entity.checkOutAt,
      checkOutLatitude: entity.checkOutLatitude,
      checkOutLongitude: entity.checkOutLongitude,
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  @override
  VisitModel copyWith({
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
    return VisitModel(
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
}
