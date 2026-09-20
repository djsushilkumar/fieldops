import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_table.dart';

enum ConflictAlgorithm {
  rollback,
  abort,
  fail,
  ignore,
  replace,
}

abstract class SqliteDatabase {
  bool get isOpen;
  Future<void> open();
  Future<void> close();

  Future<int> insert(
    String table,
    Map<String, dynamic> values, {
    ConflictAlgorithm conflictAlgorithm = ConflictAlgorithm.replace,
  });

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  });

  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
  });

  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  });

  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]);

  Future<T> transaction<T>(Future<T> Function(SqliteDatabase db) action);

  Future<int> count(String table, {String? where, List<dynamic>? whereArgs});
  Future<void> clearTable(String table);
  Future<void> clearAll();
}

class SqliteDatabaseImpl implements SqliteDatabase {
  final String name;
  final int version;
  final List<DatabaseTable> tables;
  final SharedPreferences? _prefs;

  bool _isOpen = false;
  final Map<String, Map<String, Map<String, dynamic>>> _data = {};

  SqliteDatabaseImpl({
    required this.name,
    this.version = 1,
    required this.tables,
    SharedPreferences? prefs,
  }) : _prefs = prefs;

  String get _storagePrefix => 'fieldops_sqlite_${name}_v${version}_';

  @override
  bool get isOpen => _isOpen;

  @override
  Future<void> open() async {
    if (_isOpen) return;

    for (final table in tables) {
      _data[table.name] = {};
    }

    final prefs = _prefs ?? await SharedPreferences.getInstance();
    for (final table in tables) {
      final key = '$_storagePrefix${table.name}';
      final jsonStr = prefs.getString(key);
      if (jsonStr != null) {
        try {
          final decoded = jsonDecode(jsonStr);
          if (decoded is List) {
            final pkName = table.primaryKey?.name ?? 'id';
            for (final row in decoded) {
              if (row is Map<String, dynamic>) {
                final pkVal = row[pkName]?.toString() ?? '';
                if (pkVal.isNotEmpty) {
                  _data[table.name]![pkVal] = Map<String, dynamic>.from(row);
                }
              }
            }
          }
        } catch (_) {}
      }
    }

    _isOpen = true;
  }

  @override
  Future<void> close() async {
    await _persist();
    _isOpen = false;
  }

