import '../models/product_sku_model.dart';
import '../models/sales_order_model.dart';

abstract class SalesRemoteDataSource {
  Future<List<ProductSkuModel>> fetchProducts();
  Future<SalesOrderModel> submitOrder(SalesOrderModel order);
  Future<List<SalesOrderModel>> fetchOrders({String? customerId});
}

class MockSalesRemoteDataSource implements SalesRemoteDataSource {
  final List<ProductSkuModel> _mockProducts = [
    ProductSkuModel(
      id: 'prod_sku_001',
      organizationId: 'org_001',
      skuCode: 'BEV-TEA-001',
      name: 'Organic Green Tea 250g',
      category: 'Beverages',
      unit: 'boxes',
      unitPrice: 180.0,
      taxRate: 18.0,
      stock: 150,
      isActive: true,
      createdAt: DateTime.now(),
    ),
    ProductSkuModel(
      id: 'prod_sku_002',
      organizationId: 'org_001',
      skuCode: 'GROC-OIL-002',
      name: 'Cold Pressed Olive Oil 1L',
      category: 'Groceries',
      unit: 'bottles',
      unitPrice: 650.0,
      taxRate: 18.0,
      stock: 80,
      isActive: true,
      createdAt: DateTime.now(),
    ),
    ProductSkuModel(
      id: 'prod_sku_003',
      organizationId: 'org_001',
      skuCode: 'DAIRY-PLANT-003',
      name: 'Almond Milk Unsweetened 1L',
      category: 'Dairy & Plant',
      unit: 'cartons',
      unitPrice: 240.0,
      taxRate: 18.0,
      stock: 200,
      isActive: true,
      createdAt: DateTime.now(),
    ),
    ProductSkuModel(
      id: 'prod_sku_004',
      organizationId: 'org_001',
      skuCode: 'SNK-NUT-004',
      name: 'Roasted Peanuts Salted 500g',
      category: 'Snacks',
      unit: 'packets',
      unitPrice: 120.0,
      taxRate: 12.0,
      stock: 350,
      isActive: true,
      createdAt: DateTime.now(),
    ),
    ProductSkuModel(
      id: 'prod_sku_005',
      organizationId: 'org_001',
      skuCode: 'SNK-CHOC-005',
      name: 'Artisanal Dark Chocolate 100g',
      category: 'Snacks',
      unit: 'bars',
      unitPrice: 150.0,
      taxRate: 18.0,
      stock: 120,
      isActive: true,
      createdAt: DateTime.now(),
    ),
    ProductSkuModel(
      id: 'prod_sku_006',
      organizationId: 'org_001',
      skuCode: 'HYG-SAN-006',
      name: 'Hand Sanitizer Citrus 500ml',
      category: 'Hygiene',
      unit: 'bottles',
      unitPrice: 95.0,
      taxRate: 18.0,
      stock: 220,
      isActive: true,
      createdAt: DateTime.now(),
    ),
  ];

  final List<SalesOrderModel> _remoteOrders = [];

  @override
  Future<List<ProductSkuModel>> fetchProducts() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_mockProducts);
  }

  @override
  Future<SalesOrderModel> submitOrder(SalesOrderModel order) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final submitted = order.copyWith(synced: true);
    _remoteOrders.add(SalesOrderModel.fromEntity(submitted));
    return SalesOrderModel.fromEntity(submitted);
  }

  @override
  Future<List<SalesOrderModel>> fetchOrders({String? customerId}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (customerId != null) {
      return _remoteOrders.where((o) => o.customerId == customerId).toList();
    }
    return List.from(_remoteOrders);
  }
}
