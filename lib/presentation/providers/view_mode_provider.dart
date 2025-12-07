/// View Mode Provider for switching between List and Calendar views.
///
/// Manages the display mode preference and persists it to SharedPreferences.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// View mode enum for todo display
enum ViewMode {
  list,     // Traditional list view
  calendar, // Calendar grid view
}

/// Notifier for managing view mode with persistence
class ViewModeNotifier extends Notifier<ViewMode> {
  static const String _key = 'view_mode';

  @override
  ViewMode build() {
    _loadViewMode();
    return ViewMode.calendar; // Default view mode
  }

  /// Load saved view mode from SharedPreferences
  Future<void> _loadViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key) ?? 'calendar';
    state = value == 'calendar' ? ViewMode.calendar : ViewMode.list;
  }

  /// Set and persist the view mode
  Future<void> setViewMode(ViewMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode == ViewMode.calendar ? 'calendar' : 'list');
  }

  /// Toggle between list and calendar view
  Future<void> toggleViewMode() async {
    final newMode = state == ViewMode.list ? ViewMode.calendar : ViewMode.list;
    await setViewMode(newMode);
  }
}

/// Provider for view mode state management
final viewModeProvider = NotifierProvider<ViewModeNotifier, ViewMode>(() {
  return ViewModeNotifier();
});