  Future<void> _persistTable(String tableName) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final key = '$_storagePrefix$tableName';
    final rows = _data[tableName]?.values.toList() ?? [];
    await prefs.setString(key, jsonEncode(rows));
  }

  Future<void> _persist() async {
    for (final table in tables) {
      await _persistTable(table.name);
    }
  }

  DatabaseTable? _findTable(String name) {
    for (final t in tables) {
      if (t.name == name) return t;
    }
    return null;
  }

  @override
  Future<int> insert(
    String table,
    Map<String, dynamic> values, {
    ConflictAlgorithm conflictAlgorithm = ConflictAlgorithm.replace,
  }) async {
    if (!_isOpen) await open();

    final def = _findTable(table);
    final pkName = def?.primaryKey?.name ?? 'id';
    final pkVal = values[pkName]?.toString();

    if (pkVal == null || pkVal.isEmpty) {
      throw StateError('Cannot insert into table $table without primary key $pkName');
    }

    final tableMap = _data.putIfAbsent(table, () => {});
    final exists = tableMap.containsKey(pkVal);

    if (exists) {
      if (conflictAlgorithm == ConflictAlgorithm.ignore) {
        return 0;
      } else if (conflictAlgorithm == ConflictAlgorithm.fail ||
          conflictAlgorithm == ConflictAlgorithm.abort ||
          conflictAlgorithm == ConflictAlgorithm.rollback) {
        throw StateError('Primary key constraint violated for $table: $pkVal');
      }
    }

    // Coerce values according to table definition if present
    final storedRow = <String, dynamic>{};
    for (final entry in values.entries) {
      if (entry.value is Map || entry.value is List) {
        storedRow[entry.key] = jsonEncode(entry.value);
      } else if (entry.value is DateTime) {
        storedRow[entry.key] = (entry.value as DateTime).toIso8601String();
      } else {
        storedRow[entry.key] = entry.value;
      }
    }

    tableMap[pkVal] = storedRow;
    await _persistTable(table);
    return 1;
  }

  @override
  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    if (!_isOpen) await open();

    final tableMap = _data[table] ?? {};
    var rows = tableMap.values.map((r) => Map<String, dynamic>.from(r)).toList();

    if (where != null) {
      rows = rows.where((row) => _matchesWhere(row, where, whereArgs)).toList();
    }

    if (orderBy != null) {
      _applyOrderBy(rows, orderBy);
    }

    if (offset != null && offset > 0) {
      if (offset >= rows.length) {
        return [];
      }
      rows = rows.sublist(offset);
    }

    if (limit != null && limit > 0 && rows.length > limit) {
      rows = rows.sublist(0, limit);
    }

    return rows;
  }

  @override
  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    if (!_isOpen) await open();

    final tableMap = _data[table] ?? {};
    int updatedCount = 0;

    final rowsToUpdate = <String>[];
    for (final entry in tableMap.entries) {
      if (where == null || _matchesWhere(entry.value, where, whereArgs)) {
        rowsToUpdate.add(entry.key);
      }
    }

    for (final pk in rowsToUpdate) {
      final current = tableMap[pk]!;
      for (final valEntry in values.entries) {
        if (valEntry.value is Map || valEntry.value is List) {
          current[valEntry.key] = jsonEncode(valEntry.value);
        } else if (valEntry.value is DateTime) {
          current[valEntry.key] = (valEntry.value as DateTime).toIso8601String();
        } else {
          current[valEntry.key] = valEntry.value;
        }
      }
      updatedCount++;
    }

    if (updatedCount > 0) {
      await _persistTable(table);
    }

    return updatedCount;
  }

  @override
  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    if (!_isOpen) await open();

    final tableMap = _data[table] ?? {};
    final toRemove = <String>[];

    for (final entry in tableMap.entries) {
      if (where == null || _matchesWhere(entry.value, where, whereArgs)) {
        toRemove.add(entry.key);
      }
    }

    for (final pk in toRemove) {
      tableMap.remove(pk);
    }

    if (toRemove.isNotEmpty) {
      await _persistTable(table);
    }

    return toRemove.length;
  }

  @override
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    if (!_isOpen) await open();
    final lower = sql.toLowerCase().trim();

    if (lower.startsWith('select')) {
      // Find table name: SELECT ... FROM table ...
      final fromIndex = lower.indexOf('from ');
      if (fromIndex != -1) {
        final afterFrom = lower.substring(fromIndex + 5).trim();
        final tableName = afterFrom.split(' ').first.replaceAll(';', '').trim();
        return query(tableName);
      }
    }
    return [];
  }

  @override
  Future<T> transaction<T>(Future<T> Function(SqliteDatabase db) action) async {
    if (!_isOpen) await open();
    // In-memory atomic snapshot
    final backup = <String, Map<String, Map<String, dynamic>>>{};
    for (final entry in _data.entries) {
      backup[entry.key] = {
        for (final rowEntry in entry.value.entries)
          rowEntry.key: Map<String, dynamic>.from(rowEntry.value),
      };
    }

    try {
      final result = await action(this);
      await _persist();
      return result;
    } catch (e) {
      // Rollback
      _data.clear();
      _data.addAll(backup);
      await _persist();
      rethrow;
    }
  }

  @override
  Future<int> count(String table, {String? where, List<dynamic>? whereArgs}) async {
    final rows = await query(table, where: where, whereArgs: whereArgs);
    return rows.length;
  }

  @override
  Future<void> clearTable(String table) async {
    if (!_isOpen) await open();
    _data[table]?.clear();
    await _persistTable(table);
  }

  @override
  Future<void> clearAll() async {
    if (!_isOpen) await open();
    for (final table in tables) {
      _data[table.name]?.clear();
    }
    await _persist();
  }

  // --- Helpers for query matching and ordering ---

  bool _matchesWhere(
    Map<String, dynamic> row,
    String whereClause,
    List<dynamic>? whereArgs,
  ) {
    final cleanClause = whereClause.trim();
    if (cleanClause.isEmpty) return true;

    // Handle AND clauses
    final andParts = cleanClause.split(RegExp(r'\s+AND\s+', caseSensitive: false));
    int argIndex = 0;

    for (final part in andParts) {
      final trimmedPart = part.trim();
      if (trimmedPart.contains('=')) {
        final segments = trimmedPart.split('=').map((s) => s.trim()).toList();
        final col = segments[0];
        final expectedStr = segments[1];

        dynamic expectedVal;
        if (expectedStr == '?') {
          if (whereArgs != null && argIndex < whereArgs.length) {
            expectedVal = whereArgs[argIndex++];
          }
        } else {
          expectedVal = expectedStr.replaceAll("'", "");
        }

        final actualVal = row[col];
        if (actualVal?.toString() != expectedVal?.toString()) {
          return false;
        }
      } else if (trimmedPart.contains('!=')) {
        final segments = trimmedPart.split('!=').map((s) => s.trim()).toList();
        final col = segments[0];
        final expectedStr = segments[1];
        dynamic expectedVal;
        if (expectedStr == '?') {
          if (whereArgs != null && argIndex < whereArgs.length) {
            expectedVal = whereArgs[argIndex++];
          }
        } else {
          expectedVal = expectedStr.replaceAll("'", "");
        }
        final actualVal = row[col];
        if (actualVal?.toString() == expectedVal?.toString()) {
          return false;
        }
      } else if (trimmedPart.toLowerCase().contains('in (')) {
        // IN clause support
        final match = RegExp(r'(\w+)\s+IN\s*\(([^)]+)\)', caseSensitive: false).firstMatch(trimmedPart);
        if (match != null) {
          final col = match.group(1)!;
          final inside = match.group(2)!;
          final options = inside.split(',').map((s) => s.trim().replaceAll("'", "")).toList();
          final actualVal = row[col]?.toString() ?? '';
          if (!options.contains(actualVal)) {
            return false;
          }
        }
      }
    }

    return true;
  }

  void _applyOrderBy(List<Map<String, dynamic>> rows, String orderBy) {
    final parts = orderBy.trim().split(RegExp(r'\s+'));
    final col = parts[0];
    final isDesc = parts.length > 1 && parts[1].toUpperCase() == 'DESC';

    rows.sort((a, b) {
      final valA = a[col];
      final valB = b[col];

      if (valA == null && valB == null) return 0;
      if (valA == null) return isDesc ? 1 : -1;
      if (valB == null) return isDesc ? -1 : 1;

      int comparison;
      if (valA is Comparable && valB is Comparable) {
        try {
          comparison = valA.compareTo(valB);
        } catch (_) {
          comparison = valA.toString().compareTo(valB.toString());
        }
      } else {
        comparison = valA.toString().compareTo(valB.toString());
      }

      return isDesc ? -comparison : comparison;
    });
  }
}
