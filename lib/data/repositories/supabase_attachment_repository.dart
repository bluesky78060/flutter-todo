import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_app/core/errors/failures.dart';
import 'package:todo_app/data/datasources/remote/supabase_attachment_datasource.dart';
import 'package:todo_app/domain/entities/attachment.dart';
import 'package:todo_app/domain/repositories/attachment_repository.dart';

/// Remote implementation of [AttachmentRepository] using Supabase.
///
/// This repository handles attachment operations through Supabase,
/// storing metadata in the database and files in Supabase Storage.
///
/// Features:
/// - Cloud persistence of attachment metadata
/// - Integration with Supabase Storage for file storage
/// - User-scoped attachments via RLS policies
///
/// Note: Requires authenticated user. File uploads to Supabase Storage
/// should be done separately before calling [createAttachment].
///
/// See also:
/// - [AttachmentRepository] for the interface contract
/// - [AttachmentRepositoryImpl] for local implementation
/// - [SupabaseAttachmentDataSource] for underlying operations
class SupabaseAttachmentRepository implements AttachmentRepository {
  /// The Supabase data source for attachment operations.
  final SupabaseAttachmentDataSource dataSource;

  /// Creates a [SupabaseAttachmentRepository] with the given [dataSource].
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
      // Get current user ID from Supabase
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        return const Left(AuthFailure('User not authenticated'));
      }

      final id = await dataSource.createAttachment(
        todoId: todoId,
        userId: userId,
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
