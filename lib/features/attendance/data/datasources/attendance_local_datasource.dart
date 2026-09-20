import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/attendance_model.dart';

abstract class AttendanceLocalDataSource {
  Future<AttendanceModel?> getCachedTodayAttendance(String userId);
  Future<void> cacheTodayAttendance(AttendanceModel attendance);
  Future<List<AttendanceModel>> getCachedHistory(String userId);
  Future<void> cacheHistory(String userId, List<AttendanceModel> history);
  Future<List<AttendanceModel>> getCachedTeamAttendance(String organizationId, String dateKey);
  Future<void> cacheTeamAttendance(String organizationId, String dateKey, List<AttendanceModel> attendance);
  Future<void> clearCache();
}

class AttendanceLocalDataSourceImpl implements AttendanceLocalDataSource {
  static const String _todayKeyPrefix = 'field_ops_attendance_today_';
  static const String _historyKeyPrefix = 'field_ops_attendance_hist_';
  static const String _teamKeyPrefix = 'field_ops_attendance_team_';

  final SharedPreferences? _prefs;
  final Map<String, AttendanceModel> _memoryToday = {};
  final Map<String, List<AttendanceModel>> _memoryHistory = {};
  final Map<String, List<AttendanceModel>> _memoryTeam = {};

  AttendanceLocalDataSourceImpl({SharedPreferences? prefs}) : _prefs = prefs {
    _loadFromPrefs();
  }

  void _loadFromPrefs() {
    if (_prefs == null) return;
    try {
      final keys = _prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_todayKeyPrefix)) {
          final userId = key.substring(_todayKeyPrefix.length);
          final raw = _prefs.getString(key);
          if (raw != null) {
            _memoryToday[userId] = AttendanceModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
          }
        } else if (key.startsWith(_historyKeyPrefix)) {
          final userId = key.substring(_historyKeyPrefix.length);
          final raw = _prefs.getString(key);
          if (raw != null) {
            final list = (jsonDecode(raw) as List)
                .map((e) => AttendanceModel.fromJson(e as Map<String, dynamic>))
                .toList();
            _memoryHistory[userId] = list;
          }
        }
      }
    } catch (_) {}
  }

  @override
  Future<AttendanceModel?> getCachedTodayAttendance(String userId) async {
    return _memoryToday[userId];
  }

  @override
  Future<void> cacheTodayAttendance(AttendanceModel attendance) async {
    _memoryToday[attendance.userId] = attendance;
    if (_prefs != null) {
      await _prefs.setString(
        '$_todayKeyPrefix${attendance.userId}',
        jsonEncode(attendance.toJson()),
      );
    }
  }

  @override
  Future<List<AttendanceModel>> getCachedHistory(String userId) async {
    return _memoryHistory[userId] ?? [];
  }

  @override
  Future<void> cacheHistory(String userId, List<AttendanceModel> history) async {
    _memoryHistory[userId] = history;
    if (_prefs != null) {
      final jsonList = history.map((e) => e.toJson()).toList();
      await _prefs.setString(
        '$_historyKeyPrefix$userId',
        jsonEncode(jsonList),
      );
    }
  }

  @override
  Future<List<AttendanceModel>> getCachedTeamAttendance(String organizationId, String dateKey) async {
    final compositeKey = '${organizationId}_$dateKey';
    return _memoryTeam[compositeKey] ?? [];
  }

  @override
  Future<void> cacheTeamAttendance(
    String organizationId,
    String dateKey,
    List<AttendanceModel> attendance,
  ) async {
    final compositeKey = '${organizationId}_$dateKey';
    _memoryTeam[compositeKey] = attendance;
    if (_prefs != null) {
      final jsonList = attendance.map((e) => e.toJson()).toList();
      await _prefs.setString(
        '$_teamKeyPrefix$compositeKey',
        jsonEncode(jsonList),
      );
    }
  }

  @override
  Future<void> clearCache() async {
    _memoryToday.clear();
    _memoryHistory.clear();
    _memoryTeam.clear();
    if (_prefs != null) {
      final keys = _prefs.getKeys().where(
            (k) =>
                k.startsWith(_todayKeyPrefix) ||
                k.startsWith(_historyKeyPrefix) ||
                k.startsWith(_teamKeyPrefix),
          );
      for (final k in keys) {
        await _prefs.remove(k);
      }
    }
  }
}
