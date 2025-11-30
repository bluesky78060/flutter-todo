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

// Todo filter state
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

// Category filter state
class CategoryFilterNotifier extends Notifier<int?> {
  @override
  int? build() => null; // null means no category filter

  void setCategory(int? categoryId) {
    state = categoryId;
  }

  void clearCategory() {
    state = null;
  }
}

final categoryFilterProvider =
    NotifierProvider<CategoryFilterNotifier, int?>(CategoryFilterNotifier.new);

// Search query state
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

// Todos List Provider
final todosProvider = FutureProvider<List<Todo>>((ref) async {
  final repository = ref.watch(todoRepositoryProvider);
  final filter = ref.watch(todoFilterProvider);
  final categoryFilter = ref.watch(categoryFilterProvider);
  final searchQuery = ref.watch(searchQueryProvider);

  // If search query exists, use search instead of filter
  final result = searchQuery.trim().isNotEmpty
      ? await repository.searchTodos(searchQuery)
      : await repository.getFilteredTodos(switch (filter) {
          TodoFilter.all => 'all',
          TodoFilter.pending => 'pending',
          TodoFilter.completed => 'completed',
        });

  return result.fold(
    (failure) => throw Exception(failure),
    (todos) {
      // Filter out master recurring todos (they should not be displayed, only their instances)
      var filteredTodos = todos.where((todo) {
        // Hide master todos: those with recurrenceRule but no parentRecurringTodoId
        final isMasterRecurringTodo = todo.recurrenceRule != null &&
                                       todo.recurrenceRule!.isNotEmpty &&
                                       todo.parentRecurringTodoId == null;
        return !isMasterRecurringTodo;
      }).toList();

      // Apply category filter if selected
      if (categoryFilter != null) {
        filteredTodos = filteredTodos.where((todo) => todo.categoryId == categoryFilter).toList();
      }

      return filteredTodos;
    },
  );
});

// Todo Detail Provider
final todoDetailProvider =
    FutureProvider.family<Todo, int>((ref, id) async {
  final repository = ref.watch(todoRepositoryProvider);
  final result = await repository.getTodoById(id);
  return result.fold(
    (failure) => throw Exception(failure),
    (todo) => todo,
  );
});

// Notification Service Provider
final notificationServiceProvider = Provider((ref) => NotificationService());

// Todo actions
class TodoActions {
  final Ref ref;
  TodoActions(this.ref);

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

    // Start sync
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

    // Use isRight/isLeft pattern for proper async handling
    if (result.isLeft()) {
      final failure = result.getLeft().toNullable();
      logger.e('❌ TodoActions: Failed to create todo');
      logger.e('   Error: $failure');
      syncNotifier.syncFailed('$failure', shouldRetry: true);
      throw Exception('${'db_save_failed'.tr()}: $failure');
    }

    final todoId = result.getRight().toNullable()!;
    logger.d('✅ TodoActions: Todo created with ID: $todoId');
    logger.d('   Title: $title');
    logger.d('   Due Date: $dueDate');
    logger.d('   Notification Time: $notificationTime');
    logger.d('   Recurrence Rule: $recurrenceRule');

    // Schedule notification if notificationTime is set
    if (notificationTime != null) {
      try {
        final notificationService = ref.read(notificationServiceProvider);
        final now = DateTime.now();
        final difference = notificationTime.difference(now);

        logger.d('📅 TodoActions: Scheduling notification for todo $todoId');
        logger.d('   Title: $title');
        logger.d('   Notification Time: $notificationTime');
        logger.d('   Current Time: $now');
        logger.d('   Time until notification: ${difference.inMinutes} minutes');

        await notificationService.scheduleNotification(
          id: todoId,
          title: 'todo_reminder'.tr(),
          body: title,
          scheduledDate: notificationTime,
        );

        // Verify scheduling
        final pending = await notificationService.getPendingNotifications();
        final thisNotification = pending.where((n) => n.id == todoId).firstOrNull;

        if (thisNotification != null) {
          logger.d('✅ TodoActions: Notification verified in pending list');
          logger.d('   Pending notifications count: ${pending.length}');
        } else {
          logger.d('⚠️ TodoActions: Notification not found in pending list!');
        }
      } catch (e, stackTrace) {
        logger.d('❌ TodoActions: Failed to schedule notification: $e');
        logger.d('   Stack trace: $stackTrace');
        // Don't throw - allow todo creation to succeed even if notification fails
      }
    } else {
      logger.d('ℹ️ TodoActions: No notification time set');
    }

