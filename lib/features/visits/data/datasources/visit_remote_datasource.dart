import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/visit_model.dart';

abstract class VisitRemoteDataSource {
  Future<List<VisitModel>> getVisits({
    String? userId,
    String? taskId,
    DateTime? date,
  });

  Future<VisitModel> getVisitDetail(String visitId);

  Future<VisitModel?> getActiveVisit({String? userId, String? taskId});

  Future<VisitModel> checkIn({
    required String taskId,
    required String locationId,
    required double latitude,
    required double longitude,
    String? notes,
  });

  Future<VisitModel> checkOut({
    required String visitId,
    required double latitude,
    required double longitude,
    String? notes,
  });
}

class SupabaseVisitRemoteDataSource implements VisitRemoteDataSource {
  final SupabaseClient _client;

  SupabaseVisitRemoteDataSource(this._client);

  @override
  Future<List<VisitModel>> getVisits({
    String? userId,
    String? taskId,
    DateTime? date,
  }) async {
    try {
      var query = _client.from('visits').select('''
        *,
        tasks (id, title),
        users (id, name),
        locations (id, name, customers (id, name))
      ''');

      if (userId != null) {
        query = query.eq('user_id', userId);
      }
      if (taskId != null) {
        query = query.eq('task_id', taskId);
      }
      if (date != null) {
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        query = query
            .gte('check_in_at', startOfDay.toIso8601String())
            .lt('check_in_at', endOfDay.toIso8601String());
      }

      final response = await query.order('check_in_at', ascending: false);
      return (response as List)
          .map((item) => VisitModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch visits from Supabase: $e');
    }
  }

  @override
  Future<VisitModel> getVisitDetail(String visitId) async {
    try {
      final response = await _client
          .from('visits')
          .select('''
            *,
            tasks (id, title),
            users (id, name),
            locations (id, name, customers (id, name))
          ''')
          .eq('id', visitId)
          .single();

      return VisitModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to fetch visit detail: $e');
    }
  }

  @override
  Future<VisitModel?> getActiveVisit({String? userId, String? taskId}) async {
    try {
      var query = _client
          .from('visits')
          .select('''
            *,
            tasks (id, title),
            users (id, name),
            locations (id, name, customers (id, name))
          ''')
          .isFilter('check_out_at', null);

      if (userId != null) {
        query = query.eq('user_id', userId);
      }
      if (taskId != null) {
        query = query.eq('task_id', taskId);
      }

      final response = await query.maybeSingle();
      if (response == null) return null;
      return VisitModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to fetch active visit: $e');
    }
  }

  @override
  Future<VisitModel> checkIn({
    required String taskId,
    required String locationId,
    required double latitude,
    required double longitude,
    String? notes,
  }) async {
    try {
      final user = _client.auth.currentUser;
      final userId = user?.id ?? 'usr-employee-001';

      final insertPayload = {
        'task_id': taskId,
        'location_id': locationId,
        'user_id': userId,
        'check_in_at': DateTime.now().toIso8601String(),
        'check_in_latitude': latitude,
        'check_in_longitude': longitude,
        if (notes != null) 'notes': notes,
      };

      final response = await _client
          .from('visits')
          .insert(insertPayload)
          .select('''
            *,
            tasks (id, title),
            users (id, name),
            locations (id, name, customers (id, name))
          ''')
          .single();

      return VisitModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to check in visit: $e');
    }
  }

  @override
  Future<VisitModel> checkOut({
    required String visitId,
    required double latitude,
    required double longitude,
    String? notes,
  }) async {
    try {
      final updatePayload = {
        'check_out_at': DateTime.now().toIso8601String(),
        'check_out_latitude': latitude,
        'check_out_longitude': longitude,
        if (notes != null) 'notes': notes,
      };

      final response = await _client
          .from('visits')
          .update(updatePayload)
          .eq('id', visitId)
          .select('''
            *,
            tasks (id, title),
            users (id, name),
            locations (id, name, customers (id, name))
          ''')
          .single();

      return VisitModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to check out visit: $e');
    }
  }
}
