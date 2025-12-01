import 'package:fpdart/fpdart.dart';
import 'package:todo_app/core/errors/failures.dart';
import 'package:todo_app/domain/entities/category.dart';
import 'package:todo_app/domain/entities/todo.dart';

/// Abstract repository interface for category operations.
///
/// Defines the contract for category persistence operations that must be
/// implemented by concrete repository classes. Categories are used to
/// organize and group todos by topic, project, or any classification.
///
/// Implementations:
/// - [CategoryRepositoryImpl] for local Drift database operations
/// - [SupabaseCategoryDataSource] for remote Supabase operations
///
/// See also:
/// - [Category] for the entity this repository manages
/// - [Todo] which references categories via [Todo.categoryId]
abstract class CategoryRepository {
  /// Retrieves all categories for the current user.
  ///
  /// Returns [Right] with list of categories on success,
  /// or [Left] with [Failure] on error.
  Future<Either<Failure, List<Category>>> getCategories();

  /// Retrieves a single category by its ID.
  ///
  /// Returns [Right] with the category on success,
  /// or [Left] with [Failure] if not found or on error.
  Future<Either<Failure, Category>> getCategoryById(int id);

  /// Creates a new category with the specified properties.
  ///
  /// Parameters:
  /// - [userId]: The UUID of the user creating the category
  /// - [name]: Display name for the category
  /// - [color]: Hex color code (e.g., "#FF5722")
  /// - [icon]: Optional icon identifier
  ///
  /// Returns [Right] with the new category's ID on success.
  Future<Either<Failure, int>> createCategory(String userId, String name, String color, String? icon);

  /// Updates an existing category with new values.
  ///
  /// [category] contains the updated category entity with modified fields.
  Future<Either<Failure, Unit>> updateCategory(Category category);

  /// Deletes a category by its ID.
  ///
  /// Note: Todos in this category will have their [categoryId] set to null.
  Future<Either<Failure, Unit>> deleteCategory(int id);

  /// Retrieves all todos belonging to a specific category.
  ///
  /// [categoryId] is the ID of the category to filter by.
  Future<Either<Failure, List<Todo>>> getTodosByCategory(int categoryId);
}
