import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/datasources/sales_local_datasource.dart';
import '../../data/datasources/sales_remote_datasource.dart';
import '../../data/repositories/sales_repository_impl.dart';
import '../../domain/entities/product_sku_entity.dart';
import '../../domain/entities/sales_order_entity.dart';
import '../../domain/entities/sales_order_item_entity.dart';
import '../../domain/repositories/sales_repository.dart';
import '../../domain/usecases/create_sales_order_use_case.dart';
import '../../domain/usecases/get_orders_use_case.dart';
import '../../domain/usecases/get_products_use_case.dart';

// --- Data Layer Providers ---

final salesLocalDataSourceProvider = Provider<SalesLocalDataSource>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SalesLocalDataSourceImpl(db);
});

final salesRemoteDataSourceProvider = Provider<SalesRemoteDataSource>((ref) {
  return MockSalesRemoteDataSource();
});

final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  final local = ref.watch(salesLocalDataSourceProvider);
  final remote = ref.watch(salesRemoteDataSourceProvider);
  return SalesRepositoryImpl(localDataSource: local, remoteDataSource: remote);
});

// --- Use Case Providers ---

final getProductsUseCaseProvider = Provider<GetProductsUseCase>((ref) {
  final repo = ref.watch(salesRepositoryProvider);
  return GetProductsUseCase(repo);
});

final createSalesOrderUseCaseProvider = Provider<CreateSalesOrderUseCase>((ref) {
  final repo = ref.watch(salesRepositoryProvider);
  return CreateSalesOrderUseCase(repo);
});

final getOrdersUseCaseProvider = Provider<GetOrdersUseCase>((ref) {
  final repo = ref.watch(salesRepositoryProvider);
  return GetOrdersUseCase(repo);
});

// --- Order Booking State ---

class OrderBookingState {
  final bool isLoading;
  final bool isSubmitting;
  final List<ProductSkuEntity> products;
  final List<String> categories;
  final String selectedCategory;
  final String searchQuery;
  final Map<String, SalesOrderItemEntity> cartItems; // productId -> item
  final String? customerId;
  final String? customerName;
  final SalesOrderPaymentMethod paymentMethod;
  final String? notes;
  final String? errorMessage;
  final String? successMessage;
  final SalesOrderEntity? lastSubmittedOrder;

  const OrderBookingState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.products = const [],
    this.categories = const ['All'],
    this.selectedCategory = 'All',
    this.searchQuery = '',
    this.cartItems = const {},
    this.customerId,
    this.customerName,
    this.paymentMethod = SalesOrderPaymentMethod.cash,
    this.notes,
    this.errorMessage,
    this.successMessage,
    this.lastSubmittedOrder,
  });

  double get subtotal {
    double sum = 0.0;
    for (final item in cartItems.values) {
      sum += item.subtotal;
    }
    return double.parse(sum.toStringAsFixed(2));
  }

  double get taxTotal {
    double sum = 0.0;
    for (final item in cartItems.values) {
      sum += item.taxAmount;
    }
    return double.parse(sum.toStringAsFixed(2));
  }

  double get grandTotal {
    return double.parse((subtotal + taxTotal).toStringAsFixed(2));
  }

  int get totalItemCount {
    int count = 0;
    for (final item in cartItems.values) {
      count += item.quantity;
    }
    return count;
  }

  OrderBookingState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    List<ProductSkuEntity>? products,
    List<String>? categories,
    String? selectedCategory,
    String? searchQuery,
    Map<String, SalesOrderItemEntity>? cartItems,
    String? customerId,
    String? customerName,
    SalesOrderPaymentMethod? paymentMethod,
    String? notes,
    String? errorMessage,
    String? successMessage,
    SalesOrderEntity? lastSubmittedOrder,
  }) {
    return OrderBookingState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      products: products ?? this.products,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      cartItems: cartItems ?? this.cartItems,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      errorMessage: errorMessage,
      successMessage: successMessage,
      lastSubmittedOrder: lastSubmittedOrder ?? this.lastSubmittedOrder,
    );
  }
}

class OrderBookingNotifier extends StateNotifier<OrderBookingState> {
  final GetProductsUseCase _getProductsUseCase;
  final CreateSalesOrderUseCase _createOrderUseCase;
  final String? _userId;
  final String? _userName;

