import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../controllers/forms_controller.dart';
import '../widgets/form_submission_card.dart';

class FormSubmissionsScreen extends ConsumerWidget {
  final String? formId;
  final String? taskId;
  final String? title;

  const FormSubmissionsScreen({
    super.key,
    this.formId,
    this.taskId,
    this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissionsState = taskId != null
        ? ref.watch(taskFormSubmissionsNotifierProvider(taskId!))
        : ref.watch(formSubmissionsNotifierProvider(formId));

    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? 'Checklist Submissions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Submissions',
            onPressed: () {
              if (taskId != null) {
                ref.read(taskFormSubmissionsNotifierProvider(taskId!).notifier).loadSubmissions();
              } else {
                ref.read(formSubmissionsNotifierProvider(formId).notifier).loadSubmissions();
              }
            },
          ),
        ],
      ),
      body: _buildBody(context, ref, submissionsState),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, FormSubmissionsState state) {
    if (state.isLoading && state.submissions.isEmpty) {
      return const LoadingView(message: 'Loading submissions...');
    }

    if (state.errorMessage != null && state.submissions.isEmpty) {
      return ErrorStateView(
        title: 'Failed to load submissions',
        message: state.errorMessage!,
        onRetry: () {
          if (taskId != null) {
            ref.read(taskFormSubmissionsNotifierProvider(taskId!).notifier).loadSubmissions();
          } else {
            ref.read(formSubmissionsNotifierProvider(formId).notifier).loadSubmissions();
          }
        },
      );
    }

    if (state.submissions.isEmpty) {
      return const EmptyStateView(
        icon: Icons.assignment_late_outlined,
        title: 'No Submissions Yet',
        description: 'Completed checklists and field audits will appear here with GPS verification.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.submissions.length,
      itemBuilder: (context, index) {
        final submission = state.submissions[index];
        return FormSubmissionCard(submission: submission);
      },
    );
  }
}