    // Generate recurring instances if this is a recurring todo
    if (recurrenceRule != null) {
      try {
        logger.d('🔄 TodoActions: Generating recurring instances for todo $todoId');
        final recurringService = ref.read(recurringTodoServiceProvider);

        // Fetch the created todo to pass to the service
        final todoResult = await repository.getTodoById(todoId);
        if (todoResult.isRight()) {
          final todo = todoResult.getRight().toNullable()!;
          await recurringService.generateInstancesForNewMaster(todo);
          logger.d('✅ TodoActions: Recurring instances generated successfully');
        } else {
          logger.e('❌ TodoActions: Failed to fetch created todo for recurring instance generation');
        }
      } catch (e, stackTrace) {
        logger.e('❌ TodoActions: Failed to generate recurring instances',
          error: e, stackTrace: stackTrace);
        // Don't throw - allow todo creation to succeed even if instance generation fails
      }
    }

    // Sync success
    await syncNotifier.syncSuccess();

    ref.invalidate(todosProvider);

    // Update home screen widget (await for immediate sync)
    await _updateWidget();
  }

  /// Helper method to update home screen widget
  /// Now returns Future and must be awaited for immediate sync
  Future<void> _updateWidget() async {
    print('📱 [WIDGET] TodoActions._updateWidget() CALLED');
    logger.d('📱 TodoActions: _updateWidget() called');
    try {
      final widgetService = ref.read(widgetServiceProvider);
      print('📱 [WIDGET] widgetServiceProvider read SUCCESS, calling updateWidget()...');
      logger.d('📱 TodoActions: widgetServiceProvider read success');
      await widgetService.updateWidget();
      print('📱 [WIDGET] Widget update COMPLETED successfully');
      logger.d('📱 TodoActions: Home screen widget updated successfully');
    } catch (e) {
      print('📱 [WIDGET] Widget update ERROR: $e');
      logger.e('⚠️ TodoActions: Failed to update widget: $e');
    }
  }

  /// Update a todo
  /// For recurring todo instances, this should be called after showing RecurringEditDialog
  Future<void> updateTodo(
    Todo todo, {
    RecurringEditMode? recurringEditMode,
  }) async {
    final repository = ref.read(todoRepositoryProvider);
    final syncNotifier = ref.read(syncStateProvider.notifier);

    // Start sync
    syncNotifier.startSync();

    // Check if this is a recurring todo instance (has parentRecurringTodoId)
    if (todo.parentRecurringTodoId != null && recurringEditMode != null) {
      logger.d('🔄 TodoActions: Updating recurring todo instance');
      logger.d('   Mode: $recurringEditMode');

      switch (recurringEditMode) {
        case RecurringEditMode.thisOnly:
          // Edit this instance only - detach from series by removing parent link
          logger.d('   Detaching from series');
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
            recurrenceRule: null, // Remove recurrence rule
            parentRecurringTodoId: null, // Detach from series
          );
          final result = await repository.updateTodo(detachedTodo);
          await result.fold(
            (failure) async {
              syncNotifier.syncFailed('$failure', shouldRetry: true);
              throw Exception(failure);
            },
            (_) async {
              logger.d('✅ TodoActions: Instance detached and updated');
              await syncNotifier.syncSuccess();
              ref.invalidate(todosProvider);
              ref.invalidate(todoDetailProvider(todo.id));
              await _updateWidget();
            },
          );
          break;

        case RecurringEditMode.thisAndFuture:
          // Edit this and future instances - update the master todo
          logger.d('   Updating master and future instances');

          // First, get the master todo
          final masterResult = await repository.getTodoById(todo.parentRecurringTodoId!);
          await masterResult.fold(
            (failure) async {
              logger.e('❌ TodoActions: Failed to fetch master todo');
              syncNotifier.syncFailed('$failure', shouldRetry: true);
              throw Exception('${'master_todo_fetch_failed'.tr()}: $failure');
            },
            (masterTodo) async {
              // Update the master with the changes from this instance
              final updatedMaster = masterTodo.copyWith(
                title: todo.title,
                description: todo.description,
                categoryId: todo.categoryId,
                dueDate: todo.dueDate,
                notificationTime: todo.notificationTime,
                // Keep the recurrence rule from master
              );

              final result = await repository.updateTodo(updatedMaster);
              await result.fold(
                (failure) async {
                  logger.e('❌ TodoActions: Failed to update master todo');
                  syncNotifier.syncFailed('$failure', shouldRetry: true);
                  throw Exception('${'master_todo_update_failed'.tr()}: $failure');
                },
                (_) async {
                  logger.d('✅ TodoActions: Master todo updated');

                  // Delete all future instances (they will be regenerated)
                  final allTodosResult = await repository.getTodos();
                  await allTodosResult.fold(
                    (failure) {
                      logger.e('❌ TodoActions: Failed to fetch todos for cleanup');
                    },
                    (allTodos) async {
                      final futureInstances = allTodos.where((t) =>
                        t.parentRecurringTodoId == masterTodo.id &&
                        t.dueDate != null &&
                        todo.dueDate != null &&
                        (t.dueDate!.isAfter(todo.dueDate!) ||
                         t.dueDate!.isAtSameMomentAs(todo.dueDate!))
                      ).toList();

                      logger.d('   Deleting ${futureInstances.length} future instances');
                      for (final instance in futureInstances) {
                        await repository.deleteTodo(instance.id);
                      }

                      // Regenerate instances
                      final recurringService = ref.read(recurringTodoServiceProvider);
                      await recurringService.generateInstancesForNewMaster(updatedMaster);
                      logger.d('✅ TodoActions: Future instances regenerated');
                    },
                  );

                  await syncNotifier.syncSuccess();
                  ref.invalidate(todosProvider);
                  ref.invalidate(todoDetailProvider(todo.id));
                  await _updateWidget();
                },
              );
            },
          );
          break;
      }
    } else {
      // Regular todo update (non-recurring or master todo)
      logger.d('📝 TodoActions: Updating regular todo');
      final result = await repository.updateTodo(todo);
      await result.fold(
        (failure) async {
          syncNotifier.syncFailed('$failure', shouldRetry: true);
          throw Exception(failure);
        },
        (_) async {
          logger.d('✅ TodoActions: Todo updated successfully');
          await syncNotifier.syncSuccess();
          ref.invalidate(todosProvider);
          ref.invalidate(todoDetailProvider(todo.id));
          await _updateWidget();
        },
      );
    }
  }

  /// Delete a todo
  /// For recurring todo instances, this should be called after showing RecurringDeleteDialog
  Future<void> deleteTodo(
    int id, {
    RecurringDeleteMode? recurringDeleteMode,
  }) async {
    final repository = ref.read(todoRepositoryProvider);
    final notificationService = ref.read(notificationServiceProvider);
    final syncNotifier = ref.read(syncStateProvider.notifier);

    logger.d('🗑️ TodoActions: Attempting to delete todo $id');

    // Start sync
    syncNotifier.startSync();

    // First, fetch the todo to check if it's a recurring instance
    final todoResult = await repository.getTodoById(id);
    await todoResult.fold(
      (failure) async {
        logger.e('❌ TodoActions: Failed to fetch todo for deletion');
        syncNotifier.syncFailed('$failure', shouldRetry: true);
        throw Exception('${'todo_fetch_failed'.tr()}: $failure');
      },
      (todo) async {
        // Check if this is a recurring todo instance
        if (todo.parentRecurringTodoId != null && recurringDeleteMode != null) {
          logger.d('🔄 TodoActions: Deleting recurring todo instance');
          logger.d('   Mode: $recurringDeleteMode');

          switch (recurringDeleteMode) {
            case RecurringDeleteMode.thisOnly:
              // Delete only this instance
              logger.d('   Deleting this instance only');
              await _deleteSingleTodo(id, notificationService, repository, syncNotifier);
              break;

            case RecurringDeleteMode.thisAndFuture:
              // Delete this and all future instances
              logger.d('   Deleting this and future instances');

              final allTodosResult = await repository.getTodos();
              await allTodosResult.fold(
                (failure) async {
                  logger.e('❌ TodoActions: Failed to fetch todos');
                  syncNotifier.syncFailed('$failure', shouldRetry: true);
                  throw Exception('${'todos_fetch_failed'.tr()}: $failure');
                },
                (allTodos) async {
                  // Find all future instances including this one
                  final instancesToDelete = allTodos.where((t) =>
                    t.parentRecurringTodoId == todo.parentRecurringTodoId &&
                    t.dueDate != null &&
                    todo.dueDate != null &&
                    (t.dueDate!.isAfter(todo.dueDate!) ||
                     t.dueDate!.isAtSameMomentAs(todo.dueDate!))
                  ).toList();

                  logger.d('   Deleting ${instancesToDelete.length} instances');
                  for (final instance in instancesToDelete) {
                    await _deleteSingleTodo(instance.id, notificationService, repository, syncNotifier);
                  }
                },
              );
              break;

            case RecurringDeleteMode.entireSeries:
              // Delete master and all instances
              logger.d('   Deleting entire series');

              final allTodosResult = await repository.getTodos();
              await allTodosResult.fold(
                (failure) async {
                  logger.e('❌ TodoActions: Failed to fetch todos');
                  syncNotifier.syncFailed('$failure', shouldRetry: true);
                  throw Exception('${'todos_fetch_failed'.tr()}: $failure');
                },
                (allTodos) async {
                  // Find all instances
                  final allInstances = allTodos.where((t) =>
                    t.parentRecurringTodoId == todo.parentRecurringTodoId
                  ).toList();

                  // Delete all instances
                  logger.d('   Deleting ${allInstances.length} instances');
                  for (final instance in allInstances) {
                    await _deleteSingleTodo(instance.id, notificationService, repository, syncNotifier);
                  }

                  // Delete the master todo
                  logger.d('   Deleting master todo ${todo.parentRecurringTodoId}');
                  await _deleteSingleTodo(todo.parentRecurringTodoId!, notificationService, repository, syncNotifier);
                },
              );
              break;
          }
        } else {
          // Regular todo deletion (non-recurring or master todo)
          logger.d('📝 TodoActions: Deleting regular todo');
          await _deleteSingleTodo(id, notificationService, repository, syncNotifier);
        }

        // Sync success
        await syncNotifier.syncSuccess();
        ref.invalidate(todosProvider);
        await _updateWidget();
      },
    );
  }

  /// Helper method to delete a single todo with notification and attachment cleanup
  Future<void> _deleteSingleTodo(
    int id,
    NotificationService notificationService,
    dynamic repository,
    SyncStateNotifier syncNotifier,
  ) async {
    // Cancel notification before deleting todo
    try {
      await notificationService.cancelNotification(id);
      logger.d('✅ TodoActions: Notification cancelled for todo $id');
    } catch (e) {
      logger.d('⚠️ TodoActions: Failed to cancel notification: $e');
      // Continue with deletion even if notification cancel fails
    }

    // Delete attachments from Supabase Storage before deleting todo
    try {
      final attachmentService = ref.read(attachmentServiceProvider);
      final deleteResult = await attachmentService.deleteFilesByTodoId(id);
      deleteResult.fold(
        (failure) {
          logger.d('⚠️ TodoActions: Failed to delete attachments for todo $id: $failure');
          // Continue with todo deletion even if attachment deletion fails
        },
        (_) {
          logger.d('✅ TodoActions: Attachments deleted for todo $id');
        },
      );
    } catch (e) {
      logger.d('⚠️ TodoActions: Error deleting attachments: $e');
      // Continue with todo deletion even if attachment deletion fails
    }

    final result = await repository.deleteTodo(id);
    result.fold(
      (failure) {
        logger.e('❌ TodoActions: Failed to delete todo $id');
        logger.e('   Error: $failure');
        syncNotifier.syncFailed('$failure', shouldRetry: true);
        throw Exception('${'db_delete_failed'.tr()}: $failure');
      },
      (_) {
        logger.d('✅ TodoActions: Todo deleted successfully: $id');
      },
    );
  }

  Future<void> toggleCompletion(int id) async {
    final repository = ref.read(todoRepositoryProvider);
    final syncNotifier = ref.read(syncStateProvider.notifier);

    // Start sync
    syncNotifier.startSync();

    // First, fetch the todo to check if it's a recurring instance
    final todoResult = await repository.getTodoById(id);
    await todoResult.fold(
      (failure) async {
        logger.e('❌ TodoActions: Failed to fetch todo for toggle completion');
        syncNotifier.syncFailed('$failure', shouldRetry: true);
        throw Exception('${'todo_fetch_failed'.tr()}: $failure');
      },
      (todo) async {
        // Toggle the completion status
        final result = await repository.toggleCompletion(id);
        await result.fold(
          (failure) async {
            logger.e('❌ TodoActions: Failed to toggle completion');
            syncNotifier.syncFailed('$failure', shouldRetry: true);
            throw Exception(failure);
          },
          (_) async {
            logger.d('✅ TodoActions: Todo completion toggled: $id');

            // If this is a recurring instance being completed, generate next instances
            if (!todo.isCompleted && todo.parentRecurringTodoId != null) {
              logger.d('🔄 TodoActions: Recurring instance completed, regenerating instances');

              try {
                // Fetch the master todo
                final masterResult = await repository.getTodoById(todo.parentRecurringTodoId!);
                await masterResult.fold(
                  (failure) {
                    logger.e('❌ TodoActions: Failed to fetch master todo');
                  },
                  (masterTodo) async {
                    // Regenerate instances for the master todo
                    final recurringService = ref.read(recurringTodoServiceProvider);
                    final allTodosResult = await repository.getTodos();

                    await allTodosResult.fold(
                      (failure) {
                        logger.e('❌ TodoActions: Failed to fetch todos for regeneration');
                      },
                      (allTodos) async {
                        await recurringService.generateInstancesForNewMaster(masterTodo);
                        logger.d('✅ TodoActions: Next recurring instances generated');
                      },
                    );
                  },
                );
              } catch (e, stackTrace) {
                logger.e('❌ TodoActions: Failed to generate next recurring instance',
                  error: e, stackTrace: stackTrace);
                // Don't throw - allow completion to succeed even if generation fails
              }
            }

            // Sync success
            await syncNotifier.syncSuccess();
            ref.invalidate(todosProvider);
            ref.invalidate(todoDetailProvider(id));
            await _updateWidget();
          },
        );
      },
    );
  }

  /// Reschedule a todo to a new date
  /// Maintains the original time, only changes the date
  Future<void> rescheduleTodo(
    int id,
    DateTime newDate,
  ) async {
    final repository = ref.read(todoRepositoryProvider);
    final notificationService = ref.read(notificationServiceProvider);

    logger.d('📅 TodoActions: Rescheduling todo $id to $newDate');

    // Fetch the current todo
    final todoResult = await repository.getTodoById(id);
    await todoResult.fold(
      (failure) {
        logger.e('❌ TodoActions: Failed to fetch todo for rescheduling');
        throw Exception('${'todo_fetch_failed'.tr()}: $failure');
      },
      (todo) async {
        if (todo.dueDate == null) {
          throw Exception('cannot_reschedule_without_due_date'.tr());
        }

        // Keep the original time, change only the date
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

        // Calculate new notification time if it exists
        DateTime? newNotificationTime;
        if (todo.notificationTime != null && todo.dueDate != null) {
          // Calculate the time difference between notification and due date
          final difference = todo.dueDate!.difference(todo.notificationTime!);
          // Apply the same difference to the new due date
          newNotificationTime = newDueDate.subtract(difference);
        }

        // Update the todo
        final updatedTodo = todo.copyWith(
          dueDate: newDueDate,
          notificationTime: newNotificationTime,
        );

        logger.d('   New due date: $newDueDate');
        logger.d('   New notification time: $newNotificationTime');

        final result = await repository.updateTodo(updatedTodo);
        await result.fold(
          (failure) {
            logger.e('❌ TodoActions: Failed to reschedule todo');
            throw Exception('${'reschedule_failed'.tr()}: $failure');
          },
          (_) async {
            logger.d('✅ TodoActions: Todo rescheduled successfully');

            // Update notification if it exists
            if (newNotificationTime != null) {
              try {
                // Cancel old notification
                await notificationService.cancelNotification(id);
                // Schedule new notification
                await notificationService.scheduleNotification(
                  id: id,
                  title: 'todo_reminder'.tr(),
                  body: todo.title,
                  scheduledDate: newNotificationTime,
                );
                logger.d('✅ TodoActions: Notification rescheduled');
              } catch (e) {
                logger.e('❌ TodoActions: Failed to reschedule notification: $e');
                // Don't throw - allow reschedule to succeed even if notification fails
              }
            }

            ref.invalidate(todosProvider);
            ref.invalidate(todoDetailProvider(id));
            await _updateWidget();
          },
        );
      },
    );
  }

  /// Delete all completed todos
  Future<int> deleteCompletedTodos() async {
    final repository = ref.read(todoRepositoryProvider);

    final result = await repository.deleteCompletedTodos();

    return await result.fold(
      (failure) => throw Exception('Failed to delete completed todos'),
      (count) async {
        ref.invalidate(todosProvider);
        await _updateWidget();
        return count;
      },
    );
  }

  Future<void> updateTodoPositions(List<Todo> todos) async {
    final repository = ref.read(todoRepositoryProvider);
    final result = await repository.updateTodoPositions(todos);

    result.fold(
      (failure) {
        logger.e('❌ TodoActions: Failed to update todo positions');
        logger.e('   Error: $failure');
        throw Exception('${'position_update_failed'.tr()}: $failure');
      },
      (_) {
        logger.d('✅ TodoActions: Todo positions updated successfully');
        ref.invalidate(todosProvider);
      },
    );
  }
}

final todoActionsProvider = Provider((ref) => TodoActions(ref));
