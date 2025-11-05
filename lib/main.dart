import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_app/core/config/supabase_config.dart';
import 'package:todo_app/core/router/app_router.dart';
import 'package:todo_app/core/services/notification_service.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/presentation/providers/database_provider.dart';
import 'package:todo_app/presentation/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Initialize Supabase with deep link handling
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  print('✅ Supabase initialized with PKCE auth flow');

  // No need for manual auth listener - StreamProvider handles this automatically

  // Initialize Notification Service
  final notificationService = NotificationService();
  try {
    await notificationService.initialize();
    print('✅ Main: Notification service initialized successfully');

    final permissionGranted = await notificationService.requestPermissions();
    print('📱 Main: Notification permissions granted: $permissionGranted');

    if (!permissionGranted) {
      print('⚠️ Main: Notification permissions were not granted');
    }
  } catch (e, stackTrace) {
    print('❌ Main: Failed to initialize notification service: $e');
    print('   Stack trace: $stackTrace');
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
          background: AppColors.darkBackground,
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
