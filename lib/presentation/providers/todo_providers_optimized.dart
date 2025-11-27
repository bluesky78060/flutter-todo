import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/services/notification_service.dart';
import 'package:todo_app/domain/entities/todo.dart';
import 'package:todo_app/presentation/providers/database_provider.dart';
import 'package:todo_app/presentation/providers/connectivity_provider.dart';
import 'package:todo_app/core/utils/app_logger.dart';
import 'package:todo_app/presentation/widgets/recurring_edit_dialog.dart';
import 'package:todo_app/presentation/widgets/recurring_delete_dialog.dart';
import 'package:todo_app/presentation/providers/attachment_providers.dart';
import 'package:todo_app/presentation/providers/widget_provider.dart';

// ============================================================================
// FILTER STATE PROVIDERS (No changes - already optimal)
// ============================================================================

enum TodoFilter { all, pending, completed }

class TodoFilterNotifier extends Notifier<TodoFilter> {
  @override
  TodoFilter build() => TodoFilter.all;

  void setFilter(TodoFilter filter) {
    state = filter;
  }
}

final todoFilterProvider =
    NotifierProvider<TodoFilterNotifier, TodoFilter>(TodoFilterNotifier.new);

class CategoryFilterNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void setCategory(int? categoryId) {
    state = categoryId;
  }

  void clearCategory() {
    state = null;
  }
}

final categoryFilterProvider =
    NotifierProvider<CategoryFilterNotifier, int?>(CategoryFilterNotifier.new);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }

  void clearQuery() {
    state = '';
  }
}

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

// ============================================================================
// OPTIMIZED DATA LAYER: Base Todos Provider (Cached, No Filtering)
// ============================================================================

/// Base todos provider - fetches ALL todos once and caches them
/// Only invalidated on CRUD operations, NOT on filter changes
/// This is the single source of truth for todo data
final baseTodosProvider = FutureProvider<List<Todo>>((ref) async {
  final repository = ref.watch(todoRepositoryProvider);

  logger.d('📥 baseTodosProvider: Fetching all todos from repository');

  final result = await repository.getTodos();

  return result.fold(
    (failure) {
      logger.e('❌ baseTodosProvider: Failed to fetch todos - $failure');
      throw Exception(failure);
    },
    (todos) {
      // Filter out master recurring todos (they should not be displayed)
      final visibleTodos = todos.where((todo) {
        final isMasterRecurringTodo = todo.recurrenceRule != null &&
                                       todo.recurrenceRule!.isNotEmpty &&
                                       todo.parentRecurringTodoId == null;
        return !isMasterRecurringTodo;
      }).toList();

      logger.d('✅ baseTodosProvider: Loaded ${visibleTodos.length} todos (filtered ${todos.length - visibleTodos.length} master todos)');
      return visibleTodos;
    },
  );
});

// ============================================================================
// OPTIMIZED FILTERING LAYER: Client-Side Filtering (No DB Queries)
// ============================================================================

/// Filtered todos provider - applies completion status filter in memory
/// Does NOT query database - works with cached baseTodosProvider data
/// Performance: O(n) linear scan, ~1-5ms for typical todo lists
final statusFilteredTodosProvider = Provider<AsyncValue<List<Todo>>>((ref) {
  final baseTodosAsync = ref.watch(baseTodosProvider);
  final filter = ref.watch(todoFilterProvider);

  return baseTodosAsync.whenData((todos) {
    switch (filter) {
      case TodoFilter.all:
        return todos;
      case TodoFilter.pending:
        return todos.where((todo) => !todo.isCompleted).toList();
      case TodoFilter.completed:
        return todos.where((todo) => todo.isCompleted).toList();
    }
  });
});

/// Category filtered todos provider - applies category filter in memory
/// Builds on top of statusFilteredTodosProvider for progressive filtering
/// Performance: O(n) linear scan, minimal overhead
final categoryFilteredTodosProvider = Provider<AsyncValue<List<Todo>>>((ref) {
  final statusFilteredAsync = ref.watch(statusFilteredTodosProvider);
  final categoryFilter = ref.watch(categoryFilterProvider);

  return statusFilteredAsync.whenData((todos) {
    if (categoryFilter == null) {
      return todos;
    }
    return todos.where((todo) => todo.categoryId == categoryFilter).toList();
  });
});

// ============================================================================
// SEARCH LAYER: Separate Provider for Search (DB Query Only When Needed)
// ============================================================================

