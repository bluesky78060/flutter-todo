import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb, defaultTargetPlatform, TargetPlatform;
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
import 'package:todo_app/core/utils/app_logger.dart';

// ✅ CRITICAL: Background notification handler (must be top-level function)
// This function handles notifications when the app is terminated or in background
// IMPORTANT: Keep this function as simple as possible to avoid crashes
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // Do nothing - just prevent crash
  // The app will open when user taps the notification
  // Complex logic should be handled when app comes to foreground
}

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

Future<void> runAppWithErrorHandling() async {
  // Initialize Supabase with platform-specific auth options
  if (kIsWeb) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
      authOptions: FlutterAuthClientOptions(
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
  }

  final prefs = await SharedPreferences.getInstance();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ko')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  Widget build(BuildContext context) {
    // Generate recurring todo instances AFTER authentication
    // Listen to auth state and trigger once when authenticated
    ref.listen<bool>(isAuthenticatedProvider, (prev, next) async {
      // Trigger only on transition to authenticated
      if (next == true && prev != true) {
        try {
          final recurringService = ref.read(recurringTodoServiceProvider);
          logger.d('🔄 Main: Authenticated - generating recurring todo instances');
          await recurringService.generateUpcomingInstances(lookAheadDays: 30);
          logger.d('✅ Main: Recurring instances generation completed');
        } catch (e, stackTrace) {
          logger.e('❌ Main: Failed to generate recurring instances after auth',
              error: e, stackTrace: stackTrace);
        }
      }
    });

    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Todo App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlue,
          brightness: Brightness.dark,
          surface: AppColors.darkCard,
        ),
        scaffoldBackgroundColor: AppColors.darkBackground,
        useMaterial3: true,
      ),
      themeMode: themeMode,
      routerConfig: router,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    );
  }
}
