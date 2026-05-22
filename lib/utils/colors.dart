import 'package:flutter/material.dart';

class AppColors {
  // Common Colors
  static const Color accentPurple = Color(0xFF7F3DFF);
  static const Color accentPink = Color(0xFFFF3D9A);
  static const Color callGreen = Color(0xFF22C55E);
  static const Color hangupRed = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color starGold = Color(0xFFFFB000);

  // Dark Theme Colors
  static const Color darkBg = Color(0xFF0F0F13);
  static const Color darkSurface = Color(0xFF181820);
  static const Color darkSurfaceCard = Color(0xFF22222E);
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xFF9EA1B0);
  static const Color darkBorder = Color(0xFF2C2C3E);

  // Light Theme Colors
  static const Color lightBg = Color(0xFFF8F9FD);
  static const Color lightSurface = Colors.white;
  static const Color lightSurfaceCard = Color(0xFFF1F3FA);
  static const Color lightTextPrimary = Color(0xFF1E293B);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // Dynamic colors based on brightness
  static Color background(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkBg : lightBg;
  }

  static Color surface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkSurface : lightSurface;
  }

  static Color surfaceCard(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkSurfaceCard : lightSurfaceCard;
  }

  static Color textPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkTextPrimary : lightTextPrimary;
  }

  static Color textSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkTextSecondary : lightTextSecondary;
  }

  static Color border(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkBorder : lightBorder;
  }

  // Soft random pastel background colors for Avatars
  static const List<Color> avatarColors = [
    Color(0xFFEC4899), // Pink
    Color(0xFF3B82F6), // Blue
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFF8B5CF6), // Violet
    Color(0xFFEF4444), // Red
    Color(0xFF06B6D4), // Cyan
    Color(0xFF84CC16), // Lime
  ];

  static Color getAvatarColor(String name) {
    if (name.isEmpty) return avatarColors[0];
    int hash = name.codeUnits.fold(0, (prev, elem) => prev + elem);
    return avatarColors[hash % avatarColors.length];
  }
}
