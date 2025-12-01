import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';
import 'package:todo_app/core/errors/failures.dart';
import 'package:todo_app/data/datasources/local/app_database.dart';
import 'package:todo_app/domain/entities/attachment.dart' as entity;
import 'package:todo_app/domain/repositories/attachment_repository.dart';

/// Local implementation of [AttachmentRepository] using Drift database.
///
/// This repository handles attachment metadata storage in the local database.
/// The actual file content is stored on the filesystem or cloud storage.
///
/// Features:
/// - Store attachment metadata (filename, size, mime type)
/// - Associate attachments with todos
/// - Delete attachments individually or by todo
///
/// Note: This implementation stores metadata only. File upload/download
/// should be handled separately through storage services.
///
/// See also:
/// - [AttachmentRepository] for the interface contract
/// - [SupabaseAttachmentRepository] for cloud implementation
/// - [Attachment] for the attachment entity
class AttachmentRepositoryImpl implements AttachmentRepository {
  /// The local Drift database.
  final AppDatabase database;

  /// Creates an [AttachmentRepositoryImpl] with the given [database].
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
