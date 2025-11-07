import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/data/repositories/category_repository_impl.dart';
import 'package:todo_app/domain/entities/category.dart';
import 'package:todo_app/domain/repositories/category_repository.dart';
import 'package:todo_app/presentation/providers/database_provider.dart';

// Category Repository Provider
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final database = ref.watch(localDatabaseProvider);
  return CategoryRepositoryImpl(database);
});

// Categories List Provider
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repository = ref.watch(categoryRepositoryProvider);
  final result = await repository.getCategories();
  return result.fold(
    (failure) => throw Exception(failure),
    (categories) => categories,
  );
});

// Category Detail Provider
final categoryDetailProvider =
    FutureProvider.family<Category, int>((ref, id) async {
  final repository = ref.watch(categoryRepositoryProvider);
  final result = await repository.getCategoryById(id);
  return result.fold(
    (failure) => throw Exception(failure),
    (category) => category,
  );
});

// Category actions
class CategoryActions {
  final Ref ref;
  CategoryActions(this.ref);

  Future<void> createCategory(
    String userId,
    String name,
    String color,
    String? icon,
  ) async {
    final repository = ref.read(categoryRepositoryProvider);
    final result = await repository.createCategory(userId, name, color, icon);
    result.fold(
      (failure) => throw Exception(failure),
      (_) => ref.invalidate(categoriesProvider),
    );
  }

  Future<void> updateCategory(Category category) async {
    final repository = ref.read(categoryRepositoryProvider);
    final result = await repository.updateCategory(category);
    result.fold(
      (failure) => throw Exception(failure),
      (_) {
        ref.invalidate(categoriesProvider);
        ref.invalidate(categoryDetailProvider(category.id));
      },
    );
  }

  Future<void> deleteCategory(int id) async {
    final repository = ref.read(categoryRepositoryProvider);
    final result = await repository.deleteCategory(id);
    result.fold(
      (failure) => throw Exception(failure),
      (_) => ref.invalidate(categoriesProvider),
    );
  }
}

final categoryActionsProvider = Provider((ref) => CategoryActions(ref));
