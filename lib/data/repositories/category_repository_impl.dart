import 'package:drift/drift.dart' as drift;
import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_app/core/errors/failures.dart';
import 'package:todo_app/core/utils/app_logger.dart';
import 'package:todo_app/data/datasources/local/app_database.dart';
import 'package:todo_app/data/datasources/remote/supabase_category_datasource.dart';
import 'package:todo_app/domain/entities/category.dart' as entity;
import 'package:todo_app/domain/entities/todo.dart' as entity;
import 'package:todo_app/domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final AppDatabase database;
  final SupabaseCategoryDataSource? supabaseDataSource;

  CategoryRepositoryImpl(this.database, [SupabaseClient? supabaseClient])
      : supabaseDataSource = supabaseClient != null
            ? SupabaseCategoryDataSource(supabaseClient)
            : null;

  @override
  Future<Either<Failure, List<entity.Category>>> getCategories() async {
    try {
      // Try to sync from Supabase first if available and user is authenticated
      if (supabaseDataSource != null) {
        try {
          final supabaseCategories = await supabaseDataSource!.getCategories();

          // Sync Supabase categories to local database
          for (final categoryData in supabaseCategories) {
            final id = categoryData['id'] as int;
            final existingCategory = await database.getCategoryById(id);

            if (existingCategory == null) {
              // Category doesn't exist locally, insert it
              final createdAtString = categoryData['created_at'] as String;
              final createdAtParsed = DateTime.parse(createdAtString);

              await database.insertCategoryWithId(
                CategoriesCompanion.insert(
                  id: drift.Value(id),
                  userId: categoryData['user_id'] as String,
                  name: categoryData['name'] as String,
                  color: categoryData['color'] as String,
                  icon: drift.Value(categoryData['icon'] as String?),
                  createdAt: createdAtParsed,
                ),
              );
              logger.d('✅ Synced category from Supabase: ${categoryData['name']} (ID: $id)');
            }
          }
        } catch (e) {
          logger.w('⚠️ Failed to sync categories from Supabase, using local data only', error: e);
          // Continue with local data even if Supabase sync fails
        }
      }

      // Return all categories from local database
      final categories = await database.getAllCategories();
      return Right(_mapCategoriesToEntities(categories));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, entity.Category>> getCategoryById(int id) async {
    try {
      final category = await database.getCategoryById(id);
      if (category == null) {
        return Left(DatabaseFailure('Category not found'));
      }
      return Right(_mapCategoryToEntity(category));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> createCategory(
      String userId, String name, String color, String? icon) async {
    try {
      final createdAt = DateTime.now();

      // Insert into local database first
      final id = await database.insertCategory(
        CategoriesCompanion(
          userId: drift.Value(userId),
          name: drift.Value(name),
          color: drift.Value(color),
          icon: drift.Value(icon),
          createdAt: drift.Value(createdAt),
        ),
      );

      // Sync to Supabase if available
      if (supabaseDataSource != null) {
        try {
          await supabaseDataSource!.syncCategory(
            localId: id,
            userId: userId,
            name: name,
            color: color,
            icon: icon,
            createdAt: createdAt,
          );
        } catch (e) {
          AppLogger.warning('⚠️ Failed to sync category to Supabase, will retry later', error: e);
          // Don't fail the operation if Supabase sync fails
          // The category is still saved locally
        }
      }

      return Right(id);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateCategory(
      entity.Category category) async {
    try {
      final dbCategory = Category(
        id: category.id,
        userId: category.userId,
        name: category.name,
        color: category.color,
        icon: category.icon,
        createdAt: category.createdAt,
      );
      await database.updateCategory(dbCategory);
      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteCategory(int id) async {
    try {
      await database.deleteCategory(id);
      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<entity.Todo>>> getTodosByCategory(
      int categoryId) async {
    try {
      final todos = await database.getTodosByCategory(categoryId);
      return Right(_mapTodosToEntities(todos));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  // Mappers
  List<entity.Category> _mapCategoriesToEntities(List<Category> categories) {
    return categories.map(_mapCategoryToEntity).toList();
  }

  entity.Category _mapCategoryToEntity(Category category) {
    return entity.Category(
      id: category.id,
      userId: category.userId,
      name: category.name,
      color: category.color,
      icon: category.icon,
      createdAt: category.createdAt,
    );
  }

  List<entity.Todo> _mapTodosToEntities(List<Todo> todos) {
    return todos.map(_mapTodoToEntity).toList();
  }

  entity.Todo _mapTodoToEntity(Todo todo) {
    return entity.Todo(
      id: todo.id,
      title: todo.title,
      description: todo.description,
      isCompleted: todo.isCompleted,
      createdAt: todo.createdAt,
      completedAt: todo.completedAt,
      dueDate: todo.dueDate,
      notificationTime: todo.notificationTime,
    );
  }
}
