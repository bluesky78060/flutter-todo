import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:todo_app/core/errors/failures.dart';
import 'package:todo_app/data/datasources/local/app_database.dart';
import 'package:todo_app/data/repositories/category_repository_impl.dart';
import 'package:todo_app/domain/entities/category.dart' as entity;
import 'package:todo_app/domain/entities/todo.dart' as entity;

import 'category_repository_impl_test.mocks.dart';

@GenerateMocks([AppDatabase])
void main() {
  late CategoryRepositoryImpl repository;
  late MockAppDatabase mockDatabase;

  setUp(() {
    mockDatabase = MockAppDatabase();
    repository = CategoryRepositoryImpl(mockDatabase);

    // Provide dummy values for fpdart's Either type
    provideDummy<Either<Failure, List<entity.Category>>>(
        right(<entity.Category>[]));
    provideDummy<Either<Failure, entity.Category>>(
      right(
        entity.Category(
          id: 1,
          userId: 'test-user',
          name: 'Test',
          color: '#FF0000',
          icon: null,
          createdAt: DateTime.now(),
        ),
      ),
    );
    provideDummy<Either<Failure, List<entity.Todo>>>(right(<entity.Todo>[]));
    provideDummy<Either<Failure, int>>(right(1));
    provideDummy<Either<Failure, Unit>>(right(unit));
  });

  group('CategoryRepositoryImpl', () {
    group('getCategories', () {
      test('returns list of categories from database', () async {
        // Arrange
        final now = DateTime.utc(2026, 6, 1, 10, 0);
        final dbCategories = [
          Category(
            id: 1,
            userId: 'user-123',
            name: 'Work',
            color: '#FF5733',
            icon: 'work',
            createdAt: now,
          ),
          Category(
            id: 2,
            userId: 'user-123',
            name: 'Personal',
            color: '#33C3FF',
            icon: 'home',
            createdAt: now.add(const Duration(hours: 1)),
          ),
        ];

        when(mockDatabase.getAllCategories())
            .thenAnswer((_) async => dbCategories);

        // Act
        final result = await repository.getCategories();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (categories) {
            expect(categories.length, 2);
            expect(categories[0].name, 'Work');
            expect(categories[0].color, '#FF5733');
            expect(categories[0].icon, 'work');
            expect(categories[1].name, 'Personal');
            expect(categories[1].userId, 'user-123');
          },
        );

        verify(mockDatabase.getAllCategories()).called(1);
      });

      test('returns empty list when no categories', () async {
        // Arrange
        when(mockDatabase.getAllCategories()).thenAnswer((_) async => []);

        // Act
        final result = await repository.getCategories();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (categories) {
            expect(categories, isEmpty);
          },
        );

        verify(mockDatabase.getAllCategories()).called(1);
      });

      test('returns DatabaseFailure on error', () async {
        // Arrange
        when(mockDatabase.getAllCategories())
            .thenThrow(Exception('Database error'));

        // Act
        final result = await repository.getCategories();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<DatabaseFailure>());
            expect(
                (failure as DatabaseFailure).message, contains('Database error'));
          },
          (categories) => fail('Should return Left'),
        );

        verify(mockDatabase.getAllCategories()).called(1);
      });
    });

    group('getCategoryById', () {
      test('returns category when found', () async {
        // Arrange
        final now = DateTime.utc(2026, 6, 1, 10, 0);
        final dbCategory = Category(
          id: 1,
          userId: 'user-123',
          name: 'Work',
          color: '#FF5733',
          icon: 'work',
          createdAt: now,
        );

        when(mockDatabase.getCategoryById(1))
            .thenAnswer((_) async => dbCategory);

        // Act
        final result = await repository.getCategoryById(1);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (category) {
            expect(category.id, 1);
            expect(category.name, 'Work');
            expect(category.color, '#FF5733');
            expect(category.userId, 'user-123');
          },
        );

        verify(mockDatabase.getCategoryById(1)).called(1);
      });

      test('returns DatabaseFailure when category not found', () async {
        // Arrange
        when(mockDatabase.getCategoryById(999)).thenAnswer((_) async => null);

        // Act
        final result = await repository.getCategoryById(999);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<DatabaseFailure>());
            expect(
                (failure as DatabaseFailure).message, 'Category not found');
          },
          (category) => fail('Should return Left'),
        );

        verify(mockDatabase.getCategoryById(999)).called(1);
      });

      test('returns DatabaseFailure on database error', () async {
        // Arrange
        when(mockDatabase.getCategoryById(any))
            .thenThrow(Exception('Database error'));

        // Act
        final result = await repository.getCategoryById(1);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<DatabaseFailure>());
          },
          (category) => fail('Should return Left'),
        );
      });
    });

    group('createCategory', () {
      test('creates category and returns id', () async {
        // Arrange
        when(mockDatabase.insertCategory(any)).thenAnswer((_) async => 42);

        // Act
        final result = await repository.createCategory(
          'user-123',
          'Shopping',
          '#00FF00',
          'shopping_cart',
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (id) {
            expect(id, 42);
          },
        );

        verify(mockDatabase.insertCategory(any)).called(1);
      });

      test('creates category without icon', () async {
        // Arrange
        when(mockDatabase.insertCategory(any)).thenAnswer((_) async => 10);

        // Act
        final result = await repository.createCategory(
          'user-456',
          'Health',
          '#FF00FF',
          null,
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (id) {
            expect(id, 10);
          },
        );

        verify(mockDatabase.insertCategory(any)).called(1);
      });

      test('returns DatabaseFailure on error', () async {
        // Arrange
        when(mockDatabase.insertCategory(any))
            .thenThrow(Exception('Insert error'));

        // Act
        final result = await repository.createCategory(
          'user-123',
          'Work',
          '#FF0000',
          'work',
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

    group('updateCategory', () {
      test('updates category successfully', () async {
        // Arrange
        final now = DateTime.utc(2026, 6, 1, 10, 0);
        final category = entity.Category(
          id: 1,
          userId: 'user-123',
          name: 'Updated Work',
          color: '#FF5733',
          icon: 'briefcase',
          createdAt: now,
        );

        when(mockDatabase.updateCategory(any)).thenAnswer((_) async => true);

        // Act
        final result = await repository.updateCategory(category);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (unit) {
            expect(unit, equals(unit));
          },
        );

        verify(mockDatabase.updateCategory(any)).called(1);
      });

      test('returns DatabaseFailure on error', () async {
        // Arrange
        final category = entity.Category(
          id: 1,
          userId: 'user-123',
          name: 'Test',
          color: '#FF0000',
          icon: null,
          createdAt: DateTime.now(),
        );

        when(mockDatabase.updateCategory(any))
            .thenThrow(Exception('Update error'));

        // Act
        final result = await repository.updateCategory(category);

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

    group('deleteCategory', () {
      test('deletes category successfully', () async {
        // Arrange
        when(mockDatabase.deleteCategory(1)).thenAnswer((_) async => 1);

        // Act
        final result = await repository.deleteCategory(1);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (unit) {
            expect(unit, equals(unit));
          },
        );

        verify(mockDatabase.deleteCategory(1)).called(1);
      });

      test('returns DatabaseFailure on error', () async {
        // Arrange
        when(mockDatabase.deleteCategory(any))
            .thenThrow(Exception('Delete error'));

        // Act
        final result = await repository.deleteCategory(1);

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

    group('getTodosByCategory', () {
      test('returns todos for category', () async {
        // Arrange
        final now = DateTime.utc(2026, 6, 1, 10, 0);
        final dbTodos = [
          Todo(
            id: 1,
            title: 'Work Task 1',
            description: 'Description',
            isCompleted: false,
            categoryId: 1,
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
            title: 'Work Task 2',
            description: 'Description',
            isCompleted: true,
            categoryId: 1,
            createdAt: now,
            completedAt: now.add(const Duration(hours: 1)),
            dueDate: null,
            notificationTime: null,
            recurrenceRule: null,
            parentRecurringTodoId: null,
            snoozeCount: 0,
            position: 1,
          ),
        ];

        when(mockDatabase.getTodosByCategory(1))
            .thenAnswer((_) async => dbTodos);

        // Act
        final result = await repository.getTodosByCategory(1);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (todos) {
            expect(todos.length, 2);
            expect(todos[0].title, 'Work Task 1');
            expect(todos[0].isCompleted, false);
            expect(todos[1].title, 'Work Task 2');
            expect(todos[1].isCompleted, true);
          },
        );

        verify(mockDatabase.getTodosByCategory(1)).called(1);
      });

      test('returns empty list when no todos in category', () async {
        // Arrange
        when(mockDatabase.getTodosByCategory(1)).thenAnswer((_) async => []);

        // Act
        final result = await repository.getTodosByCategory(1);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right'),
          (todos) {
            expect(todos, isEmpty);
          },
        );

        verify(mockDatabase.getTodosByCategory(1)).called(1);
      });

      test('returns DatabaseFailure on error', () async {
        // Arrange
        when(mockDatabase.getTodosByCategory(any))
            .thenThrow(Exception('Database error'));

        // Act
        final result = await repository.getTodosByCategory(1);

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
  });
}
