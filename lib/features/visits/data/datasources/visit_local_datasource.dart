import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/visit_model.dart';

abstract class VisitLocalDataSource {
  Future<List<VisitModel>> getCachedVisits({String? userId, String? taskId});
  Future<void> cacheVisits(List<VisitModel> visits);
  Future<VisitModel?> getCachedVisit(String id);
  Future<void> cacheVisit(VisitModel visit);
  Future<VisitModel?> getActiveVisit({String? userId, String? taskId});
  Future<void> clearCache();
}

class VisitLocalDataSourceImpl implements VisitLocalDataSource {
  static const String _visitsKey = 'field_ops_cached_visits';

  final SharedPreferences? _prefs;
  final Map<String, VisitModel> _memoryVisits = {};

  VisitLocalDataSourceImpl({SharedPreferences? prefs}) : _prefs = prefs {
    _loadFromPrefs();
  }

  void _loadFromPrefs() {
    if (_prefs == null) return;
    final jsonStr = _prefs.getString(_visitsKey);
    if (jsonStr != null) {
      try {
        final list = jsonDecode(jsonStr) as List;
        for (final item in list) {
          final model = VisitModel.fromJson(item as Map<String, dynamic>);
          _memoryVisits[model.id] = model;
        }
      } catch (_) {}
    }
  }

  Future<void> _persist() async {
    if (_prefs == null) return;
    final list = _memoryVisits.values.map((v) => v.toJson()).toList();
    await _prefs.setString(_visitsKey, jsonEncode(list));
  }

  @override
  Future<List<VisitModel>> getCachedVisits({String? userId, String? taskId}) async {
    var list = _memoryVisits.values.toList();
    if (userId != null) {
      list = list.where((v) => v.userId == userId).toList();
    }
    if (taskId != null) {
      list = list.where((v) => v.taskId == taskId).toList();
    }
    list.sort((a, b) => b.checkInAt.compareTo(a.checkInAt));
    return list;
  }

  @override
  Future<void> cacheVisits(List<VisitModel> visits) async {
    for (final visit in visits) {
      _memoryVisits[visit.id] = visit;
    }
    await _persist();
  }

  @override
  Future<VisitModel?> getCachedVisit(String id) async {
    return _memoryVisits[id];
  }

  @override
  Future<void> cacheVisit(VisitModel visit) async {
    _memoryVisits[visit.id] = visit;
    await _persist();
  }

  @override
  Future<VisitModel?> getActiveVisit({String? userId, String? taskId}) async {
    final visits = _memoryVisits.values.where((v) => v.checkOutAt == null);
    if (userId != null && taskId != null) {
      final match = visits.where((v) => v.userId == userId && v.taskId == taskId);
      return match.isNotEmpty ? match.first : null;
    } else if (taskId != null) {
      final match = visits.where((v) => v.taskId == taskId);
      return match.isNotEmpty ? match.first : null;
    } else if (userId != null) {
      final match = visits.where((v) => v.userId == userId);
      return match.isNotEmpty ? match.first : null;
    }
    return visits.isNotEmpty ? visits.first : null;
  }

  @override
  Future<void> clearCache() async {
    _memoryVisits.clear();
    if (_prefs != null) {
      await _prefs.remove(_visitsKey);
    }
  }
}
