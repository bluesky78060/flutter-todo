/// Todo App - Main Application Entry Point
///
/// A cross-platform Todo application built with Flutter featuring:
/// - Supabase backend for authentication and data sync
/// - Local-first architecture with offline support
/// - Recurring todos with RRULE support
/// - Location-based reminders (geofencing)
/// - Home screen widgets (Android)
/// - Multi-language support (English/Korean)
///
/// Package: kr.bluesky.dodo
///
/// Architecture:
/// - Clean Architecture with domain/data/presentation layers
/// - Riverpod for state management
/// - Drift for local database
/// - GoRouter for navigation
library;

import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:todo_app/core/services/workmanager_notification_service.dart'; // Temporarily disabled
// import 'package:sentry_flutter/sentry_flutter.dart';  // Temporarily disabled due to Kotlin conflict
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_app/core/config/supabase_config.dart';
import 'package:todo_app/core/router/app_router.dart';
import 'package:todo_app/core/services/geofence_workmanager_service.dart';
import 'package:todo_app/core/services/notification_service.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/presentation/providers/database_provider.dart';
import 'package:todo_app/presentation/providers/auth_providers.dart';
import 'package:todo_app/presentation/providers/theme_provider.dart';
import 'package:todo_app/presentation/providers/theme_customization_provider.dart';
import 'package:todo_app/core/utils/app_logger.dart';
import 'package:todo_app/core/widget/widget_init.dart';
import 'package:todo_app/core/services/widget_method_channel.dart';

/// Background notification handler for when app is terminated or in background.
///
/// CRITICAL: This must be a top-level function for Flutter to call it.
/// Keep it as simple as possible to avoid crashes.
// This function handles notifications when the app is terminated or in background
// IMPORTANT: Keep this function as simple as possible to avoid crashes
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // Do nothing - just prevent crash
  // The app will open when user taps the notification
  // Complex logic should be handled when app comes to foreground
}

/// Application entry point.
///
/// Initializes:
/// 1. Flutter binding
/// 2. Localization (EasyLocalization)
/// 3. Naver Maps SDK (platform-specific)
/// 4. Environment variables (.env)
///
/// Then calls [runAppWithErrorHandling] for remaining initialization.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Initialize Naver Map SDK
  if (!kIsWeb) {
    // Mobile platforms only - Web uses JavaScript SDK loaded in index.html
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android: 새로운 초기화 방법
      await FlutterNaverMap().init(clientId: 'rzx12utf2x');
      logger.d('✅ Naver Maps SDK initialized for Android with FlutterNaverMap().init()');
    } else {
      // iOS: 기존 방법 유지
      await NaverMapSdk.instance.initialize(clientId: 'rzx12utf2x');
      logger.d('✅ Naver Maps SDK initialized for iOS');
    }
  } else {
    // Web: SDK는 index.html의 JavaScript에서 로드됨
    logger.d('✅ Naver Maps SDK for Web loaded via index.html script tag');
  }

  // Load environment variables from .env file
  await dotenv.load(fileName: '.env');
  logger.d('✅ Environment variables loaded from .env');

  // TODO: Re-enable Sentry after resolving Kotlin version conflict
  // Get Sentry DSN from environment
  // final sentryDsn = dotenv.env['SENTRY_DSN'] ?? '';
  // final enableSentry = sentryDsn.isNotEmpty && !kDebugMode;

  // await SentryFlutter.init(
  //   (options) {
  //     options.dsn = enableSentry ? sentryDsn : '';
  //     options.environment = kDebugMode ? 'development' : 'production';
  //     options.release = 'todo_app@1.0.8+20'; // Match pubspec.yaml version
  //     options.tracesSampleRate = 1.0; // Performance monitoring (100% in production)
  //     options.enableAutoPerformanceTracing = true;

  //     // Capture error context
  //     options.attachStacktrace = true;
  //     options.attachScreenshot = true;
  //     options.attachViewHierarchy = true;

  //     // Filter out sensitive data
  //     options.beforeSend = (event, {hint}) {
  //       // Don't send events in debug mode
  //       if (kDebugMode) return null;
  //       return event;
  //     };

  //     // Log Sentry initialization
  //     if (enableSentry) {
  //       logger.d('✅ Sentry initialized for production');
  //     } else {
  //       logger.d('ℹ️ Sentry disabled (debug mode or no DSN)');
  //     }
  //   },
  //   appRunner: () => runAppWithErrorHandling(),
  // );

  runAppWithErrorHandling();
}

