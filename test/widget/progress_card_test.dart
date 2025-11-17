import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/presentation/widgets/progress_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:easy_localization_loader/easy_localization_loader.dart';

void main() {
  group('ProgressCard Widget', () {
    testWidgets('renders completed and total counts', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('ko')],
          path: 'assets/translations',
          fallbackLocale: const Locale('ko'),
          assetLoader: const JsonAssetLoader(),
          child: const MaterialApp(
            home: Scaffold(
              body: ProgressCard(
                completed: 5,
                total: 10,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('5 / 10 완료'), findsOneWidget);
    });

    testWidgets('renders progress label', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('ko')],
          path: 'assets/translations',
          fallbackLocale: const Locale('ko'),
          assetLoader: const JsonAssetLoader(),
          child: const MaterialApp(
            home: Scaffold(
              body: ProgressCard(
                completed: 3,
                total: 7,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('진행률'), findsOneWidget);
    });

    testWidgets('calculates percentage correctly for partial completion', (WidgetTester tester) async {
      // Arrange
      const completed = 3;
      const total = 10;

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressCard(
              completed: completed,
              total: total,
            ),
          ),
        ),
      );

      // Assert
      final progressCard = tester.widget<ProgressCard>(find.byType(ProgressCard));
      expect(progressCard.percentage, 0.3);
    });

    testWidgets('calculates 100% for full completion', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('ko')],
          path: 'assets/translations',
          fallbackLocale: const Locale('ko'),
          assetLoader: const JsonAssetLoader(),
          child: const MaterialApp(
            home: Scaffold(
              body: ProgressCard(
                completed: 10,
                total: 10,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      final progressCard = tester.widget<ProgressCard>(find.byType(ProgressCard));
      expect(progressCard.percentage, 1.0);
      expect(find.text('10 / 10 완료'), findsOneWidget);
    });

    testWidgets('calculates 0% for no completion', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('ko')],
          path: 'assets/translations',
          fallbackLocale: const Locale('ko'),
          assetLoader: const JsonAssetLoader(),
          child: const MaterialApp(
            home: Scaffold(
              body: ProgressCard(
                completed: 0,
                total: 15,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      final progressCard = tester.widget<ProgressCard>(find.byType(ProgressCard));
      expect(progressCard.percentage, 0.0);
      expect(find.text('0 / 15 완료'), findsOneWidget);
    });

    testWidgets('handles zero total correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('ko')],
          path: 'assets/translations',
          fallbackLocale: const Locale('ko'),
          assetLoader: const JsonAssetLoader(),
          child: const MaterialApp(
            home: Scaffold(
              body: ProgressCard(
                completed: 0,
                total: 0,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      final progressCard = tester.widget<ProgressCard>(find.byType(ProgressCard));
      expect(progressCard.percentage, 0.0);
      expect(find.text('0 / 0 완료'), findsOneWidget);
    });

    testWidgets('renders progress bar with correct structure', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressCard(
              completed: 7,
              total: 10,
            ),
          ),
        ),
      );

      // Assert - verify FractionallySizedBox exists (progress bar indicator)
      expect(find.byType(FractionallySizedBox), findsOneWidget);

      final fractionallySizedBox = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );
      expect(fractionallySizedBox.widthFactor, 0.7); // 7/10 = 0.7
    });

    testWidgets('displays different completion ratios correctly', (WidgetTester tester) async {
      // Test various ratios
      final testCases = [
        {'completed': 1, 'total': 4, 'percentage': 0.25},
        {'completed': 2, 'total': 8, 'percentage': 0.25},
        {'completed': 5, 'total': 20, 'percentage': 0.25},
        {'completed': 15, 'total': 20, 'percentage': 0.75},
      ];

      for (final testCase in testCases) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProgressCard(
                completed: testCase['completed'] as int,
                total: testCase['total'] as int,
              ),
            ),
          ),
        );

        final progressCard = tester.widget<ProgressCard>(find.byType(ProgressCard));
        expect(
          progressCard.percentage,
          testCase['percentage'],
          reason: 'Failed for ${testCase['completed']}/${testCase['total']}',
        );

        // Clear widget tree for next iteration
        await tester.pumpWidget(Container());
      }
    });

    testWidgets('renders ClipRRect for rounded progress bar', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressCard(
              completed: 5,
              total: 10,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(ClipRRect), findsOneWidget);

      final clipRRect = tester.widget<ClipRRect>(find.byType(ClipRRect));
      expect((clipRRect.borderRadius as BorderRadius).topLeft.x, 10);
    });

    testWidgets('renders Container with correct decoration', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProgressCard(
              completed: 3,
              total: 10,
            ),
          ),
        ),
      );

      // Assert - verify main Container exists
      final containers = tester.widgetList<Container>(find.byType(Container));
      expect(containers.length, greaterThan(0));
    });
  });
}
