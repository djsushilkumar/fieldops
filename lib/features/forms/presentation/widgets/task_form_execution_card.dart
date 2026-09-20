import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/forms_controller.dart';
import '../screens/fill_form_screen.dart';
import '../screens/form_submissions_screen.dart';

class TaskFormExecutionCard extends ConsumerWidget {
  final String taskId;
  final String taskTitle;
  final VoidCallback? onFormSubmitted;

  const TaskFormExecutionCard({
    super.key,
    required this.taskId,
    required this.taskTitle,
    this.onFormSubmitted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissionsState = ref.watch(taskFormSubmissionsNotifierProvider(taskId));
    final formsState = ref.watch(formsListNotifierProvider);
    final hasSubmission = submissionsState.submissions.isNotEmpty;
    final latestSubmission = hasSubmission ? submissionsState.submissions.first : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasSubmission ? AppColors.secondary.withOpacity(0.4) : AppColors.divider,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hasSubmission ? AppColors.secondaryLight : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  hasSubmission ? Icons.task_alt_rounded : Icons.description_outlined,
                  size: 20,
                  color: hasSubmission ? AppColors.secondary : AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Service Checklist & Audit',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Text(
                      hasSubmission ? 'Checklist successfully submitted' : 'Required proof of work',
                      style: TextStyle(
                        fontSize: 12,
                        color: hasSubmission ? AppColors.secondary : AppColors.textSecondary,
                        fontWeight: hasSubmission ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: hasSubmission ? AppColors.secondaryLight : const Color(0xFFFEF7E0),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  hasSubmission ? 'COMPLETED' : 'PENDING',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: hasSubmission ? AppColors.secondary : const Color(0xFFB06000),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (hasSubmission && latestSubmission != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'By: ${latestSubmission.userName ?? 'Field Officer'}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      const Spacer(),
                      Text(
                        latestSubmission.formattedSubmittedAt,
                        style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                  if (latestSubmission.hasGps) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 13, color: AppColors.info),
                        const SizedBox(width: 4),
                        Text(
                          'Verified GPS: ${latestSubmission.latitude!.toStringAsFixed(4)}, ${latestSubmission.longitude!.toStringAsFixed(4)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.info),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('View Form Submission'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => FormSubmissionsScreen(
                        taskId: taskId,
                        title: 'Task Checklist Submission',
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            const Text(
              'Complete the operational checklist and capture field readings to verify service delivery.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit_note_rounded, size: 18, color: Colors.white),
                label: const Text('Fill Service Checklist', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  // Determine target form (use first available form or fallback)
                  final availableForms = formsState.forms;
                  String targetFormId = 'form-acme-hvac-001';
                  if (availableForms.isNotEmpty) {
                    targetFormId = availableForms.first.id;
                  }

                  final submitted = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (context) => FillFormScreen(
                        formId: targetFormId,
                        taskId: taskId,
                        taskTitle: taskTitle,
                      ),
                    ),
                  );

                  if (submitted == true) {
                    ref.read(taskFormSubmissionsNotifierProvider(taskId).notifier).loadSubmissions();
                    onFormSubmitted?.call();
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