/// Runs the app with comprehensive error handling.
///
/// Initializes:
/// 1. Supabase (authentication and database)
/// 2. Notification service
/// 3. Geofence WorkManager (mobile only)
/// 4. Widget system (mobile only)
/// 5. SharedPreferences
///
/// Creates [ProviderContainer] for Riverpod state management
/// and runs [MyApp] with localization support.
Future<void> runAppWithErrorHandling() async {
  // Initialize Supabase with platform-specific auth options
  try {
    if (kIsWeb) {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          // Force web to use current URL for OAuth redirects
          // This prevents deep link URLs from being stored
          autoRefreshToken: true,
        ),
      );
      logger.d('✅ Supabase initialized for web with PKCE auth flow');
    } else {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      logger.d('✅ Supabase initialized for mobile with PKCE auth flow');
    }
  } catch (e, stackTrace) {
    logger.e('❌ Main: Failed to initialize Supabase',
        error: e, stackTrace: stackTrace);
    // Continue with app even if Supabase initialization fails
    // This allows the app to show error screen instead of crashing
  }

  logger.d('✅ Main: Supabase initialization complete, starting notification service');

  // Initialize Notification Service (without requesting permissions yet)
  // Permissions will be requested in TodoListScreen after Activity context is ready
  final notificationService = NotificationService();
  try {
    await notificationService.initialize();
    logger.d('✅ Main: Notification service initialized successfully');
  } catch (e, stackTrace) {
    logger.e('❌ Main: Failed to initialize notification service',
        error: e, stackTrace: stackTrace);
    // TODO: Report to Sentry after re-enabling
    // await Sentry.captureException(e, stackTrace: stackTrace);
  }

  logger.d('✅ Main: Notification service setup complete');

  // Initialize Geofence WorkManager Service for location-based notifications
  // Only initialize on mobile platforms, not web
  if (!kIsWeb) {
    try {
      await GeofenceWorkManagerService.initialize();
      logger.d('✅ Main: Geofence WorkManager service initialized successfully');

      // Start monitoring with 15-minute intervals (Android minimum)
      await GeofenceWorkManagerService.startMonitoring(intervalMinutes: 15);
      logger.d('✅ Main: Geofence monitoring started');
    } catch (e, stackTrace) {
      logger.e('❌ Main: Failed to initialize geofence service',
          error: e, stackTrace: stackTrace);
      // Don't fail the app if geofence service fails to initialize
    }

    // Initialize widget system (home screen widgets)
    try {
      await initializeWidgetSystem();
      logger.d('✅ Main: Widget system initialized successfully');
    } catch (e, stackTrace) {
      logger.e('❌ Main: Failed to initialize widget system',
          error: e, stackTrace: stackTrace);
      // Don't fail the app if widget system fails to initialize
    }
  }

  final prefs = await SharedPreferences.getInstance();

  logger.d('✅ Main: SharedPreferences loaded, starting app');

  // Create ProviderContainer manually to pass to WidgetMethodChannelHandler
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );

  // Set container for widget method channel
  WidgetMethodChannelHandler.setProviderContainer(container);

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ko')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: UncontrolledProviderScope(
        container: container,
        child: const MyApp(),
      ),
    ),
  );

  logger.d('✅ Main: runApp completed');
}

