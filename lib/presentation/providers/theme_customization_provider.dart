/// Theme customization state management providers using Riverpod.
///
/// Handles customizable theme properties:
/// - Primary brand color
/// - Font size scale
///
/// Uses "Apply Theme" button approach:
/// - Pending state tracks user selections (not applied yet)
/// - Applied state is the actual theme in use
/// - User must press "Apply Theme" button to commit changes
///
/// Persists preferences to SharedPreferences for consistent experience across sessions.
/// Uses synchronous initialization pattern with pre-loaded SharedPreferences from main().
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/core/utils/app_logger.dart';
import 'package:todo_app/presentation/providers/database_provider.dart';

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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThemeCustomization &&
        other.primaryColor.value == primaryColor.value &&
        other.fontSizeScale == fontSizeScale;
  }

  @override
  int get hashCode => primaryColor.value.hashCode ^ fontSizeScale.hashCode;
}

/// State that contains both pending (preview) and applied theme customization.
class ThemeCustomizationState {
  /// The pending/preview customization (user selections not yet applied)
  final ThemeCustomization pending;

  /// The applied customization (actually in use by the app)
  final ThemeCustomization applied;

  const ThemeCustomizationState({
    required this.pending,
    required this.applied,
  });

  /// Check if there are unsaved changes
  bool get hasUnsavedChanges => pending != applied;

  /// Create initial state with same values for both
  factory ThemeCustomizationState.initial(ThemeCustomization customization) {
    return ThemeCustomizationState(
      pending: customization,
      applied: customization,
    );
  }

  /// Create a copy with optional overrides
  ThemeCustomizationState copyWith({
    ThemeCustomization? pending,
    ThemeCustomization? applied,
  }) {
    return ThemeCustomizationState(
      pending: pending ?? this.pending,
      applied: applied ?? this.applied,
    );
  }
}

/// Notifier class that manages theme customization state.
///
/// Uses "Apply Theme" button approach:
/// - setPendingColor/setPendingFontScale: Update preview (not applied yet)
/// - applyTheme: Commit pending changes to applied state and save
/// - discardChanges: Reset pending to match applied
///
/// SharedPreferences is injected via sharedPreferencesProvider (loaded in main()).
class ThemeCustomizationNotifier extends Notifier<ThemeCustomizationState> {
  static const String _customizationKey = 'theme_customization';

  /// Get SharedPreferences synchronously from provider
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  ThemeCustomizationState build() {
    logger.d('🎨 ThemeCustomizationNotifier.build() called - SYNCHRONOUS LOAD');

    // Load synchronously from pre-loaded SharedPreferences
    final customization = _loadFromPrefs();
    logger.d('🎨 Loaded customization: color=${customization.primaryColor}, scale=${customization.fontSizeScale}');

    // Both pending and applied start with the same saved values
    return ThemeCustomizationState.initial(customization);
  }

  /// Load customization synchronously from SharedPreferences
  ThemeCustomization _loadFromPrefs() {
    try {
      final json = _prefs.getString(_customizationKey);
      logger.d('🎨 Retrieved from SharedPreferences: $json');

      if (json != null && json.isNotEmpty) {
        // Simple parsing: "colorValue|fontSizeScale"
        final parts = json.split('|');
        if (parts.length == 2) {
          final colorValue = int.tryParse(parts[0]);
          final fontScale = double.tryParse(parts[1]);
          logger.d('🎨 Parsed values - colorValue: $colorValue, fontScale: $fontScale');

          if (colorValue != null && fontScale != null) {
            return ThemeCustomization(
              primaryColor: Color(colorValue),
              fontSizeScale: fontScale.clamp(0.8, 1.5),
            );
          }
        }
      }
      logger.d('ℹ️ No saved customization found, using defaults');
    } catch (e, st) {
      logger.e('❌ Error loading theme customization', error: e, stackTrace: st);
    }

    return ThemeCustomization.defaults;
  }

  /// Save customization to SharedPreferences
  void _saveToPrefs(ThemeCustomization customization) {
    try {
      final json = '${customization.primaryColor.value}|${customization.fontSizeScale}';
      logger.d('🎨 Saving to SharedPreferences: $json');
      _prefs.setString(_customizationKey, json);
      logger.d('✅ Successfully saved theme customization');
    } catch (e, st) {
      logger.e('❌ Error saving theme customization', error: e, stackTrace: st);
    }
  }

