import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:field_ops/core/database/app_database.dart';
import 'package:field_ops/core/database/sqlite_database.dart';
import 'package:field_ops/features/sales/data/datasources/sales_local_datasource.dart';
import 'package:field_ops/features/sales/data/datasources/sales_remote_datasource.dart';
import 'package:field_ops/features/sales/data/models/sales_order_model.dart';
import 'package:field_ops/features/sales/data/repositories/sales_repository_impl.dart';
import 'package:field_ops/features/sales/domain/entities/sales_order_entity.dart';
import 'package:field_ops/features/sales/domain/entities/sales_order_item_entity.dart';

void main() {
  group('SalesOrderItemEntity Calculations', () {
    test('calculates subtotal, tax amount, and line total correctly without discount', () {
      const item = SalesOrderItemEntity(
        id: 'item-1',
        productId: 'prod-1',
        skuCode: 'BEV-TEA-001',
        productName: 'Organic Green Tea 250g',
        unitPrice: 180.0,
        quantity: 2,
        taxRate: 18.0,
      );

      // Raw = 180 * 2 = 360
      expect(item.subtotal, equals(360.0));
      // Tax = 360 * 18% = 64.80
      expect(item.taxAmount, equals(64.80));
      // Total = 360 + 64.80 = 424.80
      expect(item.lineTotal, equals(424.80));
    });

    test('calculates subtotal, tax amount, and line total with discount percentage', () {
      const item = SalesOrderItemEntity(
        id: 'item-2',
        productId: 'prod-2',
        skuCode: 'SNK-NUT-004',
        productName: 'Roasted Peanuts Salted 500g',
        unitPrice: 100.0,
        quantity: 5, // raw = 500.0
        taxRate: 12.0,
        discountPct: 10.0, // 10% discount = 50.0 off
      );

      // Subtotal = 500 - 50 = 450.0
      expect(item.subtotal, equals(450.0));
      // Tax = 450 * 12% = 54.0
      expect(item.taxAmount, equals(54.0));
      // Total = 450 + 54 = 504.0
      expect(item.lineTotal, equals(504.0));
    });
  });

  group('SalesOrderEntity & Model Serialization', () {
    final now = DateTime.now();
    const item1 = SalesOrderItemEntity(
      id: 'item-1',
      productId: 'prod-1',
      skuCode: 'SKU-1',
      productName: 'Item 1',
      unitPrice: 100.0,
      quantity: 2,
      taxRate: 18.0,
    );

    const item2 = SalesOrderItemEntity(
      id: 'item-2',
      productId: 'prod-2',
      skuCode: 'SKU-2',
      productName: 'Item 2',
      unitPrice: 200.0,
      quantity: 1,
      taxRate: 18.0,
    );

    test('aggregates totalItemCount correctly', () {
      final order = SalesOrderEntity(
        id: 'order-1',
        organizationId: 'org-1',
        orderNumber: 'SO-2026-001',
        customerId: 'cust-1',
        customerName: 'Test Retailer',
        userId: 'user-1',
        userName: 'Rep Name',
        orderDate: '2026-09-25',
        items: const [item1, item2],
        subtotal: 400.0,
        taxTotal: 72.0,
        grandTotal: 472.0,
        createdAt: now,
      );

      expect(order.totalItemCount, equals(3));
    });

    test('serializes to SQL map and reconstructs identically', () {
      final order = SalesOrderEntity(
        id: 'order-101',
        organizationId: 'org-demo',
        orderNumber: 'SO-2026-002',
        customerId: 'cust-101',
        customerName: 'Downtown Supermarket',
        userId: 'usr-1',
        userName: 'Field Agent',
        orderDate: '2026-09-25',
        items: const [item1, item2],
        subtotal: 400.0,
        taxTotal: 72.0,
        grandTotal: 472.0,
        status: SalesOrderStatus.confirmed,
        paymentMethod: SalesOrderPaymentMethod.credit30Days,
        notes: 'Deliver to rear loading dock',
        createdAt: now,
        synced: true,
      );

      final model = SalesOrderModel.fromEntity(order);
      final sqlMap = model.toSqlMap();

      expect(sqlMap['id'], equals('order-101'));
      expect(sqlMap['status'], equals('confirmed'));
      expect(sqlMap['payment_method'], equals('credit30Days'));
      expect(sqlMap['items_json'], isA<String>());

      final reconstructed = SalesOrderModel.fromSqlMap(sqlMap);
      expect(reconstructed.id, equals(order.id));
      expect(reconstructed.orderNumber, equals(order.orderNumber));
      expect(reconstructed.customerName, equals(order.customerName));
      expect(reconstructed.items.length, equals(2));
      expect(reconstructed.items.first.productName, equals('Item 1'));
      expect(reconstructed.grandTotal, equals(472.0));
      expect(reconstructed.status, equals(SalesOrderStatus.confirmed));
      expect(reconstructed.paymentMethod, equals(SalesOrderPaymentMethod.credit30Days));
    });
  });

  group('SalesRepository Offline-First & Sync Integration', () {
    late SqliteDatabase db;
    late SalesLocalDataSource localDataSource;
    late SalesRemoteDataSource remoteDataSource;
    late SalesRepositoryImpl repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      db = SqliteDatabaseImpl(name: 'test_sales_db', tables: AppDatabase.allTables, prefs: prefs);
      await db.open();

      localDataSource = SalesLocalDataSourceImpl(db);
      remoteDataSource = MockSalesRemoteDataSource();
      repository = SalesRepositoryImpl(
        localDataSource: localDataSource,
        remoteDataSource: remoteDataSource,
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('fetches catalogue from remote mock when local SQLite is empty', () async {
      final products = await repository.getProducts();

      expect(products, isNotEmpty);
      expect(products.length, greaterThanOrEqualTo(5));
      expect(products.any((p) => p.name.contains('Green Tea')), isTrue);
    });

    test('creates and saves order locally and syncs to remote', () async {
      final now = DateTime.now();
      final order = SalesOrderEntity(
        id: 'order-live-01',
        organizationId: 'org-01',
        orderNumber: 'SO-LIVE-001',
        customerId: 'cust-1',
        customerName: 'Sunrise Grocery Store',
        userId: 'tech-1',
        userName: 'Demo Rep',
        orderDate: '2026-09-25',
        items: const [
          SalesOrderItemEntity(
            id: 'it-1',
            productId: 'prod_sku_001',
            skuCode: 'BEV-TEA-001',
            productName: 'Organic Green Tea 250g',
            unitPrice: 180.0,
            quantity: 5,
            taxRate: 18.0,
          ),
        ],
        subtotal: 900.0,
        taxTotal: 162.0,
        grandTotal: 1062.0,
        createdAt: now,
      );

      final result = await repository.createOrder(order);

      expect(result.id, equals('order-live-01'));
      expect(result.synced, isTrue);

      final localOrders = await repository.getOrders(customerId: 'cust-1');
      expect(localOrders.length, equals(1));
      expect(localOrders.first.customerName, equals('Sunrise Grocery Store'));
    });
  });
}
