import 'package:flutter/material.dart';

class AppColors {
  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF111A22);
  static const Color darkCard = Color(0xFF192633);
  static const Color darkInput = Color(0xFF233648);
  static const Color darkBorder = Color(0xFF324D67);

  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightInput = Color(0xFFF0F4F8);
  static const Color lightBorder = Color(0xFFE1E8ED);

  // Accent Colors
  static const Color primaryBlue = Color(0xFF2B8DEE);
  static const Color primaryBlueDark = Color(0xFF1E6BB8);
  static const Color accentOrange = Color(0xFFFF9933);

  // Text Colors
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGray = Color(0xFF92ADC9);
  static const Color textDark = Color(0xFF1A202C);
  static const Color textGrayDark = Color(0xFF4A5568);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, primaryBlueDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkHeaderGradient = LinearGradient(
    colors: [darkCard, darkBackground],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient lightHeaderGradient = LinearGradient(
    colors: [lightCard, lightBackground],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Helper methods for theme-aware colors
  static Color getBackground(bool isDark) => isDark ? darkBackground : lightBackground;
  static Color getCard(bool isDark) => isDark ? darkCard : lightCard;
  static Color getInput(bool isDark) => isDark ? darkInput : lightInput;
  static Color getBorder(bool isDark) => isDark ? darkBorder : lightBorder;
  static Color getText(bool isDark) => isDark ? textWhite : textDark;
  static Color getTextSecondary(bool isDark) => isDark ? textGray : textGrayDark;
  static LinearGradient getHeaderGradient(bool isDark) => isDark ? darkHeaderGradient : lightHeaderGradient;
}
