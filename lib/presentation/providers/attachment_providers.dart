import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_app/core/services/attachment_service.dart';
import 'package:todo_app/data/datasources/remote/supabase_attachment_datasource.dart';
import 'package:todo_app/data/repositories/attachment_repository_impl.dart';
import 'package:todo_app/data/repositories/supabase_attachment_repository.dart';
import 'package:todo_app/domain/entities/attachment.dart' as entity;
import 'package:todo_app/presentation/providers/database_provider.dart';

// AttachmentService provider
final attachmentServiceProvider = Provider<AttachmentService>((ref) {
  return AttachmentService(Supabase.instance.client);
});

// Local repository provider
final attachmentLocalRepositoryProvider = Provider((ref) {
  final database = ref.watch(localDatabaseProvider);
  return AttachmentRepositoryImpl(database);
});

// Remote repository provider
final attachmentRemoteRepositoryProvider = Provider((ref) {
  final datasource = SupabaseAttachmentDataSource(Supabase.instance.client);
  return SupabaseAttachmentRepository(datasource);
});

// Attachment list provider for a specific todo
final attachmentListProvider =
    FutureProvider.family<List<entity.Attachment>, int>((ref, todoId) async {
  final localRepo = ref.watch(attachmentLocalRepositoryProvider);
  final result = await localRepo.getAttachmentsByTodoId(todoId);

  return result.fold(
    (failure) => throw Exception('Failed to load attachments'),
    (attachments) => attachments,
  );
});
