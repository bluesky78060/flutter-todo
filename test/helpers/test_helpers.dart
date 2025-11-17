import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper function to wrap widgets with EasyLocalization for testing
/// This ensures proper initialization of localization in test environment
Future<void> pumpWidgetWithLocalization(
  WidgetTester tester,
  Widget child,
) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ko')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ko'),
      // Use a simple string map for testing instead of loading from assets
      useOnlyLangCode: true,
      child: Builder(
        builder: (context) {
          // Initialize EasyLocalization before returning the child
          return MaterialApp(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: const Locale('ko'),
            home: Scaffold(body: child),
          );
        },
      ),
    ),
  );

  // Give extra time for localization to initialize
  await tester.pumpAndSettle(const Duration(seconds: 1));
}
