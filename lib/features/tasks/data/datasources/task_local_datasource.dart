import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';

abstract class TaskLocalDataSource {
  Future<List<TaskModel>> getCachedTasks({String? organizationId});
  Future<TaskModel?> getCachedTask(String taskId);
  Future<void> cacheTasks(List<TaskModel> tasks);
  Future<void> cacheTask(TaskModel task);
  Future<void> clearTasks();
}

class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  static const String _prefKeyTasks = 'fieldops_cached_tasks_v1';
  Map<String, TaskModel>? _memoryCache;

  Future<Map<String, TaskModel>> _loadMap() async {
    if (_memoryCache != null) return _memoryCache!;
    _memoryCache = {};
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefKeyTasks);
      if (jsonString != null) {
        final List<dynamic> list = jsonDecode(jsonString);
        for (final item in list) {
          final model = TaskModel.fromJson(item as Map<String, dynamic>);
          _memoryCache![model.id] = model;
        }
      }
    } catch (_) {}
    return _memoryCache!;
  }

  Future<void> _persistMap() async {
    if (_memoryCache == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _memoryCache!.values.map((e) => e.toJson()).toList();
      await prefs.setString(_prefKeyTasks, jsonEncode(list));
    } catch (_) {}
  }

  @override
  Future<List<TaskModel>> getCachedTasks({String? organizationId}) async {
    final map = await _loadMap();
    var list = map.values.toList();
    if (organizationId != null) {
      list = list.where((t) => t.organizationId == organizationId).toList();
    }
    return list;
  }

  @override
  Future<TaskModel?> getCachedTask(String taskId) async {
    final map = await _loadMap();
    return map[taskId];
  }

  @override
  Future<void> cacheTasks(List<TaskModel> tasks) async {
    final map = await _loadMap();
    for (final task in tasks) {
      map[task.id] = task;
    }
    await _persistMap();
  }

  @override
  Future<void> cacheTask(TaskModel task) async {
    final map = await _loadMap();
    map[task.id] = task;
    await _persistMap();
  }

  @override
  Future<void> clearTasks() async {
    _memoryCache = {};
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKeyTasks);
    } catch (_) {}
  }
}