  /// Update pending primary color (preview only, not applied yet)
  void setPendingColor(Color color) {
    logger.d('🎨 setPendingColor called with color: $color (value: ${color.value})');
    final newPending = state.pending.copyWith(primaryColor: color);
    state = state.copyWith(pending: newPending);
    logger.d('🎨 Pending updated - hasUnsavedChanges: ${state.hasUnsavedChanges}');
  }

  /// Update pending font size scale (preview only, not applied yet)
  void setPendingFontScale(double scale) {
    final clampedScale = scale.clamp(0.8, 1.5);
    logger.d('🎨 setPendingFontScale called with scale: $scale (clamped: $clampedScale)');
    final newPending = state.pending.copyWith(fontSizeScale: clampedScale);
    state = state.copyWith(pending: newPending);
    logger.d('🎨 Pending updated - hasUnsavedChanges: ${state.hasUnsavedChanges}');
  }

  /// Apply pending changes to the actual theme and save to SharedPreferences
  void applyTheme() {
    logger.d('🎨 applyTheme called - committing pending changes');
    logger.d('🎨 Pending: color=${state.pending.primaryColor.value}, scale=${state.pending.fontSizeScale}');

    // Commit pending to applied
    state = state.copyWith(applied: state.pending);

    // Save to SharedPreferences
    _saveToPrefs(state.applied);

    logger.d('✅ Theme applied and saved - hasUnsavedChanges: ${state.hasUnsavedChanges}');
  }

  /// Discard pending changes and reset to applied state
  void discardChanges() {
    logger.d('🎨 discardChanges called - reverting pending to applied');
    state = state.copyWith(pending: state.applied);
    logger.d('✅ Changes discarded - hasUnsavedChanges: ${state.hasUnsavedChanges}');
  }

  /// Reset both pending and applied to defaults
  void resetToDefaults() {
    logger.d('🎨 resetToDefaults called');
    state = ThemeCustomizationState.initial(ThemeCustomization.defaults);
    _saveToPrefs(ThemeCustomization.defaults);
    logger.d('✅ State reset to defaults and saved - hasUnsavedChanges: ${state.hasUnsavedChanges}');
  }

  /// Reset only pending to defaults (for preview/undo)
  void resetPendingToDefaults() {
    logger.d('🎨 resetPendingToDefaults called');
    state = state.copyWith(pending: ThemeCustomization.defaults);
    logger.d('✅ Pending reset to defaults - hasUnsavedChanges: ${state.hasUnsavedChanges}');
  }

  // Legacy methods for backward compatibility (now update pending state)
  void setPrimaryColor(Color color) => setPendingColor(color);
  void setFontSizeScale(double scale) => setPendingFontScale(scale);
}

/// Provides the theme customization notifier.
///
/// Use `ref.watch(themeCustomizationProvider)` to watch the full state,
/// or `ref.read(themeCustomizationProvider.notifier).applyTheme()` to apply changes.
final themeCustomizationProvider = NotifierProvider<ThemeCustomizationNotifier, ThemeCustomizationState>(() {
  return ThemeCustomizationNotifier();
});

/// Convenience provider for applied primary color (actually used by the app).
final primaryColorProvider = Provider<Color>((ref) {
  final state = ref.watch(themeCustomizationProvider);
  return state.applied.primaryColor;
});

/// Convenience provider for applied font size scale (actually used by the app).
final fontSizeScaleProvider = Provider<double>((ref) {
  final state = ref.watch(themeCustomizationProvider);
  return state.applied.fontSizeScale;
});

/// Convenience provider for pending (preview) primary color.
final pendingColorProvider = Provider<Color>((ref) {
  final state = ref.watch(themeCustomizationProvider);
  return state.pending.primaryColor;
});

/// Convenience provider for pending (preview) font size scale.
final pendingFontScaleProvider = Provider<double>((ref) {
  final state = ref.watch(themeCustomizationProvider);
  return state.pending.fontSizeScale;
});

/// Convenience provider to check if there are unsaved changes.
final hasUnsavedThemeChangesProvider = Provider<bool>((ref) {
  final state = ref.watch(themeCustomizationProvider);
  return state.hasUnsavedChanges;
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
