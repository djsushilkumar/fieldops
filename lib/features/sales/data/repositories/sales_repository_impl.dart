import '../../domain/entities/product_sku_entity.dart';
import '../../domain/entities/sales_order_entity.dart';
import '../../domain/repositories/sales_repository.dart';
import '../datasources/sales_local_datasource.dart';
import '../datasources/sales_remote_datasource.dart';
import '../models/sales_order_model.dart';

class SalesRepositoryImpl implements SalesRepository {
  final SalesLocalDataSource _localDataSource;
  final SalesRemoteDataSource _remoteDataSource;

  SalesRepositoryImpl({
    required SalesLocalDataSource localDataSource,
    required SalesRemoteDataSource remoteDataSource,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource;

  @override
  Future<List<ProductSkuEntity>> getProducts({
    String? category,
    String? searchQuery,
  }) async {
    var products = await _localDataSource.getProducts(
      category: category,
      searchQuery: searchQuery,
    );

    // If local DB is empty, pull from remote and cache locally
    if (products.isEmpty) {
      try {
        final remoteProducts = await _remoteDataSource.fetchProducts();
        if (remoteProducts.isNotEmpty) {
          await _localDataSource.saveProducts(remoteProducts);
          products = await _localDataSource.getProducts(
            category: category,
            searchQuery: searchQuery,
          );
        }
      } catch (_) {
        // Fallback to whatever local had
      }
    }

    return products;
  }

  @override
  Future<ProductSkuEntity?> getProductById(String id) async {
    return _localDataSource.getProductById(id);
  }

  @override
  Future<List<SalesOrderEntity>> getOrders({
    String? customerId,
    String? userId,
  }) async {
    return _localDataSource.getOrders(
      customerId: customerId,
      userId: userId,
    );
  }

  @override
  Future<SalesOrderEntity?> getOrderById(String id) async {
    return _localDataSource.getOrderById(id);
  }

  @override
  Future<SalesOrderEntity> createOrder(SalesOrderEntity order) async {
    var orderModel = SalesOrderModel.fromEntity(order);

    // 1. Save locally first (offline-first persistence)
    await _localDataSource.saveOrder(orderModel);

    // 2. Try remote sync
    try {
      final remoteSynced = await _remoteDataSource.submitOrder(orderModel);
      await _localDataSource.markOrderSynced(remoteSynced.id);
      return remoteSynced;
    } catch (_) {
      // Offline: keep as unsynced in local SQLite
      return orderModel;
    }
  }

  @override
  Future<int> syncPendingOrders() async {
    final unsynced = await _localDataSource.getUnsyncedOrders();
    int syncedCount = 0;

    for (final order in unsynced) {
      try {
        await _remoteDataSource.submitOrder(order);
        await _localDataSource.markOrderSynced(order.id);
        syncedCount++;
      } catch (_) {
        // Will retry in next sync pass
      }
    }

    return syncedCount;
  }
}
