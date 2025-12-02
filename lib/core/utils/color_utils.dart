import 'package:flutter/material.dart';
import 'package:todo_app/core/theme/app_colors.dart';

class ColorUtils {
  /// Parse a color string safely to Color object.
  /// Handles various formats:
  /// - #3B82F6
  /// - 3B82F6
  /// - 0xFF3B82F6
  /// - 0xFF#3B82F6 (malformed but handled)
  static Color parseColor(String colorString) {
    try {
      // Normalize color string: remove 0xFF prefix and ensure # is present
      String normalized = colorString
          .replaceAll('0xFF', '')
          .replaceAll('0xff', '')
          .trim();

      if (!normalized.startsWith('#')) {
        normalized = '#$normalized';
      }

      final hexString = normalized.replaceAll('#', '');
      return Color(int.parse('0xFF$hexString', radix: 16));
    } catch (e) {
      // Return default color if parsing fails
      return AppColors.primary;
    }
  }

  /// Normalize color string to #RRGGBB format.
  static String normalizeColorString(String color) {
    // Remove any 0xFF prefix and ensure # is present
    String normalized = color
        .replaceAll('0xFF', '')
        .replaceAll('0xff', '')
        .trim();

    if (!normalized.startsWith('#')) {
      normalized = '#$normalized';
    }

    return normalized.toUpperCase();
  }
}
