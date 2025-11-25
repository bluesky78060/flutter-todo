import 'package:fpdart/fpdart.dart';
import 'package:todo_app/core/errors/failures.dart';
import 'package:todo_app/domain/entities/attachment.dart';

abstract class AttachmentRepository {
  Future<Either<Failure, List<Attachment>>> getAttachmentsByTodoId(int todoId);
  Future<Either<Failure, Attachment>> getAttachmentById(int id);
  Future<Either<Failure, int>> createAttachment({
    required int todoId,
    required String fileName,
    required String filePath,
    required int fileSize,
    required String mimeType,
    required String storagePath,
  });
  Future<Either<Failure, Unit>> deleteAttachment(int id);
  Future<Either<Failure, Unit>> deleteAttachmentsByTodoId(int todoId);
}
