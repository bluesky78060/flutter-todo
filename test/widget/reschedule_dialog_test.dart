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

      await tester.tap(find.text('오늘로'));
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

      await tester.tap(find.text('내일로'));
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

      await tester.tap(find.text('직접 선택'));
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
