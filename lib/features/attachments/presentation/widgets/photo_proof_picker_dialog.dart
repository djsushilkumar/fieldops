import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/location/location_coordinates.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';

class PhotoProofResult {
  final String category;
  final String fileName;
  final String? notes;
  final LocationCoordinates? location;

  const PhotoProofResult({
    required this.category,
    required this.fileName,
    this.notes,
    this.location,
  });
}

class PhotoProofPickerDialog extends StatefulWidget {
  final String taskTitle;
  final LocationService? locationService;

  const PhotoProofPickerDialog({
    super.key,
    required this.taskTitle,
    this.locationService,
  });

  @override
  State<PhotoProofPickerDialog> createState() => _PhotoProofPickerDialogState();
}

class _PhotoProofPickerDialogState extends State<PhotoProofPickerDialog> {
  String _selectedCategory = 'after'; // default: 'after' completion proof
  late final TextEditingController _notesController;
  LocationCoordinates? _capturedLocation;
  bool _isLocating = false;

  final List<Map<String, String>> _categories = [
    {'code': 'before', 'title': 'Before Work', 'desc': 'Initial site or equipment state'},
    {'code': 'after', 'title': 'After Work', 'desc': 'Completed work and restored state'},
    {'code': 'site', 'title': 'Site Condition', 'desc': 'General site or environment'},
    {'code': 'hazard', 'title': 'Hazard / Defect', 'desc': 'Safety hazard or equipment defect'},
    {'code': 'general', 'title': 'General Proof', 'desc': 'Additional verification evidence'},
  ];

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _fetchGpsCoordinates();
  }

  Future<void> _fetchGpsCoordinates() async {
    if (widget.locationService == null) return;
    setState(() => _isLocating = true);
    try {
      final loc = await widget.locationService!.getCurrentLocation();
      if (mounted) {
        setState(() {
          _capturedLocation = loc;
          _isLocating = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    final now = DateTime.now();
    final fileName = 'proof_${_selectedCategory}_${now.millisecondsSinceEpoch}.jpg';

    final result = PhotoProofResult(
      category: _selectedCategory,
      fileName: fileName,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      location: _capturedLocation,
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.photo_camera_rounded, color: AppColors.secondary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Upload Photo Proof of Work',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          widget.taskTitle,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textTertiary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Proof Category Selector
              const Text(
                'Proof Category',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((c) {
                  final isSelected = _selectedCategory == c['code'];
                  return ChoiceChip(
                    label: Text(c['title']!),
                    selected: isSelected,
                    selectedColor: AppColors.secondaryLight,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.secondary : AppColors.textPrimary,
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() => _selectedCategory = c['code']!);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Camera Simulation Preview
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Stack(
                  children: [
                    // Mock camera viewfinder
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _selectedCategory == 'before'
                                ? Icons.access_time
                                : _selectedCategory == 'after'
                                    ? Icons.check_circle_outline
                                    : Icons.camera_alt_outlined,
                            size: 42,
                            color: Colors.white70,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Camera Capture: ${_selectedCategory.toUpperCase()} PROOF',
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'High-resolution field photo captured with GPS tags',
                            style: TextStyle(color: Colors.white60, fontSize: 11),
                          ),
                        ],
                      ),
                    ),

                    // Top GPS Watermark overlay
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, size: 12, color: AppColors.secondary),
                            const SizedBox(width: 4),
                            Text(
                              _capturedLocation != null
                                  ? '${_capturedLocation!.latitude.toStringAsFixed(5)}, ${_capturedLocation!.longitude.toStringAsFixed(5)}${_capturedLocation!.accuracy != null ? " (±${_capturedLocation!.accuracy!.toStringAsFixed(1)}m)" : ""}'
                                  : (_isLocating ? 'Acquiring GPS...' : 'GPS FIX ACTIVE'),
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Timestamp overlay
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          now.toUtc().toIso8601String().substring(0, 19).replaceAll('T', ' '),
                          style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace'),
                        ),
                      ),
                    ),

                    // Verified badge
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'TAMPER-PROOF',
                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Notes field
              AppTextField(
                controller: _notesController,
                label: 'Field Observations / Notes',
                hint: 'e.g. Coil cleaned thoroughly, baseline pressure verified at 120 PSI',
                maxLines: 2,
                prefixIcon: const Icon(Icons.notes),
              ),
              const SizedBox(height: 20),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Save & Upload Proof',
                      icon: Icons.upload_rounded,
                      variant: AppButtonVariant.primary,
                      onPressed: _submit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
