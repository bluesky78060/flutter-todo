import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fpdart/fpdart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/core/errors/failures.dart';
import 'package:todo_app/data/datasources/local/app_database.dart';
import 'package:todo_app/domain/repositories/todo_repository.dart';
import 'package:todo_app/domain/repositories/category_repository.dart';

/// Backup and restore service for all app data
class BackupService {
  final AppDatabase _database;
  final SharedPreferences _prefs;
  final TodoRepository _todoRepository;
  final CategoryRepository _categoryRepository;

  BackupService(
    this._database,
    this._prefs,
    this._todoRepository,
    this._categoryRepository,
  );

  /// Export all data to JSON format
  Future<Either<Failure, File>> exportData() async {
    try {
      // Request storage permission on Android
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          return Left(const DatabaseFailure('Storage permission denied'));
        }
      }

      // Get all todos and categories from Supabase repository
      final todosResult = await _todoRepository.getTodos();
      final categoriesResult = await _categoryRepository.getCategories();

      // Extract todos or return error
      final todos = todosResult.fold(
        (failure) => throw Exception('Failed to fetch todos'),
        (todosList) => todosList,
      );

      // Extract categories or return error
      final categories = categoriesResult.fold(
        (failure) => throw Exception('Failed to fetch categories'),
        (categoriesList) => categoriesList,
      );

      // Get user ID from preferences
      final userId = _prefs.getInt('user_id');

      // Create backup data structure
      final backupData = {
        'version': '1.0.0',
        'exportedAt': DateTime.now().toIso8601String(),
        'userId': userId,
        'todos': todos.map((todo) => _todoToJson(todo)).toList(),
        'categories': categories.map((cat) => _categoryToJson(cat)).toList(),
        'settings': {
          'isDarkMode': _prefs.getBool('isDarkMode') ?? false,
        },
      };

      // Convert to JSON string
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      // Get Downloads directory (accessible to user)
      Directory? directory;
      if (Platform.isAndroid) {
        // On Android, use external storage Downloads directory
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          // Fallback to getExternalStorageDirectory
          directory = await getExternalStorageDirectory();
        }
      } else {
        // On iOS/other platforms, use application documents directory
        directory = await getApplicationDocumentsDirectory();
      }

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final filePath = '${directory!.path}/todo_backup_$timestamp.json';

      // Write to file
      final file = File(filePath);
      await file.writeAsString(jsonString);

      return Right(file);
    } catch (e) {
      return Left(const DatabaseFailure('Failed to export data'));
    }
  }

  /// Import data from JSON file
  Future<Either<Failure, String>> importData({
    required ImportStrategy strategy,
  }) async {
    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        return Left(const DatabaseFailure('No file selected'));
      }

      final filePath = result.files.first.path;
      if (filePath == null) {
        return Left(const DatabaseFailure('Invalid file path'));
      }

      // Read file content
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final Map<String, dynamic> backupData = jsonDecode(jsonString);

      // Validate backup format
      if (!_validateBackupFormat(backupData)) {
        return Left(const DatabaseFailure('Invalid backup file format'));
      }

      // Apply import strategy
      int importedCount = 0;
      if (strategy == ImportStrategy.overwrite) {
        // Clear all existing data from Supabase
        // We'll delete existing todos first
        final existingTodos = await _todoRepository.getTodos();
        await existingTodos.fold(
          (failure) async => null,
          (todos) async {
            for (final todo in todos) {
              await _todoRepository.deleteTodo(todo.id);
            }
          },
        );

        // Delete existing categories
        final existingCategories = await _categoryRepository.getCategories();
        await existingCategories.fold(
          (failure) async => null,
          (categories) async {
            for (final category in categories) {
              await _categoryRepository.deleteCategory(category.id);
            }
          },
        );

        // Import all backup data to Supabase
        importedCount = await _importAllData(backupData);
      } else if (strategy == ImportStrategy.merge) {
        // Merge data (simple: just import all, allow duplicates for now)
        importedCount = await _importAllData(backupData);
      }

      // Restore settings
      final settings = backupData['settings'] as Map<String, dynamic>?;
      if (settings != null) {
        await _prefs.setBool('isDarkMode', settings['isDarkMode'] ?? false);
      }

      return Right('Successfully imported $importedCount items');
    } catch (e) {
      return Left(const DatabaseFailure('Failed to import data'));
    }
  }

  /// Import all data to Supabase (used for overwrite strategy)
  Future<int> _importAllData(Map<String, dynamic> backupData) async {
    int count = 0;

    // Import categories first (todos may reference them)
    final categories = backupData['categories'] as List;
    for (final categoryJson in categories) {
      final result = await _categoryRepository.createCategory(
        categoryJson['userId'] as String,
        categoryJson['name'] as String,
        categoryJson['color'] as String,
        categoryJson['icon'] as String?,
      );

      result.fold(
        (failure) => print('Failed to import category: ${categoryJson['name']}'),
        (categoryId) => count++,
      );
    }

    // Import todos
    final todos = backupData['todos'] as List;
    for (final todoJson in todos) {
      final result = await _todoRepository.createTodo(
        todoJson['title'] as String,
        todoJson['description'] as String,
        todoJson['dueDate'] != null
            ? DateTime.parse(todoJson['dueDate'] as String)
            : null,
        categoryId: todoJson['categoryId'] as int?,
        notificationTime: todoJson['notificationTime'] != null
            ? DateTime.parse(todoJson['notificationTime'] as String)
            : null,
        recurrenceRule: todoJson['recurrenceRule'] as String?,
        parentRecurringTodoId: todoJson['parentRecurringTodoId'] as int?,
      );

      result.fold(
        (failure) => print('Failed to import todo: ${todoJson['title']}'),
        (todoId) => count++,
      );
    }

    return count;
  }

  /// Validate backup file format
  bool _validateBackupFormat(Map<String, dynamic> data) {
    return data.containsKey('version') &&
        data.containsKey('exportedAt') &&
        data.containsKey('todos') &&
        data.containsKey('categories');
  }

  /// Convert Todo Domain entity to JSON
  Map<String, dynamic> _todoToJson(dynamic todo) {
    return {
      'id': todo.id,
      'title': todo.title,
      'description': todo.description,
      'isCompleted': todo.isCompleted,
      'categoryId': todo.categoryId,
      'createdAt': todo.createdAt.toIso8601String(),
      'completedAt': todo.completedAt?.toIso8601String(),
      'dueDate': todo.dueDate?.toIso8601String(),
      'notificationTime': todo.notificationTime?.toIso8601String(),
      'recurrenceRule': todo.recurrenceRule,
      'parentRecurringTodoId': todo.parentRecurringTodoId,
    };
  }

  /// Convert Category Domain entity to JSON
  Map<String, dynamic> _categoryToJson(dynamic category) {
    return {
      'id': category.id,
      'userId': category.userId,
      'name': category.name,
      'color': category.color,
      'icon': category.icon,
      'createdAt': category.createdAt.toIso8601String(),
    };
  }
}

/// Import strategy for conflict resolution
enum ImportStrategy {
  /// Replace all existing data with backup data
  overwrite,

  /// Merge backup data with existing data (keep newer items)
  merge,
}
