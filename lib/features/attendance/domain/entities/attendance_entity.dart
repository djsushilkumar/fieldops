import 'package:intl/intl.dart';
import 'attendance_status.dart';

class AttendanceEntity {
  final String id;
  final String organizationId;
  final String userId;
  final String? userName;
  final String? userEmail;
  final DateTime date;
  final DateTime checkInAt;
  final double checkInLatitude;
  final double checkInLongitude;
  final DateTime? checkOutAt;
  final double? checkOutLatitude;
  final double? checkOutLongitude;
  final int? totalMinutes;
  final AttendanceStatus status;

  const AttendanceEntity({
    required this.id,
    required this.organizationId,
    required this.userId,
    this.userName,
    this.userEmail,
    required this.date,
    required this.checkInAt,
    required this.checkInLatitude,
    required this.checkInLongitude,
    this.checkOutAt,
    this.checkOutLatitude,
    this.checkOutLongitude,
    this.totalMinutes,
    this.status = AttendanceStatus.present,
  });

  bool get isCheckedIn => checkOutAt == null;
  bool get isCheckedOut => checkOutAt != null;

  Duration get workingDuration {
    if (checkOutAt != null) {
      return checkOutAt!.difference(checkInAt);
    }
    final now = DateTime.now();
    if (now.isBefore(checkInAt)) {
      return Duration.zero;
    }
    return now.difference(checkInAt);
  }

  String get formattedDuration {
    final duration = totalMinutes != null
        ? Duration(minutes: totalMinutes!)
        : workingDuration;

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String get formattedCheckInTime {
    return DateFormat('hh:mm a').format(checkInAt.toLocal());
  }

  String? get formattedCheckOutTime {
    if (checkOutAt == null) return null;
    return DateFormat('hh:mm a').format(checkOutAt!.toLocal());
  }

  String get formattedDate {
    return DateFormat('EEE, MMM d, yyyy').format(date);
  }

  AttendanceEntity copyWith({
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
    return AttendanceEntity(
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
