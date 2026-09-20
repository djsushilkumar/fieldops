import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database_table.dart';
import 'sqlite_database.dart';

class AppDatabase {
  static const String dbName = 'field_ops_db';
  static const int dbVersion = 1;

  // Table definitions matching Supabase V1 schema
  static const DatabaseTable tasksTable = DatabaseTable(
    name: 'tasks',
    columns: [
      ColumnDefinition(name: 'id', type: ColumnType.text, isPrimaryKey: true, isNullable: false),
      ColumnDefinition(name: 'organization_id', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'title', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'description', type: ColumnType.text),
      ColumnDefinition(name: 'priority', type: ColumnType.text, defaultValue: 'MEDIUM'),
      ColumnDefinition(name: 'status', type: ColumnType.text, defaultValue: 'ASSIGNED'),
      ColumnDefinition(name: 'customer_id', type: ColumnType.text),
      ColumnDefinition(name: 'customer_name', type: ColumnType.text),
      ColumnDefinition(name: 'location_id', type: ColumnType.text),
      ColumnDefinition(name: 'location_name', type: ColumnType.text),
      ColumnDefinition(name: 'assigned_to_id', type: ColumnType.text),
      ColumnDefinition(name: 'assigned_to_name', type: ColumnType.text),
      ColumnDefinition(name: 'scheduled_start', type: ColumnType.text),
      ColumnDefinition(name: 'scheduled_end', type: ColumnType.text),
      ColumnDefinition(name: 'actual_start', type: ColumnType.text),
      ColumnDefinition(name: 'actual_end', type: ColumnType.text),
      ColumnDefinition(name: 'requires_gps', type: ColumnType.integer, defaultValue: 0),
      ColumnDefinition(name: 'requires_photo', type: ColumnType.integer, defaultValue: 0),
      ColumnDefinition(name: 'requires_form', type: ColumnType.integer, defaultValue: 0),
      ColumnDefinition(name: 'notes', type: ColumnType.text),
      ColumnDefinition(name: 'created_at', type: ColumnType.text),
      ColumnDefinition(name: 'updated_at', type: ColumnType.text),
    ],
    indexes: ['organization_id', 'status', 'assigned_to_id'],
  );

  static const DatabaseTable customersTable = DatabaseTable(
    name: 'customers',
    columns: [
      ColumnDefinition(name: 'id', type: ColumnType.text, isPrimaryKey: true, isNullable: false),
      ColumnDefinition(name: 'organization_id', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'name', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'phone', type: ColumnType.text),
      ColumnDefinition(name: 'email', type: ColumnType.text),
      ColumnDefinition(name: 'address', type: ColumnType.text),
      ColumnDefinition(name: 'notes', type: ColumnType.text),
      ColumnDefinition(name: 'created_at', type: ColumnType.text),
      ColumnDefinition(name: 'updated_at', type: ColumnType.text),
    ],
    indexes: ['organization_id', 'name'],
  );

  static const DatabaseTable locationsTable = DatabaseTable(
    name: 'locations',
    columns: [
      ColumnDefinition(name: 'id', type: ColumnType.text, isPrimaryKey: true, isNullable: false),
      ColumnDefinition(name: 'organization_id', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'customer_id', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'name', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'address', type: ColumnType.text),
      ColumnDefinition(name: 'latitude', type: ColumnType.real, isNullable: false),
      ColumnDefinition(name: 'longitude', type: ColumnType.real, isNullable: false),
      ColumnDefinition(name: 'radius_meters', type: ColumnType.integer, defaultValue: 100),
      ColumnDefinition(name: 'created_at', type: ColumnType.text),
      ColumnDefinition(name: 'updated_at', type: ColumnType.text),
    ],
    indexes: ['customer_id', 'organization_id'],
  );

  static const DatabaseTable visitsTable = DatabaseTable(
    name: 'visits',
    columns: [
      ColumnDefinition(name: 'id', type: ColumnType.text, isPrimaryKey: true, isNullable: false),
      ColumnDefinition(name: 'organization_id', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'task_id', type: ColumnType.text),
      ColumnDefinition(name: 'user_id', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'location_id', type: ColumnType.text),
      ColumnDefinition(name: 'check_in_at', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'check_in_latitude', type: ColumnType.real, isNullable: false),
      ColumnDefinition(name: 'check_in_longitude', type: ColumnType.real, isNullable: false),
      ColumnDefinition(name: 'check_out_at', type: ColumnType.text),
      ColumnDefinition(name: 'check_out_latitude', type: ColumnType.real),
      ColumnDefinition(name: 'check_out_longitude', type: ColumnType.real),
      ColumnDefinition(name: 'notes', type: ColumnType.text),
      ColumnDefinition(name: 'created_at', type: ColumnType.text),
      ColumnDefinition(name: 'updated_at', type: ColumnType.text),
    ],
    indexes: ['user_id', 'task_id', 'organization_id'],
  );