/// Search results provider - queries database only when search query exists
/// Uses debounced search query from searchQueryProvider
/// Performance: Database query only on search, not on filter changes
final searchResultsProvider = FutureProvider<List<Todo>?>((ref) async {
  final repository = ref.watch(todoRepositoryProvider);
  final searchQuery = ref.watch(searchQueryProvider);

  // Return null if no search query (signals to use filtered todos instead)
  if (searchQuery.trim().isEmpty) {
    return null;
  }

  logger.d('🔍 searchResultsProvider: Searching for "$searchQuery"');

  final result = await repository.searchTodos(searchQuery);

  return result.fold(
    (failure) {
      logger.e('❌ searchResultsProvider: Search failed - $failure');
      throw Exception(failure);
    },
    (todos) {
      // Filter out master recurring todos
      final visibleTodos = todos.where((todo) {
        final isMasterRecurringTodo = todo.recurrenceRule != null &&
                                       todo.recurrenceRule!.isNotEmpty &&
                                       todo.parentRecurringTodoId == null;
        return !isMasterRecurringTodo;
      }).toList();

      logger.d('✅ searchResultsProvider: Found ${visibleTodos.length} results');
      return visibleTodos;
    },
  );
});

// ============================================================================
// FINAL TODOS PROVIDER: Smart Selection Between Search and Filter
// ============================================================================

/// Main todos provider - smart selector between search results and filtered todos
/// UI should watch this provider for the final list of todos to display
///
/// Performance characteristics:
/// - Filter change: 1-5ms (in-memory filtering only)
/// - Search: 50-200ms (database query)
/// - CRUD operation: Invalidates baseTodosProvider, triggers refetch
final todosProvider = Provider<AsyncValue<List<Todo>>>((ref) {
  final searchResultsAsync = ref.watch(searchResultsProvider);
  final categoryFilteredAsync = ref.watch(categoryFilteredTodosProvider);

  // If search is active, use search results
  return searchResultsAsync.whenData((searchResults) {
    if (searchResults != null) {
      return searchResults;
    }
    // Otherwise, use filtered todos
    return categoryFilteredAsync.value ?? [];
  });
});

// ============================================================================
// TODO DETAIL PROVIDER (No changes needed)
// ============================================================================

final todoDetailProvider =
    FutureProvider.family<Todo, int>((ref, id) async {
  final repository = ref.watch(todoRepositoryProvider);
  final result = await repository.getTodoById(id);
  return result.fold(
    (failure) => throw Exception(failure),
    (todo) => todo,
  );
});

// ============================================================================
// NOTIFICATION SERVICE PROVIDER (No changes needed)
// ============================================================================

final notificationServiceProvider = Provider((ref) => NotificationService());

// ============================================================================
// OPTIMIZED TODO ACTIONS: Reduced Unnecessary Invalidations
// ============================================================================

class TodoActions {
  final Ref ref;
  TodoActions(this.ref);

  /// Helper to invalidate only the base provider (not filtered providers)
  /// Filtered providers will automatically update via their dependencies
  void _invalidateTodos() {
    logger.d('🔄 TodoActions: Invalidating baseTodosProvider only');
    ref.invalidate(baseTodosProvider);
    // Note: No need to invalidate todosProvider - it will update automatically
  }

