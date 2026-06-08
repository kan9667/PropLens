import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Colors.blue;
  static const Color primaryLight = Color(0xFFE3F2FD);
  static const Color success = Colors.green;
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color textSecondary = Colors.grey;
  static const Color textPrimary = Colors.black;
  static const Color textPrimaryDark = Colors.white;
  static const Color warning = Colors.amber;
  static const Color error = Colors.red;
  static const Color divider = Color(0xFFE2E8F0);
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
        color: Colors.black.withAlpha(12),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
