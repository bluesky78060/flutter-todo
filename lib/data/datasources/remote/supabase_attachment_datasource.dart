import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_app/domain/entities/attachment.dart';

/// Remote data source for attachment operations via Supabase.
///
/// This class handles all CRUD operations for todo attachments in Supabase.
/// Attachments are files associated with todos, stored in Supabase Storage.
///
/// Features:
/// - Retrieve attachments by todo ID
/// - Create new attachments with file metadata
/// - Delete individual attachments or all attachments for a todo
///
/// See also:
/// - [SupabaseAttachmentRepository] for the repository implementation
/// - [Attachment] for the attachment entity
class SupabaseAttachmentDataSource {
  /// The Supabase client used for database operations.
  final SupabaseClient client;

  /// Creates a new [SupabaseAttachmentDataSource] with the given [client].
  SupabaseAttachmentDataSource(this.client);

  /// Retrieves all attachments for a specific todo.
  ///
  /// Attachments are ordered by creation date (newest first).
  Future<List<Attachment>> getAttachmentsByTodoId(int todoId) async {
    final response = await client
        .from('attachments')
        .select()
        .eq('todo_id', todoId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => _fromJson(json)).toList();
  }

  /// Retrieves a single attachment by its ID.
  Future<Attachment> getAttachmentById(int id) async {
    final response = await client
        .from('attachments')
        .select()
        .eq('id', id)
        .single();

    return _fromJson(response);
  }

  /// Creates a new attachment record in the database.
  ///
  /// Note: This only creates the database record. The actual file should be
  /// uploaded to Supabase Storage separately before calling this method.
  ///
  /// Returns the ID of the created attachment.
  Future<int> createAttachment({
    required int todoId,
    required String userId,
    required String fileName,
    required String filePath,
    required int fileSize,
    required String mimeType,
    required String storagePath,
  }) async {
    final response = await client
        .from('attachments')
        .insert({
          'todo_id': todoId,
          'user_id': userId,
          'file_name': fileName,
          'file_path': filePath,
          'file_size': fileSize,
          'mime_type': mimeType,
          'storage_path': storagePath,
        })
        .select()
        .single();

    return response['id'] as int;
  }

  /// Deletes an attachment by its ID.
  ///
  /// Note: This only deletes the database record. The actual file in
  /// Supabase Storage should be deleted separately.
  Future<void> deleteAttachment(int id) async {
    await client.from('attachments').delete().eq('id', id);
  }

  /// Deletes all attachments for a specific todo.
  ///
  /// This is typically called when deleting a todo to clean up associated files.
  Future<void> deleteAttachmentsByTodoId(int todoId) async {
    await client.from('attachments').delete().eq('todo_id', todoId);
  }

  /// Converts a JSON map to an [Attachment] entity.
  Attachment _fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id'] as int,
      todoId: json['todo_id'] as int,
      fileName: json['file_name'] as String,
      filePath: json['file_path'] as String,
      fileSize: json['file_size'] as int,
      mimeType: json['mime_type'] as String,
      storagePath: json['storage_path'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
