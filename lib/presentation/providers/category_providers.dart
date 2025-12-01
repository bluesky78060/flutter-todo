/// Category state management providers using Riverpod.
///
/// Provides category data access, listing, and CRUD operations
/// for organizing todos into groups.
///
/// Providers:
/// - [categoryRepositoryProvider]: Repository for category persistence
/// - [categoriesProvider]: List of all user categories
/// - [categoryDetailProvider]: Single category by ID
/// - [categoryActionsProvider]: CRUD operations for categories
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_app/data/repositories/category_repository_impl.dart';
import 'package:todo_app/domain/entities/category.dart';
import 'package:todo_app/domain/repositories/category_repository.dart';
import 'package:todo_app/presentation/providers/database_provider.dart';

/// Provides the category repository for persistence operations.
///
/// Uses local-first sync strategy with Supabase.
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final database = ref.watch(localDatabaseProvider);
  final supabaseClient = Supabase.instance.client;
  return CategoryRepositoryImpl(database, supabaseClient);
});

/// Provides the list of all categories for the current user.
///
/// Returns an empty list if retrieval fails.
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repository = ref.watch(categoryRepositoryProvider);
  final result = await repository.getCategories();
  return result.fold(
    (failure) => throw Exception(failure),
    (categories) => categories,
  );
});

/// Provides a single category by its ID.
///
/// Uses family modifier to cache category lookups by ID.
final categoryDetailProvider =
    FutureProvider.family<Category, int>((ref, id) async {
  final repository = ref.watch(categoryRepositoryProvider);
  final result = await repository.getCategoryById(id);
  return result.fold(
    (failure) => throw Exception(failure),
    (category) => category,
  );
});

/// Action class for category CRUD operations.
///
/// Provides methods to create, update, and delete categories,
/// automatically invalidating related providers on success.
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

/// Provides the [CategoryActions] instance for category operations.
final categoryActionsProvider = Provider((ref) => CategoryActions(ref));
