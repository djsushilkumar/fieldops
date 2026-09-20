import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class RoleBadge extends StatelessWidget {
  final String role;

  const RoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final cleanRole = role.toLowerCase();
    Color textColor;
    Color bgColor;
    String displayLabel;

    switch (cleanRole) {
      case 'owner':
        textColor = AppColors.roleAdmin;
        bgColor = AppColors.roleAdminBg;
        displayLabel = 'Owner';
        break;
      case 'admin':
        textColor = AppColors.roleAdmin;
        bgColor = AppColors.roleAdminBg;
        displayLabel = 'Admin';
        break;
      case 'manager':
        textColor = AppColors.roleManager;
        bgColor = AppColors.roleManagerBg;
        displayLabel = 'Manager';
        break;
      case 'employee':
      default:
        textColor = AppColors.roleEmployee;
        bgColor = AppColors.roleEmployeeBg;
        displayLabel = 'Field Employee';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        displayLabel,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
