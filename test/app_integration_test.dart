import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/main.dart';

/// Integration tests for DoDo App
///
/// ⚠️ NOTE: These tests require platform plugins (Supabase, SharedPreferences, etc.)
/// and are better suited for integration testing on actual devices.
///
/// To run integration tests:
/// 1. Use `flutter test integration_test/` with integration_test package
/// 2. Or run on physical device: `flutter run test/app_integration_test.dart`
///
/// For unit tests, see:
/// - test/unit/utils/recurrence_utils_test.dart (31 tests, all passing)
/// - test/unit/services/recurring_todo_service_test.dart (16 tests, partial)
///
/// Current status: Disabled due to platform plugin requirements
///
/// ⚠️ 2026-08-18 (DTA-2-2): 이 그룹은 이름만 "(Disabled)"였고 `skip:`이 없어
/// 실제로는 계속 실행되며 4건이 실패하고 있었다. 아래는 조사 결과다.
///
/// 1차 원인: `MyApp`이 `context.localizationDelegates`(main.dart:451)를 호출하는데
///          테스트가 `EasyLocalization` 조상 없이 `ProviderScope(child: MyApp())`만
///          감싸서 `Null check operator used on a null value` 발생.
/// 2차 원인: `EasyLocalization`으로 감싸 1차 원인을 제거해도
///          `ProviderException: Tried to use a provider that is in error state`가 발생.
///          `main()`이 수행하는 Supabase 초기화가 없어 관련 provider가 error 상태다.
///
/// 즉 순수 위젯 테스트로는 복구 불가능하며, 파일 헤더의 기존 설명이 실측으로 확인됐다.
/// 그래서 이름뿐이던 비활성화를 `skip:`으로 코드에 실제 반영한다.
///
/// 제거 조건: `integration_test` 패키지로 이관하거나, Supabase를 mock 주입할 수 있도록
///           `MyApp` 초기화 경로를 리팩터링하면 이 skip을 없앨 수 있다.
void main() {
  group('DoDo App Integration Tests (Disabled)', skip:
      'DTA-2-2: Supabase 등 플랫폼 플러그인 초기화가 필요해 순수 위젯 테스트로 실행 불가. '
      'integration_test 패키지로 이관하거나 MyApp 초기화를 mock 가능하게 리팩터링해야 해제 가능.',
      () {
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
