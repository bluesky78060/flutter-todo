/// Widget Configuration for Windows Desktop
///
/// Manages widget window settings:
/// - Window size and position
/// - Always on top state
/// - Launch at startup setting
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Widget configuration manager
class WidgetConfig {
  static const String _keyWindowX = 'widget_window_x';
  static const String _keyWindowY = 'widget_window_y';
  static const String _keyWindowWidth = 'widget_window_width';
  static const String _keyWindowHeight = 'widget_window_height';
  static const String _keyAlwaysOnTop = 'widget_always_on_top';
  static const String _keyLaunchAtStartup = 'widget_launch_at_startup';

  final SharedPreferences _prefs;

  WidgetConfig(this._prefs);

  /// Default widget size
  static const Size defaultSize = Size(320, 420);

  /// Minimum widget size
  static const Size minSize = Size(280, 350);

  /// Maximum widget size
  static const Size maxSize = Size(450, 600);

  /// Get saved window position or default to bottom-right
  Future<Offset> getSavedPosition() async {
    final savedX = _prefs.getDouble(_keyWindowX);
    final savedY = _prefs.getDouble(_keyWindowY);

    if (savedX != null && savedY != null) {
      return Offset(savedX, savedY);
    }

    // Default to bottom-right corner
    return await _getBottomRightPosition();
  }

  /// Get bottom-right position based on screen size
  Future<Offset> _getBottomRightPosition() async {
    try {
      final primaryDisplay = await screenRetriever.getPrimaryDisplay();
      final screenSize = primaryDisplay.size;
      final size = getSavedSize();

      const margin = 16.0;
      const taskbarHeight = 48.0;

      return Offset(
        screenSize.width - size.width - margin,
        screenSize.height - size.height - taskbarHeight - margin,
      );
    } catch (e) {
      // Fallback for non-desktop platforms
      return const Offset(1600, 600);
    }
  }

  /// Get saved window size or default
  Size getSavedSize() {
    final width = _prefs.getDouble(_keyWindowWidth) ?? defaultSize.width;
    final height = _prefs.getDouble(_keyWindowHeight) ?? defaultSize.height;
    return Size(width, height);
  }

  /// Save window position
  Future<void> savePosition(Offset position) async {
    await _prefs.setDouble(_keyWindowX, position.dx);
    await _prefs.setDouble(_keyWindowY, position.dy);
  }

  /// Save window size
  Future<void> saveSize(Size size) async {
    await _prefs.setDouble(_keyWindowWidth, size.width);
    await _prefs.setDouble(_keyWindowHeight, size.height);
  }

  /// Get always on top setting
  bool getAlwaysOnTop() {
    return _prefs.getBool(_keyAlwaysOnTop) ?? true;
  }

  /// Save always on top setting
  Future<void> setAlwaysOnTop(bool value) async {
    await _prefs.setBool(_keyAlwaysOnTop, value);
  }

  /// Get launch at startup setting
  bool getLaunchAtStartup() {
    return _prefs.getBool(_keyLaunchAtStartup) ?? false;
  }

  /// Set launch at startup
  Future<void> setLaunchAtStartup(bool value) async {
    await _prefs.setBool(_keyLaunchAtStartup, value);

    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
      return;
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();

      launchAtStartup.setup(
        appName: packageInfo.appName,
        appPath: Platform.resolvedExecutable,
        args: ['--widget'],
      );

      if (value) {
        await launchAtStartup.enable();
      } else {
        await launchAtStartup.disable();
      }
    } catch (e) {
      debugPrint('Failed to set launch at startup: $e');
    }
  }

  /// Initialize window with saved settings
  Future<void> initializeWindow() async {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
      return;
    }

    await windowManager.ensureInitialized();

    final size = getSavedSize();
    final position = await getSavedPosition();
    final alwaysOnTop = getAlwaysOnTop();

    final windowOptions = WindowOptions(
      size: size,
      minimumSize: minSize,
      maximumSize: maxSize,
      center: false,
      backgroundColor: Colors.transparent,
      skipTaskbar: true,
      alwaysOnTop: alwaysOnTop,
      titleBarStyle: TitleBarStyle.hidden,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setPosition(position);
      await windowManager.show();
      await windowManager.setAsFrameless();
    });

    // Listen for window position/size changes to save them
    _setupWindowListener();
  }

  void _setupWindowListener() {
    // This would need to be called from the widget state
    // to properly save position/size on changes
  }

  /// Save current window state
  Future<void> saveCurrentState() async {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
      return;
    }

    try {
      final position = await windowManager.getPosition();
      final size = await windowManager.getSize();
      final alwaysOnTop = await windowManager.isAlwaysOnTop();

      await savePosition(position);
      await saveSize(size);
      await setAlwaysOnTop(alwaysOnTop);
    } catch (e) {
      debugPrint('Failed to save window state: $e');
    }
  }

  /// Reset to default position (bottom-right)
  Future<void> resetToDefaultPosition() async {
    final position = await _getBottomRightPosition();
    await windowManager.setPosition(position);
    await savePosition(position);
  }

  /// Reset to default size
  Future<void> resetToDefaultSize() async {
    await windowManager.setSize(defaultSize);
    await saveSize(defaultSize);
  }
}
