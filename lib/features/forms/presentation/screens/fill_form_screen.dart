import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../tasks/presentation/controllers/task_controller.dart';
import '../controllers/forms_controller.dart';
import '../widgets/form_field_renderer.dart';

class FillFormScreen extends ConsumerStatefulWidget {
  final String formId;
  final String? taskId;
  final String? taskTitle;

  const FillFormScreen({
    super.key,
    required this.formId,
    this.taskId,
    this.taskTitle,
  });

  @override
  ConsumerState<FillFormScreen> createState() => _FillFormScreenState();
}

class _FillFormScreenState extends ConsumerState<FillFormScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.taskId != null) {
      Future.microtask(() {
        ref.read(formFillerNotifierProvider(widget.formId).notifier).setTaskId(widget.taskId);
      });
    }
  }

  Future<void> _handleSubmit() async {
    final submission = await ref.read(formFillerNotifierProvider(widget.formId).notifier).submit();

    if (submission != null && mounted) {
      // If linked to a task, refresh task detail and task list
      if (widget.taskId != null) {
        ref.read(taskDetailNotifierProvider(widget.taskId!).notifier).loadTask();
        ref.read(taskListNotifierProvider.notifier).loadTasks();
      }

      // Refresh submissions lists
      ref.invalidate(formSubmissionsNotifierProvider(widget.formId));
      if (widget.taskId != null) {
        ref.invalidate(taskFormSubmissionsNotifierProvider(widget.taskId!));
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            submission.hasGps
                ? 'Checklist submitted with GPS coordinates (${submission.latitude!.toStringAsFixed(4)}, ${submission.longitude!.toStringAsFixed(4)})!'
                : 'Checklist submitted successfully!',
          ),
          backgroundColor: AppColors.secondary,
        ),
      );

      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fillerState = ref.watch(formFillerNotifierProvider(widget.formId));

    if (fillerState.form == null) {
      if (fillerState.errorMessage != null) {
        return Scaffold(
          appBar: AppBar(title: const Text('Fill Checklist')),
          body: ErrorStateView(
            title: 'Failed to load checklist',
            message: fillerState.errorMessage!,
            onRetry: () => ref.read(formFillerNotifierProvider(widget.formId).notifier).loadForm(),
          ),
        );
      }
      return Scaffold(
        appBar: AppBar(title: const Text('Fill Checklist')),
        body: const LoadingView(message: 'Loading checklist schema...'),
      );
    }

    final form = fillerState.form!;

    return Scaffold(
      appBar: AppBar(
        title: Text(form.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, size: 20),
            tooltip: 'Form Info',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(form.name),
                  content: Text(form.description ?? 'Standard field checklist form.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              icon: fillerState.isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
              label: Text(
                fillerState.isSubmitting ? 'Submitting...' : 'Submit Checklist',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: fillerState.isSubmitting ? null : _handleSubmit,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task link header if present
            if (widget.taskId != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.roleEmployeeBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.roleEmployee.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link_rounded, color: AppColors.roleEmployee, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Linked to Task',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.roleEmployee),
                          ),
                          Text(
                            widget.taskTitle ?? 'Task #${widget.taskId}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Form Description Banner
            if (form.description != null && form.description!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        form.description!,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Error summary banner if validation failed
            if (fillerState.errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 18, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        fillerState.errorMessage!,
                        style: const TextStyle(fontSize: 13, color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Form Fields List
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
                  Row(
                    children: [
                      const Icon(Icons.checklist_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Form Inputs (${form.schema.fields.length})',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...form.schema.fields.map((field) {
                    return FormFieldRenderer(
                      field: field,
                      value: fillerState.answers[field.id],
                      errorText: fillerState.errors[field.id],
                      onChanged: (val) {
                        ref.read(formFillerNotifierProvider(widget.formId).notifier).setAnswer(field.id, val);
                      },
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // GPS audit disclosure card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FE),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.info.withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.gps_fixed_rounded, size: 16, color: AppColors.info),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'GPS coordinates are verified automatically upon submitting this checklist for proof-of-work compliance.',
                      style: TextStyle(fontSize: 12, color: AppColors.info),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
