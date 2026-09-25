import '../entities/product_sku_entity.dart';
import '../entities/sales_order_entity.dart';

abstract class SalesRepository {
  Future<List<ProductSkuEntity>> getProducts({
    String? category,
    String? searchQuery,
  });

  Future<ProductSkuEntity?> getProductById(String id);

  Future<List<SalesOrderEntity>> getOrders({
    String? customerId,
    String? userId,
  });

  Future<SalesOrderEntity?> getOrderById(String id);

  Future<SalesOrderEntity> createOrder(SalesOrderEntity order);

  Future<int> syncPendingOrders();
}
