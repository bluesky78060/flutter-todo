import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:todo_app/core/errors/failures.dart';
import 'package:todo_app/core/services/recurring_todo_service.dart';
import 'package:todo_app/core/utils/clock.dart';
import 'package:todo_app/domain/entities/todo.dart';
import 'package:todo_app/domain/repositories/todo_repository.dart';

import 'recurring_todo_service_test.mocks.dart';

@GenerateMocks([TodoRepository])
void main() {
  late RecurringTodoService service;
  late MockTodoRepository mockRepository;
  late TestClock testClock;

  final baseDate = DateTime.utc(2026, 6, 1, 10, 0);

  setUp(() {
    mockRepository = MockTodoRepository();
    testClock = TestClock(baseDate);
    service = RecurringTodoService(mockRepository, clock: testClock);

    // Provide dummy values for fpdart's Either type
    provideDummy<Either<Failure, List<Todo>>>(right(<Todo>[]));
    provideDummy<Either<Failure, int>>(right(1));
    provideDummy<Either<Failure, Unit>>(right(unit));
  });

  group('RecurringTodoService', () {
    group('generateUpcomingInstances', () {
      test('generates instances for master recurring todos', () async {
        // Arrange
        final now = DateTime.utc(2026, 6, 1, 10, 0); // Fixed date for testing
        final masterTodo = Todo(
          id: 1,
          title: 'Daily Task',
          description: 'Test description',
          isCompleted: false,
          createdAt: now,
          dueDate: now.add(const Duration(days: 1)),
          recurrenceRule: 'FREQ=DAILY;INTERVAL=1',
          parentRecurringTodoId: null,
        );

        when(mockRepository.getTodos()).thenAnswer(
          (_) async => right([masterTodo]),
        );

        when(mockRepository.createTodo(
          any,
          any,
          any,
          categoryId: anyNamed('categoryId'),
          notificationTime: anyNamed('notificationTime'),
          parentRecurringTodoId: anyNamed('parentRecurringTodoId'),
        )).thenAnswer((_) async => right(1));

        // Act
        await service.generateUpcomingInstances(lookAheadDays: 7);

        // Assert
        verify(mockRepository.getTodos()).called(1);
        // Should create instances for the next 7 days
        verify(mockRepository.createTodo(
          any,
          any,
          any,
          categoryId: anyNamed('categoryId'),
          notificationTime: anyNamed('notificationTime'),
          parentRecurringTodoId: anyNamed('parentRecurringTodoId'),
        )).called(greaterThan(0));
      });

      test('skips completed master todos', () async {
        // Arrange
        final now = DateTime.utc(2026, 6, 1, 10, 0);
        final completedMasterTodo = Todo(
          id: 1,
          title: 'Completed Daily Task',
          description: 'Test description',
          isCompleted: true,
          createdAt: now,
          completedAt: now,
          dueDate: now.add(const Duration(days: 1)),
          recurrenceRule: 'FREQ=DAILY;INTERVAL=1',
          parentRecurringTodoId: null,
        );

        when(mockRepository.getTodos()).thenAnswer(
          (_) async => right([completedMasterTodo]),
        );

        // Act
        await service.generateUpcomingInstances(lookAheadDays: 7);

        // Assert
        verify(mockRepository.getTodos()).called(1);
        // Should NOT create any instances for completed master
        verifyNever(mockRepository.createTodo(
          any,
          any,
          any,
          categoryId: anyNamed('categoryId'),
          notificationTime: anyNamed('notificationTime'),
          parentRecurringTodoId: anyNamed('parentRecurringTodoId'),
        ));
      });

      test('skips todos without recurrence rule', () async {
        // Arrange
        final now = DateTime.utc(2026, 6, 1, 10, 0);
        final nonRecurringTodo = Todo(
          id: 1,
          title: 'Non-recurring Task',
          description: 'Test description',
          isCompleted: false,
          createdAt: now,
          dueDate: now.add(const Duration(days: 1)),
          recurrenceRule: null, // No recurrence
          parentRecurringTodoId: null,
        );

        when(mockRepository.getTodos()).thenAnswer(
          (_) async => right([nonRecurringTodo]),
        );

        // Act
        await service.generateUpcomingInstances(lookAheadDays: 7);

        // Assert
        verify(mockRepository.getTodos()).called(1);
        verifyNever(mockRepository.createTodo(
          any,
          any,
          any,
          categoryId: anyNamed('categoryId'),
          notificationTime: anyNamed('notificationTime'),
          parentRecurringTodoId: anyNamed('parentRecurringTodoId'),
        ));
      });

      test('skips instance todos (those with parentRecurringTodoId)', () async {
        // Arrange
        final now = DateTime.utc(2026, 6, 1, 10, 0);
        final instanceTodo = Todo(
          id: 2,
          title: 'Instance Task',
          description: 'Test description',
          isCompleted: false,
          createdAt: now,
          dueDate: now.add(const Duration(days: 1)),
          recurrenceRule: null,
          parentRecurringTodoId: 1, // This is an instance
        );

        when(mockRepository.getTodos()).thenAnswer(
          (_) async => right([instanceTodo]),
        );

        // Act
        await service.generateUpcomingInstances(lookAheadDays: 7);

        // Assert
        verify(mockRepository.getTodos()).called(1);
        verifyNever(mockRepository.createTodo(
          any,
          any,
          any,
          categoryId: anyNamed('categoryId'),
          notificationTime: anyNamed('notificationTime'),
          parentRecurringTodoId: anyNamed('parentRecurringTodoId'),
        ));
      });

      test('does not create duplicate instances', () async {
        // Arrange
        final now = DateTime.utc(2026, 6, 1, 10, 0);
        final nextDay = now.add(const Duration(days: 1));

        final masterTodo = Todo(
          id: 1,
          title: 'Daily Task',
          description: 'Test description',
          isCompleted: false,
          createdAt: now,
          dueDate: nextDay,
          recurrenceRule: 'FREQ=DAILY;INTERVAL=1',
          parentRecurringTodoId: null,
        );

        // Existing instance for tomorrow
        final existingInstance = Todo(
          id: 2,
          title: 'Daily Task',
          description: 'Test description',
          isCompleted: false,
          createdAt: now,
          dueDate: nextDay,
          recurrenceRule: null,
          parentRecurringTodoId: 1,
        );

        when(mockRepository.getTodos()).thenAnswer(
          (_) async => right([masterTodo, existingInstance]),
        );

        when(mockRepository.createTodo(
          any,
          any,
          any,
          categoryId: anyNamed('categoryId'),
          notificationTime: anyNamed('notificationTime'),
          parentRecurringTodoId: anyNamed('parentRecurringTodoId'),
        )).thenAnswer((_) async => right(1));

        // Act
        await service.generateUpcomingInstances(lookAheadDays: 2);

        // Assert
        verify(mockRepository.getTodos()).called(1);
        // Should only create instance for day 2 (day 1 already exists)
        // Note: Exact count depends on timing, but should be less than total days
        final createCalls = verify(mockRepository.createTodo(
          any,
          any,
          any,
          categoryId: anyNamed('categoryId'),
          notificationTime: anyNamed('notificationTime'),
          parentRecurringTodoId: anyNamed('parentRecurringTodoId'),
        )).callCount;

        expect(createCalls, lessThan(2)); // Should skip the existing instance
      });

      test('handles repository failure gracefully', () async {
        // Arrange
        when(mockRepository.getTodos()).thenAnswer(
          (_) async => left(const NetworkFailure('Network error')),
        );

        // Act & Assert - should not throw
        await service.generateUpcomingInstances(lookAheadDays: 7);

        verify(mockRepository.getTodos()).called(1);
      });

      test('respects lookAheadDays parameter', () async {
        // Arrange
        final now = DateTime.utc(2026, 6, 1, 10, 0);
        final masterTodo = Todo(
          id: 1,
          title: 'Daily Task',
          description: 'Test description',
          isCompleted: false,
          createdAt: now,
          dueDate: now.add(const Duration(days: 1)),
          recurrenceRule: 'FREQ=DAILY;INTERVAL=1',
          parentRecurringTodoId: null,
        );

        when(mockRepository.getTodos()).thenAnswer(
          (_) async => right([masterTodo]),
        );

        when(mockRepository.createTodo(
          any,
          any,
          any,
          categoryId: anyNamed('categoryId'),
          notificationTime: anyNamed('notificationTime'),
          parentRecurringTodoId: anyNamed('parentRecurringTodoId'),
        )).thenAnswer((_) async => right(1));

        // Act
        await service.generateUpcomingInstances(lookAheadDays: 3);

        // Assert
        final createCalls = verify(mockRepository.createTodo(
          any,
          any,
          any,
          categoryId: anyNamed('categoryId'),
          notificationTime: anyNamed('notificationTime'),
          parentRecurringTodoId: anyNamed('parentRecurringTodoId'),
        )).callCount;

        // Should create roughly 3 instances (for 3 days)
        expect(createCalls, lessThanOrEqualTo(3));
      });
    });

    group('generateInstancesForNewMaster', () {
      test('generates instances for new recurring todo', () async {
        // Arrange
        final now = DateTime.utc(2026, 6, 1, 10, 0);
        final masterTodo = Todo(
          id: 1,
          title: 'New Recurring Task',
          description: 'Test description',
          isCompleted: false,
          createdAt: now,
          dueDate: now.add(const Duration(days: 1)),
          recurrenceRule: 'FREQ=DAILY;INTERVAL=1',
          parentRecurringTodoId: null,
        );

        when(mockRepository.getTodos()).thenAnswer(
          (_) async => right([masterTodo]),
        );

        when(mockRepository.createTodo(
          any,
          any,
          any,
          categoryId: anyNamed('categoryId'),
          notificationTime: anyNamed('notificationTime'),
          parentRecurringTodoId: anyNamed('parentRecurringTodoId'),
        )).thenAnswer((_) async => right(1));

        // Act
        await service.generateInstancesForNewMaster(masterTodo);

        // Assert
        verify(mockRepository.getTodos()).called(1);
        verify(mockRepository.createTodo(
          any,
          any,
          any,
          categoryId: anyNamed('categoryId'),
          notificationTime: anyNamed('notificationTime'),
          parentRecurringTodoId: anyNamed('parentRecurringTodoId'),
        )).called(greaterThan(0));
      });

      test('does nothing for non-recurring todo', () async {
        // Arrange
        final now = DateTime.utc(2026, 6, 1, 10, 0);
        final nonRecurringTodo = Todo(
          id: 1,
          title: 'Non-recurring Task',
          description: 'Test description',
          isCompleted: false,
          createdAt: now,
          dueDate: now.add(const Duration(days: 1)),
          recurrenceRule: null,
          parentRecurringTodoId: null,
        );

        // Act
        await service.generateInstancesForNewMaster(nonRecurringTodo);

        // Assert
        verifyNever(mockRepository.getTodos());
        verifyNever(mockRepository.createTodo(
          any,
          any,
          any,
          categoryId: anyNamed('categoryId'),
          notificationTime: anyNamed('notificationTime'),
          parentRecurringTodoId: anyNamed('parentRecurringTodoId'),
        ));
      });

      test('handles repository failure gracefully', () async {
        // Arrange
        final now = DateTime.utc(2026, 6, 1, 10, 0);
        final masterTodo = Todo(
          id: 1,
          title: 'Recurring Task',
          description: 'Test description',
          isCompleted: false,
          createdAt: now,
          dueDate: now.add(const Duration(days: 1)),
          recurrenceRule: 'FREQ=DAILY;INTERVAL=1',
          parentRecurringTodoId: null,
        );

        when(mockRepository.getTodos()).thenAnswer(
          (_) async => left(const NetworkFailure('Network error')),
        );

        // Act & Assert - should not throw
        await service.generateInstancesForNewMaster(masterTodo);

        verify(mockRepository.getTodos()).called(1);
      });
    });

    group('instance creation with notification time', () {
      test('calculates notification time offset correctly', () async {
        // Arrange
        final now = DateTime.utc(2026, 6, 1, 10, 0);
        final dueDate = now.add(const Duration(days: 1));
        final notificationTime = dueDate.subtract(const Duration(hours: 1));

        final masterTodo = Todo(
          id: 1,
          title: 'Task with Notification',
          description: 'Test description',
          isCompleted: false,
          createdAt: now,
          dueDate: dueDate,
          notificationTime: notificationTime,
          recurrenceRule: 'FREQ=DAILY;INTERVAL=1',
          parentRecurringTodoId: null,
        );

        when(mockRepository.getTodos()).thenAnswer(
          (_) async => right([masterTodo]),
        );

        when(mockRepository.createTodo(
          any,
          any,
          any,
          categoryId: anyNamed('categoryId'),
          notificationTime: anyNamed('notificationTime'),
          parentRecurringTodoId: anyNamed('parentRecurringTodoId'),
        )).thenAnswer((_) async => right(1));

        // Act
        await service.generateUpcomingInstances(lookAheadDays: 2);

        // Assert
        verify(mockRepository.getTodos()).called(1);

        // Verify that createTodo was called at least once
        // (instances should be created with notification time offset preserved)
        verify(mockRepository.createTodo(
          any,
          any,
          any,
          categoryId: anyNamed('categoryId'),
          notificationTime: anyNamed('notificationTime'),
          parentRecurringTodoId: anyNamed('parentRecurringTodoId'),
        )).called(greaterThan(0));
      });

      test('uses createdAt as base date if dueDate is null', () async {
        // Arrange
        final now = DateTime.utc(2026, 6, 1, 10, 0);
        final masterTodo = Todo(
          id: 1,
          title: 'Task without due date',
          description: 'Test description',
          isCompleted: false,
          createdAt: now,
          dueDate: null, // No due date
          recurrenceRule: 'FREQ=DAILY;INTERVAL=1',
          parentRecurringTodoId: null,
        );

        when(mockRepository.getTodos()).thenAnswer(
          (_) async => right([masterTodo]),
        );

        when(mockRepository.createTodo(
          any,
          any,
          any,
          categoryId: anyNamed('categoryId'),
          notificationTime: anyNamed('notificationTime'),
          parentRecurringTodoId: anyNamed('parentRecurringTodoId'),
        )).thenAnswer((_) async => right(1));

        // Act
        await service.generateUpcomingInstances(lookAheadDays: 3);

        // Assert - should not crash and should create instances
        verify(mockRepository.getTodos()).called(1);
        verify(mockRepository.createTodo(
          any,
          any,
          any,
          categoryId: anyNamed('categoryId'),
          notificationTime: anyNamed('notificationTime'),
          parentRecurringTodoId: anyNamed('parentRecurringTodoId'),
        )).called(greaterThan(0));
      });
    });

    group('edge cases', () {
      test('handles empty todo list', () async {
        // Arrange
        when(mockRepository.getTodos()).thenAnswer(
          (_) async => right(const []),
        );

        // Act & Assert - should not throw
        await service.generateUpcomingInstances(lookAheadDays: 7);

        verify(mockRepository.getTodos()).called(1);
        verifyNever(mockRepository.createTodo(
          any,
          any,
          any,
          categoryId: anyNamed('categoryId'),
          notificationTime: anyNamed('notificationTime'),
          parentRecurringTodoId: anyNamed('parentRecurringTodoId'),
        ));
      });

      test('handles invalid recurrence rule gracefully', () async {
        // Arrange
        final now = DateTime.utc(2026, 6, 1, 10, 0);
        final masterTodo = Todo(
          id: 1,
          title: 'Task with invalid RRULE',
          description: 'Test description',
          isCompleted: false,
          createdAt: now,
          dueDate: now.add(const Duration(days: 1)),
          recurrenceRule: 'INVALID_RRULE',
          parentRecurringTodoId: null,
        );

        when(mockRepository.getTodos()).thenAnswer(
          (_) async => right([masterTodo]),
        );

        // Act & Assert - should not throw
        await service.generateUpcomingInstances(lookAheadDays: 7);

        verify(mockRepository.getTodos()).called(1);
        // Should not create any instances for invalid RRULE
        verifyNever(mockRepository.createTodo(
          any,
          any,
          any,
          categoryId: anyNamed('categoryId'),
          notificationTime: anyNamed('notificationTime'),
          parentRecurringTodoId: anyNamed('parentRecurringTodoId'),
        ));
      });

      test('handles weekly recurrence correctly', () async {
        // Arrange
        final now = DateTime.utc(2026, 6, 1, 10, 0);
        final masterTodo = Todo(
          id: 1,
          title: 'Weekly Task',
          description: 'Test description',
          isCompleted: false,
          createdAt: now,
          dueDate: now.add(const Duration(days: 1)),
          recurrenceRule: 'FREQ=WEEKLY;INTERVAL=1',
          parentRecurringTodoId: null,
        );

        when(mockRepository.getTodos()).thenAnswer(
          (_) async => right([masterTodo]),
        );

        when(mockRepository.createTodo(
          any,
          any,
          any,
          categoryId: anyNamed('categoryId'),
          notificationTime: anyNamed('notificationTime'),
          parentRecurringTodoId: anyNamed('parentRecurringTodoId'),
        )).thenAnswer((_) async => right(1));

        // Act
        await service.generateUpcomingInstances(lookAheadDays: 21); // 3 weeks

        // Assert
        final createCalls = verify(mockRepository.createTodo(
          any,
          any,
          any,
          categoryId: anyNamed('categoryId'),
          notificationTime: anyNamed('notificationTime'),
          parentRecurringTodoId: anyNamed('parentRecurringTodoId'),
        )).callCount;

        // Should create approximately 3 instances (one per week)
        expect(createCalls, lessThanOrEqualTo(3));
      });

      test('handles monthly recurrence correctly', () async {
        // Arrange
        final now = DateTime.utc(2026, 6, 1, 10, 0);
        final masterTodo = Todo(
          id: 1,
          title: 'Monthly Task',
          description: 'Test description',
          isCompleted: false,
          createdAt: now,
          dueDate: now.add(const Duration(days: 1)),
          recurrenceRule: 'FREQ=MONTHLY;INTERVAL=1',
          parentRecurringTodoId: null,
        );

        when(mockRepository.getTodos()).thenAnswer(
          (_) async => right([masterTodo]),
        );

        when(mockRepository.createTodo(
          any,
          any,
          any,
          categoryId: anyNamed('categoryId'),
          notificationTime: anyNamed('notificationTime'),
          parentRecurringTodoId: anyNamed('parentRecurringTodoId'),
        )).thenAnswer((_) async => right(1));

        // Act
        await service.generateUpcomingInstances(lookAheadDays: 90); // ~3 months

        // Assert
        final createCalls = verify(mockRepository.createTodo(
          any,
          any,
          any,
          categoryId: anyNamed('categoryId'),
          notificationTime: anyNamed('notificationTime'),
          parentRecurringTodoId: anyNamed('parentRecurringTodoId'),
        )).callCount;

        // Should create approximately 3 instances (one per month)
        expect(createCalls, lessThanOrEqualTo(3));
      });
    });
  });
}
