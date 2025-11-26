import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:todo_app/core/errors/failures.dart';
import 'package:todo_app/data/datasources/local/app_database.dart';
import 'package:todo_app/data/repositories/todo_repository_impl.dart';
import 'package:todo_app/domain/entities/todo.dart' as entity;

import 'todo_repository_impl_test.mocks.dart';

@GenerateMocks([AppDatabase])
void main() {
  late TodoRepositoryImpl repository;
  late MockAppDatabase mockDatabase;

  setUp(() {
    mockDatabase = MockAppDatabase();
    repository = TodoRepositoryImpl(mockDatabase);

    // Provide dummy values for fpdart's Either type
    provideDummy<Either<Failure, List<entity.Todo>>>(right(<entity.Todo>[]));
    provideDummy<Either<Failure, entity.Todo>>(
      right(
        entity.Todo(
          id: 1,
          title: 'Test',
          description: 'Test',
          isCompleted: false,
          createdAt: DateTime.now(),
        ),
      ),
    );
    provideDummy<Either<Failure, int>>(right(1));
    provideDummy<Either<Failure, Unit>>(right(unit));
  });

  group('TodoRepositoryImpl', () {
    group('getTodos', () {
      test('returns list of todos from database', () async {
        // Arrange
        final now = DateTime.utc(2026, 6, 1, 10, 0);
        final dbTodos = [
          Todo(
            id: 1,
            title: 'Test Todo 1',
            description: 'Description 1',
            isCompleted: false,
            categoryId: null,
            createdAt: now,
            completedAt: null,
            dueDate: null,
            notificationTime: null,
            recurrenceRule: null,
            parentRecurringTodoId: null,
            snoozeCount: 0,
            position: 0,
          ),
          Todo(
            id: 2,
            title: 'Test Todo 2',
            description: 'Description 2',
            isCompleted: true,
            categoryId: 1,
            createdAt: now,
            completedAt: now.add(const Duration(hours: 1)),
            dueDate: now.add(const Duration(days: 1)),
            notificationTime: null,
            recurrenceRule: null,
            parentRecurringTodoId: null,
            snoozeCount: 0,
            position: 1,
          ),
        ];

        when(mockDatabase.getAllTodos()).thenAnswer((_) async => dbTodos);

        // Act
        final result = await repository.getTodos();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (todos) {
            expect(todos.length, 2);
            expect(todos[0].title, 'Test Todo 1');
            expect(todos[0].isCompleted, false);
            expect(todos[1].title, 'Test Todo 2');
            expect(todos[1].isCompleted, true);
            expect(todos[1].categoryId, 1);
          },
        );

        verify(mockDatabase.getAllTodos()).called(1);
      });

      test('returns empty list when no todos', () async {
        // Arrange
        when(mockDatabase.getAllTodos()).thenAnswer((_) async => []);

        // Act
        final result = await repository.getTodos();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (todos) {
            expect(todos, isEmpty);
          },
        );

        verify(mockDatabase.getAllTodos()).called(1);
      });

      test('returns DatabaseFailure on error', () async {
        // Arrange
        when(mockDatabase.getAllTodos())
            .thenThrow(Exception('Database error'));

        // Act
        final result = await repository.getTodos();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<DatabaseFailure>());
            expect((failure as DatabaseFailure).message, contains('Database error'));
          },
          (todos) => fail('Should return Left'),
        );

        verify(mockDatabase.getAllTodos()).called(1);
      });
    });

    group('getFilteredTodos', () {
      test('returns filtered todos for "all" filter', () async {
        // Arrange
        final now = DateTime.utc(2026, 6, 1, 10, 0);
        final dbTodos = [
          Todo(
            id: 1,
            title: 'Test Todo',
            description: '',
            isCompleted: false,
            categoryId: null,
            createdAt: now,
            completedAt: null,
            dueDate: null,
            notificationTime: null,
            recurrenceRule: null,
            parentRecurringTodoId: null,
            snoozeCount: 0,
            position: 0,
          ),
        ];

        when(mockDatabase.getFilteredTodos('all'))
            .thenAnswer((_) async => dbTodos);

        // Act
        final result = await repository.getFilteredTodos('all');

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (todos) {
            expect(todos.length, 1);
          },
        );

        verify(mockDatabase.getFilteredTodos('all')).called(1);
      });

      test('returns DatabaseFailure on error', () async {
        // Arrange
        when(mockDatabase.getFilteredTodos(any))
            .thenThrow(Exception('Filter error'));

        // Act
        final result = await repository.getFilteredTodos('completed');

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<DatabaseFailure>());
          },
          (todos) => fail('Should return Left'),
        );
      });
    });

    group('getTodoById', () {
      test('returns todo when found', () async {
        // Arrange
        final now = DateTime.utc(2026, 6, 1, 10, 0);
        final dbTodo = Todo(
          id: 1,
          title: 'Test Todo',
          description: 'Description',
          isCompleted: false,
          categoryId: 1,
          createdAt: now,
          completedAt: null,
          dueDate: now.add(const Duration(days: 1)),
          notificationTime: null,
          recurrenceRule: null,
          parentRecurringTodoId: null,
          snoozeCount: 0,
          position: 0,
        );

        when(mockDatabase.getTodoById(1)).thenAnswer((_) async => dbTodo);

        // Act
        final result = await repository.getTodoById(1);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (todo) {
            expect(todo.id, 1);
            expect(todo.title, 'Test Todo');
            expect(todo.categoryId, 1);
          },
        );

        verify(mockDatabase.getTodoById(1)).called(1);
      });

      test('returns DatabaseFailure when todo not found', () async {
        // Arrange
        when(mockDatabase.getTodoById(999)).thenAnswer((_) async => null);

        // Act
        final result = await repository.getTodoById(999);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<DatabaseFailure>());
            expect((failure as DatabaseFailure).message, 'Todo not found');
          },
          (todo) => fail('Should return Left'),
        );

        verify(mockDatabase.getTodoById(999)).called(1);
      });

      test('returns DatabaseFailure on database error', () async {
        // Arrange
        when(mockDatabase.getTodoById(any))
            .thenThrow(Exception('Database error'));

        // Act
        final result = await repository.getTodoById(1);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<DatabaseFailure>());
          },
          (todo) => fail('Should return Left'),
        );
      });
    });

    group('createTodo', () {
      test('creates todo and returns id', () async {
        // Arrange
        when(mockDatabase.getMaxTodoPosition()).thenAnswer((_) async => 0);
        when(mockDatabase.insertTodo(any)).thenAnswer((_) async => 42);

        // Act
        final result = await repository.createTodo(
          'New Todo',
          'Description',
          DateTime.utc(2026, 6, 2),
          categoryId: 1,
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (id) {
            expect(id, 42);
          },
        );

        verify(mockDatabase.getMaxTodoPosition()).called(1);
        verify(mockDatabase.insertTodo(any)).called(1);
      });

      test('creates todo with all optional parameters', () async {
        // Arrange
        final dueDate = DateTime.utc(2026, 6, 5);
        final notificationTime = DateTime.utc(2026, 6, 5, 9, 0);

        when(mockDatabase.getMaxTodoPosition()).thenAnswer((_) async => 5);
        when(mockDatabase.insertTodo(any)).thenAnswer((_) async => 10);

        // Act
        final result = await repository.createTodo(
          'Recurring Task',
          'Test description',
          dueDate,
          categoryId: 2,
          notificationTime: notificationTime,
          recurrenceRule: 'FREQ=DAILY;INTERVAL=1',
          parentRecurringTodoId: 5,
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (id) {
            expect(id, 10);
          },
        );

        verify(mockDatabase.getMaxTodoPosition()).called(1);
        verify(mockDatabase.insertTodo(any)).called(1);
      });

      test('returns DatabaseFailure on error', () async {
        // Arrange
        when(mockDatabase.getMaxTodoPosition()).thenAnswer((_) async => 0);
        when(mockDatabase.insertTodo(any))
            .thenThrow(Exception('Insert error'));

        // Act
        final result = await repository.createTodo(
          'New Todo',
          'Description',
          null,
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<DatabaseFailure>());
          },
          (id) => fail('Should return Left'),
        );
      });
    });

    group('updateTodo', () {
      test('updates todo successfully', () async {
        // Arrange
        final now = DateTime.utc(2026, 6, 1, 10, 0);
        final todo = entity.Todo(
          id: 1,
          title: 'Updated Todo',
          description: 'Updated description',
          isCompleted: true,
          categoryId: 2,
          createdAt: now,
          completedAt: now.add(const Duration(hours: 2)),
          dueDate: null,
          notificationTime: null,
          recurrenceRule: null,
          parentRecurringTodoId: null,
        );

        when(mockDatabase.updateTodo(any)).thenAnswer((_) async => true);

        // Act
        final result = await repository.updateTodo(todo);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (unit) {
            expect(unit, equals(unit));
          },
        );

        verify(mockDatabase.updateTodo(any)).called(1);
      });

      test('returns DatabaseFailure on error', () async {
        // Arrange
        final todo = entity.Todo(
          id: 1,
          title: 'Test',
          description: '',
          isCompleted: false,
          createdAt: DateTime.now(),
        );

        when(mockDatabase.updateTodo(any))
            .thenThrow(Exception('Update error'));

        // Act
        final result = await repository.updateTodo(todo);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<DatabaseFailure>());
          },
          (unit) => fail('Should return Left'),
        );
      });
    });

    group('deleteTodo', () {
      test('deletes todo successfully', () async {
        // Arrange
        when(mockDatabase.deleteTodo(1)).thenAnswer((_) async => 1);

        // Act
        final result = await repository.deleteTodo(1);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (unit) {
            expect(unit, equals(unit));
          },
        );

        verify(mockDatabase.deleteTodo(1)).called(1);
      });

      test('returns DatabaseFailure on error', () async {
        // Arrange
        when(mockDatabase.deleteTodo(any))
            .thenThrow(Exception('Delete error'));

        // Act
        final result = await repository.deleteTodo(1);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<DatabaseFailure>());
          },
          (unit) => fail('Should return Left'),
        );
      });
    });

    group('toggleCompletion', () {
      test('toggles todo completion successfully', () async {
        // Arrange
        when(mockDatabase.toggleTodoCompletion(1)).thenAnswer((_) async => true);

        // Act
        final result = await repository.toggleCompletion(1);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (unit) {
            expect(unit, equals(unit));
          },
        );

        verify(mockDatabase.toggleTodoCompletion(1)).called(1);
      });

      test('returns DatabaseFailure on error', () async {
        // Arrange
        when(mockDatabase.toggleTodoCompletion(any))
            .thenThrow(Exception('Toggle error'));

        // Act
        final result = await repository.toggleCompletion(1);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<DatabaseFailure>());
          },
          (unit) => fail('Should return Left'),
        );
      });
    });
  });
}
