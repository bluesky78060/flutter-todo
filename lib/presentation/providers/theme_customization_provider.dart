/// Theme customization state management providers using Riverpod.
///
/// Handles customizable theme properties:
/// - Primary brand color
/// - Font size scale
///
/// Persists preferences to SharedPreferences for consistent experience across sessions.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/core/utils/app_logger.dart';

/// Model class for theme customization settings.
class ThemeCustomization {
  final Color primaryColor;
  final double fontSizeScale; // 0.8 (80%) to 1.5 (150%), default 1.0

  const ThemeCustomization({
    required this.primaryColor,
    required this.fontSizeScale,
  });

  /// Default theme customization settings
  static const ThemeCustomization defaults = ThemeCustomization(
    primaryColor: Color(0xFF2B8DEE), // Default primary blue
    fontSizeScale: 1.0,
  );

  /// Create a copy with optional overrides
  ThemeCustomization copyWith({
    Color? primaryColor,
    double? fontSizeScale,
  }) {
    return ThemeCustomization(
      primaryColor: primaryColor ?? this.primaryColor,
      fontSizeScale: fontSizeScale ?? this.fontSizeScale,
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() => {
    'primaryColor': primaryColor.value,
    'fontSizeScale': fontSizeScale,
  };

  /// Convert from JSON
  factory ThemeCustomization.fromJson(Map<String, dynamic> json) {
    return ThemeCustomization(
      primaryColor: Color(json['primaryColor'] as int? ?? defaults.primaryColor.value),
      fontSizeScale: (json['fontSizeScale'] as num?)?.toDouble() ?? defaults.fontSizeScale,
    );
  }
}

/// Notifier class that manages theme customization state.
///
/// Persists customization preferences to SharedPreferences and loads on app startup.
/// Simplified to use synchronous loading for reliability.
class ThemeCustomizationNotifier extends Notifier<ThemeCustomization> {
  static const String _customizationKey = 'theme_customization';

  @override
  ThemeCustomization build() {
    logger.d('🎨 ThemeCustomizationNotifier.build() called');

    // Start async loading in the background
    _loadAndApplyCustomizationAsync();

    // Return defaults immediately - will be updated when async load completes
    return ThemeCustomization.defaults;
  }

  /// Load customization asynchronously without blocking build
  void _loadAndApplyCustomizationAsync() {
    logger.d('🎨 Starting async load of theme customization from SharedPreferences...');

    SharedPreferences.getInstance().then((prefs) {
      try {
        final json = prefs.getString(_customizationKey);
        logger.d('🎨 Retrieved from SharedPreferences: $json');

        if (json != null && json.isNotEmpty) {
          // Simple parsing: "colorValue|fontSizeScale"
          final parts = json.split('|');
          if (parts.length == 2) {
            final colorValue = int.tryParse(parts[0]);
            final fontScale = double.tryParse(parts[1]);
            logger.d('🎨 Parsed values - colorValue: $colorValue, fontScale: $fontScale');

            if (colorValue != null && fontScale != null) {
              final newCustomization = ThemeCustomization(
                primaryColor: Color(colorValue),
                fontSizeScale: fontScale.clamp(0.8, 1.5),
              );
              logger.d('🎨 Loaded customization: color=${newCustomization.primaryColor}, scale=${newCustomization.fontSizeScale}');
              logger.d('🎨 Updating state...');
              state = newCustomization;
              logger.d('✅ Theme customization loaded and applied successfully');
            }
          }
        } else {
          logger.d('ℹ️ No saved customization found, using defaults');
        }
      } catch (e, st) {
        logger.e('❌ Error loading theme customization', error: e, stackTrace: st);
      }
    }).catchError((error, stackTrace) {
      logger.e('❌ Error getting SharedPreferences instance', error: error, stackTrace: stackTrace);
    });
  }

  /// Save customization to SharedPreferences
  Future<void> _saveCustomization(ThemeCustomization customization) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = '${customization.primaryColor.value}|${customization.fontSizeScale}';
      logger.d('🎨 Saving to SharedPreferences: $json');
      await prefs.setString(_customizationKey, json);
      logger.d('✅ Successfully saved theme customization');
    } catch (e, st) {
      logger.e('❌ Error saving theme customization', error: e, stackTrace: st);
    }
  }

  /// Update primary color
  Future<void> setPrimaryColor(Color color) async {
    logger.d('🎨 setPrimaryColor called with color: $color');
    final newCustomization = state.copyWith(primaryColor: color);
    logger.d('🎨 Updating state to new customization: $newCustomization');
    state = newCustomization;
    logger.d('✅ State updated, now saving to SharedPreferences');
    await _saveCustomization(newCustomization);
  }

  /// Update font size scale
  Future<void> setFontSizeScale(double scale) async {
    final clampedScale = scale.clamp(0.8, 1.5);
    logger.d('🎨 setFontSizeScale called with scale: $scale (clamped: $clampedScale)');
    final newCustomization = state.copyWith(fontSizeScale: clampedScale);
    logger.d('🎨 Updating state to new customization: $newCustomization');
    state = newCustomization;
    logger.d('✅ State updated, now saving to SharedPreferences');
    await _saveCustomization(newCustomization);
  }

  /// Reset to default customization
  Future<void> resetToDefaults() async {
    logger.d('🎨 resetToDefaults called');
    state = ThemeCustomization.defaults;
    logger.d('✅ State reset to defaults');
    await _saveCustomization(ThemeCustomization.defaults);
  }
}

/// Provides the theme customization notifier.
///
/// Use `ref.watch(themeCustomizationProvider)` to watch changes,
/// or `ref.read(themeCustomizationProvider.notifier).setPrimaryColor(color)` to update.
final themeCustomizationProvider = NotifierProvider<ThemeCustomizationNotifier, ThemeCustomization>(() {
  return ThemeCustomizationNotifier();
});

/// Convenience provider for primary color only.
final primaryColorProvider = Provider<Color>((ref) {
  final customization = ref.watch(themeCustomizationProvider);
  return customization.primaryColor;
});

/// Convenience provider for font size scale only.
final fontSizeScaleProvider = Provider<double>((ref) {
  final customization = ref.watch(themeCustomizationProvider);
  return customization.fontSizeScale;
});

/// Predefined color palette for theme customization.
class ThemeColorPalette {
  static const List<Color> colors = [
    Color(0xFF2B8DEE), // Blue (default)
    Color(0xFF00D9A3), // Teal
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Red
    Color(0xFF14B8A6), // Cyan
    Color(0xFF6366F1), // Indigo
  ];

  static const Map<String, Color> namedColors = {
    'blue': Color(0xFF2B8DEE),
    'teal': Color(0xFF00D9A3),
    'purple': Color(0xFF8B5CF6),
    'pink': Color(0xFFEC4899),
    'amber': Color(0xFFF59E0B),
    'red': Color(0xFFEF4444),
    'cyan': Color(0xFF14B8A6),
    'indigo': Color(0xFF6366F1),
  };
}
