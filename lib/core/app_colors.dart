import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF7F9FC);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE8ECF0);
  static const Color primary = Color(0xFF1A6B4A);      // deep emerald
  static const Color primaryLight = Color(0xFFEBF5F0);
  static const Color accent = Color(0xFF00C37A);       // electric mint
  static const Color accentLight = Color(0xFFE6FBF3);
  static const Color secondary = Color(0xFFF5A623);    // amber
  static const Color textPrimary = Color(0xFF0D1117);
  static const Color textSecond = Color(0xFF5A6273);
  static const Color textHint = Color(0xFF9EA8B3);
  static const Color error = Color(0xFFFF3B30);
  static const Color white = Color(0xFFFFFFFF);

  static const BoxShadow cardShadow = BoxShadow(
    color: Color(0x121A6B4A),
    blurRadius: 24,
    offset: Offset(0, 8),
  );

  static const BoxShadow softShadow = BoxShadow(
    color: Color(0x10000000),
    blurRadius: 12,
    offset: Offset(0, 4),
  );

  static const BoxShadow searchGlow = BoxShadow(
    color: Color(0x3000C37A),
    blurRadius: 20,
    spreadRadius: 2,
  );

  static const LinearGradient heroBg = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF0FAF5), Color(0xFFFFFFFF), Color(0xFFFFF8EE)],
  );

  static const LinearGradient primaryGrad = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00C37A), Color(0xFF1A6B4A)],
  );

  static const LinearGradient badgeGrad = LinearGradient(
    colors: [Color(0xFFF5A623), Color(0xFFE8920F)],
  );

  static const LinearGradient priceGradient = LinearGradient(
    colors: [Color(0xFF00C37A), Color(0xFF1A6B4A)],
  );
}
