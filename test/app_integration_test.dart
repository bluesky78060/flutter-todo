import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/main.dart';

void main() {
  group('DoDo App Integration Tests', () {
    testWidgets('App initializes without errors', (WidgetTester tester) async {
      // Build the app with ProviderScope
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );

      // Allow initial async operations to complete
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify the app launches successfully
      // Should show either login screen or todos screen
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('App has proper theme configuration', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify MaterialApp exists
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

      // Verify theme is configured
      expect(materialApp.theme, isNotNull);
      expect(materialApp.darkTheme, isNotNull);
    });

    testWidgets('App uses proper routing', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify MaterialApp has router configuration
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.routerConfig, isNotNull);
    });

    testWidgets('App supports dark mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify MaterialApp has dark theme
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.darkTheme, isNotNull);
      expect(materialApp.themeMode, ThemeMode.dark);
    });
  });
}
