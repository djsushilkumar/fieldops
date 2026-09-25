import '../entities/sales_order_entity.dart';
import '../repositories/sales_repository.dart';

class GetOrdersUseCase {
  final SalesRepository _repository;

  GetOrdersUseCase(this._repository);

  Future<List<SalesOrderEntity>> call({
    String? customerId,
    String? userId,
  }) {
    return _repository.getOrders(
      customerId: customerId,
      userId: userId,
    );
  }
}
