import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/customer_controller.dart';
import '../widgets/customer_card.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerListNotifierProvider);
    final user = ref.watch(currentUserProvider);
    final canManageCustomers = user?.role.canManageCustomers ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers & Sites'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search customer name or address...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(customerListNotifierProvider.notifier)
                              .setSearchQuery('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
              onChanged: (val) {
                setState(() {});
                ref
                    .read(customerListNotifierProvider.notifier)
                    .setSearchQuery(val);
              },
            ),
          ),
        ),
      ),
      floatingActionButton: canManageCustomers
          ? FloatingActionButton.extended(
              key: const Key('add_customer_fab'),
              onPressed: () => context.push('/customers/create'),
              icon: const Icon(Icons.add),
              label: const Text('Add Customer'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(customerListNotifierProvider.notifier).refresh(),
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(CustomerListState state) {
    if (state.status == CustomerListStatus.loading && state.customers.isEmpty) {
      return const LoadingView(message: 'Loading customers...');
    }

    if (state.status == CustomerListStatus.error && state.customers.isEmpty) {
      return ErrorStateView(
        message: state.errorMessage ?? 'Failed to load customers',
        onRetry: () =>
            ref.read(customerListNotifierProvider.notifier).loadCustomers(),
      );
    }

    if (state.customers.isEmpty) {
      return EmptyStateView(
        icon: Icons.business_outlined,
        title: state.searchQuery != null
            ? 'No customers found matching "${state.searchQuery}"'
            : 'No customers found',
        description: 'Add your first customer to start dispatching field tasks.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: state.customers.length,
      itemBuilder: (context, index) {
        final customer = state.customers[index];
        return CustomerCard(
          customer: customer,
          onTap: () {
            context.push('/customers/${customer.id}');
          },
        );
      },
    );
  }
}
