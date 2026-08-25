import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/presentation/widgets/reschedule_dialog.dart';
import 'package:todo_app/presentation/providers/theme_provider.dart';

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  // EasyLocalization.ensureInitialized()는 SharedPreferences를 사용하므로
  // mock을 먼저 심지 않으면 MissingPluginException으로 파일 전체가 로드 실패한다.
  SharedPreferences.setMockInitialValues({});
  // 이 호출이 없으면 번역 자산이 로드되지 않아 위젯 트리가 로딩 상태로 남고,
  // Dialog를 포함한 모든 위젯이 0개로 잡힌다.
  await EasyLocalization.ensureInitialized();
  final assetLoader = _MapAssetLoader(await _readTranslations());

  group('RescheduleDialog Widget', () {
    Widget createTestWidget(Widget child) {
      return ProviderScope(
        overrides: [
          isDarkModeProvider.overrideWith((ref) => false),
        ],
        child: EasyLocalization(
          assetLoader: assetLoader,
          supportedLocales: const [Locale('ko'), Locale('en')],
          path: 'assets/translations',
          fallbackLocale: const Locale('en'),
          startLocale: const Locale('ko'),
          child: Builder(
            builder: (context) => MaterialApp(
              locale: const Locale('ko'),
              supportedLocales: const [Locale('ko'), Locale('en')],
              localizationsDelegates: context.localizationDelegates,
              home: Scaffold(
                body: child,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders dialog title', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(const RescheduleDialog()));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('일정 이월'), findsOneWidget);
    });

    testWidgets('renders three reschedule options', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(const RescheduleDialog()));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('오늘로'), findsOneWidget);
      expect(find.text('내일로'), findsOneWidget);
      expect(find.text('직접 선택'), findsOneWidget);
    });

    testWidgets('renders cancel button', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(const RescheduleDialog()));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('취소'), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('renders Dialog widget', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(const RescheduleDialog()));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('returns today option when tapped', (WidgetTester tester) async {
      // Arrange
      RescheduleOption? result;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isDarkModeProvider.overrideWith((ref) => false),
          ],
          child: EasyLocalization(
            assetLoader: assetLoader,
            supportedLocales: const [Locale('ko'), Locale('en')],
            path: 'assets/translations',
            fallbackLocale: const Locale('en'),
            startLocale: const Locale('ko'),
            child: Builder(
              builder: (context) => MaterialApp(
                locale: const Locale('ko'),
                supportedLocales: const [Locale('ko'), Locale('en')],
                localizationsDelegates: context.localizationDelegates,
                home: Builder(
                  builder: (innerContext) => Scaffold(
                    body: ElevatedButton(
                      onPressed: () async {
                        result = await showDialog<RescheduleOption>(
                          context: innerContext,
                          builder: (_) => const RescheduleDialog(),
                        );
                      },
                      child: const Text('Show Dialog'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('오늘로'));
      await tester.pumpAndSettle();

      // Assert
      expect(result, RescheduleOption.today);
    });

    testWidgets('returns tomorrow option when tapped', (WidgetTester tester) async {
      // Arrange
      RescheduleOption? result;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isDarkModeProvider.overrideWith((ref) => false),
          ],
          child: EasyLocalization(
            assetLoader: assetLoader,
            supportedLocales: const [Locale('ko'), Locale('en')],
            path: 'assets/translations',
            fallbackLocale: const Locale('en'),
            startLocale: const Locale('ko'),
            child: Builder(
              builder: (context) => MaterialApp(
                locale: const Locale('ko'),
                supportedLocales: const [Locale('ko'), Locale('en')],
                localizationsDelegates: context.localizationDelegates,
                home: Builder(
                  builder: (innerContext) => Scaffold(
                    body: ElevatedButton(
                      onPressed: () async {
                        result = await showDialog<RescheduleOption>(
                          context: innerContext,
                          builder: (_) => const RescheduleDialog(),
                        );
                      },
                      child: const Text('Show Dialog'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('내일로'));
      await tester.pumpAndSettle();

      // Assert
      expect(result, RescheduleOption.tomorrow);
    });

    testWidgets('returns custom option when tapped', (WidgetTester tester) async {
      // Arrange
      RescheduleOption? result;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isDarkModeProvider.overrideWith((ref) => false),
          ],
          child: EasyLocalization(
            assetLoader: assetLoader,
            supportedLocales: const [Locale('ko'), Locale('en')],
            path: 'assets/translations',
            fallbackLocale: const Locale('en'),
            startLocale: const Locale('ko'),
            child: Builder(
              builder: (context) => MaterialApp(
                locale: const Locale('ko'),
                supportedLocales: const [Locale('ko'), Locale('en')],
                localizationsDelegates: context.localizationDelegates,
                home: Builder(
                  builder: (innerContext) => Scaffold(
                    body: ElevatedButton(
                      onPressed: () async {
                        result = await showDialog<RescheduleOption>(
                          context: innerContext,
                          builder: (_) => const RescheduleDialog(),
                        );
                      },
                      child: const Text('Show Dialog'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('직접 선택'));
      await tester.pumpAndSettle();

      // Assert
      expect(result, RescheduleOption.custom);
    });

    testWidgets('returns null when cancel button tapped', (WidgetTester tester) async {
      // Arrange
      RescheduleOption? result = RescheduleOption.today; // Start with non-null

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isDarkModeProvider.overrideWith((ref) => false),
          ],
          child: EasyLocalization(
            assetLoader: assetLoader,
            supportedLocales: const [Locale('ko'), Locale('en')],
            path: 'assets/translations',
            fallbackLocale: const Locale('en'),
            startLocale: const Locale('ko'),
            child: Builder(
              builder: (context) => MaterialApp(
                locale: const Locale('ko'),
                supportedLocales: const [Locale('ko'), Locale('en')],
                localizationsDelegates: context.localizationDelegates,
                home: Builder(
                  builder: (innerContext) => Scaffold(
                    body: ElevatedButton(
                      onPressed: () async {
                        result = await showDialog<RescheduleOption>(
                          context: innerContext,
                          builder: (_) => const RescheduleDialog(),
                        );
                      },
                      child: const Text('Show Dialog'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      // Assert
      expect(result, null);
    });

    testWidgets('renders all option icons', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(const RescheduleDialog()));
      await tester.pumpAndSettle();

      // Assert - verify InkWell widgets for options
      final inkWells = tester.widgetList<InkWell>(find.byType(InkWell));
      expect(inkWells.length, greaterThanOrEqualTo(3)); // At least 3 options
    });

    testWidgets('renders chevron icons for each option', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(const RescheduleDialog()));
      await tester.pumpAndSettle();

      // Assert - verify Icon widgets (title icon + 3 option icons + 3 chevrons = 7 icons total)
      final icons = tester.widgetList<Icon>(find.byType(Icon));
      expect(icons.length, greaterThanOrEqualTo(7));
    });
  });
}

/// 실제 파일 I/O 없이 번역 맵을 그대로 돌려주는 테스트용 로더.
///
/// 기본 로더(`RootBundleAssetLoader`)는 `assets/translations/*.json`을
/// **실제 파일 I/O**로 읽는다. 위젯 테스트의 fake async 클럭은 실제 I/O를
/// 진행시키지 못하므로 `pumpAndSettle()`을 아무리 돌려도 로딩이 끝나지 않고,
/// 위젯 트리가 로딩 상태에 머물러 `Dialog`를 포함한 모든 위젯이 0개로 잡힌다.
///
/// 이 로더는 이미 메모리에 올라온 맵을 반환하므로 그 Future가 **마이크로태스크로**
/// 완료된다. 마이크로태스크는 fake async 클럭이 처리하므로 `pumpAndSettle()`만으로
/// 결정적으로 로딩이 끝난다. 고정 지연(`Future.delayed`)에 의존하지 않는다.
class _MapAssetLoader extends AssetLoader {
  const _MapAssetLoader(this._byLanguageCode);

  final Map<String, Map<String, dynamic>> _byLanguageCode;

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      _byLanguageCode[locale.languageCode];
}

/// `assets/translations/`의 실제 JSON을 테스트 시작 전에 한 번만 읽어 둔다.
Future<Map<String, Map<String, dynamic>>> _readTranslations() async {
  final result = <String, Map<String, dynamic>>{};
  for (final code in ['ko', 'en']) {
    final raw = await File('assets/translations/$code.json').readAsString();
    result[code] = json.decode(raw) as Map<String, dynamic>;
  }
  return result;
}
