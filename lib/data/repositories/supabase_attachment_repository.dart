import 'package:fpdart/fpdart.dart';
import 'package:todo_app/core/errors/failures.dart';
import 'package:todo_app/data/datasources/remote/supabase_attachment_datasource.dart';
import 'package:todo_app/domain/entities/attachment.dart';
import 'package:todo_app/domain/repositories/attachment_repository.dart';

class SupabaseAttachmentRepository implements AttachmentRepository {
  final SupabaseAttachmentDataSource dataSource;

  SupabaseAttachmentRepository(this.dataSource);

  @override
  Future<Either<Failure, List<Attachment>>> getAttachmentsByTodoId(
      int todoId) async {
    try {
      final attachments = await dataSource.getAttachmentsByTodoId(todoId);
      return Right(attachments);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Attachment>> getAttachmentById(int id) async {
    try {
      final attachment = await dataSource.getAttachmentById(id);
      return Right(attachment);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> createAttachment({
    required int todoId,
    required String fileName,
    required String filePath,
    required int fileSize,
    required String mimeType,
    required String storagePath,
  }) async {
    try {
      // User ID will be set by provider
      final id = await dataSource.createAttachment(
        todoId: todoId,
        userId: '', // Will be set by provider
        fileName: fileName,
        filePath: filePath,
        fileSize: fileSize,
        mimeType: mimeType,
        storagePath: storagePath,
      );
      return Right(id);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteAttachment(int id) async {
    try {
      await dataSource.deleteAttachment(id);
      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteAttachmentsByTodoId(int todoId) async {
    try {
      await dataSource.deleteAttachmentsByTodoId(todoId);
      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
