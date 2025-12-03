/// System Tray Manager for Windows Desktop Widget
///
/// Handles system tray icon and context menu for the calendar widget:
/// - Show/hide widget toggle
/// - Settings access
/// - Exit application
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/// Manages the system tray icon and menu for Windows widget
class TrayManager with TrayListener {
  bool _isInitialized = false;

  /// Initialize the system tray
  Future<void> init() async {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
      return;
    }

    if (_isInitialized) return;

    try {
      // Add listener
      trayManager.addListener(this);

      // Initialize system tray with icon
      String iconPath = Platform.isWindows
          ? 'assets/icon/app_icon.ico'
          : 'assets/icon/app_icon.png';

      await trayManager.setIcon(iconPath);
      await trayManager.setToolTip('DoDo Todo Calendar Widget');

      // Build context menu
      Menu menu = Menu(
        items: [
          MenuItem(
            key: 'show_widget',
            label: '위젯 표시',
          ),
          MenuItem(
            key: 'hide_widget',
            label: '위젯 숨기기',
          ),
          MenuItem.separator(),
          MenuItem(
            key: 'toggle_always_on_top',
            label: '항상 위에 표시',
          ),
          MenuItem.separator(),
          MenuItem(
            key: 'exit_app',
            label: '종료',
          ),
        ],
      );

      await trayManager.setContextMenu(menu);

      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize system tray: $e');
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
