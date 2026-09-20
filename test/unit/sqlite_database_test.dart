import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:field_ops/core/database/database_table.dart';
import 'package:field_ops/core/database/sqlite_database.dart';

void main() {
  late SqliteDatabase db;

  const testTable = DatabaseTable(
    name: 'test_items',
    columns: [
      ColumnDefinition(name: 'id', type: ColumnType.text, isPrimaryKey: true, isNullable: false),
      ColumnDefinition(name: 'title', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'status', type: ColumnType.text, defaultValue: 'PENDING'),
      ColumnDefinition(name: 'score', type: ColumnType.real, defaultValue: 0.0),
    ],
    indexes: ['status'],
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    db = SqliteDatabaseImpl(
      name: 'test_db',
      tables: [testTable],
      prefs: prefs,
    );
    await db.open();
  });

  group('SqliteDatabase Tests', () {
    test('open initializes tables and isOpen is true', () {
      expect(db.isOpen, isTrue);
    });

    test('insert stores row and query returns it', () async {
      await db.insert('test_items', {
        'id': 'item-01',
        'title': 'Test Item One',
        'status': 'ACTIVE',
        'score': 95.5,
      });

      final rows = await db.query('test_items');
      expect(rows.length, 1);
      expect(rows.first['id'], 'item-01');
      expect(rows.first['title'], 'Test Item One');
      expect(rows.first['score'], 95.5);
    });

    test('query with where clause filters results', () async {
      await db.insert('test_items', {'id': 'item-01', 'title': 'First', 'status': 'ACTIVE'});
      await db.insert('test_items', {'id': 'item-02', 'title': 'Second', 'status': 'ARCHIVED'});
      await db.insert('test_items', {'id': 'item-03', 'title': 'Third', 'status': 'ACTIVE'});

      final active = await db.query('test_items', where: 'status = ?', whereArgs: ['ACTIVE']);
      expect(active.length, 2);
      expect(active.map((r) => r['id']), containsAll(['item-01', 'item-03']));
    });

    test('update modifies matching rows and count reflects changes', () async {
      await db.insert('test_items', {'id': 'item-01', 'title': 'Before Update', 'status': 'PENDING'});

      final updated = await db.update(
        'test_items',
        {'title': 'After Update', 'status': 'DONE'},
        where: 'id = ?',
        whereArgs: ['item-01'],
      );
      expect(updated, 1);

      final row = (await db.query('test_items', where: 'id = ?', whereArgs: ['item-01'])).first;
      expect(row['title'], 'After Update');
      expect(row['status'], 'DONE');
    });

    test('delete removes matching rows', () async {
      await db.insert('test_items', {'id': 'item-01', 'title': 'Item 1'});
      await db.insert('test_items', {'id': 'item-02', 'title': 'Item 2'});

      final deleted = await db.delete('test_items', where: 'id = ?', whereArgs: ['item-01']);
      expect(deleted, 1);

      final remaining = await db.query('test_items');
      expect(remaining.length, 1);
      expect(remaining.first['id'], 'item-02');
    });

    test('transaction commits on success and rolls back on exception', () async {
      await db.insert('test_items', {'id': 'item-init', 'title': 'Initial'});

      // Successful transaction
      await db.transaction((tDb) async {
        await tDb.insert('test_items', {'id': 'item-tx1', 'title': 'Tx 1'});
        await tDb.insert('test_items', {'id': 'item-tx2', 'title': 'Tx 2'});
      });

      expect(await db.count('test_items'), 3);

      // Failing transaction should rollback
      bool didThrow = false;
      try {
        await db.transaction((tDb) async {
          await tDb.insert('test_items', {'id': 'item-fail', 'title': 'Failing'});
          throw Exception('Simulated Tx Crash');
        });
      } catch (_) {
        didThrow = true;
      }
      expect(didThrow, isTrue);

      final rowsAfterRollback = await db.query('test_items');
      expect(rowsAfterRollback.length, 3);
      expect(rowsAfterRollback.any((r) => r['id'] == 'item-fail'), isFalse);
    });

    test('clearTable removes all records in specified table', () async {
      await db.insert('test_items', {'id': 'item-01', 'title': 'Item 1'});
      expect(await db.count('test_items'), 1);

      await db.clearTable('test_items');
      expect(await db.count('test_items'), 0);
    });
  });
}
