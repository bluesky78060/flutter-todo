import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:todo_app/presentation/providers/todo_providers.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('TodoFilterNotifier', () {
    test('initial state is all', () {
      // Act
      final state = container.read(todoFilterProvider);

      // Assert
      expect(state, TodoFilter.all);
    });

    test('setFilter changes state to pending', () {
      // Arrange
      final notifier = container.read(todoFilterProvider.notifier);

      // Act
      notifier.setFilter(TodoFilter.pending);

      // Assert
      final state = container.read(todoFilterProvider);
      expect(state, TodoFilter.pending);
    });

    test('setFilter changes state to completed', () {
      // Arrange
      final notifier = container.read(todoFilterProvider.notifier);

      // Act
      notifier.setFilter(TodoFilter.completed);

      // Assert
      final state = container.read(todoFilterProvider);
      expect(state, TodoFilter.completed);
    });

    test('setFilter can be called multiple times', () {
      // Arrange
      final notifier = container.read(todoFilterProvider.notifier);

      // Act & Assert
      notifier.setFilter(TodoFilter.pending);
      expect(container.read(todoFilterProvider), TodoFilter.pending);

      notifier.setFilter(TodoFilter.completed);
      expect(container.read(todoFilterProvider), TodoFilter.completed);

      notifier.setFilter(TodoFilter.all);
      expect(container.read(todoFilterProvider), TodoFilter.all);
    });
  });

  group('CategoryFilterNotifier', () {
    test('initial state is null', () {
      // Act
      final state = container.read(categoryFilterProvider);

      // Assert
      expect(state, null);
    });

    test('setCategory changes state to category ID', () {
      // Arrange
      final notifier = container.read(categoryFilterProvider.notifier);

      // Act
      notifier.setCategory(1);

      // Assert
      final state = container.read(categoryFilterProvider);
      expect(state, 1);
    });

    test('setCategory can change to different categories', () {
      // Arrange
      final notifier = container.read(categoryFilterProvider.notifier);

      // Act & Assert
      notifier.setCategory(1);
      expect(container.read(categoryFilterProvider), 1);

      notifier.setCategory(2);
      expect(container.read(categoryFilterProvider), 2);

      notifier.setCategory(42);
      expect(container.read(categoryFilterProvider), 42);
    });

    test('clearCategory resets state to null', () {
      // Arrange
      final notifier = container.read(categoryFilterProvider.notifier);
      notifier.setCategory(5);
      expect(container.read(categoryFilterProvider), 5);

      // Act
      notifier.clearCategory();

      // Assert
      final state = container.read(categoryFilterProvider);
      expect(state, null);
    });

    test('setCategory and clearCategory can be called multiple times', () {
      // Arrange
      final notifier = container.read(categoryFilterProvider.notifier);

      // Act & Assert
      notifier.setCategory(1);
      expect(container.read(categoryFilterProvider), 1);

      notifier.clearCategory();
      expect(container.read(categoryFilterProvider), null);

      notifier.setCategory(3);
      expect(container.read(categoryFilterProvider), 3);

      notifier.clearCategory();
      expect(container.read(categoryFilterProvider), null);
    });
  });
}
