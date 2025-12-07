/// System Tray Manager for Windows Desktop Widget
///
/// Handles system tray icon and context menu for the calendar widget:
/// - Show/hide widget toggle
/// - Settings access
/// - Exit application
library;

import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/// Manages the system tray icon and menu for Windows widget
class TrayManager with TrayListener {
  bool _isInitialized = false;

  /// Initialize the system tray
  Future<void> init() async {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
      debugPrint('⚠️ Tray: Not a desktop platform, skipping tray init');
      return;
    }

    if (_isInitialized) {
      debugPrint('⚠️ Tray: Already initialized');
      return;
    }

    try {
      debugPrint('🔧 Tray: Starting initialization...');

      // Add listener
      trayManager.addListener(this);
      debugPrint('✅ Tray: Listener added');

      // Initialize system tray with icon
      // Try multiple icon paths for robustness
      String iconPath = Platform.isWindows
          ? 'assets/icon/app_icon.ico'
          : 'assets/icon/app_icon.png';

      debugPrint('🔧 Tray: Setting icon from: $iconPath');

      try {
        await trayManager.setIcon(iconPath);
        debugPrint('✅ Tray: Icon set successfully');
      } catch (iconError) {
        debugPrint('⚠️ Tray: Failed to set icon from $iconPath: $iconError');
        // Try fallback - use executable directory
        try {
          final exePath = Platform.resolvedExecutable;
          final exeDir = exePath.substring(0, exePath.lastIndexOf(Platform.pathSeparator));
          final fallbackPath = '$exeDir${Platform.pathSeparator}data${Platform.pathSeparator}flutter_assets${Platform.pathSeparator}assets${Platform.pathSeparator}icon${Platform.pathSeparator}app_icon.ico';
          debugPrint('🔧 Tray: Trying fallback icon: $fallbackPath');
          await trayManager.setIcon(fallbackPath);
          debugPrint('✅ Tray: Fallback icon set');
        } catch (fallbackError) {
          debugPrint('❌ Tray: Fallback icon also failed: $fallbackError');
        }
      }

      await trayManager.setToolTip('DoDo Todo Calendar Widget');
      debugPrint('✅ Tray: Tooltip set');

      // Build context menu
      Menu menu = Menu(
        items: [
          MenuItem(
            key: 'show_widget',
            label: tr('show_widget'),
          ),
          MenuItem(
            key: 'hide_widget',
            label: tr('hide_widget'),
          ),
          MenuItem.separator(),
          MenuItem(
            key: 'toggle_always_on_top',
            label: tr('always_on_top'),
          ),
          MenuItem.separator(),
          MenuItem(
            key: 'exit_app',
            label: tr('exit'),
          ),
        ],
      );

      await trayManager.setContextMenu(menu);
      debugPrint('✅ Tray: Context menu set');

      _isInitialized = true;
      debugPrint('✅ Tray: Initialization complete');
    } catch (e, stackTrace) {
      debugPrint('❌ Tray: Failed to initialize system tray: $e');
      debugPrint('❌ Tray: Stack trace: $stackTrace');
    }
  }

  @override
  void onTrayIconMouseDown() {
    _toggleWidget();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show_widget':
        _showWidget();
        break;
      case 'hide_widget':
        _hideWidget();
        break;
      case 'toggle_always_on_top':
        _toggleAlwaysOnTop();
        break;
      case 'exit_app':
        _exitApp();
        break;
    }
  }

  Future<void> _showWidget() async {
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _hideWidget() async {
    await windowManager.hide();
  }

  Future<void> _toggleWidget() async {
    final isVisible = await windowManager.isVisible();
    if (isVisible) {
      await _hideWidget();
    } else {
      await _showWidget();
    }
  }

  Future<void> _toggleAlwaysOnTop() async {
    final isAlwaysOnTop = await windowManager.isAlwaysOnTop();
    await windowManager.setAlwaysOnTop(!isAlwaysOnTop);
  }

  Future<void> _exitApp() async {
    await destroy();
    exit(0);
  }

  /// Update tray tooltip
  Future<void> updateTooltip(String tooltip) async {
    if (!_isInitialized) return;
    await trayManager.setToolTip(tooltip);
  }

  /// Destroy the system tray
  Future<void> destroy() async {
    if (!_isInitialized) return;
    trayManager.removeListener(this);
    await trayManager.destroy();
    _isInitialized = false;
  }
}
