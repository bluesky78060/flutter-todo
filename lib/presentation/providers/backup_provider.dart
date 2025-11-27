import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/core/services/backup_service.dart';
import 'package:todo_app/presentation/providers/database_provider.dart';
import 'package:todo_app/presentation/providers/category_providers.dart';

/// Future provider for BackupService with SharedPreferences
final backupServiceFutureProvider = FutureProvider<BackupService>((ref) async {
  final todoRepository = ref.watch(todoRepositoryProvider);
  final categoryRepository = ref.watch(categoryRepositoryProvider);
  final prefs = await SharedPreferences.getInstance();
  return BackupService(prefs, todoRepository, categoryRepository);
});

/// Actions provider for backup operations
final backupActionsProvider = Provider<BackupActions>((ref) {
  return BackupActions(ref);
});

/// Backup actions class
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
