import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/location/location_coordinates.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/digital_signature_data.dart';

class SignaturePadDialog extends StatefulWidget {
  final String taskTitle;
  final String? customerName;
  final LocationService? locationService;

  const SignaturePadDialog({
    super.key,
    required this.taskTitle,
    this.customerName,
    this.locationService,
  });

  @override
  State<SignaturePadDialog> createState() => _SignaturePadDialogState();
}

class _SignaturePadDialogState extends State<SignaturePadDialog> {
  final List<DigitalSignatureStroke> _strokes = [];
  List<DigitalSignaturePoint> _currentStrokePoints = [];

  late final TextEditingController _nameController;
  late final TextEditingController _roleController;
  late final TextEditingController _emailController;

  LocationCoordinates? _capturedLocation;
  bool _isLocating = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customerName ?? '');
    _roleController = TextEditingController(text: 'Customer / Site Contact');
    _emailController = TextEditingController();
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
    _nameController.dispose();
    _roleController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details, BoxConstraints constraints) {
    setState(() {
      _validationError = null;
      _currentStrokePoints = [
        DigitalSignaturePoint(details.localPosition.dx, details.localPosition.dy),
      ];
    });
  }

  void _onPanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    setState(() {
      _currentStrokePoints.add(
        DigitalSignaturePoint(details.localPosition.dx, details.localPosition.dy),
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentStrokePoints.isNotEmpty) {
      setState(() {
        _strokes.add(
          DigitalSignatureStroke(
            points: List.from(_currentStrokePoints),
            colorValue: 0xFF1A1A2E,
            strokeWidth: 2.8,
          ),
        );
        _currentStrokePoints = [];
      });
    }
  }

  void _clearSignature() {
    setState(() {
      _strokes.clear();
      _currentStrokePoints.clear();
      _validationError = null;
    });
  }

  void _undoLastStroke() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _strokes.removeLast();
      });
    }
  }

  void _submitSignature() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _validationError = 'Please enter the signer\'s full name');
      return;
    }

    if (_strokes.isEmpty || _strokes.every((s) => s.points.isEmpty)) {
      setState(() => _validationError = 'Please provide a handwritten signature in the pad');
      return;
    }

    final data = DigitalSignatureData(
      strokes: List.from(_strokes),
      signerName: name,
      signerRole: _roleController.text.trim().isNotEmpty
          ? _roleController.text.trim()
          : 'Customer / Site Contact',
      signerEmail: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
      signedAt: DateTime.now(),
      latitude: _capturedLocation?.latitude,
      longitude: _capturedLocation?.longitude,
      accuracy: _capturedLocation?.accuracy,
    );

    Navigator.of(context).pop(data);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540),
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
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.draw_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Digital Sign-Off Acceptance',
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

              // Signer Information Inputs
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: AppTextField(
                      controller: _nameController,
                      label: 'Signer Full Name *',
                      hint: 'e.g. Marcus Vance',
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: AppTextField(
                      controller: _roleController,
                      label: 'Signer Role',
                      hint: 'e.g. Supervisor',
                      prefixIcon: const Icon(Icons.badge_outlined),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              AppTextField(
                controller: _emailController,
                label: 'Signer Email (Optional for receipt copy)',
                hint: 'e.g. signer@company.com',
                prefixIcon: const Icon(Icons.email_outlined),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Canvas Header with Undo and Clear
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Handwritten Signature *',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.undo, size: 14),
                        label: const Text('Undo', style: TextStyle(fontSize: 11)),
                        onPressed: _strokes.isNotEmpty ? _undoLastStroke : null,
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.delete_outline, size: 14, color: AppColors.error),
                        label: const Text('Clear', style: TextStyle(fontSize: 11, color: AppColors.error)),
                        onPressed: _strokes.isNotEmpty ? _clearSignature : null,
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Signature Drawing Pad
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _validationError != null ? AppColors.error : AppColors.divider,
                    width: _validationError != null ? 1.5 : 1.0,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        key: const Key('signature_pad_canvas'),
                        behavior: HitTestBehavior.opaque,
                        onPanStart: (d) => _onPanStart(d, constraints),
                        onPanUpdate: (d) => _onPanUpdate(d, constraints),
                        onPanEnd: _onPanEnd,
                        child: CustomPaint(
                          painter: SignaturePainter(
                            strokes: _strokes,
                            currentStroke: _currentStrokePoints,
                          ),
                          child: Stack(
                            children: [
                              // Guide line
                              Positioned(
                                bottom: 38,
                                left: 20,
                                right: 20,
                                child: Container(
                                  height: 1,
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              Positioned(
                                bottom: 12,
                                right: 16,
                                child: Text(
                                  'Sign Above The Line',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade400,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (_strokes.isEmpty && _currentStrokePoints.isEmpty)
                                const Center(
                                  child: Text(
                                    'Touch & draw signature here',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Validation Error
              if (_validationError != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.error_outline, size: 14, color: AppColors.error),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _validationError!,
                        style: const TextStyle(fontSize: 11, color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),

              // GPS and Timestamp Audit Watermark
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.security, size: 16, color: AppColors.secondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _capturedLocation != null
                                ? 'GPS Watermark: ${_capturedLocation!.latitude.toStringAsFixed(5)}, ${_capturedLocation!.longitude.toStringAsFixed(5)}${_capturedLocation!.accuracy != null ? " (±${_capturedLocation!.accuracy!.toStringAsFixed(1)}m)" : ""}'
                                : (_isLocating ? 'Acquiring GPS fix...' : 'GPS Watermark: Site Verification Active'),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                          Text(
                            'Timestamp: ${now.toUtc().toIso8601String().substring(0, 19)}Z',
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.verified, size: 16, color: AppColors.secondary),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
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
                      label: 'Save & Sign',
                      icon: Icons.check,
                      variant: AppButtonVariant.primary,
                      onPressed: _submitSignature,
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

class SignaturePainter extends CustomPainter {
  final List<DigitalSignatureStroke> strokes;
  final List<DigitalSignaturePoint>? currentStroke;

  SignaturePainter({
    required this.strokes,
    this.currentStroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw completed strokes
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      final paint = Paint()
        ..color = Color(stroke.colorValue)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = stroke.strokeWidth
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(stroke.points.first.x, stroke.points.first.y);
      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].x, stroke.points[i].y);
      }
      canvas.drawPath(path, paint);
    }

    // Draw active stroke currently being dragged
    if (currentStroke != null && currentStroke!.isNotEmpty) {
      final activePaint = Paint()
        ..color = const Color(0xFF1A1A2E)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 2.8
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(currentStroke!.first.x, currentStroke!.first.y);
      for (int i = 1; i < currentStroke!.length; i++) {
        path.lineTo(currentStroke![i].x, currentStroke![i].y);
      }
      canvas.drawPath(path, activePaint);
    }
  }

  @override
  bool shouldRepaint(covariant SignaturePainter oldDelegate) => true;
}
