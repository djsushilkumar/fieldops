import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/attachment_entity.dart';
import '../../domain/entities/digital_signature_data.dart';
import 'signature_pad_dialog.dart';

class SignaturePreviewCard extends StatelessWidget {
  final AttachmentEntity signatureAttachment;
  final VoidCallback? onReSign;
  final bool isReadOnly;

  const SignaturePreviewCard({
    super.key,
    required this.signatureAttachment,
    this.onReSign,
    this.isReadOnly = false,
  });

  DigitalSignatureData? _parseSignatureData() {
    if (signatureAttachment.rawData == null) return null;
    try {
      final map = jsonDecode(signatureAttachment.rawData!) as Map<String, dynamic>;
      return DigitalSignatureData.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = signatureAttachment.metadata;
    final signatureData = _parseSignatureData();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.roleAdminBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.draw_rounded, color: AppColors.roleAdmin, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meta.signerName ?? 'Digital Signature Verified',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      meta.signerRole ?? 'Customer / Site Sign-Off',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified, size: 12, color: AppColors.secondary),
                    SizedBox(width: 4),
                    Text(
                      'VERIFIED SIGN-OFF',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Render strokes if available, else stylized preview
          Container(
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: signatureData != null && signatureData.strokes.isNotEmpty
                  ? CustomPaint(
                      painter: SignaturePainter(strokes: signatureData.strokes),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.draw, size: 28, color: Colors.grey.shade400),
                          const SizedBox(height: 4),
                          Text(
                            meta.signerName ?? 'Signed electronically',
                            style: const TextStyle(
                              fontFamily: 'cursive',
                              fontSize: 18,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),

          // Metadata Watermark
          Row(
            children: [
              const Icon(Icons.location_on, size: 12, color: AppColors.secondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  meta.hasGps ? meta.formattedGpsCoordinates : 'GPS Tagged',
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontFamily: 'monospace'),
                ),
              ),
              Text(
                signatureAttachment.createdAt.toUtc().toIso8601String().substring(0, 16).replaceAll('T', ' '),
                style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
              ),
            ],
          ),

          if (!isReadOnly && onReSign != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.refresh, size: 14),
                label: const Text('Re-Sign / Update', style: TextStyle(fontSize: 11)),
                onPressed: onReSign,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
