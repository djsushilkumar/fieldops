import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/custom_form_entity.dart';
import '../../domain/entities/form_field_type.dart';
import '../controllers/forms_controller.dart';
import '../widgets/form_field_builder_card.dart';

class FormBuilderScreen extends ConsumerStatefulWidget {
  final CustomFormEntity? existingForm;

  const FormBuilderScreen({super.key, this.existingForm});

  @override
  ConsumerState<FormBuilderScreen> createState() => _FormBuilderScreenState();
}

class _FormBuilderScreenState extends ConsumerState<FormBuilderScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingForm?.name ?? '');
    _descController = TextEditingController(text: widget.existingForm?.description ?? '');
    Future.microtask(() {
      ref.read(formBuilderNotifierProvider.notifier).initialize(widget.existingForm);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _showAddFieldSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Field Type',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...FormFieldType.values.map((type) {
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(type.icon, size: 20, color: AppColors.primary),
                    ),
                    title: Text(type.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    onTap: () {
                      Navigator.of(sheetCtx).pop();
                      ref.read(formBuilderNotifierProvider.notifier).addField(type);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSave() async {
    final org = ref.read(currentOrgProvider);
    final orgId = org?.id ?? 'org-acme-ops-001';

    // Update notifier state from text controllers first
    ref.read(formBuilderNotifierProvider.notifier).setName(_nameController.text);
    ref.read(formBuilderNotifierProvider.notifier).setDescription(_descController.text);

    final result = await ref.read(formBuilderNotifierProvider.notifier).saveForm(organizationId: orgId);

    if (result != null && mounted) {
      ref.read(formsListNotifierProvider.notifier).loadForms(forceRefresh: true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Form "${result.name}" saved successfully!'),
          backgroundColor: AppColors.secondary,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final builderState = ref.watch(formBuilderNotifierProvider);
    final isEditing = widget.existingForm != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Form' : 'Create Custom Form'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: builderState.isSaving
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                  )
                : TextButton.icon(
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Save Form', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                    onPressed: _handleSave,
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Error banner if any
            if (builderState.errorMessage != null) ...[
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
                        builderState.errorMessage!,
                        style: const TextStyle(fontSize: 13, color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Form Title & Description Card
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
                  const Text(
                    'Form Details',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Form Title *',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Safety Inspection Checklist',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (val) {
                      ref.read(formBuilderNotifierProvider.notifier).setName(val);
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Description / Instructions',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _descController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Brief instructions for technicians completing this form...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (val) {
                      ref.read(formBuilderNotifierProvider.notifier).setDescription(val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form Fields Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Form Fields',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${builderState.fields.length} dynamic field(s) configured',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                  label: const Text('Add Field', style: TextStyle(color: Colors.white, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _showAddFieldSheet(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Field cards list
            if (builderState.fields.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.add_circle_outline, size: 36, color: AppColors.textTertiary),
                    const SizedBox(height: 8),
                    const Text(
                      'No fields added yet',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Click "Add Field" to add inputs (Text, Number, Dropdown, etc.)',
                      style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add First Field'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 36),
                      ),
                      onPressed: () => _showAddFieldSheet(context),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ...List.generate(builderState.fields.length, (idx) {
                final field = builderState.fields[idx];
                return FormFieldBuilderCard(
                  key: ValueKey(field.id),
                  index: idx,
                  field: field,
                  isFirst: idx == 0,
                  isLast: idx == builderState.fields.length - 1,
                  onUpdated: (updated) {
                    ref.read(formBuilderNotifierProvider.notifier).updateField(idx, updated);
                  },
                  onDeleted: () {
                    ref.read(formBuilderNotifierProvider.notifier).removeField(idx);
                  },
                  onMoveUp: () {
                    ref.read(formBuilderNotifierProvider.notifier).reorderField(idx, idx - 1);
                  },
                  onMoveDown: () {
                    ref.read(formBuilderNotifierProvider.notifier).reorderField(idx, idx + 2);
                  },
                );
              }),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