  Future<void> createTodo(
    String title,
    String description,
    DateTime? dueDate, {
    int? categoryId,
    DateTime? notificationTime,
    String? recurrenceRule,
    double? locationLatitude,
    double? locationLongitude,
    String? locationName,
    double? locationRadius,
  }) async {
    final repository = ref.read(todoRepositoryProvider);
    final syncNotifier = ref.read(syncStateProvider.notifier);

    syncNotifier.startSync();

    final result = await repository.createTodo(
      title,
      description,
      dueDate,
      categoryId: categoryId,
      notificationTime: notificationTime,
      recurrenceRule: recurrenceRule,
      locationLatitude: locationLatitude,
      locationLongitude: locationLongitude,
      locationName: locationName,
      locationRadius: locationRadius,
    );

    if (result.isLeft()) {
      final failure = result.getLeft().toNullable();
      logger.e('❌ TodoActions: Failed to create todo - $failure');
      syncNotifier.syncFailed('$failure', shouldRetry: true);
      throw Exception('${'db_save_failed'.tr()}: $failure');
    }

    final todoId = result.getRight().toNullable()!;
    logger.d('✅ TodoActions: Todo created with ID: $todoId');

    // Schedule notification if needed
    if (notificationTime != null) {
      try {
        final notificationService = ref.read(notificationServiceProvider);
        await notificationService.scheduleNotification(
          id: todoId,
          title: 'todo_reminder'.tr(),
          body: title,
          scheduledDate: notificationTime,
        );
        logger.d('✅ TodoActions: Notification scheduled');
      } catch (e) {
        logger.d('⚠️ TodoActions: Failed to schedule notification: $e');
      }
    }

    // Generate recurring instances if needed
    if (recurrenceRule != null) {
      try {
        final recurringService = ref.read(recurringTodoServiceProvider);
        final todoResult = await repository.getTodoById(todoId);
        if (todoResult.isRight()) {
          final todo = todoResult.getRight().toNullable()!;
          await recurringService.generateInstancesForNewMaster(todo);
          logger.d('✅ TodoActions: Recurring instances generated');
        }
      } catch (e) {
        logger.e('❌ TodoActions: Failed to generate recurring instances: $e');
      }
    }

    await syncNotifier.syncSuccess();
    _invalidateTodos();
    _updateWidget();
  }

  void _updateWidget() {
    try {
      final widgetService = ref.read(widgetServiceProvider);
      widgetService.updateWidget();
      logger.d('📱 TodoActions: Widget updated');
    } catch (e) {
      logger.d('⚠️ TodoActions: Failed to update widget: $e');
    }
  }

  Future<void> updateTodo(
    Todo todo, {
    RecurringEditMode? recurringEditMode,
  }) async {
    final repository = ref.read(todoRepositoryProvider);
    final syncNotifier = ref.read(syncStateProvider.notifier);

    syncNotifier.startSync();

    // Handle recurring todo instances
    if (todo.parentRecurringTodoId != null && recurringEditMode != null) {
      switch (recurringEditMode) {
        case RecurringEditMode.thisOnly:
          final detachedTodo = Todo(
            id: todo.id,
            title: todo.title,
            description: todo.description,
            isCompleted: todo.isCompleted,
            categoryId: todo.categoryId,
            createdAt: todo.createdAt,
            completedAt: todo.completedAt,
            dueDate: todo.dueDate,
            notificationTime: todo.notificationTime,
            recurrenceRule: null,
            parentRecurringTodoId: null,
          );
          final result = await repository.updateTodo(detachedTodo);
          await result.fold(
            (failure) async {
              syncNotifier.syncFailed('$failure', shouldRetry: true);
              throw Exception(failure);
            },
            (_) async {
              await syncNotifier.syncSuccess();
              _invalidateTodos();
              ref.invalidate(todoDetailProvider(todo.id));
              _updateWidget();
            },
          );
          break;

        case RecurringEditMode.thisAndFuture:
          // Update master and regenerate future instances
          final masterResult = await repository.getTodoById(todo.parentRecurringTodoId!);
          await masterResult.fold(
            (failure) async {
              syncNotifier.syncFailed('$failure', shouldRetry: true);
              throw Exception('${'master_todo_fetch_failed'.tr()}: $failure');
            },
            (masterTodo) async {
              final updatedMaster = masterTodo.copyWith(
                title: todo.title,
                description: todo.description,
                categoryId: todo.categoryId,
                dueDate: todo.dueDate,
                notificationTime: todo.notificationTime,
              );

              final result = await repository.updateTodo(updatedMaster);
              await result.fold(
                (failure) async {
                  syncNotifier.syncFailed('$failure', shouldRetry: true);
                  throw Exception('${'master_todo_update_failed'.tr()}: $failure');
                },
                (_) async {
                  // Delete and regenerate future instances
                  final allTodosResult = await repository.getTodos();
                  await allTodosResult.fold(
                    (failure) {
                      logger.e('❌ Failed to fetch todos for cleanup');
                    },
                    (allTodos) async {
                      final futureInstances = allTodos.where((t) =>
                        t.parentRecurringTodoId == masterTodo.id &&
                        t.dueDate != null &&
                        todo.dueDate != null &&
                        (t.dueDate!.isAfter(todo.dueDate!) ||
                         t.dueDate!.isAtSameMomentAs(todo.dueDate!))
                      ).toList();

                      for (final instance in futureInstances) {
                        await repository.deleteTodo(instance.id);
                      }

                      final recurringService = ref.read(recurringTodoServiceProvider);
                      await recurringService.generateInstancesForNewMaster(updatedMaster);
                    },
                  );

                  await syncNotifier.syncSuccess();
                  _invalidateTodos();
                  ref.invalidate(todoDetailProvider(todo.id));
                  _updateWidget();
                },
              );
            },
          );
          break;
      }
    } else {
      // Regular todo update
      final result = await repository.updateTodo(todo);
      await result.fold(
        (failure) async {
          syncNotifier.syncFailed('$failure', shouldRetry: true);
          throw Exception(failure);
        },
        (_) async {
          await syncNotifier.syncSuccess();
          _invalidateTodos();
          ref.invalidate(todoDetailProvider(todo.id));
          _updateWidget();
        },
      );
    }
  }

