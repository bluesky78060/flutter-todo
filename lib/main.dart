import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_app/core/config/supabase_config.dart';
import 'package:todo_app/core/router/app_router.dart';
import 'package:todo_app/core/services/notification_service.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/presentation/providers/database_provider.dart';
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

  // Load environment variables from .env file
  await dotenv.load(fileName: '.env');
  logger.d('✅ Environment variables loaded from .env');

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

  // No need for manual auth listener - StreamProvider handles this automatically

  // Initialize Notification Service (without requesting permissions yet)
  // Permissions will be requested in TodoListScreen after Activity context is ready
  final notificationService = NotificationService();
  try {
    await notificationService.initialize();
    logger.d('✅ Main: Notification service initialized successfully');
  } catch (e, stackTrace) {
    logger.d('❌ Main: Failed to initialize notification service: $e');
    logger.d('   Stack trace: $stackTrace');
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

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
