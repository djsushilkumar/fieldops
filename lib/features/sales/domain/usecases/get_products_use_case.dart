import '../entities/product_sku_entity.dart';
import '../repositories/sales_repository.dart';

class GetProductsUseCase {
  final SalesRepository _repository;

  GetProductsUseCase(this._repository);

  Future<List<ProductSkuEntity>> call({
    String? category,
    String? searchQuery,
  }) {
    return _repository.getProducts(
      category: category,
      searchQuery: searchQuery,
    );
  }
}
