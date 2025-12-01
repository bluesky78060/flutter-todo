/// Theme state management providers using Riverpod.
///
/// Handles app-wide theme mode (light/dark) with persistence
/// to SharedPreferences for consistent user experience across sessions.
///
/// Providers:
/// - [themeProvider]: The main theme notifier for theme mode
/// - [isDarkModeProvider]: Convenience provider for dark mode checks
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Notifier class that manages theme mode state.
///
/// Persists theme preference to SharedPreferences and loads it
/// on app startup. Defaults to light mode if no preference is stored.
class ThemeNotifier extends Notifier<ThemeMode> {
  static const String _themeKey = 'theme_mode';

  @override
  ThemeMode build() {
    _loadTheme();
    return ThemeMode.light; // Default theme
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? 1; // Default: light (index 1)
    state = ThemeMode.values[themeIndex];
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }

  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setTheme(newMode);
  }
}

/// Provides the theme notifier for controlling app theme mode.
///
/// Use `ref.read(themeProvider.notifier).toggleTheme()` to toggle,
/// or `ref.read(themeProvider.notifier).setTheme(ThemeMode.dark)` for specific mode.
final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});

/// Convenience provider that returns true if dark mode is active.
///
/// Useful for conditional styling in widgets:
/// ```dart
/// final isDark = ref.watch(isDarkModeProvider);
/// ```
final isDarkModeProvider = Provider<bool>((ref) {
  final themeMode = ref.watch(themeProvider);
  return themeMode == ThemeMode.dark;
});
