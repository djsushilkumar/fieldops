import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/custom_form_entity.dart';
import '../controllers/forms_controller.dart';
import 'form_builder_screen.dart';

class FormsManagementScreen extends ConsumerStatefulWidget {
  const FormsManagementScreen({super.key});

  @override
  ConsumerState<FormsManagementScreen> createState() => _FormsManagementScreenState();
}

class _FormsManagementScreenState extends ConsumerState<FormsManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formsState = ref.watch(formsListNotifierProvider);
    final currentUser = ref.watch(currentUserProvider);
    final canManageForms = currentUser?.role.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Forms & Checklists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Forms',
            onPressed: () => ref.read(formsListNotifierProvider.notifier).loadForms(forceRefresh: true),
          ),
        ],
      ),
      floatingActionButton: canManageForms
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const FormBuilderScreen(),
                  ),
                );
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Create Form',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
      body: Column(
        children: [
          // Search & filter bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search forms by title or description...',
                prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textTertiary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(formsListNotifierProvider.notifier).setSearchQuery('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
              ),
              onChanged: (val) {
                ref.read(formsListNotifierProvider.notifier).setSearchQuery(val);
              },
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // Content body
          Expanded(
            child: _buildBody(formsState, canManageForms),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(FormsListState state, bool canManage) {
    if (state.isLoading && state.forms.isEmpty) {
      return const LoadingView(message: 'Loading organization forms...');
    }

    if (state.errorMessage != null && state.forms.isEmpty) {
      return ErrorStateView(
        title: 'Failed to load forms',
        message: state.errorMessage!,
        onRetry: () => ref.read(formsListNotifierProvider.notifier).loadForms(forceRefresh: true),
      );
    }

    final forms = state.filteredForms;

    if (forms.isEmpty) {
      return EmptyStateView(
        icon: Icons.dynamic_form_rounded,
        title: state.searchQuery.isNotEmpty ? 'No Matching Forms' : 'No Custom Forms Yet',
        description: state.searchQuery.isNotEmpty
            ? 'No forms found matching "${state.searchQuery}".'
            : 'Build custom inspection checklists and service sign-off forms.',
        actionLabel: canManage ? 'Create First Form' : null,
        onAction: canManage
            ? () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const FormBuilderScreen(),
                  ),
                );
              }
            : null,
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(formsListNotifierProvider.notifier).loadForms(forceRefresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: forms.length,
        itemBuilder: (context, index) {
          final form = forms[index];
          return _buildFormCard(form, canManage);
        },
      ),
    );
  }

  Widget _buildFormCard(CustomFormEntity form, bool canManage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Title + Actions menu
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.assignment_outlined, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        form.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (form.description != null && form.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          form.description!,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (canManage)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textSecondary),
                    onSelected: (action) {
                      if (action == 'edit') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => FormBuilderScreen(existingForm: form),
                          ),
                        );
                      } else if (action == 'delete') {
                        _confirmDelete(form);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Edit in Builder'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('Delete Form', style: TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Metadata Badges Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F3F4),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.format_list_bulleted, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${form.fieldCount} fields',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 13, color: AppColors.secondary),
                      const SizedBox(width: 4),
                      Text(
                        '${form.submissionsCount} submissions',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: AppColors.divider),

            // Bottom Buttons: "Fill Checklist" and "View Submissions"
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.history_rounded, size: 16),
                    label: const Text('Submissions'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      context.push('/forms/${form.id}/submissions');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit_document, size: 16, color: Colors.white),
                    label: const Text('Fill Form', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      context.push('/forms/${form.id}/fill');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(CustomFormEntity form) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Form?'),
        content: Text('Are you sure you want to delete "${form.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              final ok = await ref.read(formsListNotifierProvider.notifier).deleteForm(form.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'Form deleted' : 'Failed to delete form'),
                    backgroundColor: ok ? AppColors.secondary : AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
