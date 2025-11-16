import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:riverpod/riverpod.dart';
import 'package:todo_app/core/errors/failures.dart';
import 'package:todo_app/domain/entities/category.dart';
import 'package:todo_app/domain/repositories/category_repository.dart';
import 'package:todo_app/presentation/providers/category_providers.dart';

import 'category_providers_test.mocks.dart';

@GenerateMocks([CategoryRepository])
void main() {
  late MockCategoryRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockCategoryRepository();

    // Create container with overridden repository
    container = ProviderContainer(
      overrides: [
        categoryRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );

    // Provide dummy values for fpdart's Either type
    provideDummy<Either<Failure, List<Category>>>(right(<Category>[]));
    provideDummy<Either<Failure, Category>>(
      right(
        Category(
          id: 1,
          userId: 'test-user',
          name: 'Test',
          color: '#FF0000',
          icon: null,
          createdAt: DateTime.now(),
        ),
      ),
    );
    provideDummy<Either<Failure, int>>(right(1));
    provideDummy<Either<Failure, Unit>>(right(unit));
  });

  tearDown(() {
    container.dispose();
  });

  group('categoriesProvider', () {
    test('returns list of categories on success', () async {
      // Arrange
      final now = DateTime.utc(2026, 6, 1, 10, 0);
      final categories = [
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

      when(mockRepository.getCategories())
          .thenAnswer((_) async => right(categories));

      // Act
      final state = await container.read(categoriesProvider.future);

      // Assert
      expect(state.length, 2);
      expect(state[0].name, 'Work');
      expect(state[1].name, 'Personal');

      verify(mockRepository.getCategories()).called(1);
    });

    test('returns empty list when no categories', () async {
      // Arrange
      when(mockRepository.getCategories())
          .thenAnswer((_) async => right(<Category>[]));

      // Act
      final state = await container.read(categoriesProvider.future);

      // Assert
      expect(state, isEmpty);
      verify(mockRepository.getCategories()).called(1);
    });
  });

  group('categoryDetailProvider', () {
    test('returns category when found', () async {
      // Arrange
      final now = DateTime.utc(2026, 6, 1, 10, 0);
      final category = Category(
        id: 1,
        userId: 'user-123',
        name: 'Work',
        color: '#FF5733',
        icon: 'work',
        createdAt: now,
      );

      when(mockRepository.getCategoryById(1))
          .thenAnswer((_) async => right(category));

      // Act
      final state = await container.read(categoryDetailProvider(1).future);

      // Assert
      expect(state.id, 1);
      expect(state.name, 'Work');
      expect(state.color, '#FF5733');

      verify(mockRepository.getCategoryById(1)).called(1);
    });
  });

  group('CategoryActions', () {
    test('createCategory creates category and invalidates provider', () async {
      // Arrange
      final actions = container.read(categoryActionsProvider);

      when(mockRepository.createCategory(
        'user-123',
        'Shopping',
        '#00FF00',
        'shopping_cart',
      )).thenAnswer((_) async => right(42));

      when(mockRepository.getCategories())
          .thenAnswer((_) async => right(<Category>[]));

      // Act
      await actions.createCategory('user-123', 'Shopping', '#00FF00', 'shopping_cart');

      // Assert
      verify(mockRepository.createCategory(
        'user-123',
        'Shopping',
        '#00FF00',
        'shopping_cart',
      )).called(1);

      // Verify that categoriesProvider was invalidated by checking it can be read again
      await container.read(categoriesProvider.future);
      verify(mockRepository.getCategories()).called(1);
    });

    test('updateCategory updates category and invalidates providers', () async {
      // Arrange
      final actions = container.read(categoryActionsProvider);
      final now = DateTime.utc(2026, 6, 1, 10, 0);
      final category = Category(
        id: 1,
        userId: 'user-123',
        name: 'Updated Work',
        color: '#FF5733',
        icon: 'briefcase',
        createdAt: now,
      );

      when(mockRepository.updateCategory(any))
          .thenAnswer((_) async => right(unit));

      when(mockRepository.getCategories())
          .thenAnswer((_) async => right(<Category>[]));

      when(mockRepository.getCategoryById(1))
          .thenAnswer((_) async => right(category));

      // Act
      await actions.updateCategory(category);

      // Assert
      verify(mockRepository.updateCategory(category)).called(1);

      // Verify invalidation by reading providers
      await container.read(categoriesProvider.future);
      await container.read(categoryDetailProvider(1).future);

      verify(mockRepository.getCategories()).called(1);
      verify(mockRepository.getCategoryById(1)).called(1);
    });

    test('deleteCategory deletes category and invalidates provider', () async{
      // Arrange
      final actions = container.read(categoryActionsProvider);

      when(mockRepository.deleteCategory(1))
          .thenAnswer((_) async => right(unit));

      when(mockRepository.getCategories())
          .thenAnswer((_) async => right(<Category>[]));

      // Act
      await actions.deleteCategory(1);

      // Assert
      verify(mockRepository.deleteCategory(1)).called(1);

      // Verify invalidation
      await container.read(categoriesProvider.future);
      verify(mockRepository.getCategories()).called(1);
    });
  });
}
