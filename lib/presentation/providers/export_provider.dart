import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/services/export_service.dart';
import 'package:todo_app/presentation/providers/category_providers.dart';
import 'package:todo_app/presentation/providers/database_provider.dart';

/// Provider for ExportService
final exportServiceProvider = Provider((ref) {
  final todoRepository = ref.watch(todoRepositoryProvider);
  final categoryRepository = ref.watch(categoryRepositoryProvider);
  return ExportService(todoRepository, categoryRepository);
});

/// Provider for export operations
final exportProvider = FutureProvider.family<bool, String>((ref, format) async {
  final exportService = ref.watch(exportServiceProvider);

  if (format == 'csv') {
    return await exportService.exportAsCSV();
  } else if (format == 'pdf') {
    return await exportService.exportAsPDF();
  }

  return false;
});
