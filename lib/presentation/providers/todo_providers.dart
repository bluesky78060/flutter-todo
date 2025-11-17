import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/services/notification_service.dart';
import 'package:todo_app/domain/entities/todo.dart';
import 'package:todo_app/presentation/providers/database_provider.dart';
import 'package:todo_app/core/utils/app_logger.dart';
import 'package:todo_app/presentation/widgets/recurring_edit_dialog.dart';
import 'package:todo_app/presentation/widgets/recurring_delete_dialog.dart';

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

    await result.fold(
      (failure) {
        logger.e('❌ TodoActions: Failed to create todo');
        logger.e('   Error: $failure');
        throw Exception('DB 저장 실패: $failure');
      },
      (todoId) async {
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
              title: '할일 알림',
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
            await todoResult.fold(
              (failure) {
                logger.e('❌ TodoActions: Failed to fetch created todo for recurring instance generation');
              },
              (todo) async {
                await recurringService.generateInstancesForNewMaster(todo);
                logger.d('✅ TodoActions: Recurring instances generated successfully');
              },
            );
          } catch (e, stackTrace) {
            logger.e('❌ TodoActions: Failed to generate recurring instances',
              error: e, stackTrace: stackTrace);
            // Don't throw - allow todo creation to succeed even if instance generation fails
          }
        }

        ref.invalidate(todosProvider);
      },
    );
  }

  /// Update a todo
  /// For recurring todo instances, this should be called after showing RecurringEditDialog
  Future<void> updateTodo(
    Todo todo, {
    RecurringEditMode? recurringEditMode,
  }) async {
    final repository = ref.read(todoRepositoryProvider);

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
          result.fold(
            (failure) => throw Exception(failure),
            (_) {
              logger.d('✅ TodoActions: Instance detached and updated');
              ref.invalidate(todosProvider);
              ref.invalidate(todoDetailProvider(todo.id));
            },
          );
          break;

        case RecurringEditMode.thisAndFuture:
          // Edit this and future instances - update the master todo
          logger.d('   Updating master and future instances');

          // First, get the master todo
          final masterResult = await repository.getTodoById(todo.parentRecurringTodoId!);
          await masterResult.fold(
            (failure) {
              logger.e('❌ TodoActions: Failed to fetch master todo');
              throw Exception('마스터 todo 조회 실패: $failure');
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
                (failure) {
                  logger.e('❌ TodoActions: Failed to update master todo');
                  throw Exception('마스터 todo 업데이트 실패: $failure');
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

                  ref.invalidate(todosProvider);
                  ref.invalidate(todoDetailProvider(todo.id));
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
      result.fold(
        (failure) => throw Exception(failure),
        (_) {
          logger.d('✅ TodoActions: Todo updated successfully');
          ref.invalidate(todosProvider);
          ref.invalidate(todoDetailProvider(todo.id));
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

    logger.d('🗑️ TodoActions: Attempting to delete todo $id');

    // First, fetch the todo to check if it's a recurring instance
    final todoResult = await repository.getTodoById(id);
    await todoResult.fold(
      (failure) {
        logger.e('❌ TodoActions: Failed to fetch todo for deletion');
        throw Exception('Todo 조회 실패: $failure');
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
              await _deleteSingleTodo(id, notificationService, repository);
              break;

            case RecurringDeleteMode.thisAndFuture:
              // Delete this and all future instances
              logger.d('   Deleting this and future instances');

              final allTodosResult = await repository.getTodos();
              await allTodosResult.fold(
                (failure) {
                  logger.e('❌ TodoActions: Failed to fetch todos');
                  throw Exception('Todos 조회 실패: $failure');
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
                    await _deleteSingleTodo(instance.id, notificationService, repository);
                  }
                },
              );
              break;

            case RecurringDeleteMode.entireSeries:
              // Delete master and all instances
              logger.d('   Deleting entire series');

              final allTodosResult = await repository.getTodos();
              await allTodosResult.fold(
                (failure) {
                  logger.e('❌ TodoActions: Failed to fetch todos');
                  throw Exception('Todos 조회 실패: $failure');
                },
                (allTodos) async {
                  // Find all instances
                  final allInstances = allTodos.where((t) =>
                    t.parentRecurringTodoId == todo.parentRecurringTodoId
                  ).toList();

                  // Delete all instances
                  logger.d('   Deleting ${allInstances.length} instances');
                  for (final instance in allInstances) {
                    await _deleteSingleTodo(instance.id, notificationService, repository);
                  }

                  // Delete the master todo
                  logger.d('   Deleting master todo ${todo.parentRecurringTodoId}');
                  await _deleteSingleTodo(todo.parentRecurringTodoId!, notificationService, repository);
                },
              );
              break;
          }
        } else {
          // Regular todo deletion (non-recurring or master todo)
          logger.d('📝 TodoActions: Deleting regular todo');
          await _deleteSingleTodo(id, notificationService, repository);
        }

        ref.invalidate(todosProvider);
      },
    );
  }

  /// Helper method to delete a single todo with notification cleanup
  Future<void> _deleteSingleTodo(
    int id,
    NotificationService notificationService,
    dynamic repository,
  ) async {
    // Cancel notification before deleting todo
    try {
      await notificationService.cancelNotification(id);
      logger.d('✅ TodoActions: Notification cancelled for todo $id');
    } catch (e) {
      logger.d('⚠️ TodoActions: Failed to cancel notification: $e');
      // Continue with deletion even if notification cancel fails
    }

    final result = await repository.deleteTodo(id);
    result.fold(
      (failure) {
        logger.e('❌ TodoActions: Failed to delete todo $id');
        logger.e('   Error: $failure');
        throw Exception('DB 삭제 실패: $failure');
      },
      (_) {
        logger.d('✅ TodoActions: Todo deleted successfully: $id');
      },
    );
  }

  Future<void> toggleCompletion(int id) async {
    final repository = ref.read(todoRepositoryProvider);

    // First, fetch the todo to check if it's a recurring instance
    final todoResult = await repository.getTodoById(id);
    await todoResult.fold(
      (failure) {
        logger.e('❌ TodoActions: Failed to fetch todo for toggle completion');
        throw Exception('Todo 조회 실패: $failure');
      },
      (todo) async {
        // Toggle the completion status
        final result = await repository.toggleCompletion(id);
        await result.fold(
          (failure) {
            logger.e('❌ TodoActions: Failed to toggle completion');
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

            ref.invalidate(todosProvider);
            ref.invalidate(todoDetailProvider(id));
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
        throw Exception('Todo 조회 실패: $failure');
      },
      (todo) async {
        if (todo.dueDate == null) {
          throw Exception('마감일이 없는 할일은 이월할 수 없습니다');
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
            throw Exception('일정 이월 실패: $failure');
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
                  title: '할일 알림',
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
          },
        );
      },
    );
  }

  /// Delete all completed todos
  Future<int> deleteCompletedTodos() async {
    final repository = ref.read(todoRepositoryProvider);

    final result = await repository.deleteCompletedTodos();

    return result.fold(
      (failure) => throw Exception('Failed to delete completed todos'),
      (count) {
        ref.invalidate(todosProvider);
        return count;
      },
    );
  }
}

final todoActionsProvider = Provider((ref) => TodoActions(ref));
