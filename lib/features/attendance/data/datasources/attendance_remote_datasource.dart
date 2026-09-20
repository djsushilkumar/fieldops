import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/attendance_model.dart';

abstract class AttendanceRemoteDataSource {
  Future<AttendanceModel?> getTodayAttendance({required String userId});

  Future<List<AttendanceModel>> getAttendanceHistory({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<List<AttendanceModel>> getTeamAttendance({
    required String organizationId,
    required DateTime date,
  });

  Future<AttendanceModel> checkIn({
    required String userId,
    required String organizationId,
    required double latitude,
    required double longitude,
    DateTime? checkInTime,
  });

  Future<AttendanceModel> checkOut({
    required String attendanceId,
    required double latitude,
    required double longitude,
    DateTime? checkOutTime,
  });
}

class SupabaseAttendanceRemoteDataSource implements AttendanceRemoteDataSource {
  final SupabaseClient _client;

  SupabaseAttendanceRemoteDataSource(this._client);

  @override
  Future<AttendanceModel?> getTodayAttendance({required String userId}) async {
    try {
      final now = DateTime.now();
      final dateKey = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final response = await _client
          .from('attendance')
          .select('*, users(name, email)')
          .eq('user_id', userId)
          .eq('date', dateKey)
          .maybeSingle();

      if (response == null) return null;
      return AttendanceModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to fetch today attendance: $e');
    }
  }

  @override
  Future<List<AttendanceModel>> getAttendanceHistory({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _client
          .from('attendance')
          .select('*, users(name, email)')
          .eq('user_id', userId);

      if (startDate != null) {
        final startKey = '${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
        query = query.gte('date', startKey);
      }
      if (endDate != null) {
        final endKey = '${endDate.year.toString().padLeft(4, '0')}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
        query = query.lte('date', endKey);
      }

      final response = await query.order('date', ascending: false);
      return (response as List)
          .map((item) => AttendanceModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch attendance history: $e');
    }
  }

  @override
  Future<List<AttendanceModel>> getTeamAttendance({
    required String organizationId,
    required DateTime date,
  }) async {
    try {
      final dateKey = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final response = await _client
          .from('attendance')
          .select('*, users(name, email)')
          .eq('organization_id', organizationId)
          .eq('date', dateKey)
          .order('check_in_at', ascending: true);

      return (response as List)
          .map((item) => AttendanceModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch team attendance: $e');
    }
  }

  @override
  Future<AttendanceModel> checkIn({
    required String userId,
    required String organizationId,
    required double latitude,
    required double longitude,
    DateTime? checkInTime,
  }) async {
    try {
      final now = checkInTime ?? DateTime.now();
      final dateKey = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final insertData = {
        'organization_id': organizationId,
        'user_id': userId,
        'date': dateKey,
        'check_in_at': now.toIso8601String(),
        'check_in_latitude': latitude,
        'check_in_longitude': longitude,
        'status': 'PRESENT',
      };

      final response = await _client
          .from('attendance')
          .insert(insertData)
          .select('*, users(name, email)')
          .single();

      return AttendanceModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to record check-in: $e');
    }
  }

  @override
  Future<AttendanceModel> checkOut({
    required String attendanceId,
    required double latitude,
    required double longitude,
    DateTime? checkOutTime,
  }) async {
    try {
      final now = checkOutTime ?? DateTime.now();

      // First retrieve existing to compute total minutes
      final existing = await _client
          .from('attendance')
          .select('check_in_at')
          .eq('id', attendanceId)
          .single();

      final checkInAt = DateTime.parse(existing['check_in_at'] as String);
      final totalMinutes = now.difference(checkInAt).inMinutes;

      final updateData = {
        'check_out_at': now.toIso8601String(),
        'check_out_latitude': latitude,
        'check_out_longitude': longitude,
        'total_minutes': totalMinutes,
      };

      final response = await _client
          .from('attendance')
          .update(updateData)
          .eq('id', attendanceId)
          .select('*, users(name, email)')
          .single();

      return AttendanceModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to record check-out: $e');
    }
  }
}
