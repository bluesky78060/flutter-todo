import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/presentation/widgets/reschedule_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RescheduleDialog Widget', () {
    Widget createTestWidget(Widget child) {
      return EasyLocalization(
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
      );
    }

    testWidgets('renders dialog title', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(const RescheduleDialog()));
      await tester.pumpAndSettle();
      await tester.pump(); // Extra pump for EasyLocalization

      // Assert - check for translation key if translation not loaded
      final titleFinder = find.text('일정 이월').evaluate().isEmpty
          ? find.text('reschedule_title')
          : find.text('일정 이월');
      expect(titleFinder, findsOneWidget);
    });

    testWidgets('renders three reschedule options', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(const RescheduleDialog()));
      await tester.pumpAndSettle();
      await tester.pump(); // Extra pump for EasyLocalization

      // Assert - check for translation keys if translations not loaded
      final todayFinder = find.text('오늘로').evaluate().isEmpty
          ? find.text('reschedule_to_today')
          : find.text('오늘로');
      final tomorrowFinder = find.text('내일로').evaluate().isEmpty
          ? find.text('reschedule_to_tomorrow')
          : find.text('내일로');
      final customFinder = find.text('직접 선택').evaluate().isEmpty
          ? find.text('reschedule_custom')
          : find.text('직접 선택');

      expect(todayFinder, findsOneWidget);
      expect(tomorrowFinder, findsOneWidget);
      expect(customFinder, findsOneWidget);
    });

    testWidgets('renders cancel button', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(const RescheduleDialog()));
      await tester.pumpAndSettle();
      await tester.pump(); // Extra pump for EasyLocalization

      // Assert - check for translation key if translation not loaded
      final cancelFinder = find.text('취소').evaluate().isEmpty
          ? find.text('cancel')
          : find.text('취소');
      expect(cancelFinder, findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('renders Dialog widget', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(const RescheduleDialog()));
      await tester.pumpAndSettle();
      await tester.pump(); // Extra pump for EasyLocalization

      // Assert
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('returns today option when tapped', (WidgetTester tester) async {
      // Arrange
      RescheduleOption? result;

      await tester.pumpWidget(
        EasyLocalization(
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
      );

      // Act
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();
      await tester.pump(); // Extra pump for EasyLocalization

      // Try both Korean and English key
      final todayButton = find.text('오늘로').evaluate().isNotEmpty
          ? find.text('오늘로')
          : find.text('reschedule_to_today');
      await tester.tap(todayButton);
      await tester.pumpAndSettle();

      // Assert
      expect(result, RescheduleOption.today);
    });

    testWidgets('returns tomorrow option when tapped', (WidgetTester tester) async {
      // Arrange
      RescheduleOption? result;

      await tester.pumpWidget(
        EasyLocalization(
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
      );

      // Act
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();
      await tester.pump(); // Extra pump for EasyLocalization

      // Try both Korean and English key
      final tomorrowButton = find.text('내일로').evaluate().isNotEmpty
          ? find.text('내일로')
          : find.text('reschedule_to_tomorrow');
      await tester.tap(tomorrowButton);
      await tester.pumpAndSettle();

      // Assert
      expect(result, RescheduleOption.tomorrow);
    });

    testWidgets('returns custom option when tapped', (WidgetTester tester) async {
      // Arrange
      RescheduleOption? result;

      await tester.pumpWidget(
        EasyLocalization(
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
      );

      // Act
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();
      await tester.pump(); // Extra pump for EasyLocalization

      // Try both Korean and English key
      final customButton = find.text('직접 선택').evaluate().isNotEmpty
          ? find.text('직접 선택')
          : find.text('reschedule_custom');
      await tester.tap(customButton);
      await tester.pumpAndSettle();

      // Assert
      expect(result, RescheduleOption.custom);
    });

    testWidgets('returns null when cancel button tapped', (WidgetTester tester) async {
      // Arrange
      RescheduleOption? result = RescheduleOption.today; // Start with non-null

      await tester.pumpWidget(
        EasyLocalization(
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
      );

      // Act
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();
      await tester.pump(); // Extra pump for EasyLocalization

      // Try both Korean and English key
      final cancelButton = find.text('취소').evaluate().isNotEmpty
          ? find.text('취소')
          : find.text('cancel');
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      // Assert
      expect(result, null);
    });

    testWidgets('renders all option icons', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(const RescheduleDialog()));
      await tester.pumpAndSettle();
      await tester.pump(); // Extra pump for EasyLocalization

      // Assert - verify InkWell widgets for options
      final inkWells = tester.widgetList<InkWell>(find.byType(InkWell));
      expect(inkWells.length, greaterThanOrEqualTo(3)); // At least 3 options
    });

    testWidgets('renders chevron icons for each option', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(const RescheduleDialog()));
      await tester.pumpAndSettle();
      await tester.pump(); // Extra pump for EasyLocalization

      // Assert - verify Icon widgets (title icon + 3 option icons + 3 chevrons = 7 icons total)
      final icons = tester.widgetList<Icon>(find.byType(Icon));
      expect(icons.length, greaterThanOrEqualTo(7));
    });
  });
}
