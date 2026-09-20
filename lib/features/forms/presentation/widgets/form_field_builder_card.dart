import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/form_field_definition.dart';
import '../../domain/entities/form_field_type.dart';

class FormFieldBuilderCard extends StatefulWidget {
  final int index;
  final FormFieldDefinition field;
  final bool isFirst;
  final bool isLast;
  final ValueChanged<FormFieldDefinition> onUpdated;
  final VoidCallback onDeleted;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  const FormFieldBuilderCard({
    super.key,
    required this.index,
    required this.field,
    required this.isFirst,
    required this.isLast,
    required this.onUpdated,
    required this.onDeleted,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  @override
  State<FormFieldBuilderCard> createState() => _FormFieldBuilderCardState();
}

class _FormFieldBuilderCardState extends State<FormFieldBuilderCard> {
  late TextEditingController _labelController;
  late TextEditingController _placeholderController;
  final TextEditingController _optionInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.field.label);
    _placeholderController = TextEditingController(text: widget.field.placeholder ?? '');
  }

  @override
  void didUpdateWidget(covariant FormFieldBuilderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.field.label != widget.field.label && _labelController.text != widget.field.label) {
      _labelController.text = widget.field.label;
    }
    if (oldWidget.field.placeholder != widget.field.placeholder && _placeholderController.text != (widget.field.placeholder ?? '')) {
      _placeholderController.text = widget.field.placeholder ?? '';
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _placeholderController.dispose();
    _optionInputController.dispose();
    super.dispose();
  }

  void _addOption() {
    final text = _optionInputController.text.trim();
    if (text.isEmpty) return;
    if (widget.field.options.contains(text)) return;
    final updatedOptions = [...widget.field.options, text];
    widget.onUpdated(widget.field.copyWith(options: updatedOptions));
    _optionInputController.clear();
  }

  void _removeOption(String opt) {
    final updatedOptions = widget.field.options.where((o) => o != opt).toList();
    widget.onUpdated(widget.field.copyWith(options: updatedOptions));
  }

  @override
  Widget build(BuildContext context) {
    final field = widget.field;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
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
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(field.type.icon, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        '#${widget.index + 1} ${field.type.label}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.arrow_upward, size: 18),
                  tooltip: 'Move Up',
                  visualDensity: VisualDensity.compact,
                  onPressed: widget.isFirst ? null : widget.onMoveUp,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward, size: 18),
                  tooltip: 'Move Down',
                  visualDensity: VisualDensity.compact,
                  onPressed: widget.isLast ? null : widget.onMoveDown,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                  tooltip: 'Remove Field',
                  visualDensity: VisualDensity.compact,
                  onPressed: widget.onDeleted,
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label input
                const Text(
                  'Field Label',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _labelController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Serial Number, Inspection Result...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (val) {
                    widget.onUpdated(field.copyWith(label: val));
                  },
                ),
                const SizedBox(height: 14),

                // Field Type & Required Toggle Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Field type dropdown
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Field Type',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<FormFieldType>(
                            value: field.type,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            items: FormFieldType.values.map((t) {
                              return DropdownMenuItem(
                                value: t,
                                child: Row(
                                  children: [
                                    Icon(t.icon, size: 16, color: AppColors.textSecondary),
                                    const SizedBox(width: 8),
                                    Text(t.label, style: const TextStyle(fontSize: 13)),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (newType) {
                              if (newType != null) {
                                widget.onUpdated(field.copyWith(type: newType));
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Required Switch
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Required',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 6),
                          SwitchListTile(
                            value: field.required,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              field.required ? 'Mandatory' : 'Optional',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: field.required ? AppColors.error : AppColors.textSecondary,
                              ),
                            ),
                            activeColor: AppColors.error,
                            onChanged: (val) {
                              widget.onUpdated(field.copyWith(required: val));
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Dropdown Options Editor (if Select type)
                if (field.type == FormFieldType.select) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Dropdown Options',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: field.options.map((opt) {
                      return Chip(
                        label: Text(opt, style: const TextStyle(fontSize: 12)),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () => _removeOption(opt),
                        backgroundColor: const Color(0xFFF1F3F4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _optionInputController,
                          decoration: InputDecoration(
                            hintText: 'Add option...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onSubmitted: (_) => _addOption(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        icon: const Icon(Icons.add, size: 18),
                        onPressed: _addOption,
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
