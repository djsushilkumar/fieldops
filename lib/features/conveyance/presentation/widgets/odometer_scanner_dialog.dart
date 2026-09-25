import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/location/location_service.dart';
import '../../domain/entities/odometer_reading_entity.dart';
import '../../domain/services/odometer_ocr_engine.dart';

class OdometerScannerDialog extends StatefulWidget {
  final OdometerReadingType readingType;
  final double? previousReading;
  final void Function(OdometerReadingEntity reading) onReadingCaptured;

  const OdometerScannerDialog({
    super.key,
    required this.readingType,
    this.previousReading,
    required this.onReadingCaptured,
  });

  static Future<OdometerReadingEntity?> show(
    BuildContext context, {
    required OdometerReadingType readingType,
    double? previousReading,
  }) {
    return showDialog<OdometerReadingEntity>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => OdometerScannerDialog(
        readingType: readingType,
        previousReading: previousReading,
        onReadingCaptured: (reading) {
          Navigator.of(ctx).pop(reading);
        },
      ),
    );
  }

  @override
  State<OdometerScannerDialog> createState() => _OdometerScannerDialogState();
}

class _OdometerScannerDialogState extends State<OdometerScannerDialog> {
  bool _isProcessing = false;
  bool _hasCaptured = false;
  String _simulatedRawOcr = '';
  OcrExtractionResult? _ocrResult;
  final _readingController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isManualOverride = false;
  double _lat = 0.0;
  double _lng = 0.0;

  @override
  void initState() {
    super.initState();
    _acquireGps();
  }

  @override
  void dispose() {
    _readingController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _acquireGps() async {
    try {
      final loc = await GeolocatorLocationService().getCurrentLocation();
      if (mounted) {
        setState(() {
          _lat = loc.latitude;
          _lng = loc.longitude;
        });
      }
    } catch (_) {}
  }

  void _simulateCameraCapture() {
    setState(() {
      _isProcessing = true;
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;

      // Realistic simulated OCR output from vehicle odometer dashboard
      final baseReading = widget.previousReading != null
          ? (widget.previousReading! + 38.5)
          : 12450.0;

      final sampleOcrStrings = [
        'TOTAL ODO 0${baseReading.toInt()} KM TRIP A 38.5',
        'ODO ${baseReading.toStringAsFixed(1)} km SPEED 0 km/h',
        'METER 0${baseReading.toInt()}KM',
      ];

      final raw = sampleOcrStrings[(baseReading.toInt()) % sampleOcrStrings.length];
      final result = OdometerOcrEngine.extractOdometerReading(
        raw,
        previousReading: widget.previousReading,
      );

      setState(() {
        _isProcessing = false;
        _hasCaptured = true;
        _simulatedRawOcr = raw;
        _ocrResult = result;
        if (result.reading != null) {
          _readingController.text = result.reading!.toStringAsFixed(1);
        }
      });
    });
  }

  void _submitReading() {
    final parsedReading = double.tryParse(_readingController.text.trim());
    if (parsedReading == null || parsedReading < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid numeric odometer reading.')),
      );
      return;
    }

    if (widget.previousReading != null && parsedReading < widget.previousReading!) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ending reading ($parsedReading km) cannot be less than start reading (${widget.previousReading} km).',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final entity = OdometerReadingEntity(
      reading: parsedReading,
      readingType: widget.readingType,
      photoPath: 'odometer_capture_${DateTime.now().millisecondsSinceEpoch}.jpg',
      rawOcrText: _simulatedRawOcr,
      confidence: _ocrResult?.confidence ?? 1.0,
      timestamp: DateTime.now(),
      latitude: _lat,
      longitude: _lng,
      isManualOverride: _isManualOverride,
      overrideReason: _isManualOverride ? _reasonController.text.trim() : null,
    );

    widget.onReadingCaptured(entity);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
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
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.speed_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.readingType.displayName} Odometer',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const Text(
                          'AI-Powered ML Kit OCR Digit Recognition',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Camera Viewport / OCR Preview Card
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade800),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (!_hasCaptured && !_isProcessing)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined, color: Colors.white.withOpacity(0.7), size: 40),
                          const SizedBox(height: 8),
                          const Text(
                            'Align vehicle odometer within the frame',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.camera, size: 18),
                            label: const Text('Capture & Scan OCR'),
                            onPressed: _simulateCameraCapture,
                          ),
                        ],
                      ),
                    if (_isProcessing)
                      const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 12),
                          Text(
                            'Processing image with ML OCR...',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                    if (_hasCaptured && !_isProcessing)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline, color: AppColors.success, size: 36),
                          const SizedBox(height: 6),
                          Text(
                            'Odometer Digits Extracted: ${_readingController.text} km',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Confidence: ${((_ocrResult?.confidence ?? 0.95) * 100).toInt()}% • Raw: "$_simulatedRawOcr"',
                            style: const TextStyle(color: Colors.white60, fontSize: 11),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            style: TextButton.styleFrom(foregroundColor: Colors.white70),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Retake Photo'),
                            onPressed: _simulateCameraCapture,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Reading text field
              TextFormField(
                controller: _readingController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Detected Odometer (km)',
                  suffixText: 'km',
                  prefixIcon: const Icon(Icons.pin, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 8),

              // Manual override option
              Row(
                children: [
                  Checkbox(
                    value: _isManualOverride,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        _isManualOverride = val ?? false;
                      });
                    },
                  ),
                  const Text('Manual correction / OCR override', style: TextStyle(fontSize: 13)),
                ],
              ),

              if (_isManualOverride) ...[
                const SizedBox(height: 4),
                TextFormField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                    labelText: 'Reason for override (e.g. Glare on dashboard)',
                    hintText: 'Enter reason for manager review',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Confirm button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _readingController.text.isNotEmpty ? _submitReading : null,
                child: Text('Confirm ${widget.readingType.displayName} Reading'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
