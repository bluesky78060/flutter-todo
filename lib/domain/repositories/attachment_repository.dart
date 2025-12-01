import 'package:fpdart/fpdart.dart';
import 'package:todo_app/core/errors/failures.dart';
import 'package:todo_app/domain/entities/attachment.dart';

/// Abstract repository interface for attachment operations.
///
/// Defines the contract for file attachment metadata persistence.
/// Attachments allow users to associate files (images, documents, PDFs)
/// with their todos. File content is stored separately in cloud storage.
///
/// Implementations:
/// - [AttachmentRepositoryImpl] for local Drift database operations
/// - [SupabaseAttachmentRepository] for remote Supabase operations
///
/// See also:
/// - [Attachment] for the entity this repository manages
/// - [Todo] for the parent entity
abstract class AttachmentRepository {
  /// Retrieves all attachments for a specific todo.
  ///
  /// [todoId] is the ID of the parent todo.
  /// Returns attachments ordered by creation date.
  Future<Either<Failure, List<Attachment>>> getAttachmentsByTodoId(int todoId);

  /// Retrieves a single attachment by its ID.
  ///
  /// Returns [Right] with the attachment on success,
  /// or [Left] with [Failure] if not found.
  Future<Either<Failure, Attachment>> getAttachmentById(int id);

  /// Creates a new attachment metadata record.
  ///
  /// Parameters:
  /// - [todoId]: The ID of the parent todo
  /// - [fileName]: Original filename
  /// - [filePath]: Local file path
  /// - [fileSize]: File size in bytes
  /// - [mimeType]: MIME type (e.g., "image/jpeg", "application/pdf")
  /// - [storagePath]: Path in cloud storage (`{user_id}/{todo_id}/{filename}`)
  ///
  /// Returns [Right] with the new attachment's ID on success.
  Future<Either<Failure, int>> createAttachment({
    required int todoId,
    required String fileName,
    required String filePath,
    required int fileSize,
    required String mimeType,
    required String storagePath,
  });

  /// Deletes an attachment by its ID.
  ///
  /// Note: This only deletes metadata; cloud storage cleanup
  /// should be handled separately.
  Future<Either<Failure, Unit>> deleteAttachment(int id);

  /// Deletes all attachments for a specific todo.
  ///
  /// Used when deleting a todo to clean up associated attachments.
  Future<Either<Failure, Unit>> deleteAttachmentsByTodoId(int todoId);
}