/// Root application widget.
///
/// Configures:
/// - Material Design 3 theming (light/dark)
/// - GoRouter for navigation
/// - Localization delegates
/// - Recurring todo instance generation on authentication
class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // 위젯 MethodChannel 리스너 설정 (위젯 버튼 클릭 처리)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        WidgetMethodChannelHandler.setupMethodChannelListener();
        logger.d('✅ 위젯 MethodChannel 리스너 등록 완료');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Generate recurring todo instances AFTER authentication
    // Listen to auth state and trigger once when authenticated
    ref.listen<bool>(isAuthenticatedProvider, (prev, next) async {
      // Trigger only on transition to authenticated
      if (next == true && prev != true) {
        try {
          // Save access token to SharedPreferences for widget background sync
          final session = Supabase.instance.client.auth.currentSession;
          if (session != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('supabase_access_token', session.accessToken);
            logger.d('✅ Main: Saved access token to SharedPreferences for widget sync');
          }

          final recurringService = ref.read(recurringTodoServiceProvider);
          logger.d('🔄 Main: Authenticated - generating recurring todo instances');
          await recurringService.generateUpcomingInstances(lookAheadDays: 30);
          logger.d('✅ Main: Recurring instances generation completed');
        } catch (e, stackTrace) {
          logger.e('❌ Main: Failed to generate recurring instances after auth',
              error: e, stackTrace: stackTrace);
        }
      } else if (next == false && prev == true) {
        // Clear access token on logout
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('supabase_access_token');
          logger.d('✅ Main: Cleared access token from SharedPreferences');
        } catch (e) {
          logger.e('❌ Main: Failed to clear access token', error: e);
        }
      }
    });

    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeProvider);

    // Watch the full state directly to ensure rebuild on any state change
    final themeState = ref.watch(themeCustomizationProvider);
    final primaryColor = themeState.applied.primaryColor;
    final fontScale = themeState.applied.fontSizeScale;

    logger.d('🎨 MyApp.build() rebuilding with APPLIED theme: primaryColor=${primaryColor.value}, fontScale=$fontScale, hasUnsavedChanges=${themeState.hasUnsavedChanges}');

    // Update AppColors dynamic primary color and font scale for widgets
    AppColors.setDynamicPrimary(primaryColor);
    AppColors.setDynamicFontScale(fontScale);
    logger.d('🎨 AppColors theme updated: color=${primaryColor.value}, fontScale=$fontScale');

    // Build light theme with custom primary color
    final lightTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      textTheme: TextTheme(
        displayLarge: TextStyle(fontSize: AppColors.scaledFontSize(32)),
        displayMedium: TextStyle(fontSize: AppColors.scaledFontSize(28)),
        displaySmall: TextStyle(fontSize: AppColors.scaledFontSize(24)),
        headlineLarge: TextStyle(fontSize: AppColors.scaledFontSize(24)),
        headlineMedium: TextStyle(fontSize: AppColors.scaledFontSize(20)),
        headlineSmall: TextStyle(fontSize: AppColors.scaledFontSize(18)),
        titleLarge: TextStyle(fontSize: AppColors.scaledFontSize(18), fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: AppColors.scaledFontSize(16), fontWeight: FontWeight.w600),
        titleSmall: TextStyle(fontSize: AppColors.scaledFontSize(14), fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: AppColors.scaledFontSize(16)),
        bodyMedium: TextStyle(fontSize: AppColors.scaledFontSize(14)),
        bodySmall: TextStyle(fontSize: AppColors.scaledFontSize(12)),
        labelLarge: TextStyle(fontSize: AppColors.scaledFontSize(14), fontWeight: FontWeight.w500),
        labelMedium: TextStyle(fontSize: AppColors.scaledFontSize(12), fontWeight: FontWeight.w500),
        labelSmall: TextStyle(fontSize: AppColors.scaledFontSize(11), fontWeight: FontWeight.w500),
      ),
    );

    // Build dark theme with custom primary color
    final darkTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        surface: AppColors.darkCard,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      useMaterial3: true,
      textTheme: TextTheme(
        displayLarge: TextStyle(fontSize: AppColors.scaledFontSize(32)),
        displayMedium: TextStyle(fontSize: AppColors.scaledFontSize(28)),
        displaySmall: TextStyle(fontSize: AppColors.scaledFontSize(24)),
        headlineLarge: TextStyle(fontSize: AppColors.scaledFontSize(24)),
        headlineMedium: TextStyle(fontSize: AppColors.scaledFontSize(20)),
        headlineSmall: TextStyle(fontSize: AppColors.scaledFontSize(18)),
        titleLarge: TextStyle(fontSize: AppColors.scaledFontSize(18), fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: AppColors.scaledFontSize(16), fontWeight: FontWeight.w600),
        titleSmall: TextStyle(fontSize: AppColors.scaledFontSize(14), fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: AppColors.scaledFontSize(16)),
        bodyMedium: TextStyle(fontSize: AppColors.scaledFontSize(14)),
        bodySmall: TextStyle(fontSize: AppColors.scaledFontSize(12)),
        labelLarge: TextStyle(fontSize: AppColors.scaledFontSize(14), fontWeight: FontWeight.w500),
        labelMedium: TextStyle(fontSize: AppColors.scaledFontSize(12), fontWeight: FontWeight.w500),
        labelSmall: TextStyle(fontSize: AppColors.scaledFontSize(11), fontWeight: FontWeight.w500),
      ),
    );

    return MaterialApp.router(
      title: 'Todo App',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    );
  }
}
