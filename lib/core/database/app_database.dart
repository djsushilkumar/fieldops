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

  static const DatabaseTable attachmentsTable = DatabaseTable(
    name: 'attachments',
    columns: [
      ColumnDefinition(name: 'id', type: ColumnType.text, isPrimaryKey: true, isNullable: false),
      ColumnDefinition(name: 'organization_id', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'task_id', type: ColumnType.text),
      ColumnDefinition(name: 'visit_id', type: ColumnType.text),
      ColumnDefinition(name: 'uploaded_by', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'uploaded_by_name', type: ColumnType.text),
      ColumnDefinition(name: 'type', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'storage_path', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'file_name', type: ColumnType.text),
      ColumnDefinition(name: 'file_size', type: ColumnType.integer),
      ColumnDefinition(name: 'mime_type', type: ColumnType.text),
      ColumnDefinition(name: 'metadata', type: ColumnType.text),
      ColumnDefinition(name: 'created_at', type: ColumnType.text),
    ],
    indexes: ['task_id', 'visit_id', 'uploaded_by', 'type'],
  );

  static const DatabaseTable notificationsTable = DatabaseTable(
    name: 'notifications',
    columns: [
      ColumnDefinition(name: 'id', type: ColumnType.text, isPrimaryKey: true, isNullable: false),
      ColumnDefinition(name: 'organization_id', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'user_id', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'type', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'title', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'body', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'read_at', type: ColumnType.text),
      ColumnDefinition(name: 'data', type: ColumnType.text),
      ColumnDefinition(name: 'created_at', type: ColumnType.text),
    ],
    indexes: ['user_id', 'type', 'created_at'],
  );

  static const DatabaseTable conveyanceClaimsTable = DatabaseTable(
    name: 'conveyance_claims',
    columns: [
      ColumnDefinition(name: 'id', type: ColumnType.text, isPrimaryKey: true, isNullable: false),
      ColumnDefinition(name: 'organization_id', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'user_id', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'user_name', type: ColumnType.text),
      ColumnDefinition(name: 'shift_date', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'vehicle_type', type: ColumnType.text, defaultValue: 'twoWheelerBike'),
      ColumnDefinition(name: 'rate_per_km', type: ColumnType.real, defaultValue: 3.5),
      ColumnDefinition(name: 'start_odometer', type: ColumnType.real),
      ColumnDefinition(name: 'start_odo_photo', type: ColumnType.text),
      ColumnDefinition(name: 'start_time', type: ColumnType.text),
      ColumnDefinition(name: 'start_lat', type: ColumnType.real),
      ColumnDefinition(name: 'start_lng', type: ColumnType.real),
      ColumnDefinition(name: 'end_odometer', type: ColumnType.real),
      ColumnDefinition(name: 'end_odo_photo', type: ColumnType.text),
      ColumnDefinition(name: 'end_time', type: ColumnType.text),
      ColumnDefinition(name: 'end_lat', type: ColumnType.real),
      ColumnDefinition(name: 'end_lng', type: ColumnType.real),
      ColumnDefinition(name: 'claimed_distance_km', type: ColumnType.real, defaultValue: 0.0),
      ColumnDefinition(name: 'gps_distance_km', type: ColumnType.real, defaultValue: 0.0),
      ColumnDefinition(name: 'discrepancy_pct', type: ColumnType.real, defaultValue: 0.0),
      ColumnDefinition(name: 'is_flagged', type: ColumnType.integer, defaultValue: 0),
      ColumnDefinition(name: 'fraud_reason', type: ColumnType.text),
      ColumnDefinition(name: 'status', type: ColumnType.text, defaultValue: 'DRAFT'),
      ColumnDefinition(name: 'approved_payout', type: ColumnType.real, defaultValue: 0.0),
      ColumnDefinition(name: 'manager_notes', type: ColumnType.text),
      ColumnDefinition(name: 'created_at', type: ColumnType.text),
      ColumnDefinition(name: 'updated_at', type: ColumnType.text),
    ],
    indexes: ['user_id', 'shift_date', 'organization_id', 'status'],
  );

  static const DatabaseTable beatPlansTable = DatabaseTable(
    name: 'beat_plans',
    columns: [
      ColumnDefinition(name: 'id', type: ColumnType.text, isPrimaryKey: true, isNullable: false),
      ColumnDefinition(name: 'organization_id', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'code', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'name', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'description', type: ColumnType.text),
      ColumnDefinition(name: 'assigned_technician_id', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'assigned_technician_name', type: ColumnType.text),
      ColumnDefinition(name: 'frequency', type: ColumnType.text, defaultValue: 'daily'),
      ColumnDefinition(name: 'day_of_week', type: ColumnType.integer, defaultValue: 1),
      ColumnDefinition(name: 'stops_json', type: ColumnType.text),
      ColumnDefinition(name: 'is_active', type: ColumnType.integer, defaultValue: 1),
      ColumnDefinition(name: 'created_at', type: ColumnType.text),
      ColumnDefinition(name: 'updated_at', type: ColumnType.text),
    ],
    indexes: ['organization_id', 'assigned_technician_id'],
  );

  static const DatabaseTable beatExecutionsTable = DatabaseTable(
    name: 'beat_executions',
    columns: [
      ColumnDefinition(name: 'id', type: ColumnType.text, isPrimaryKey: true, isNullable: false),
      ColumnDefinition(name: 'beat_plan_id', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'beat_name', type: ColumnType.text),
      ColumnDefinition(name: 'user_id', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'user_name', type: ColumnType.text),
      ColumnDefinition(name: 'date', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'status', type: ColumnType.text, defaultValue: 'inProgress'),
      ColumnDefinition(name: 'total_stops', type: ColumnType.integer, defaultValue: 0),
      ColumnDefinition(name: 'visited_stops', type: ColumnType.integer, defaultValue: 0),
      ColumnDefinition(name: 'skipped_stops', type: ColumnType.integer, defaultValue: 0),
      ColumnDefinition(name: 'compliance_rate', type: ColumnType.real, defaultValue: 0.0),
      ColumnDefinition(name: 'start_time', type: ColumnType.text),
      ColumnDefinition(name: 'end_time', type: ColumnType.text),
      ColumnDefinition(name: 'stops_json', type: ColumnType.text),
      ColumnDefinition(name: 'created_at', type: ColumnType.text),
    ],
    indexes: ['user_id', 'date', 'beat_plan_id'],
  );

  static const DatabaseTable productsTable = DatabaseTable(
    name: 'products',
    columns: [
      ColumnDefinition(name: 'id', type: ColumnType.text, isPrimaryKey: true, isNullable: false),
      ColumnDefinition(name: 'organization_id', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'sku_code', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'name', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'category', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'unit', type: ColumnType.text, defaultValue: 'pcs'),
      ColumnDefinition(name: 'unit_price', type: ColumnType.real, isNullable: false),
      ColumnDefinition(name: 'tax_rate', type: ColumnType.real, defaultValue: 18.0),
      ColumnDefinition(name: 'stock', type: ColumnType.integer, defaultValue: 100),
      ColumnDefinition(name: 'is_active', type: ColumnType.integer, defaultValue: 1),
      ColumnDefinition(name: 'image_url', type: ColumnType.text),
      ColumnDefinition(name: 'created_at', type: ColumnType.text),
    ],
    indexes: ['organization_id', 'sku_code', 'category'],
  );

  static const DatabaseTable salesOrdersTable = DatabaseTable(
    name: 'sales_orders',
    columns: [
      ColumnDefinition(name: 'id', type: ColumnType.text, isPrimaryKey: true, isNullable: false),
      ColumnDefinition(name: 'organization_id', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'order_number', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'customer_id', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'customer_name', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'location_id', type: ColumnType.text),
      ColumnDefinition(name: 'user_id', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'user_name', type: ColumnType.text),
      ColumnDefinition(name: 'order_date', type: ColumnType.text, isNullable: false),
      ColumnDefinition(name: 'items_json', type: ColumnType.text),
      ColumnDefinition(name: 'subtotal', type: ColumnType.real, defaultValue: 0.0),
      ColumnDefinition(name: 'tax_total', type: ColumnType.real, defaultValue: 0.0),
      ColumnDefinition(name: 'grand_total', type: ColumnType.real, defaultValue: 0.0),
      ColumnDefinition(name: 'status', type: ColumnType.text, defaultValue: 'submitted'),
      ColumnDefinition(name: 'payment_method', type: ColumnType.text, defaultValue: 'cash'),
      ColumnDefinition(name: 'notes', type: ColumnType.text),
      ColumnDefinition(name: 'created_at', type: ColumnType.text),
      ColumnDefinition(name: 'synced', type: ColumnType.integer, defaultValue: 0),
    ],
    indexes: ['organization_id', 'customer_id', 'user_id', 'order_date'],
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
    attachmentsTable,
    notificationsTable,
    conveyanceClaimsTable,
    beatPlansTable,
    beatExecutionsTable,
    productsTable,
    salesOrdersTable,
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
