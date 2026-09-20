import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/location_entity.dart';
import '../controllers/customer_controller.dart';
import '../widgets/create_location_dialog.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;

  const CustomerDetailScreen({
    super.key,
    required this.customerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(customerDetailNotifierProvider(customerId));
    final user = ref.watch(currentUserProvider);
    final canManageLocations = user?.role.canManageCustomers ?? false;

    if (state.status == CustomerDetailStatus.loading && state.customer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customer Details')),
        body: const LoadingView(message: 'Loading customer...'),
      );
    }

    if (state.status == CustomerDetailStatus.error && state.customer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customer Details')),
        body: ErrorStateView(
          message: state.errorMessage ?? 'Failed to load customer',
          onRetry: () => ref
              .read(customerDetailNotifierProvider(customerId).notifier)
              .loadCustomer(),
        ),
      );
    }

    final customer = state.customer;
    if (customer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customer Details')),
        body: const Center(child: Text('Customer not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(customer.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref
                .read(customerDetailNotifierProvider(customerId).notifier)
                .loadCustomer(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Customer Info Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    if (customer.phone != null) ...[
                      _DetailRow(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        value: customer.phone!,
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (customer.email != null) ...[
                      _DetailRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: customer.email!,
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (customer.address != null) ...[
                      _DetailRow(
                        icon: Icons.place_outlined,
                        label: 'Address',
                        value: customer.address!,
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (customer.notes != null) ...[
                      _DetailRow(
                        icon: Icons.notes_outlined,
                        label: 'Notes',
                        value: customer.notes!,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Sites / Locations Header
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Sites & Locations',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${customer.locations.length}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                if (canManageLocations)
                  OutlinedButton.icon(
                    key: const Key('add_site_button'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onPressed: () => showDialog<LocationEntity>(
                      context: context,
                      builder: (_) =>
                          CreateLocationDialog(customerId: customer.id),
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Site'),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Locations List
            if (customer.locations.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.place_outlined,
                        size: 40, color: AppColors.textTertiary),
                    const SizedBox(height: 8),
                    const Text(
                      'No sites added yet',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Add GPS coordinates and radius for geofenced visits.',
                      style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                      textAlign: TextAlign.center,
                    ),
                    if (canManageLocations) ...[
                      const SizedBox(height: 16),
                      AppButton(
                        label: 'Add First Site',
                        onPressed: () => showDialog<LocationEntity>(
                          context: context,
                          builder: (_) =>
                              CreateLocationDialog(customerId: customer.id),
                        ),
                      ),
                    ],
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: customer.locations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final loc = customer.locations[index];
                  return _LocationItemCard(location: loc);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LocationItemCard extends StatelessWidget {
  final LocationEntity location;

  const _LocationItemCard({required this.location});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  location.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  location.type.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          if (location.address != null) ...[
            const SizedBox(height: 4),
            Text(
              location.address!,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.gps_fixed, size: 12, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.radar, size: 12, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    '${location.radiusMeters}m geofence radius',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