  static const DatabaseTable attendanceTable = DatabaseTable(
    name: 'attendance',
    columns: [
      ColumnDefinition(name: 'id', type: ColumnType.text, isPrimaryKey: true, isNullable: false),
      ColumnDefinition(name: 'organization_id', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'user_id', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'user_name', type: ColumnType.text),
      ColumnDefinition(name: 'date', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'check_in_at', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'check_in_latitude', type: ColumnType.real, isNullable: false),
      ColumnDefinition(name: 'check_in_longitude', type: ColumnType.real, isNullable: false),
      ColumnDefinition(name: 'check_out_at', type: ColumnType.text),
      ColumnDefinition(name: 'check_out_latitude', type: ColumnType.real),
      ColumnDefinition(name: 'check_out_longitude', type: ColumnType.real),
      ColumnDefinition(name: 'total_minutes', type: ColumnType.integer),
      ColumnDefinition(name: 'status', type: ColumnType.text, defaultValue: 'PRESENT'),
      ColumnDefinition(name: 'notes', type: ColumnType.text),
    ],
    indexes: ['user_id', 'date', 'organization_id'],
  );

  static const DatabaseTable formsTable = DatabaseTable(
    name: 'forms',
    columns: [
      ColumnDefinition(name: 'id', type: ColumnType.text, isPrimaryKey: true, isNullable: false),
      ColumnDefinition(name: 'organization_id', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'name', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'description', type: ColumnType.text),
      ColumnDefinition(name: 'schema', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'submissions_count', type: ColumnType.integer, defaultValue: 0),
      ColumnDefinition(name: 'created_at', type: ColumnType.text),
      ColumnDefinition(name: 'updated_at', type: ColumnType.text),
    ],
    indexes: ['organization_id'],
  );

  static const DatabaseTable formSubmissionsTable = DatabaseTable(
    name: 'form_submissions',
    columns: [
      ColumnDefinition(name: 'id', type: ColumnType.text, isPrimaryKey: true, isNullable: false),
      ColumnDefinition(name: 'form_id', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'form_name', type: ColumnType.text),
      ColumnDefinition(name: 'task_id', type: ColumnType.text),
      ColumnDefinition(name: 'task_title', type: ColumnType.text),
      ColumnDefinition(name: 'user_id', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'user_name', type: ColumnType.text),
      ColumnDefinition(name: 'latitude', type: ColumnType.real),
      ColumnDefinition(name: 'longitude', type: ColumnType.real),
      ColumnDefinition(name: 'data', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'submitted_at', type: ColumnType.text),
    ],
    indexes: ['form_id', 'task_id', 'user_id'],
  );

  static const DatabaseTable syncQueueTable = DatabaseTable(
    name: 'sync_queue',
    columns: [
      ColumnDefinition(name: 'id', type: ColumnType.text, isPrimaryKey: true, isNullable: false),
      ColumnDefinition(name: 'user_id', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'operation', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'entity_type', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'entity_id', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'payload', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'status', type: ColumnType.text, defaultValue: 'PENDING'),
      ColumnDefinition(name: 'attempts', type: ColumnType.integer, defaultValue: 0),
      ColumnDefinition(name: 'max_attempts', type: ColumnType.integer, defaultValue: 5),
      ColumnDefinition(name: 'last_error', type: ColumnType.text),
      ColumnDefinition(name: 'created_at', type: ColumnType.text),
      ColumnDefinition(name: 'updated_at', type: ColumnType.text),
      ColumnDefinition(name: 'scheduled_retry_at', type: ColumnType.text),
    ],
    indexes: ['user_id', 'status', 'entity_type'],
  );

  static final List<DatabaseTable> allTables = [
    tasksTable,
    customersTable,
    locationsTable,
    visitsTable,
    attendanceTable,
    formsTable,
    formSubmissionsTable,
    syncQueueTable,
  ];

  static SqliteDatabase createDatabase() {
    return SqliteDatabaseImpl(
      name: dbName,
      version: dbVersion,
      tables: allTables,
    );
  }
}

final appDatabaseProvider = Provider<SqliteDatabase>((ref) {
  final db = AppDatabase.createDatabase();
  return db;
});
