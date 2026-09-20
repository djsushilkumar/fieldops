import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../../../core/errors/exceptions.dart';
import '../models/task_model.dart';

abstract class TaskRemoteDataSource {
  Future<List<TaskModel>> getTasks({
    String? organizationId,
    String? assignedUserId,
    String? status,
    String? priority,
  });
  Future<TaskModel> getTask(String taskId);
  Future<TaskModel> createTask(TaskModel task, {String? assignToUserId});
  Future<TaskModel> assignTask(String taskId, String userId);
  Future<TaskModel> updateTaskStatus(
    String taskId,
    String status, {
    DateTime? actualStart,
    DateTime? actualEnd,
    String? notes,
  });
}

class SupabaseTaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  final supa.SupabaseClient client;

  SupabaseTaskRemoteDataSourceImpl(this.client);

  @override
  Future<List<TaskModel>> getTasks({
    String? organizationId,
    String? assignedUserId,
    String? status,
    String? priority,
  }) async {
    try {
      var query = client.from('tasks').select('''
        *,
        task_assignments(user_id, users(name, email)),
        customers(name),
        locations(name)
      ''');

      if (organizationId != null) {
        query = query.eq('organization_id', organizationId);
      }
      if (status != null) {
        query = query.eq('status', status);
      }
      if (priority != null) {
        query = query.eq('priority', priority);
      }

      final data = await query.order('created_at', ascending: false);
      final list = (data as List<dynamic>).map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        // Map assignments and joined customer/location names
        if (map['customers'] != null) {
          map['customer_name'] = map['customers']['name'];
        }
        if (map['locations'] != null) {
          map['location_name'] = map['locations']['name'];
        }
        if (map['task_assignments'] != null && (map['task_assignments'] as List).isNotEmpty) {
          final firstAssign = (map['task_assignments'] as List).first;
          map['assigned_to_user_id'] = firstAssign['user_id'];
          if (firstAssign['users'] != null) {
            map['assigned_to_user_name'] = firstAssign['users']['name'];
          }
        }
        return TaskModel.fromJson(map);
      }).toList();

      if (assignedUserId != null) {
        return list.where((t) => t.assignedToUserId == assignedUserId).toList();
      }

      return list;
    } catch (e) {
      throw ServerException('Failed to fetch tasks: $e');
    }
  }

  @override
  Future<TaskModel> getTask(String taskId) async {
    try {
      final data = await client.from('tasks').select('''
        *,
        task_assignments(user_id, users(name, email)),
        customers(name),
        locations(name)
      ''').eq('id', taskId).single();

      final map = Map<String, dynamic>.from(data);
      if (map['customers'] != null) {
        map['customer_name'] = map['customers']['name'];
      }
      if (map['locations'] != null) {
        map['location_name'] = map['locations']['name'];
      }
      if (map['task_assignments'] != null && (map['task_assignments'] as List).isNotEmpty) {
        final firstAssign = (map['task_assignments'] as List).first;
        map['assigned_to_user_id'] = firstAssign['user_id'];
        if (firstAssign['users'] != null) {
          map['assigned_to_user_name'] = firstAssign['users']['name'];
        }
      }

      return TaskModel.fromJson(map);
    } catch (e) {
      throw ServerException('Failed to fetch task detail: $e');
    }
  }

  @override
  Future<TaskModel> createTask(TaskModel task, {String? assignToUserId}) async {
    try {
      final taskMap = task.toJson();
      taskMap.remove('id'); // let db assign or keep uuid
      taskMap.remove('assigned_to_user_id');
      taskMap.remove('assigned_to_user_name');
      taskMap.remove('customer_name');
      taskMap.remove('location_name');
      taskMap.remove('creator_name');

      final inserted = await client.from('tasks').insert(taskMap).select().single();
      final newTaskId = inserted['id'] as String;

      if (assignToUserId != null) {
        await client.from('task_assignments').insert({
          'task_id': newTaskId,
          'user_id': assignToUserId,
          'assigned_by': client.auth.currentUser?.id,
        });
      }

      return await getTask(newTaskId);
    } catch (e) {
      throw ServerException('Failed to create task: $e');
    }
  }

  @override
  Future<TaskModel> assignTask(String taskId, String userId) async {
    try {
      // Remove previous assignment if any
      await client.from('task_assignments').delete().eq('task_id', taskId);

      // Insert new assignment
      await client.from('task_assignments').insert({
        'task_id': taskId,
        'user_id': userId,
        'assigned_by': client.auth.currentUser?.id,
      });

      // Update task status to ASSIGNED if it was DRAFT
      await client.from('tasks').update({
        'status': 'ASSIGNED',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', taskId);

      return await getTask(taskId);
    } catch (e) {
      throw ServerException('Failed to assign task: $e');
    }
  }

  @override
  Future<TaskModel> updateTaskStatus(
    String taskId,
    String status, {
    DateTime? actualStart,
    DateTime? actualEnd,
    String? notes,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (actualStart != null) updates['actual_start'] = actualStart.toIso8601String();
      if (actualEnd != null) updates['actual_end'] = actualEnd.toIso8601String();
      if (notes != null) updates['notes'] = notes;

      await client.from('tasks').update(updates).eq('id', taskId);
      return await getTask(taskId);
    } catch (e) {
      throw ServerException('Failed to update task status: $e');
    }
  }
}