  OrderBookingNotifier({
    required GetProductsUseCase getProductsUseCase,
    required CreateSalesOrderUseCase createOrderUseCase,
    String? userId,
    String? userName,
  })  : _getProductsUseCase = getProductsUseCase,
        _createOrderUseCase = createOrderUseCase,
        _userId = userId,
        _userName = userName,
        super(const OrderBookingState()) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final products = await _getProductsUseCase(
        category: state.selectedCategory == 'All' ? null : state.selectedCategory,
        searchQuery: state.searchQuery.isEmpty ? null : state.searchQuery,
      );

      final categorySet = <String>{'All'};
      for (final p in products) {
        categorySet.add(p.category);
      }

      state = state.copyWith(
        isLoading: false,
        products: products,
        categories: categorySet.toList(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setCustomer({required String customerId, required String customerName}) {
    state = state.copyWith(customerId: customerId, customerName: customerName);
  }

  void filterCategory(String category) {
    state = state.copyWith(selectedCategory: category);
    loadProducts();
  }

  void search(String query) {
    state = state.copyWith(searchQuery: query);
    loadProducts();
  }

  void setPaymentMethod(SalesOrderPaymentMethod method) {
    state = state.copyWith(paymentMethod: method);
  }

  void setNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  void addItem(ProductSkuEntity product, {int quantity = 1}) {
    final updatedCart = Map<String, SalesOrderItemEntity>.from(state.cartItems);
    if (updatedCart.containsKey(product.id)) {
      final existing = updatedCart[product.id]!;
      updatedCart[product.id] = existing.copyWith(
        quantity: existing.quantity + quantity,
      );
    } else {
      updatedCart[product.id] = SalesOrderItemEntity(
        id: 'so_item_${DateTime.now().microsecondsSinceEpoch}',
        productId: product.id,
        skuCode: product.skuCode,
        productName: product.name,
        unitPrice: product.unitPrice,
        quantity: quantity,
        taxRate: product.taxRate,
      );
    }
    state = state.copyWith(cartItems: updatedCart);
  }

  void updateQuantity(String productId, int newQuantity) {
    final updatedCart = Map<String, SalesOrderItemEntity>.from(state.cartItems);
    if (newQuantity <= 0) {
      updatedCart.remove(productId);
    } else if (updatedCart.containsKey(productId)) {
      updatedCart[productId] = updatedCart[productId]!.copyWith(quantity: newQuantity);
    }
    state = state.copyWith(cartItems: updatedCart);
  }

  void removeItem(String productId) {
    final updatedCart = Map<String, SalesOrderItemEntity>.from(state.cartItems);
    updatedCart.remove(productId);
    state = state.copyWith(cartItems: updatedCart);
  }

  void clearCart() {
    state = state.copyWith(cartItems: const {});
  }

  Future<bool> submitOrder() async {
    if (state.cartItems.isEmpty) {
      state = state.copyWith(errorMessage: 'Please add at least one SKU to the order.');
      return false;
    }

    final custId = state.customerId ?? 'walk_in_customer';
    final custName = state.customerName ?? 'Walk-in Retailer';
    final uid = _userId ?? 'tech_current';
    final uname = _userName ?? 'Field Representative';

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final orderNumber = 'SO-${now.year}${now.month.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(7)}';

      final newOrder = SalesOrderEntity(
        id: 'order_${now.millisecondsSinceEpoch}',
        organizationId: 'org_001',
        orderNumber: orderNumber,
        customerId: custId,
        customerName: custName,
        userId: uid,
        userName: uname,
        orderDate: dateStr,
        items: state.cartItems.values.toList(),
        subtotal: state.subtotal,
        taxTotal: state.taxTotal,
        grandTotal: state.grandTotal,
        status: SalesOrderStatus.submitted,
        paymentMethod: state.paymentMethod,
        notes: state.notes,
        createdAt: now,
      );

      final result = await _createOrderUseCase(newOrder);

      state = state.copyWith(
        isSubmitting: false,
        cartItems: const {},
        lastSubmittedOrder: result,
        successMessage: 'Order $orderNumber booked successfully for $custName!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
      return false;
    }
  }
}

final orderBookingNotifierProvider =
    StateNotifierProvider<OrderBookingNotifier, OrderBookingState>((ref) {
  final getProducts = ref.watch(getProductsUseCaseProvider);
  final createOrder = ref.watch(createSalesOrderUseCaseProvider);
  final auth = ref.watch(authNotifierProvider);

  return OrderBookingNotifier(
    getProductsUseCase: getProducts,
    createOrderUseCase: createOrder,
    userId: auth.user?.id,
    userName: auth.user?.name,
  );
});
