import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Theme Mode State
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

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});

// Is Dark Mode Provider (for UI convenience)
final isDarkModeProvider = Provider<bool>((ref) {
  final themeMode = ref.watch(themeProvider);
  return themeMode == ThemeMode.dark;
});
