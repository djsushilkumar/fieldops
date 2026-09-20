import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/location_entity.dart';
import '../controllers/customer_controller.dart';

class CreateLocationDialog extends ConsumerStatefulWidget {
  final String customerId;

  const CreateLocationDialog({
    super.key,
    required this.customerId,
  });

  @override
  ConsumerState<CreateLocationDialog> createState() =>
      _CreateLocationDialogState();
}

class _CreateLocationDialogState extends ConsumerState<CreateLocationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _latController = TextEditingController(text: '37.7749');
  final _lonController = TextEditingController(text: '-122.4194');

  int _selectedRadius = 100;
  String _selectedType = 'site';
  bool _isAcquiringGps = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  Future<void> _fetchGps() async {
    setState(() {
      _isAcquiringGps = true;
      _errorMessage = null;
    });

    try {
      final locService = ref.read(locationServiceProvider);
      final coords = await locService.getCurrentLocation();
      _latController.text = coords.latitude.toStringAsFixed(6);
      _lonController.text = coords.longitude.toStringAsFixed(6);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to acquire GPS: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAcquiringGps = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final lat = double.tryParse(_latController.text.trim());
    final lon = double.tryParse(_lonController.text.trim());

    if (lat == null || lon == null) {
      setState(() {
        _errorMessage = 'Please provide valid decimal coordinates';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final user = ref.read(currentUserProvider);
      final now = DateTime.now();
      final newLocation = LocationEntity(
        id: 'loc-${const Uuid().v4().substring(0, 8)}',
        organizationId: user?.organizationId ?? 'org-001',
        customerId: widget.customerId,
        name: _nameController.text.trim(),
        address: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        latitude: lat,
        longitude: lon,
        radiusMeters: _selectedRadius,
        type: _selectedType,
        createdAt: now,
        updatedAt: now,
      );

      await ref
          .read(customerDetailNotifierProvider(widget.customerId).notifier)
          .addLocation(newLocation);

      if (mounted) {
        Navigator.of(context).pop(newLocation);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add Site / Location',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                AppTextField(
                  key: const Key('location_name_field'),
                  controller: _nameController,
                  label: 'Site / Location Name *',
                  hint: 'e.g. Building C Server Room',
                  prefixIcon: const Icon(Icons.business),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Site name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _addressController,
                  label: 'Address (Optional)',
                  hint: 'Street address or landmark',
                  prefixIcon: const Icon(Icons.place_outlined),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _latController,
                        label: 'Latitude *',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        validator: (val) {
                          if (val == null || double.tryParse(val) == null) {
                            return 'Valid latitude required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppTextField(
                        controller: _lonController,
                        label: 'Longitude *',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        validator: (val) {
                          if (val == null || double.tryParse(val) == null) {
                            return 'Valid longitude required';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _isAcquiringGps ? null : _fetchGps,
                  icon: _isAcquiringGps
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location, size: 16),
                  label: const Text('Capture Device GPS'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Geofence Radius',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<int>(
                            value: _selectedRadius,
                            decoration: InputDecoration(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(value: 50, child: Text('50 meters')),
                              DropdownMenuItem(value: 100, child: Text('100 meters (Default)')),
                              DropdownMenuItem(value: 200, child: Text('200 meters')),
                              DropdownMenuItem(value: 500, child: Text('500 meters')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedRadius = val);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Location Type',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<String>(
                            value: _selectedType,
                            decoration: InputDecoration(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'site', child: Text('Site')),
                              DropdownMenuItem(value: 'branch', child: Text('Branch')),
                              DropdownMenuItem(value: 'client_office', child: Text('Office')),
                              DropdownMenuItem(value: 'warehouse', child: Text('Warehouse')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedType = val);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                AppButton(
                  key: const Key('submit_location_button'),
                  label: 'Add Location',
                  isLoading: _isSubmitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
