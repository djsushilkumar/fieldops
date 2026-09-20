import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../navigation/presentation/widgets/app_top_nav_bar.dart';
import '../controllers/organization_settings_controller.dart';

class OrganizationProfileScreen extends ConsumerStatefulWidget {
  const OrganizationProfileScreen({super.key});

  @override
  ConsumerState<OrganizationProfileScreen> createState() => _OrganizationProfileScreenState();
}

class _OrganizationProfileScreenState extends ConsumerState<OrganizationProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _industryController;
  String _timezone = 'America/New_York';
  String _currency = 'USD';
  int _geofenceRadius = 100;
  int _autoCheckoutHours = 10;
  bool _requirePhoto = true;
  bool _requireGps = true;
  bool _initialized = false;

  final List<String> _timezones = const [
    'America/New_York',
    'America/Chicago',
    'America/Denver',
    'America/Los_Angeles',
    'UTC',
    'Europe/London',
  ];

  final List<String> _currencies = const ['USD', 'EUR', 'GBP', 'CAD', 'AUD'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _industryController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _industryController.dispose();
    super.dispose();
  }

  void _initFields(state) {
    if (_initialized || state.organization == null) return;
    final org = state.organization!;
    _nameController.text = org.name;
    _industryController.text = org.industry;
    _timezone = org.timezone;
    _currency = org.currency;
    _geofenceRadius = org.geofenceDefaultRadius;
    _autoCheckoutHours = org.autoCheckoutHours;
    _requirePhoto = org.requirePhotoOnCompletion;
    _requireGps = org.requireGpsOnCheckin;
    _initialized = true;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(organizationSettingsControllerProvider.notifier);
    final success = await controller.saveSettings(
      name: _nameController.text.trim(),
      industry: _industryController.text.trim(),
      timezone: _timezone,
      currency: _currency,
      geofenceRadius: _geofenceRadius,
      autoCheckoutHours: _autoCheckoutHours,
      requirePhoto: _requirePhoto,
      requireGps: _requireGps,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Organization settings saved!'),
            ],
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(organizationSettingsControllerProvider);
    _initFields(state);

    final org = state.organization;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: const AppTopNavBar(
        title: 'Organization Settings',
      ),
      body: state.isLoading && org == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Section: Tenant ID banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.roleAdminBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.apartment_rounded, color: AppColors.roleAdmin),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Organization Tenant ID',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                org?.id ?? 'org-acme-ops-001',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Copy Tenant ID',
                          icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.roleAdmin),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: org?.id ?? 'org-acme-ops-001'));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Tenant ID copied to clipboard'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Section: General Information
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Company & Localization',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 14),

                        // Name
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Organization Name',
                            prefixIcon: Icon(Icons.business_rounded, size: 20),
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Enter company name' : null,
                        ),
                        const SizedBox(height: 14),

                        // Industry
                        TextFormField(
                          controller: _industryController,
                          decoration: const InputDecoration(
                            labelText: 'Industry / Domain',
                            prefixIcon: Icon(Icons.category_rounded, size: 20),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Timezone & Currency
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                value: _timezones.contains(_timezone) ? _timezone : _timezones.first,
                                decoration: const InputDecoration(
                                  labelText: 'Timezone',
                                  prefixIcon: Icon(Icons.schedule_rounded, size: 20),
                                  border: OutlineInputBorder(),
                                ),
                                items: _timezones.map((tz) {
                                  return DropdownMenuItem(value: tz, child: Text(tz, style: const TextStyle(fontSize: 12)));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _timezone = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                value: _currencies.contains(_currency) ? _currency : _currencies.first,
                                decoration: const InputDecoration(
                                  labelText: 'Currency',
                                  prefixIcon: Icon(Icons.attach_money_rounded, size: 20),
                                  border: OutlineInputBorder(),
                                ),
                                items: _currencies.map((c) {
                                  return DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12)));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _currency = val);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Section: Geofencing & Operational Policies
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Field Dispatch & Geofencing Policies',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Enforce automated boundary checks and verification proofs across all mobile devices.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),

                        // Geofence Radius Selector
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Default Site Geofence Radius',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '$_geofenceRadius meters',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<int>(
                          segments: const [
                            ButtonSegment(value: 50, label: Text('50m')),
                            ButtonSegment(value: 100, label: Text('100m')),
                            ButtonSegment(value: 200, label: Text('200m')),
                            ButtonSegment(value: 500, label: Text('500m')),
                          ],
                          selected: {_geofenceRadius},
                          onSelectionChanged: (set) {
                            setState(() => _geofenceRadius = set.first);
                          },
                        ),
                        const Divider(height: 28),

                        // Require GPS Switch
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Require GPS Verification on Check-in', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: const Text('Prevents remote check-in outside authorized customer boundaries.', style: TextStyle(fontSize: 11)),
                          value: _requireGps,
                          activeColor: AppColors.roleAdmin,
                          onChanged: (val) => setState(() => _requireGps = val),
                        ),
                        const Divider(height: 20),

                        // Require Photo Switch
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Require Photo Proof on Task Completion', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: const Text('Technicians must capture timestamped site photos before closing work orders.', style: TextStyle(fontSize: 11)),
                          value: _requirePhoto,
                          activeColor: AppColors.roleAdmin,
                          onChanged: (val) => setState(() => _requirePhoto = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  ElevatedButton.icon(
                    onPressed: state.isSaving ? null : _handleSave,
                    icon: state.isSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_rounded, size: 20),
                    label: Text(state.isSaving ? 'Saving...' : 'Save Organization Settings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.roleAdmin,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
