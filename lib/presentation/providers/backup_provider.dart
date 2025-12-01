/// Backup and restore state management providers using Riverpod.
///
/// Provides data export and import functionality for user data backup.
/// Supports JSON file export/import with configurable import strategies.
///
/// Key providers:
/// - [backupServiceFutureProvider]: Backup service instance
/// - [backupActionsProvider]: Export and import operations
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/core/services/backup_service.dart';
import 'package:todo_app/presentation/providers/database_provider.dart';
import 'package:todo_app/presentation/providers/category_providers.dart';

/// Provides the backup service for export/import operations.
final backupServiceFutureProvider = FutureProvider<BackupService>((ref) async {
  final todoRepository = ref.watch(todoRepositoryProvider);
  final categoryRepository = ref.watch(categoryRepositoryProvider);
  final prefs = await SharedPreferences.getInstance();
  return BackupService(prefs, todoRepository, categoryRepository);
});

/// Provides the backup actions for export/import operations.
final backupActionsProvider = Provider<BackupActions>((ref) {
  return BackupActions(ref);
});

/// Action class for backup operations.
///
/// Provides export to JSON file and import with strategy selection.
class BackupActions {
  final Ref _ref;

  BackupActions(this._ref);

  /// Export data to file
  Future<String> exportData() async {
    final service = await _ref.read(backupServiceFutureProvider.future);
    final result = await service.exportData();

    return result.fold(
      (failure) => throw Exception('Failed to export data'),
      (file) => file.path,
    );
  }

  /// Import data from file with selected strategy
  Future<String> importData(ImportStrategy strategy) async {
    final service = await _ref.read(backupServiceFutureProvider.future);
    final result = await service.importData(strategy: strategy);

    return result.fold(
      (failure) => throw Exception('Failed to import data'),
      (message) => message,
    );
  }
}