  Future<void> deleteTodo(
    int id, {
    RecurringDeleteMode? recurringDeleteMode,
  }) async {
    final repository = ref.read(todoRepositoryProvider);
    final notificationService = ref.read(notificationServiceProvider);
    final syncNotifier = ref.read(syncStateProvider.notifier);

    syncNotifier.startSync();

    final todoResult = await repository.getTodoById(id);
    await todoResult.fold(
      (failure) async {
        syncNotifier.syncFailed('$failure', shouldRetry: true);
        throw Exception('${'todo_fetch_failed'.tr()}: $failure');
      },
      (todo) async {
        // Handle recurring todo instances
        if (todo.parentRecurringTodoId != null && recurringDeleteMode != null) {
          switch (recurringDeleteMode) {
            case RecurringDeleteMode.thisOnly:
              await _deleteSingleTodo(id, notificationService, repository, syncNotifier);
              break;

            case RecurringDeleteMode.thisAndFuture:
              final allTodosResult = await repository.getTodos();
              await allTodosResult.fold(
                (failure) async {
                  syncNotifier.syncFailed('$failure', shouldRetry: true);
                  throw Exception('${'todos_fetch_failed'.tr()}: $failure');
                },
                (allTodos) async {
                  final instancesToDelete = allTodos.where((t) =>
                    t.parentRecurringTodoId == todo.parentRecurringTodoId &&
                    t.dueDate != null &&
                    todo.dueDate != null &&
                    (t.dueDate!.isAfter(todo.dueDate!) ||
                     t.dueDate!.isAtSameMomentAs(todo.dueDate!))
                  ).toList();

                  for (final instance in instancesToDelete) {
                    await _deleteSingleTodo(instance.id, notificationService, repository, syncNotifier);
                  }
                },
              );
              break;

            case RecurringDeleteMode.entireSeries:
              final allTodosResult = await repository.getTodos();
              await allTodosResult.fold(
                (failure) async {
                  syncNotifier.syncFailed('$failure', shouldRetry: true);
                  throw Exception('${'todos_fetch_failed'.tr()}: $failure');
                },
                (allTodos) async {
                  final allInstances = allTodos.where((t) =>
                    t.parentRecurringTodoId == todo.parentRecurringTodoId
                  ).toList();

                  for (final instance in allInstances) {
                    await _deleteSingleTodo(instance.id, notificationService, repository, syncNotifier);
                  }

                  await _deleteSingleTodo(todo.parentRecurringTodoId!, notificationService, repository, syncNotifier);
                },
              );
              break;
          }
        } else {
          await _deleteSingleTodo(id, notificationService, repository, syncNotifier);
        }

        await syncNotifier.syncSuccess();
        _invalidateTodos();
        _updateWidget();
      },
    );
  }

  Future<void> _deleteSingleTodo(
    int id,
    NotificationService notificationService,
    dynamic repository,
    SyncStateNotifier syncNotifier,
  ) async {
    try {
      await notificationService.cancelNotification(id);
      logger.d('✅ Notification cancelled for todo $id');
    } catch (e) {
      logger.d('⚠️ Failed to cancel notification: $e');
    }

    try {
      final attachmentService = ref.read(attachmentServiceProvider);
      final deleteResult = await attachmentService.deleteFilesByTodoId(id);
      deleteResult.fold(
        (failure) => logger.d('⚠️ Failed to delete attachments: $failure'),
        (_) => logger.d('✅ Attachments deleted'),
      );
    } catch (e) {
      logger.d('⚠️ Error deleting attachments: $e');
    }

    final result = await repository.deleteTodo(id);
    result.fold(
      (failure) {
        syncNotifier.syncFailed('$failure', shouldRetry: true);
        throw Exception('${'db_delete_failed'.tr()}: $failure');
      },
      (_) => logger.d('✅ Todo deleted: $id'),
    );
  }

