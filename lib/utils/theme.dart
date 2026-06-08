import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1A6B4A);      // deep emerald
  static const Color primaryLight = Color(0xFFEBF5F0);
  static const Color success = Color(0xFF00C37A);       // electric mint
  static const Color successLight = Color(0xFFE6FBF3);
  static const Color textSecondary = Color(0xFF5A6273);
  static const Color textPrimary = Color(0xFF0D1117);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color warning = Color(0xFFF5A623);       // amber
  static const Color error = Color(0xFFFF3B30);
  static const Color divider = Color(0xFFE8ECF0);
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF7F9FC);
}

class AppTextStyles {
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    color: AppColors.textSecondary,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  static const TextStyle titleMediumBold = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );
}

class AppTheme {
  static final cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF1A6B4A).withOpacity(0.08),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
