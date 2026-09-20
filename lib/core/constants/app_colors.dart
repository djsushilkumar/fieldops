import 'package:flutter/material.dart';

class AppColors {
  // Brand colors
  static const Color primary = Color(0xFF0F52BA); // Sapphire Blue
  static const Color primaryDark = Color(0xFF0A387E);
  static const Color primaryLight = Color(0xFFE8F0FE);
  
  static const Color secondary = Color(0xFF00A86B); // Jade Green (success & check-in)
  static const Color secondaryLight = Color(0xFFE6F7F0);
  
  static const Color success = secondary;
  static const Color successLight = secondaryLight;

  static const Color accent = Color(0xFFFF7A00); // Amber / Warning
  static const Color warning = accent;
  static const Color warningLight = Color(0xFFFEF7E0);

  static const Color error = Color(0xFFD93025);
  static const Color errorLight = Color(0xFFFDE8E8);

  static const Color info = Color(0xFF1A73E8);
  static const Color infoLight = Color(0xFFE8F0FE);
  
  // Neutrals
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF202124);
  static const Color textSecondary = Color(0xFF5F6368);
  static const Color textTertiary = Color(0xFF80868B);
  static const Color border = Color(0xFFDADCE0);
  static const Color divider = Color(0xFFE8EAED);
  
  // Role specific colors
  static const Color roleAdmin = Color(0xFF7B1FA2); // Purple
  static const Color roleAdminBg = Color(0xFFF3E5F5);
  static const Color roleManager = Color(0xFF0288D1); // Light Blue
  static const Color roleManagerBg = Color(0xFFE1F5FE);
  static const Color roleEmployee = Color(0xFF2E7D32); // Forest Green
  static const Color roleEmployeeBg = Color(0xFFE8F5E9);
}