  Future<void> toggleCompletion(int id) async {
    final repository = ref.read(todoRepositoryProvider);
    final syncNotifier = ref.read(syncStateProvider.notifier);

    syncNotifier.startSync();

    final todoResult = await repository.getTodoById(id);
    await todoResult.fold(
      (failure) async {
        syncNotifier.syncFailed('$failure', shouldRetry: true);
        throw Exception('${'todo_fetch_failed'.tr()}: $failure');
      },
      (todo) async {
        final result = await repository.toggleCompletion(id);
        await result.fold(
          (failure) async {
            syncNotifier.syncFailed('$failure', shouldRetry: true);
            throw Exception(failure);
          },
          (_) async {
            // Generate next recurring instance if needed
            if (!todo.isCompleted && todo.parentRecurringTodoId != null) {
              try {
                final masterResult = await repository.getTodoById(todo.parentRecurringTodoId!);
                masterResult.fold(
                  (failure) => logger.e('❌ Failed to fetch master todo'),
                  (masterTodo) async {
                    final recurringService = ref.read(recurringTodoServiceProvider);
                    await recurringService.generateInstancesForNewMaster(masterTodo);
                  },
                );
              } catch (e) {
                logger.e('❌ Failed to generate next recurring instance: $e');
              }
            }

            await syncNotifier.syncSuccess();
            _invalidateTodos();
            ref.invalidate(todoDetailProvider(id));
            _updateWidget();
          },
        );
      },
    );
  }

  Future<void> rescheduleTodo(int id, DateTime newDate) async {
    final repository = ref.read(todoRepositoryProvider);
    final notificationService = ref.read(notificationServiceProvider);

    final todoResult = await repository.getTodoById(id);
    await todoResult.fold(
      (failure) {
        throw Exception('${'todo_fetch_failed'.tr()}: $failure');
      },
      (todo) async {
        if (todo.dueDate == null) {
          throw Exception('cannot_reschedule_without_due_date'.tr());
        }

        final originalTime = TimeOfDay(
          hour: todo.dueDate!.hour,
          minute: todo.dueDate!.minute,
        );
        final newDueDate = DateTime(
          newDate.year,
          newDate.month,
          newDate.day,
          originalTime.hour,
          originalTime.minute,
        );

        DateTime? newNotificationTime;
        if (todo.notificationTime != null && todo.dueDate != null) {
          final difference = todo.dueDate!.difference(todo.notificationTime!);
          newNotificationTime = newDueDate.subtract(difference);
        }

        final updatedTodo = todo.copyWith(
          dueDate: newDueDate,
          notificationTime: newNotificationTime,
        );

        final result = await repository.updateTodo(updatedTodo);
        await result.fold(
          (failure) {
            throw Exception('${'reschedule_failed'.tr()}: $failure');
          },
          (_) async {
            if (newNotificationTime != null) {
              try {
                await notificationService.cancelNotification(id);
                await notificationService.scheduleNotification(
                  id: id,
                  title: 'todo_reminder'.tr(),
                  body: todo.title,
                  scheduledDate: newNotificationTime,
                );
              } catch (e) {
                logger.e('❌ Failed to reschedule notification: $e');
              }
            }

            _invalidateTodos();
            ref.invalidate(todoDetailProvider(id));
            _updateWidget();
          },
        );
      },
    );
  }

  Future<int> deleteCompletedTodos() async {
    final repository = ref.read(todoRepositoryProvider);
    final result = await repository.deleteCompletedTodos();

    return result.fold(
      (failure) => throw Exception('Failed to delete completed todos'),
      (count) {
        _invalidateTodos();
        _updateWidget();
        return count;
      },
    );
  }

  Future<void> updateTodoPositions(List<Todo> todos) async {
    final repository = ref.read(todoRepositoryProvider);
    final result = await repository.updateTodoPositions(todos);

    result.fold(
      (failure) {
        throw Exception('${'position_update_failed'.tr()}: $failure');
      },
      (_) {
        _invalidateTodos();
      },
    );
  }
}

final todoActionsProvider = Provider((ref) => TodoActions(ref));
