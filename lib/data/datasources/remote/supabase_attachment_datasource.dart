import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_app/domain/entities/attachment.dart';

class SupabaseAttachmentDataSource {
  final SupabaseClient client;

  SupabaseAttachmentDataSource(this.client);

  Future<List<Attachment>> getAttachmentsByTodoId(int todoId) async {
    final response = await client
        .from('attachments')
        .select()
        .eq('todo_id', todoId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => _fromJson(json)).toList();
  }

  Future<Attachment> getAttachmentById(int id) async {
    final response = await client
        .from('attachments')
        .select()
        .eq('id', id)
        .single();

    return _fromJson(response);
  }

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

  Future<void> deleteAttachment(int id) async {
    await client.from('attachments').delete().eq('id', id);
  }

  Future<void> deleteAttachmentsByTodoId(int todoId) async {
    await client.from('attachments').delete().eq('todo_id', todoId);
  }

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
