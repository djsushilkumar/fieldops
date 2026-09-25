import '../entities/sales_order_entity.dart';
import '../repositories/sales_repository.dart';

class CreateSalesOrderUseCase {
  final SalesRepository _repository;

  CreateSalesOrderUseCase(this._repository);

  Future<SalesOrderEntity> call(SalesOrderEntity order) {
    if (order.items.isEmpty) {
      throw ArgumentError('Cannot submit order with 0 items.');
    }
    return _repository.createOrder(order);
  }
}
