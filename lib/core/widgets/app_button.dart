import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum AppButtonVariant { primary, secondary, outline, text }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonVariant variant;
  final IconData? icon;
  final Color? customColor;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 48,
        decoration: BoxDecoration(
          color: (customColor ?? AppColors.primary).withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    switch (variant) {
      case AppButtonVariant.primary:
        return ElevatedButton(
          onPressed: onPressed,
          style: customColor != null
              ? ElevatedButton.styleFrom(backgroundColor: customColor)
              : null,
          child: _buildChild(Colors.white),
        );
      case AppButtonVariant.secondary:
        return ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: customColor ?? AppColors.secondary,
            foregroundColor: Colors.white,
          ),
          child: _buildChild(Colors.white),
        );
      case AppButtonVariant.outline:
        return OutlinedButton(
          onPressed: onPressed,
          style: customColor != null
              ? OutlinedButton.styleFrom(foregroundColor: customColor)
              : null,
          child: _buildChild(customColor ?? AppColors.primary),
        );
      case AppButtonVariant.text:
        return TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: customColor ?? AppColors.primary,
            minimumSize: const Size.fromHeight(48),
          ),
          child: _buildChild(customColor ?? AppColors.primary),
        );
    }
  }

  Widget _buildChild(Color defaultIconColor) {
    if (icon == null) {
      return Text(label, maxLines: 1, overflow: TextOverflow.ellipsis);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: defaultIconColor),
        const SizedBox(width: 8),
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
