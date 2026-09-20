import '../../domain/entities/attendance_entity.dart';
import '../../domain/entities/attendance_status.dart';

class AttendanceModel extends AttendanceEntity {
  const AttendanceModel({
    required super.id,
    required super.organizationId,
    required super.userId,
    super.userName,
    super.userEmail,
    required super.date,
    required super.checkInAt,
    required super.checkInLatitude,
    required super.checkInLongitude,
    super.checkOutAt,
    super.checkOutLatitude,
    super.checkOutLongitude,
    super.totalMinutes,
    super.status = AttendanceStatus.present,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    // Handle joined user profile if available
    String? userName = json['user_name'] as String?;
    String? userEmail = json['user_email'] as String?;
    if (json['users'] is Map<String, dynamic>) {
      final userMap = json['users'] as Map<String, dynamic>;
      userName ??= userMap['name'] as String?;
      userEmail ??= userMap['email'] as String?;
    }

    // Parse date (e.g. '2026-09-20' or ISO timestamp)
    DateTime date;
    if (json['date'] is String) {
      date = DateTime.parse(json['date'] as String);
    } else if (json['date'] is DateTime) {
      date = json['date'] as DateTime;
    } else {
      date = DateTime.now();
    }

    return AttendanceModel(
      id: json['id'] as String,
      organizationId: json['organization_id'] as String,
      userId: json['user_id'] as String,
      userName: userName,
      userEmail: userEmail,
      date: date,
      checkInAt: json['check_in_at'] != null
          ? DateTime.parse(json['check_in_at'] as String)
          : DateTime.now(),
      checkInLatitude: (json['check_in_latitude'] as num?)?.toDouble() ?? 0.0,
      checkInLongitude: (json['check_in_longitude'] as num?)?.toDouble() ?? 0.0,
      checkOutAt: json['check_out_at'] != null
          ? DateTime.parse(json['check_out_at'] as String)
          : null,
      checkOutLatitude: (json['check_out_latitude'] as num?)?.toDouble(),
      checkOutLongitude: (json['check_out_longitude'] as num?)?.toDouble(),
      totalMinutes: json['total_minutes'] as int?,
      status: json['status'] != null
          ? AttendanceStatus.fromCode(json['status'] as String)
          : AttendanceStatus.present,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'user_id': userId,
      if (userName != null) 'user_name': userName,
      if (userEmail != null) 'user_email': userEmail,
      'date': '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'check_in_at': checkInAt.toIso8601String(),
      'check_in_latitude': checkInLatitude,
      'check_in_longitude': checkInLongitude,
      'check_out_at': checkOutAt?.toIso8601String(),
      'check_out_latitude': checkOutLatitude,
      'check_out_longitude': checkOutLongitude,
      'total_minutes': totalMinutes,
      'status': status.code,
    };
  }

  factory AttendanceModel.fromEntity(AttendanceEntity entity) {
    return AttendanceModel(
      id: entity.id,
      organizationId: entity.organizationId,
      userId: entity.userId,
      userName: entity.userName,
      userEmail: entity.userEmail,
      date: entity.date,
      checkInAt: entity.checkInAt,
      checkInLatitude: entity.checkInLatitude,
      checkInLongitude: entity.checkInLongitude,
      checkOutAt: entity.checkOutAt,
      checkOutLatitude: entity.checkOutLatitude,
      checkOutLongitude: entity.checkOutLongitude,
      totalMinutes: entity.totalMinutes,
      status: entity.status,
    );
  }

  @override
  AttendanceModel copyWith({
    String? id,
    String? organizationId,
    String? userId,
    String? userName,
    String? userEmail,
    DateTime? date,
    DateTime? checkInAt,
    double? checkInLatitude,
    double? checkInLongitude,
    DateTime? checkOutAt,
    double? checkOutLatitude,
    double? checkOutLongitude,
    int? totalMinutes,
    AttendanceStatus? status,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      date: date ?? this.date,
      checkInAt: checkInAt ?? this.checkInAt,
      checkInLatitude: checkInLatitude ?? this.checkInLatitude,
      checkInLongitude: checkInLongitude ?? this.checkInLongitude,
      checkOutAt: checkOutAt ?? this.checkOutAt,
      checkOutLatitude: checkOutLatitude ?? this.checkOutLatitude,
      checkOutLongitude: checkOutLongitude ?? this.checkOutLongitude,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      status: status ?? this.status,
    );
  }
}
