import '../../../../core/database/sqlite_database.dart';
import '../models/product_sku_model.dart';
import '../models/sales_order_model.dart';

abstract class SalesLocalDataSource {
  Future<List<ProductSkuModel>> getProducts({String? category, String? searchQuery});
  Future<ProductSkuModel?> getProductById(String id);
  Future<void> saveProduct(ProductSkuModel product);
  Future<void> saveProducts(List<ProductSkuModel> products);
  Future<List<SalesOrderModel>> getOrders({String? customerId, String? userId});
  Future<SalesOrderModel?> getOrderById(String id);
  Future<void> saveOrder(SalesOrderModel order);
  Future<List<SalesOrderModel>> getUnsyncedOrders();
  Future<void> markOrderSynced(String id);
}

class SalesLocalDataSourceImpl implements SalesLocalDataSource {
  final SqliteDatabase _database;
  static const String productsTable = 'products';
  static const String ordersTable = 'sales_orders';

  SalesLocalDataSourceImpl(this._database);

  @override
  Future<List<ProductSkuModel>> getProducts({String? category, String? searchQuery}) async {
    final whereClauses = <String>['is_active = 1'];
    final whereArgs = <dynamic>[];

    if (category != null && category.isNotEmpty && category != 'All') {
      whereClauses.add('category = ?');
      whereArgs.add(category);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClauses.add('(name LIKE ? OR sku_code LIKE ?)');
      whereArgs.add('%$searchQuery%');
      whereArgs.add('%$searchQuery%');
    }

    final where = whereClauses.join(' AND ');
    final rows = await _database.query(
      productsTable,
      where: where,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'name ASC',
    );

    return rows.map((r) => ProductSkuModel.fromSqlMap(r)).toList();
  }

  @override
  Future<ProductSkuModel?> getProductById(String id) async {
    final rows = await _database.query(
      productsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ProductSkuModel.fromSqlMap(rows.first);
  }

  @override
  Future<void> saveProduct(ProductSkuModel product) async {
    await _database.insert(
      productsTable,
      product.toSqlMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> saveProducts(List<ProductSkuModel> products) async {
    for (final p in products) {
      await saveProduct(p);
    }
  }

  @override
  Future<List<SalesOrderModel>> getOrders({String? customerId, String? userId}) async {
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (customerId != null && customerId.isNotEmpty) {
      whereClauses.add('customer_id = ?');
      whereArgs.add(customerId);
    }

    if (userId != null && userId.isNotEmpty) {
      whereClauses.add('user_id = ?');
      whereArgs.add(userId);
    }

    final where = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;
    final rows = await _database.query(
      ordersTable,
      where: where,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at DESC',
    );

    return rows.map((r) => SalesOrderModel.fromSqlMap(r)).toList();
  }

  @override
  Future<SalesOrderModel?> getOrderById(String id) async {
    final rows = await _database.query(
      ordersTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return SalesOrderModel.fromSqlMap(rows.first);
  }

  @override
  Future<void> saveOrder(SalesOrderModel order) async {
    await _database.insert(
      ordersTable,
      order.toSqlMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<SalesOrderModel>> getUnsyncedOrders() async {
    final rows = await _database.query(
      ordersTable,
      where: 'synced = 0',
      orderBy: 'created_at ASC',
    );
    return rows.map((r) => SalesOrderModel.fromSqlMap(r)).toList();
  }

  @override
  Future<void> markOrderSynced(String id) async {
    await _database.update(
      ordersTable,
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
