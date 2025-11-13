import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:todo_app/domain/entities/todo.dart';
import 'package:todo_app/domain/repositories/todo_repository.dart';
import 'package:todo_app/presentation/providers/todo_providers.dart';
import 'package:todo_app/presentation/providers/database_provider.dart';
import 'package:todo_app/core/services/notification_service.dart';
import 'package:todo_app/core/services/recurring_todo_service.dart';
import 'package:fpdart/fpdart.dart';
import 'package:todo_app/core/errors/failures.dart';

import 'todo_integration_test.mocks.dart';

/// Integration tests for Todo CRUD operations
///
/// These tests verify the complete flow of todo operations including:
/// - Creating todos
/// - Updating todos
/// - Deleting todos
/// - Toggling completion
///
/// Note: These are integration tests that test the interaction between
/// TodoActions, TodoRepository, and NotificationService

@GenerateMocks([
  TodoRepository,
  NotificationService,
  RecurringTodoService,
])
void main() {
  late MockTodoRepository mockRepository;
  late MockNotificationService mockNotificationService;
  late MockRecurringTodoService mockRecurringService;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockTodoRepository();
    mockNotificationService = MockNotificationService();
    mockRecurringService = MockRecurringTodoService();

    container = ProviderContainer(
      overrides: [
        todoRepositoryProvider.overrideWithValue(mockRepository),
        notificationServiceProvider.overrideWithValue(mockNotificationService),
        recurringTodoServiceProvider.overrideWithValue(mockRecurringService),
      ],
    );

    // Setup dummy values for Either types
    provideDummy<Either<Failure, int>>(right(1));
    provideDummy<Either<Failure, Unit>>(right(unit));
    provideDummy<Either<Failure, Todo>>(
      right(Todo(
        id: 1,
        title: 'Test',
        description: '',
        isCompleted: false,
        createdAt: DateTime.now(),
      )),
    );
    provideDummy<Either<Failure, List<Todo>>>(right(<Todo>[]));
  });

  tearDown(() {
    container.dispose();
  });

  group('TodoActions Integration Tests', () {
    group('createTodo', () {
      test('creates todo and invalidates provider', () async {
        // Arrange
        final actions = container.read(todoActionsProvider);
        when(mockRepository.createTodo(
          any,
          any,
          any,
          categoryId: anyNamed('categoryId'),
          notificationTime: anyNamed('notificationTime'),
          recurrenceRule: anyNamed('recurrenceRule'),
        )).thenAnswer((_) async => right(42));

        // Act
        await actions.createTodo(
          'Test Todo',
          'Description',
          DateTime.now(),
        );

        // Assert
        verify(mockRepository.createTodo(
          'Test Todo',
          'Description',
          any,
          categoryId: null,
          notificationTime: null,
          recurrenceRule: null,
        )).called(1);
      });

      test('creates todo with notification and schedules it', () async {
        // Arrange
        final actions = container.read(todoActionsProvider);
        final notificationTime = DateTime.now().add(Duration(hours: 1));

        when(mockRepository.createTodo(
          any,
          any,
          any,
          categoryId: anyNamed('categoryId'),
          notificationTime: anyNamed('notificationTime'),
          recurrenceRule: anyNamed('recurrenceRule'),
        )).thenAnswer((_) async => right(42));

        when(mockNotificationService.scheduleNotification(
          id: anyNamed('id'),
          title: anyNamed('title'),
          body: anyNamed('body'),
          scheduledDate: anyNamed('scheduledDate'),
        )).thenAnswer((_) async => Future.value());

        when(mockNotificationService.getPendingNotifications())
            .thenAnswer((_) async => []);

        // Act
        await actions.createTodo(
          'Test Todo',
          'Description',
          DateTime.now(),
          notificationTime: notificationTime,
        );

        // Assert
        verify(mockRepository.createTodo(
          'Test Todo',
          'Description',
          any,
          categoryId: null,
          notificationTime: notificationTime,
          recurrenceRule: null,
        )).called(1);

        verify(mockNotificationService.scheduleNotification(
          id: 42,
          title: '할일 알림',
          body: 'Test Todo',
          scheduledDate: notificationTime,
        )).called(1);
      });

      test('creates recurring todo and generates instances', () async {
        // Arrange
        final actions = container.read(todoActionsProvider);
        const recurrenceRule = 'FREQ=DAILY;INTERVAL=1';
        final testTodo = Todo(
          id: 42,
          title: 'Test Todo',
          description: 'Description',
          isCompleted: false,
          createdAt: DateTime.now(),
          recurrenceRule: recurrenceRule,
        );

        when(mockRepository.createTodo(
          any,
          any,
          any,
          categoryId: anyNamed('categoryId'),
          notificationTime: anyNamed('notificationTime'),
          recurrenceRule: anyNamed('recurrenceRule'),
        )).thenAnswer((_) async => right(42));

        when(mockRepository.getTodoById(42))
            .thenAnswer((_) async => right(testTodo));

        when(mockRecurringService.generateInstancesForNewMaster(any))
            .thenAnswer((_) async => Future.value());

        // Act
        await actions.createTodo(
          'Test Todo',
          'Description',
          DateTime.now(),
          recurrenceRule: recurrenceRule,
        );

        // Assert
        verify(mockRepository.createTodo(
          'Test Todo',
          'Description',
          any,
          categoryId: null,
          notificationTime: null,
          recurrenceRule: recurrenceRule,
        )).called(1);

        verify(mockRepository.getTodoById(42)).called(1);
        verify(mockRecurringService.generateInstancesForNewMaster(testTodo))
            .called(1);
      });
    });

    group('updateTodo', () {
      test('updates regular todo successfully', () async {
        // Arrange
        final actions = container.read(todoActionsProvider);
        final testTodo = Todo(
          id: 1,
          title: 'Updated Title',
          description: 'Updated Description',
          isCompleted: false,
          createdAt: DateTime.now(),
        );

        when(mockRepository.updateTodo(any))
            .thenAnswer((_) async => right(unit));

        // Act
        await actions.updateTodo(testTodo);

        // Assert
        verify(mockRepository.updateTodo(testTodo)).called(1);
      });
    });

    group('deleteTodo', () {
      test('deletes regular todo and cancels notification', () async {
        // Arrange
        final actions = container.read(todoActionsProvider);
        final testTodo = Todo(
          id: 1,
          title: 'Test',
          description: '',
          isCompleted: false,
          createdAt: DateTime.now(),
        );

        when(mockRepository.getTodoById(1))
            .thenAnswer((_) async => right(testTodo));

        when(mockNotificationService.cancelNotification(any))
            .thenAnswer((_) async => Future.value());

        when(mockRepository.deleteTodo(1))
            .thenAnswer((_) async => right(unit));

        // Act
        await actions.deleteTodo(1);

        // Assert
        verify(mockNotificationService.cancelNotification(1)).called(1);
        verify(mockRepository.deleteTodo(1)).called(1);
      });
    });

    group('toggleCompletion', () {
      test('toggles completion for regular todo', () async {
        // Arrange
        final actions = container.read(todoActionsProvider);
        final testTodo = Todo(
          id: 1,
          title: 'Test',
          description: '',
          isCompleted: false,
          createdAt: DateTime.now(),
        );

        when(mockRepository.getTodoById(1))
            .thenAnswer((_) async => right(testTodo));

        when(mockRepository.toggleCompletion(1))
            .thenAnswer((_) async => right(unit));

        // Act
        await actions.toggleCompletion(1);

        // Assert
        verify(mockRepository.getTodoById(1)).called(1);
        verify(mockRepository.toggleCompletion(1)).called(1);
      });

      test('toggles completion for recurring instance and regenerates', () async {
        // Arrange
        final actions = container.read(todoActionsProvider);
        final recurringInstance = Todo(
          id: 2,
          title: 'Recurring Instance',
          description: '',
          isCompleted: false,
          createdAt: DateTime.now(),
          parentRecurringTodoId: 1, // This is a recurring instance
        );

        final masterTodo = Todo(
          id: 1,
          title: 'Master Todo',
          description: '',
          isCompleted: false,
          createdAt: DateTime.now(),
          recurrenceRule: 'FREQ=DAILY;INTERVAL=1',
        );

        when(mockRepository.getTodoById(2))
            .thenAnswer((_) async => right(recurringInstance));

        when(mockRepository.toggleCompletion(2))
            .thenAnswer((_) async => right(unit));

        when(mockRepository.getTodoById(1))
            .thenAnswer((_) async => right(masterTodo));

        when(mockRepository.getTodos())
            .thenAnswer((_) async => right([]));

        when(mockRecurringService.generateInstancesForNewMaster(any))
            .thenAnswer((_) async => Future.value());

        // Act
        await actions.toggleCompletion(2);

        // Assert
        verify(mockRepository.getTodoById(2)).called(1);
        verify(mockRepository.toggleCompletion(2)).called(1);
        verify(mockRepository.getTodoById(1)).called(1);
        verify(mockRepository.getTodos()).called(1);
        verify(mockRecurringService.generateInstancesForNewMaster(masterTodo))
            .called(1);
      });
    });

    group('rescheduleTodo', () {
      test('reschedules todo to new date maintaining time', () async {
        // Arrange
        final actions = container.read(todoActionsProvider);
        final originalDate = DateTime(2025, 11, 13, 14, 30); // 2:30 PM
        final newDate = DateTime(2025, 11, 14); // Next day
        final expectedNewDate = DateTime(2025, 11, 14, 14, 30); // Next day, 2:30 PM

        final testTodo = Todo(
          id: 1,
          title: 'Test',
          description: '',
          isCompleted: false,
          createdAt: DateTime.now(),
          dueDate: originalDate,
        );

        when(mockRepository.getTodoById(1))
            .thenAnswer((_) async => right(testTodo));

        when(mockRepository.updateTodo(any))
            .thenAnswer((_) async => right(unit));

        // Act
        await actions.rescheduleTodo(1, newDate);

        // Assert
        verify(mockRepository.getTodoById(1)).called(1);
        final capturedTodo = verify(mockRepository.updateTodo(captureAny))
            .captured
            .single as Todo;

        expect(capturedTodo.dueDate, expectedNewDate);
      });

      test('reschedules todo with notification', () async {
        // Arrange
        final actions = container.read(todoActionsProvider);
        final originalDate = DateTime(2025, 11, 13, 14, 30);
        final originalNotification = DateTime(2025, 11, 13, 13, 30); // 1 hour before
        final newDate = DateTime(2025, 11, 14);
        final expectedNewNotification = DateTime(2025, 11, 14, 13, 30); // 1 hour before new date

        final testTodo = Todo(
          id: 1,
          title: 'Test',
          description: '',
          isCompleted: false,
          createdAt: DateTime.now(),
          dueDate: originalDate,
          notificationTime: originalNotification,
        );

        when(mockRepository.getTodoById(1))
            .thenAnswer((_) async => right(testTodo));

        when(mockRepository.updateTodo(any))
            .thenAnswer((_) async => right(unit));

        when(mockNotificationService.cancelNotification(any))
            .thenAnswer((_) async => Future.value());

        when(mockNotificationService.scheduleNotification(
          id: anyNamed('id'),
          title: anyNamed('title'),
          body: anyNamed('body'),
          scheduledDate: anyNamed('scheduledDate'),
        )).thenAnswer((_) async => Future.value());

        // Act
        await actions.rescheduleTodo(1, newDate);

        // Assert
        verify(mockNotificationService.cancelNotification(1)).called(1);
        verify(mockNotificationService.scheduleNotification(
          id: 1,
          title: '할일 알림',
          body: 'Test',
          scheduledDate: expectedNewNotification,
        )).called(1);
      });
    });
  });
}
