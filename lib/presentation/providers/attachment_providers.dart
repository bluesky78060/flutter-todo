/// Attachment state management providers using Riverpod.
///
/// Provides file attachment data access for todos, including
/// local metadata storage and cloud file storage via Supabase.
///
/// Key providers:
/// - [attachmentServiceProvider]: Service for file upload/download
/// - [attachmentLocalRepositoryProvider]: Local metadata storage
/// - [attachmentRemoteRepositoryProvider]: Remote file storage
/// - [attachmentListProvider]: List of attachments for a todo
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_app/core/services/attachment_service.dart';
import 'package:todo_app/data/datasources/remote/supabase_attachment_datasource.dart';
import 'package:todo_app/data/repositories/attachment_repository_impl.dart';
import 'package:todo_app/data/repositories/supabase_attachment_repository.dart';
import 'package:todo_app/domain/entities/attachment.dart' as entity;
import 'package:todo_app/presentation/providers/database_provider.dart';

/// Provides the attachment service for file upload/download operations.
final attachmentServiceProvider = Provider<AttachmentService>((ref) {
  return AttachmentService(Supabase.instance.client);
});

/// Provides the local attachment repository for metadata storage.
final attachmentLocalRepositoryProvider = Provider((ref) {
  final database = ref.watch(localDatabaseProvider);
  return AttachmentRepositoryImpl(database);
});

/// Provides the remote attachment repository for Supabase storage.
final attachmentRemoteRepositoryProvider = Provider((ref) {
  final datasource = SupabaseAttachmentDataSource(Supabase.instance.client);
  return SupabaseAttachmentRepository(datasource);
});

/// Provides attachments for a specific todo.
///
/// Fetches attachment metadata from local storage.
final attachmentListProvider =
    FutureProvider.family<List<entity.Attachment>, int>((ref, todoId) async {
  final localRepo = ref.watch(attachmentLocalRepositoryProvider);
  final result = await localRepo.getAttachmentsByTodoId(todoId);

  return result.fold(
    (failure) => throw Exception('Failed to load attachments'),
    (attachments) => attachments,
  );
});
