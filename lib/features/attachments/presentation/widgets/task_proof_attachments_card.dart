import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/location/location_service.dart';
import '../../../tasks/domain/entities/task_entity.dart';
import '../../domain/entities/digital_signature_data.dart';
import '../controllers/task_attachments_controller.dart';
import 'attachment_thumbnail_widget.dart';
import 'photo_proof_picker_dialog.dart';
import 'signature_pad_dialog.dart';
import 'signature_preview_card.dart';

class TaskProofAttachmentsCard extends ConsumerWidget {
  final TaskEntity task;
  final VoidCallback? onProofUpdated;
  final bool isReadOnly;

  const TaskProofAttachmentsCard({
    super.key,
    required this.task,
    this.onProofUpdated,
    this.isReadOnly = false,
  });

  void _openPhotoDialog(BuildContext context, WidgetRef ref) async {
    final locationService = ref.read(locationServiceProvider);
    final result = await showDialog<PhotoProofResult>(
      context: context,
      builder: (ctx) => PhotoProofPickerDialog(
        taskTitle: task.title,
        locationService: locationService,
      ),
    );

    if (result != null) {
      final success = await ref
          .read(taskAttachmentsNotifierProvider(task.id).notifier)
          .uploadPhotoProof(
            category: result.category,
            fileName: result.fileName,
            notes: result.notes,
            location: result.location,
          );
      if (success) {
        onProofUpdated?.call();
      }
    }
  }

  void _openSignatureDialog(BuildContext context, WidgetRef ref) async {
    final locationService = ref.read(locationServiceProvider);
    final result = await showDialog<DigitalSignatureData>(
      context: context,
      builder: (ctx) => SignaturePadDialog(
        taskTitle: task.title,
        customerName: task.customerName,
        locationService: locationService,
      ),
    );

    if (result != null) {
      final success = await ref
          .read(taskAttachmentsNotifierProvider(task.id).notifier)
          .saveDigitalSignature(signature: result);
      if (success) {
        onProofUpdated?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attachmentsState = ref.watch(taskAttachmentsNotifierProvider(task.id));
    final photos = attachmentsState.photos;
    final signature = attachmentsState.latestSignature;

    final hasPhotoProof = !task.requiresPhoto || photos.isNotEmpty;
    final hasSignatureProof = !task.requiresSignature || signature != null;
    final isProofsComplete = hasPhotoProof && hasSignatureProof;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isProofsComplete ? AppColors.secondaryLight : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isProofsComplete ? Icons.verified_rounded : Icons.photo_library_outlined,
                    color: isProofsComplete ? AppColors.secondary : AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Proof of Work Attachments',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        task.requiresPhoto && task.requiresSignature
                            ? 'Photos & Sign-Off Required'
                            : task.requiresPhoto
                                ? 'Photos Required'
                                : task.requiresSignature
                                    ? 'Customer Sign-Off Required'
                                    : 'Field Evidence & Signatures',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isProofsComplete ? AppColors.secondaryLight : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isProofsComplete ? 'COMPLETE' : 'PENDING PROOF',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isProofsComplete ? AppColors.secondary : AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Upload action buttons (if task can be modified)
          if (!isReadOnly && !task.isCompleted)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                      label: Text(
                        photos.isEmpty ? 'Add Photo Proof' : 'Add More Photos',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () => _openPhotoDialog(context, ref),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: BorderSide(
                          color: task.requiresPhoto && photos.isEmpty
                              ? AppColors.primary
                              : AppColors.divider,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.draw_outlined, size: 16),
                      label: Text(
                        signature == null ? 'Get Signature' : 'Re-Sign',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () => _openSignatureDialog(context, ref),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: BorderSide(
                          color: task.requiresSignature && signature == null
                              ? AppColors.roleAdmin
                              : AppColors.divider,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Photos section
          if (photos.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Photo Evidences (${photos.length})',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    task.requiresPhoto ? '✓ Photo requirement met' : 'Optional photos',
                    style: TextStyle(
                      fontSize: 11,
                      color: task.requiresPhoto ? AppColors.secondary : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 115,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (ctx, i) => const SizedBox(width: 10),
                itemBuilder: (ctx, index) {
                  final att = photos[index];
                  return AttachmentThumbnailWidget(
                    attachment: att,
                    isReadOnly: isReadOnly || task.isCompleted,
                    onDelete: () async {
                      await ref
                          .read(taskAttachmentsNotifierProvider(task.id).notifier)
                          .deleteAttachment(att.id);
                      onProofUpdated?.call();
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ] else if (task.requiresPhoto) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'At least one photo proof is required before this task can be completed.',
                        style: TextStyle(fontSize: 11, color: Colors.brown),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Digital Signature Section
          if (signature != null) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: SignaturePreviewCard(
                signatureAttachment: signature,
                isReadOnly: isReadOnly || task.isCompleted,
                onReSign: () => _openSignatureDialog(context, ref),
              ),
            ),
          ] else if (task.requiresSignature) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.edit_note_rounded, size: 18, color: AppColors.roleAdmin),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Digital customer or site supervisor sign-off signature is mandatory.',
                        style: TextStyle(fontSize: 11, color: AppColors.roleAdmin),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (photos.isEmpty && signature == null && !task.requiresPhoto && !task.requiresSignature)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No attachments or signatures uploaded for this task.',
                  style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
