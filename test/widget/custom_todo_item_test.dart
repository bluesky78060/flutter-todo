import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/domain/entities/todo.dart';
import 'package:todo_app/presentation/widgets/custom_todo_item.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:easy_localization_loader/easy_localization_loader.dart';

void main() {
  group('CustomTodoItem Widget', () {
    late Todo testTodo;
    late bool toggleCalled;
    late bool deleteCalled;
    late bool tapCalled;

    setUp(() {
      toggleCalled = false;
      deleteCalled = false;
      tapCalled = false;
    });

    testWidgets('renders todo title', (WidgetTester tester) async {
      // Arrange
      testTodo = Todo(
        id: 1,
        title: 'Test Todo',
        description: '',
        isCompleted: false,
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTodoItem(
              todo: testTodo,
              onToggle: () {},
              onDelete: () {},
              onTap: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Test Todo'), findsOneWidget);
    });

    testWidgets('renders todo description when not empty', (WidgetTester tester) async {
      // Arrange
      testTodo = Todo(
        id: 1,
        title: 'Test Todo',
        description: 'Test Description',
        isCompleted: false,
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTodoItem(
              todo: testTodo,
              onToggle: () {},
              onDelete: () {},
              onTap: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Test Description'), findsOneWidget);
    });

    testWidgets('does not render description when empty', (WidgetTester tester) async {
      // Arrange
      testTodo = Todo(
        id: 1,
        title: 'Test Todo',
        description: '',
        isCompleted: false,
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTodoItem(
              todo: testTodo,
              onToggle: () {},
              onDelete: () {},
              onTap: () {},
            ),
          ),
        ),
      );

      // Assert
      // Description should not be rendered when empty
      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      expect(textWidgets.length, 1); // Only title
    });

    testWidgets('shows checkmark icon when todo is completed', (WidgetTester tester) async {
      // Arrange
      testTodo = Todo(
        id: 1,
        title: 'Completed Todo',
        description: '',
        isCompleted: true,
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTodoItem(
              todo: testTodo,
              onToggle: () {},
              onDelete: () {},
              onTap: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('does not show checkmark when todo is not completed', (WidgetTester tester) async {
      // Arrange
      testTodo = Todo(
        id: 1,
        title: 'Pending Todo',
        description: '',
        isCompleted: false,
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTodoItem(
              todo: testTodo,
              onToggle: () {},
              onDelete: () {},
              onTap: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('calls onToggle when checkbox is tapped', (WidgetTester tester) async {
      // Arrange
      testTodo = Todo(
        id: 1,
        title: 'Test Todo',
        description: '',
        isCompleted: false,
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTodoItem(
              todo: testTodo,
              onToggle: () => toggleCalled = true,
              onDelete: () {},
              onTap: () {},
            ),
          ),
        ),
      );

      // Wait for animations to complete
      await tester.pumpAndSettle();

      // Find the checkbox by finding AnimatedContainer (the checkbox itself)
      final checkboxContainers = find.byType(AnimatedContainer);
      // First AnimatedContainer is the outer one (MouseRegion), second is the checkbox
      await tester.tap(checkboxContainers.at(1));
      await tester.pump();

      // Assert
      expect(toggleCalled, true);
    });

    testWidgets('calls onDelete when delete button is tapped', (WidgetTester tester) async {
      // Arrange
      testTodo = Todo(
        id: 1,
        title: 'Test Todo',
        description: '',
        isCompleted: false,
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTodoItem(
              todo: testTodo,
              onToggle: () {},
              onDelete: () => deleteCalled = true,
              onTap: () {},
            ),
          ),
        ),
      );

      // Wait for animations to complete
      await tester.pumpAndSettle();

      // Find the delete IconButton
      final deleteButtonFinder = find.byIcon(Icons.delete_outline);
      await tester.tap(deleteButtonFinder);
      await tester.pump();

      // Assert
      expect(deleteCalled, true);
    });

    testWidgets('calls onTap when item is tapped', (WidgetTester tester) async {
      // Arrange
      testTodo = Todo(
        id: 1,
        title: 'Test Todo',
        description: '',
        isCompleted: false,
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTodoItem(
              todo: testTodo,
              onToggle: () {},
              onDelete: () {},
              onTap: () => tapCalled = true,
            ),
          ),
        ),
      );

      // Wait for animations to complete
      await tester.pumpAndSettle();

      // Tap on the title text (which is inside the InkWell)
      final titleFinder = find.text('Test Todo');
      await tester.tap(titleFinder);
      await tester.pump();

      // Assert
      expect(tapCalled, true);
    });

    testWidgets('renders due date when present', (WidgetTester tester) async {
      // Arrange
      final dueDate = DateTime(2026, 6, 15, 14, 30);
      testTodo = Todo(
        id: 1,
        title: 'Test Todo',
        description: '',
        isCompleted: false,
        createdAt: DateTime.now(),
        dueDate: dueDate,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTodoItem(
              todo: testTodo,
              onToggle: () {},
              onDelete: () {},
              onTap: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('2026-06-15 14:30'), findsOneWidget);
    });

    testWidgets('renders notification time when present', (WidgetTester tester) async {
      // Arrange
      final notificationTime = DateTime(2026, 6, 15, 13, 0);
      testTodo = Todo(
        id: 1,
        title: 'Test Todo',
        description: '',
        isCompleted: false,
        createdAt: DateTime.now(),
        notificationTime: notificationTime,
      );

      // Act
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('ko')],
          path: 'assets/translations',
          fallbackLocale: const Locale('ko'),
          assetLoader: const JsonAssetLoader(),
          child: MaterialApp(
            home: Scaffold(
              body: CustomTodoItem(
                todo: testTodo,
                onToggle: () {},
                onDelete: () {},
                onTap: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('알림: 2026-06-15 13:00'), findsOneWidget);
    });

    testWidgets('renders recurrence indicator when recurrence rule is present', (WidgetTester tester) async {
      // Arrange
      testTodo = Todo(
        id: 1,
        title: 'Recurring Todo',
        description: '',
        isCompleted: false,
        createdAt: DateTime.now(),
        recurrenceRule: 'FREQ=DAILY;INTERVAL=1',
      );

      // Act
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('ko')],
          path: 'assets/translations',
          fallbackLocale: const Locale('ko'),
          assetLoader: const JsonAssetLoader(),
          child: MaterialApp(
            home: Scaffold(
              body: CustomTodoItem(
                todo: testTodo,
                onToggle: () {},
                onDelete: () {},
                onTap: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('반복'), findsOneWidget);
    });

    testWidgets('applies line-through decoration when todo is completed', (WidgetTester tester) async {
      // Arrange
      testTodo = Todo(
        id: 1,
        title: 'Completed Todo',
        description: 'Completed Description',
        isCompleted: true,
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTodoItem(
              todo: testTodo,
              onToggle: () {},
              onDelete: () {},
              onTap: () {},
            ),
          ),
        ),
      );

      // Assert - find Text widgets with line-through decoration
      final titleText = tester.widget<Text>(find.text('Completed Todo'));
      expect(titleText.style?.decoration, TextDecoration.lineThrough);

      final descText = tester.widget<Text>(find.text('Completed Description'));
      expect(descText.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('does not apply line-through when todo is not completed', (WidgetTester tester) async {
      // Arrange
      testTodo = Todo(
        id: 1,
        title: 'Pending Todo',
        description: 'Pending Description',
        isCompleted: false,
        createdAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTodoItem(
              todo: testTodo,
              onToggle: () {},
              onDelete: () {},
              onTap: () {},
            ),
          ),
        ),
      );

      // Assert
      final titleText = tester.widget<Text>(find.text('Pending Todo'));
      expect(titleText.style?.decoration, null);

      final descText = tester.widget<Text>(find.text('Pending Description'));
      expect(descText.style?.decoration, null);
    });
  });
}
