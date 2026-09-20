import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/form_field_definition.dart';
import '../../domain/entities/form_field_type.dart';

class FormFieldRenderer extends StatelessWidget {
  final FormFieldDefinition field;
  final dynamic value;
  final String? errorText;
  final ValueChanged<dynamic> onChanged;
  final bool readOnly;

  const FormFieldRenderer({
    super.key,
    required this.field,
    required this.value,
    this.errorText,
    required this.onChanged,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row
          Row(
            children: [
              Text(
                field.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (field.required) ...[
                const SizedBox(width: 4),
                const Text(
                  '*',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          if (field.helpText != null && field.helpText!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              field.helpText!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 8),

          // Field type input widget
          _buildInput(context),

          // Error text
          if (errorText != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.error_outline, size: 14, color: AppColors.error),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    errorText!,
                    style: const TextStyle(fontSize: 12, color: AppColors.error),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInput(BuildContext context) {
    switch (field.type) {
      case FormFieldType.text:
        return _buildTextField();
      case FormFieldType.multiline:
        return _buildMultilineField();
      case FormFieldType.number:
        return _buildNumberField();
      case FormFieldType.date:
        return _buildDateField(context);
      case FormFieldType.select:
        return _buildSelectField(context);
      case FormFieldType.checkbox:
        return _buildCheckboxField();
    }
  }

  Widget _buildTextField() {
    return TextFormField(
      initialValue: value?.toString() ?? '',
      enabled: !readOnly,
      decoration: InputDecoration(
        hintText: field.placeholder ?? 'Enter ${field.label.toLowerCase()}',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: errorText != null ? AppColors.error : AppColors.divider,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: errorText != null ? AppColors.error : AppColors.divider,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: errorText != null ? AppColors.error : AppColors.primary,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        filled: true,
        fillColor: readOnly ? const Color(0xFFF8F9FA) : Colors.white,
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildMultilineField() {
    return TextFormField(
      initialValue: value?.toString() ?? '',
      enabled: !readOnly,
      minLines: 3,
      maxLines: 5,
      decoration: InputDecoration(
        hintText: field.placeholder ?? 'Enter detailed notes...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: errorText != null ? AppColors.error : AppColors.divider,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: errorText != null ? AppColors.error : AppColors.divider,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: errorText != null ? AppColors.error : AppColors.primary,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.all(12),
        filled: true,
        fillColor: readOnly ? const Color(0xFFF8F9FA) : Colors.white,
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildNumberField() {
    return TextFormField(
      initialValue: value != null ? value.toString() : '',
      enabled: !readOnly,
      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
      decoration: InputDecoration(
        hintText: field.placeholder ?? '0.00',
        prefixIcon: const Icon(Icons.pin, size: 18, color: AppColors.textTertiary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: errorText != null ? AppColors.error : AppColors.divider,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: errorText != null ? AppColors.error : AppColors.divider,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: errorText != null ? AppColors.error : AppColors.primary,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        filled: true,
        fillColor: readOnly ? const Color(0xFFF8F9FA) : Colors.white,
      ),
      onChanged: (val) {
        final parsed = num.tryParse(val.trim());
        onChanged(parsed ?? val.trim());
      },
    );
  }

  Widget _buildDateField(BuildContext context) {
    DateTime? selectedDate;
    if (value != null && value.toString().isNotEmpty) {
      selectedDate = DateTime.tryParse(value.toString());
    }

    final displayStr = selectedDate != null
        ? DateFormat('EEEE, MMM d, yyyy').format(selectedDate)
        : (field.placeholder ?? 'Select date');

    return InkWell(
      onTap: readOnly
          ? null
          : () async {
              final initial = selectedDate ?? DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: initial,
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );
              if (picked != null) {
                final dateStr = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                onChanged(dateStr);
              }
            },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: readOnly ? const Color(0xFFF8F9FA) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: errorText != null ? AppColors.error : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayStr,
                style: TextStyle(
                  fontSize: 14,
                  color: selectedDate != null ? AppColors.textPrimary : AppColors.textTertiary,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectField(BuildContext context) {
    final currentValue = value?.toString();
    final items = field.options.map((opt) {
      return DropdownMenuItem<String>(
        value: opt,
        child: Text(opt, style: const TextStyle(fontSize: 14)),
      );
    }).toList();

    return DropdownButtonFormField<String>(
      value: (currentValue != null && field.options.contains(currentValue)) ? currentValue : null,
      decoration: InputDecoration(
        hintText: field.placeholder ?? 'Select an option',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: errorText != null ? AppColors.error : AppColors.divider,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: errorText != null ? AppColors.error : AppColors.divider,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        filled: true,
        fillColor: readOnly ? const Color(0xFFF8F9FA) : Colors.white,
      ),
      items: items,
      onChanged: readOnly ? null : (selected) => onChanged(selected),
    );
  }

  Widget _buildCheckboxField() {
    final isChecked = value == true;

    return Container(
      decoration: BoxDecoration(
        color: isChecked ? AppColors.primaryLight.withOpacity(0.3) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: errorText != null
              ? AppColors.error
              : isChecked
                  ? AppColors.primary
                  : AppColors.divider,
        ),
      ),
      child: CheckboxListTile(
        title: Text(
          field.placeholder ?? 'Confirm / Verified',
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        ),
        value: isChecked,
        dense: true,
        activeColor: AppColors.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        controlAffinity: ListTileControlAffinity.leading,
        onChanged: readOnly ? null : (val) => onChanged(val ?? false),
      ),
    );
  }
}
