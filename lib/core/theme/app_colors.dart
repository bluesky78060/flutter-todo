import 'package:flutter/material.dart';

class AppColors {
  // Dark Theme Colors (from HTML design)
  static const Color darkBackground = Color(0xFF111A22);
  static const Color darkCard = Color(0xFF192633);
  static const Color darkInput = Color(0xFF233648);
  static const Color darkBorder = Color(0xFF324D67);

  // Accent Colors
  static const Color primaryBlue = Color(0xFF2B8DEE);
  static const Color primaryBlueDark = Color(0xFF1E6BB8);

  // Text Colors
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGray = Color(0xFF92ADC9);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, primaryBlueDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [darkCard, darkBackground],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
