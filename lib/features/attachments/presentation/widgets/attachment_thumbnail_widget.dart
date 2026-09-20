import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/attachment_entity.dart';

class AttachmentThumbnailWidget extends StatelessWidget {
  final AttachmentEntity attachment;
  final VoidCallback? onDelete;
  final bool isReadOnly;

  const AttachmentThumbnailWidget({
    super.key,
    required this.attachment,
    this.onDelete,
    this.isReadOnly = false,
  });

  Color _getCategoryColor(String? cat) {
    switch (cat?.toLowerCase()) {
      case 'before':
        return AppColors.warning;
      case 'after':
        return AppColors.secondary;
      case 'hazard':
        return AppColors.error;
      case 'site':
        return AppColors.primary;
      default:
        return AppColors.accent;
    }
  }

  void _showDetailModal(BuildContext context) {
    final meta = attachment.metadata;
    final catColor = _getCategoryColor(meta.category);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
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
                        color: catColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.photo_camera_rounded, color: catColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meta.category != null ? '${meta.category!.toUpperCase()} PROOF' : 'PHOTO PROOF',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: catColor,
                            ),
                          ),
                          Text(
                            attachment.fileName,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Photo visual
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              meta.category == 'before' ? Icons.history : Icons.verified,
                              color: catColor,
                              size: 48,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Verified Proof: ${meta.category?.toUpperCase() ?? "WORK"}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              attachment.formattedSize,
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),

                      // Overlay Watermark
                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (meta.hasGps)
                                Text(
                                  'GPS: ${meta.formattedGpsCoordinates}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              Text(
                                'TIMESTAMP: ${attachment.createdAt.toUtc().toIso8601String().substring(0, 19)}Z',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Metadata Details
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: [
                      _buildMetaRow('Uploaded By', attachment.uploadedByName ?? attachment.uploadedBy),
                      if (meta.notes != null && meta.notes!.isNotEmpty) ...[
                        const Divider(height: 16),
                        _buildMetaRow('Field Notes', meta.notes!),
                      ],
                      if (meta.hasGps) ...[
                        const Divider(height: 16),
                        _buildMetaRow('Coordinates', '${meta.latitude!.toStringAsFixed(6)}, ${meta.longitude!.toStringAsFixed(6)}'),
                        if (meta.accuracy != null) ...[
                          const SizedBox(height: 4),
                          _buildMetaRow('GPS Accuracy', '±${meta.accuracy!.toStringAsFixed(1)} meters'),
                        ],
                      ],
                      const Divider(height: 16),
                      _buildMetaRow('File Storage Path', attachment.storagePath),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Close Button
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Close Preview'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final meta = attachment.metadata;
    final catColor = _getCategoryColor(meta.category);

    return InkWell(
      onTap: () => _showDetailModal(context),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Preview Header
            Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      meta.category == 'before' ? Icons.history : Icons.photo_camera_rounded,
                      color: catColor,
                      size: 28,
                    ),
                  ),
                  // Category pill
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: catColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        (meta.category ?? 'photo').toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Delete button
                  if (!isReadOnly && onDelete != null)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: InkWell(
                        onTap: onDelete,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Metadata footer
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.fileName,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (meta.hasGps) ...[
                        const Icon(Icons.location_on, size: 10, color: AppColors.secondary),
                        const SizedBox(width: 2),
                      ],
                      Expanded(
                        child: Text(
                          meta.hasGps ? 'GPS Fix' : attachment.formattedSize,
                          style: TextStyle(
                            fontSize: 9,
                            color: meta.hasGps ? AppColors.secondary : AppColors.textTertiary,
                            fontWeight: meta.hasGps ? FontWeight.bold : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
