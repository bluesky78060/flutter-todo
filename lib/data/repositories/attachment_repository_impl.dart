import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';
import 'package:todo_app/core/errors/failures.dart';
import 'package:todo_app/data/datasources/local/app_database.dart';
import 'package:todo_app/domain/entities/attachment.dart' as entity;
import 'package:todo_app/domain/repositories/attachment_repository.dart';

class AttachmentRepositoryImpl implements AttachmentRepository {
  final AppDatabase database;

  AttachmentRepositoryImpl(this.database);

  @override
  Future<Either<Failure, List<entity.Attachment>>> getAttachmentsByTodoId(
      int todoId) async {
    try {
      final dbAttachments = await database.getAttachmentsByTodoId(todoId);
      final attachments = dbAttachments.map(_mapToEntity).toList();
      return Right(attachments);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, entity.Attachment>> getAttachmentById(int id) async {
    try {
      final dbAttachment = await database.getAttachmentById(id);
      if (dbAttachment == null) {
        return const Left(DatabaseFailure('Attachment not found'));
      }
      return Right(_mapToEntity(dbAttachment));
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
      final id = await database.insertAttachment(
        AttachmentsCompanion(
          todoId: Value(todoId),
          userId: const Value(''), // Will be set by provider
          fileName: Value(fileName),
          filePath: Value(filePath),
          fileSize: Value(fileSize),
          mimeType: Value(mimeType),
          storagePath: Value(storagePath),
          createdAt: Value(DateTime.now()),
        ),
      );
      return Right(id);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteAttachment(int id) async {
    try {
      await database.deleteAttachment(id);
      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteAttachmentsByTodoId(int todoId) async {
    try {
      await database.deleteAttachmentsByTodoId(todoId);
      return const Right(unit);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  entity.Attachment _mapToEntity(Attachment dbAttachment) {
    return entity.Attachment(
      id: dbAttachment.id,
      todoId: dbAttachment.todoId,
      fileName: dbAttachment.fileName,
      filePath: dbAttachment.filePath,
      fileSize: dbAttachment.fileSize,
      mimeType: dbAttachment.mimeType,
      storagePath: dbAttachment.storagePath,
      createdAt: dbAttachment.createdAt,
    );
  }
}
