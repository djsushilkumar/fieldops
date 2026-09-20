import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/supabase_config.dart';
import '../../data/datasources/customer_local_datasource.dart';
import '../../data/datasources/customer_remote_datasource.dart';
import '../../data/datasources/mock_customer_remote_datasource.dart';
import '../../data/repositories/customer_repository_impl.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/entities/location_entity.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/usecases/create_customer_use_case.dart';
import '../../domain/usecases/create_location_use_case.dart';
import '../../domain/usecases/get_customer_detail_use_case.dart';
import '../../domain/usecases/get_customers_use_case.dart';
import '../../domain/usecases/get_locations_use_case.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final customerLocalDataSourceProvider =
    Provider<CustomerLocalDataSource>((ref) {
  return CustomerLocalDataSourceImpl();
});

final customerRemoteDataSourceProvider =
    Provider<CustomerRemoteDataSource>((ref) {
  final supabase = SupabaseConfig.client;
  if (supabase != null) {
    return SupabaseCustomerRemoteDataSource(supabase);
  }
  return MockCustomerRemoteDataSource();
});

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final remote = ref.watch(customerRemoteDataSourceProvider);
  final local = ref.watch(customerLocalDataSourceProvider);
  return CustomerRepositoryImpl(
    remoteDataSource: remote,
    localDataSource: local,
  );
});

final getCustomersUseCaseProvider = Provider<GetCustomersUseCase>((ref) {
  return GetCustomersUseCase(ref.watch(customerRepositoryProvider));
});

final getCustomerDetailUseCaseProvider =
    Provider<GetCustomerDetailUseCase>((ref) {
  return GetCustomerDetailUseCase(ref.watch(customerRepositoryProvider));
});

final createCustomerUseCaseProvider = Provider<CreateCustomerUseCase>((ref) {
  return CreateCustomerUseCase(ref.watch(customerRepositoryProvider));
});

final createLocationUseCaseProvider = Provider<CreateLocationUseCase>((ref) {
  return CreateLocationUseCase(ref.watch(customerRepositoryProvider));
});

final getLocationsUseCaseProvider = Provider<GetLocationsUseCase>((ref) {
  return GetLocationsUseCase(ref.watch(customerRepositoryProvider));
});

// ---------------------------------------------------------------------------
// Customer List State & Notifier
// ---------------------------------------------------------------------------

enum CustomerListStatus { initial, loading, success, error }

class CustomerListState {
  final CustomerListStatus status;
  final List<CustomerEntity> customers;
  final String? searchQuery;
  final String? errorMessage;

  const CustomerListState({
    this.status = CustomerListStatus.initial,
    this.customers = const [],
    this.searchQuery,
    this.errorMessage,
  });

  CustomerListState copyWith({
    CustomerListStatus? status,
    List<CustomerEntity>? customers,
    String? searchQuery,
    String? errorMessage,
  }) {
    return CustomerListState(
      status: status ?? this.status,
      customers: customers ?? this.customers,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
    );
  }
}

class CustomerListNotifier extends StateNotifier<CustomerListState> {
  final GetCustomersUseCase _getCustomersUseCase;
  final CreateCustomerUseCase _createCustomerUseCase;

  CustomerListNotifier({
    required GetCustomersUseCase getCustomersUseCase,
    required CreateCustomerUseCase createCustomerUseCase,
  })  : _getCustomersUseCase = getCustomersUseCase,
        _createCustomerUseCase = createCustomerUseCase,
        super(const CustomerListState()) {
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    state = state.copyWith(status: CustomerListStatus.loading);
    try {
      final list = await _getCustomersUseCase(searchQuery: state.searchQuery);
      if (!mounted) return;
      state = state.copyWith(
        status: CustomerListStatus.success,
        customers: list,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        status: CustomerListStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> setSearchQuery(String query) async {
    final clean = query.trim().isEmpty ? null : query.trim();
    if (state.searchQuery == clean) return;

    state = state.copyWith(
      searchQuery: clean,
      status: CustomerListStatus.loading,
    );
    try {
      final list = await _getCustomersUseCase(searchQuery: clean);
      if (!mounted) return;
      state = state.copyWith(
        status: CustomerListStatus.success,
        customers: list,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        status: CustomerListStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    try {
      final list = await _getCustomersUseCase(searchQuery: state.searchQuery);
      if (!mounted) return;
      state = state.copyWith(
        status: CustomerListStatus.success,
        customers: list,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        status: CustomerListStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<CustomerEntity> createCustomer(CustomerEntity customer) async {
    try {
      final created = await _createCustomerUseCase(customer);
      if (mounted) {
        state = state.copyWith(
          customers: [created, ...state.customers],
        );
      }
      return created;
    } catch (e) {
      rethrow;
    }
  }
}

final customerListNotifierProvider =
    StateNotifierProvider<CustomerListNotifier, CustomerListState>((ref) {
  return CustomerListNotifier(
    getCustomersUseCase: ref.watch(getCustomersUseCaseProvider),
    createCustomerUseCase: ref.watch(createCustomerUseCaseProvider),
  );
});

// ---------------------------------------------------------------------------
// Customer Detail State & Notifier (Family)
// ---------------------------------------------------------------------------

enum CustomerDetailStatus { initial, loading, success, error }

class CustomerDetailState {
  final CustomerDetailStatus status;
  final CustomerEntity? customer;
  final String? errorMessage;

  const CustomerDetailState({
    this.status = CustomerDetailStatus.initial,
    this.customer,
    this.errorMessage,
  });

  CustomerDetailState copyWith({
    CustomerDetailStatus? status,
    CustomerEntity? customer,
    String? errorMessage,
  }) {
    return CustomerDetailState(
      status: status ?? this.status,
      customer: customer ?? this.customer,
      errorMessage: errorMessage,
    );
  }
}

class CustomerDetailNotifier extends StateNotifier<CustomerDetailState> {
  final String customerId;
  final GetCustomerDetailUseCase _getCustomerDetailUseCase;
  final CreateLocationUseCase _createLocationUseCase;

  CustomerDetailNotifier({
    required this.customerId,
    required GetCustomerDetailUseCase getCustomerDetailUseCase,
    required CreateLocationUseCase createLocationUseCase,
  })  : _getCustomerDetailUseCase = getCustomerDetailUseCase,
        _createLocationUseCase = createLocationUseCase,
        super(const CustomerDetailState()) {
    loadCustomer();
  }

  Future<void> loadCustomer() async {
    state = state.copyWith(status: CustomerDetailStatus.loading);
    try {
      final customer = await _getCustomerDetailUseCase(customerId);
      if (!mounted) return;
      state = state.copyWith(
        status: CustomerDetailStatus.success,
        customer: customer,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        status: CustomerDetailStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<LocationEntity> addLocation(LocationEntity location) async {
    try {
      final created = await _createLocationUseCase(location);
      if (mounted && state.customer != null) {
        final updatedLocs = [...state.customer!.locations, created];
        state = state.copyWith(
          customer: state.customer!.copyWith(locations: updatedLocs),
        );
      }
      return created;
    } catch (e) {
      rethrow;
    }
  }
}

final customerDetailNotifierProvider = StateNotifierProvider.family<
    CustomerDetailNotifier, CustomerDetailState, String>((ref, customerId) {
  return CustomerDetailNotifier(
    customerId: customerId,
    getCustomerDetailUseCase: ref.watch(getCustomerDetailUseCaseProvider),
    createLocationUseCase: ref.watch(createLocationUseCaseProvider),
  );
});
