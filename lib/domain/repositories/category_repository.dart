import 'package:fpdart/fpdart.dart';
import 'package:todo_app/core/errors/failures.dart';
import 'package:todo_app/domain/entities/category.dart';
import 'package:todo_app/domain/entities/todo.dart';

abstract class CategoryRepository {
  Future<Either<Failure, List<Category>>> getCategories();
  Future<Either<Failure, Category>> getCategoryById(int id);
  Future<Either<Failure, int>> createCategory(String userId, String name, String color, String? icon);
  Future<Either<Failure, Unit>> updateCategory(Category category);
  Future<Either<Failure, Unit>> deleteCategory(int id);
  Future<Either<Failure, List<Todo>>> getTodosByCategory(int categoryId);
}
