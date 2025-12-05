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
import 'package:todo_app/platforms/windows/widget_login_screen.dart';
import 'package:todo_app/presentation/providers/database_provider.dart';
import 'package:todo_app/presentation/providers/theme_provider.dart';
import 'package:todo_app/presentation/providers/theme_customization_provider.dart';
import 'package:todo_app/presentation/providers/auth_providers.dart';

/// Widget-specific entry point
void main() async {
  logger.d('🚀 Widget: Starting main()...');
  logger.d('🖥️ Widget: Platform = ${Platform.operatingSystem}');

  WidgetsFlutterBinding.ensureInitialized();
  logger.d('✅ Widget: Flutter binding initialized');

  await EasyLocalization.ensureInitialized();
  logger.d('✅ Widget: EasyLocalization initialized');

  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
    logger.d('✅ Widget: Environment variables loaded');
  } catch (e) {
    logger.w('⚠️ Widget: Could not load .env file: $e');
  }

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  logger.d('✅ Widget: SharedPreferences initialized');

  // Initialize Supabase for data sync
  try {
    logger.d('🔧 Widget: Initializing Supabase...');
    logger.d('🔧 Widget: URL=${SupabaseConfig.url}');
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    logger.d('✅ Widget: Supabase initialized');
  } catch (e, stackTrace) {
    logger.e('❌ Widget: Supabase initialization failed: $e');
    logger.e('❌ Widget: Stack trace: $stackTrace');
  }

  // Initialize widget configuration and window
  final widgetConfig = WidgetConfig(prefs);
  logger.d('✅ Widget: WidgetConfig created');

  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    logger.d('🔧 Widget: Initializing window...');
    try {
      await widgetConfig.initializeWindow();
      logger.d('✅ Widget: Window initialized');
    } catch (e, stackTrace) {
      logger.e('❌ Widget: Window initialization failed: $e');
      logger.e('❌ Widget: Stack trace: $stackTrace');
    }
  } else {
    logger.d('⚠️ Widget: Not a desktop platform, skipping window init');
  }

  // Initialize system tray
  logger.d('🔧 Widget: Initializing system tray...');
  final trayManager = TrayManager();
  try {
    await trayManager.init();
    logger.d('✅ Widget: System tray initialized');
  } catch (e, stackTrace) {
    logger.e('❌ Widget: System tray initialization failed: $e');
    logger.e('❌ Widget: Stack trace: $stackTrace');
  }

  logger.d('🚀 Widget: Starting Flutter app...');
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
  logger.d('✅ Widget: runApp completed');
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
    final authState = ref.watch(currentUserProvider);

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
      home: authState.when(
        data: (user) {
          if (user != null) {
            // User is logged in, show calendar
            return const CalendarWidgetWindow();
          } else {
            // User is not logged in, show login screen
            return const WidgetLoginScreen();
          }
        },
        loading: () => const Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, stack) => const WidgetLoginScreen(),
      ),
    );
  }
}
