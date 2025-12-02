import 'package:flutter/material.dart';

/// Application color palette and theme colors.
///
/// This class provides a centralized location for all colors used in the app,
/// supporting both dark and light themes. Colors are organized into categories:
/// - Theme-specific background/surface colors
/// - Accent/brand colors
/// - Text colors
/// - Gradients
///
/// Use the helper methods (e.g., [getBackground], [getText]) for theme-aware
/// color selection instead of directly referencing dark/light variants.
///
/// For dynamic primary color (theme customization), use [primary] getter
/// instead of [primaryBlue] constant.
class AppColors {
  // ============================================
  // Dynamic Theme Color (Set from ThemeCustomization)
  // ============================================

  /// Current dynamic primary color (set by theme customization)
  static Color _dynamicPrimary = const Color(0xFF2B8DEE);

  /// Current dynamic font scale (set by theme customization)
  static double _dynamicFontScale = 1.0;

  /// Set the dynamic primary color (called when theme is applied)
  static void setDynamicPrimary(Color color) {
    _dynamicPrimary = color;
  }

  /// Set the dynamic font scale (called when theme is applied)
  static void setDynamicFontScale(double scale) {
    _dynamicFontScale = scale;
  }

  /// Get current dynamic primary color
  static Color get primary => _dynamicPrimary;

  /// Get current dynamic font scale
  static double get fontScale => _dynamicFontScale;

  /// Get scaled font size (base size * fontScale)
  static double scaledFontSize(double baseSize) => baseSize * _dynamicFontScale;
  // ============================================
  // Dark Theme Colors
  // ============================================

  /// Main background color for dark theme.
  static const Color darkBackground = Color(0xFF111A22);

  /// Card/surface color for dark theme.
  static const Color darkCard = Color(0xFF192633);

  /// Input field background color for dark theme.
  static const Color darkInput = Color(0xFF233648);

  /// Border color for dark theme.
  static const Color darkBorder = Color(0xFF324D67);

  // ============================================
  // Light Theme Colors
  // ============================================

  /// Main background color for light theme.
  static const Color lightBackground = Color(0xFFF5F7FA);

  /// Card/surface color for light theme.
  static const Color lightCard = Color(0xFFF8FAFB);

  /// Input field background color for light theme.
  static const Color lightInput = Color(0xFFF0F4F8);

  /// Border color for light theme.
  static const Color lightBorder = Color(0xFFE1E8ED);

  // ============================================
  // Accent Colors (Theme-Independent)
  // ============================================

  /// Primary brand blue color.
  static const Color primaryBlue = Color(0xFF2B8DEE);

  /// Darker variant of primary blue for pressed states.
  static const Color primaryBlueDark = Color(0xFF1E6BB8);

  /// Accent orange color for highlights and warnings.
  static const Color accentOrange = Color(0xFFFF9933);

  /// Success indicator green color.
  static const Color successGreen = Color(0xFF10B981);

  /// Danger/error indicator red color.
  static const Color dangerRed = Color(0xFFEF4444);

  // ============================================
  // Text Colors
  // ============================================

  /// White text color (primarily for dark theme).
  static const Color textWhite = Color(0xFFFFFFFF);

  /// Gray text color for secondary content in dark theme.
  static const Color textGray = Color(0xFF92ADC9);

  /// Dark text color for primary content in light theme.
  ///
  /// Uses a much darker shade for better readability.
  static const Color textDark = Color(0xFF0F1419);

  /// Darker gray text for secondary content in light theme.
  static const Color textGrayDark = Color(0xFF1A202C);

  // ============================================
  // Gradients
  // ============================================

  /// Primary brand gradient (blue tones).
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, primaryBlueDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Header gradient for dark theme.
  static const LinearGradient darkHeaderGradient = LinearGradient(
    colors: [darkCard, darkBackground],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Header gradient for light theme.
  static const LinearGradient lightHeaderGradient = LinearGradient(
    colors: [lightCard, lightBackground],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Progress indicator gradient for light theme.
  static const LinearGradient lightProgressGradient = LinearGradient(
    colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============================================
  // Theme-Aware Helper Methods
  // ============================================

  /// Returns the appropriate background color based on theme.
  static Color getBackground(bool isDark) => isDark ? darkBackground : lightBackground;

  /// Returns the appropriate card/surface color based on theme.
  static Color getCard(bool isDark) => isDark ? darkCard : lightCard;

  /// Returns the appropriate input field background color based on theme.
  static Color getInput(bool isDark) => isDark ? darkInput : lightInput;

  /// Returns the appropriate border color based on theme.
  static Color getBorder(bool isDark) => isDark ? darkBorder : lightBorder;

  /// Returns the appropriate primary text color based on theme.
  static Color getText(bool isDark) => isDark ? textWhite : textDark;

  /// Returns the appropriate secondary text color based on theme.
  static Color getTextSecondary(bool isDark) => isDark ? textGray : textGrayDark;

  /// Returns the appropriate header gradient based on theme.
  static LinearGradient getHeaderGradient(bool isDark) => isDark ? darkHeaderGradient : lightHeaderGradient;

  /// Returns the appropriate progress indicator gradient based on theme.
  static LinearGradient getProgressGradient(bool isDark) => isDark ? primaryGradient : lightProgressGradient;
}
