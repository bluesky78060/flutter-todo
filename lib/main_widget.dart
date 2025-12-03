/// Windows Calendar Widget Entry Point
///
/// Separate entry point for the Windows desktop calendar widget.
/// This creates a lightweight, always-on-top calendar widget that:
/// - Shows monthly calendar view
/// - Displays todos for selected date
/// - Allows quick todo creation
/// - Runs in system tray
///
/// Build command:
/// ```bash
/// flutter build windows --release -t lib/main_widget.dart
/// ```
library;

import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_app/core/config/supabase_config.dart';
import 'package:todo_app/core/utils/app_logger.dart';
import 'package:todo_app/platforms/windows/calendar_widget_window.dart';
import 'package:todo_app/platforms/windows/tray_manager.dart';
import 'package:todo_app/platforms/windows/widget_config.dart';
import 'package:todo_app/presentation/providers/database_provider.dart';
import 'package:todo_app/presentation/providers/theme_provider.dart';
import 'package:todo_app/presentation/providers/theme_customization_provider.dart';

/// Widget-specific entry point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
    logger.d('✅ Environment variables loaded for widget');
  } catch (e) {
    logger.w('⚠️ Could not load .env file: $e');
  }

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Initialize Supabase for data sync
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    logger.d('✅ Supabase initialized for widget');
  } catch (e) {
    logger.e('❌ Supabase initialization failed: $e');
  }

  // Initialize widget configuration and window
  final widgetConfig = WidgetConfig(prefs);

  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await widgetConfig.initializeWindow();
    logger.d('✅ Widget window initialized');
  }

  // Initialize system tray
  final trayManager = TrayManager();
  await trayManager.init();
  logger.d('✅ System tray initialized');

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ko')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: CalendarWidgetApp(
          widgetConfig: widgetConfig,
          trayManager: trayManager,
        ),
      ),
    ),
  );
}

/// Calendar widget application
class CalendarWidgetApp extends ConsumerStatefulWidget {
  final WidgetConfig widgetConfig;
  final TrayManager trayManager;

  const CalendarWidgetApp({
    super.key,
    required this.widgetConfig,
    required this.trayManager,
  });

  @override
  ConsumerState<CalendarWidgetApp> createState() => _CalendarWidgetAppState();
}

class _CalendarWidgetAppState extends ConsumerState<CalendarWidgetApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.trayManager.destroy();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Save window state when app is paused
      widget.widgetConfig.saveCurrentState();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final primaryColor = ref.watch(primaryColorProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DoDo Calendar Widget',
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeData(
        useMaterial3: true,
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: isDarkMode ? Brightness.dark : Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: const CalendarWidgetWindow(),
    );
  }
}
