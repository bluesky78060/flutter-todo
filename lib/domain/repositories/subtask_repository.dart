import 'package:fpdart/fpdart.dart';
import 'package:todo_app/core/errors/failures.dart';
import 'package:todo_app/domain/entities/subtask.dart';

abstract class SubtaskRepository {
  Future<Either<Failure, List<Subtask>>> getSubtasksByTodoId(int todoId);
  Future<Either<Failure, Subtask>> getSubtaskById(int id);
  Future<Either<Failure, int>> createSubtask(Subtask subtask);
  Future<Either<Failure, Unit>> updateSubtask(Subtask subtask);
  Future<Either<Failure, Unit>> deleteSubtask(int id);
  Future<Either<Failure, Unit>> toggleSubtaskCompletion(int id);
  Future<Either<Failure, Map<String, int>>> getSubtaskStats(int todoId);
}
