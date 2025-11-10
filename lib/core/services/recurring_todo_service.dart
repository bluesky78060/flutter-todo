import 'package:flutter/foundation.dart';
import 'package:todo_app/core/utils/app_logger.dart';
import 'package:todo_app/core/utils/recurrence_utils.dart';
import 'package:todo_app/domain/entities/todo.dart';
import 'package:todo_app/domain/repositories/todo_repository.dart';

/// Service for managing recurring todo instances
///
/// This service handles:
/// - Generating instances from recurring todo patterns
/// - Checking if new instances need to be created
/// - Managing the lifecycle of recurring todo instances
class RecurringTodoService {
  final TodoRepository repository;

  RecurringTodoService(this.repository);

  /// Generate upcoming instances for all recurring todos
  ///
  /// This should be called:
  /// - On app startup
  /// - After creating a new recurring todo
  /// - Periodically (e.g., daily) to ensure instances are always available
  ///
  /// [lookAheadDays] - How many days ahead to generate instances (default: 30)
  Future<void> generateUpcomingInstances({int lookAheadDays = 30}) async {
    try {
      if (kDebugMode) {
        logger.d('🔄 RecurringTodoService: Starting instance generation');
        logger.d('   Look-ahead period: $lookAheadDays days');
      }

      // Get all todos
      final todosResult = await repository.getTodos();

      await todosResult.fold(
        (failure) {
          logger.e('❌ RecurringTodoService: Failed to fetch todos');
          logger.e('   Error: $failure');
        },
        (todos) async {
          // Filter to get only master recurring todos (those with recurrence_rule but no parent)
          final masterRecurringTodos = todos.where((todo) =>
            todo.recurrenceRule != null &&
            todo.parentRecurringTodoId == null &&
            !todo.isCompleted // Don't generate from completed masters
          ).toList();

          if (kDebugMode) {
            logger.d('📋 RecurringTodoService: Found ${masterRecurringTodos.length} master recurring todos');
          }

          for (final masterTodo in masterRecurringTodos) {
            await _generateInstancesForMaster(
              masterTodo,
              todos,
              lookAheadDays: lookAheadDays,
            );
          }

          if (kDebugMode) {
            logger.d('✅ RecurringTodoService: Instance generation completed');
          }
        },
      );
    } catch (e, stackTrace) {
      logger.e('❌ RecurringTodoService: Error during instance generation',
        error: e, stackTrace: stackTrace);
    }
  }

  /// Generate instances for a specific master recurring todo
  Future<void> _generateInstancesForMaster(
    Todo masterTodo,
    List<Todo> allTodos, {
    required int lookAheadDays,
  }) async {
    try {
      final rrule = masterTodo.recurrenceRule;
      if (rrule == null) return;

      if (kDebugMode) {
        logger.d('🔍 RecurringTodoService: Processing master todo #${masterTodo.id}');
        logger.d('   Title: ${masterTodo.title}');
        logger.d('   RRULE: $rrule');
      }

      // Check if recurrence has ended
      if (RecurrenceUtils.isRecurrenceEnded(rrule, DateTime.now())) {
        if (kDebugMode) {
          logger.d('⏹️ RecurringTodoService: Recurrence has ended for todo #${masterTodo.id}');
        }
        return;
      }

      // Get existing instances for this master todo
      final existingInstances = allTodos.where((todo) =>
        todo.parentRecurringTodoId == masterTodo.id
      ).toList();

      if (kDebugMode) {
        logger.d('   Existing instances: ${existingInstances.length}');
      }

      // Get the base date for generating instances
      // Use the master's due date if available, otherwise use creation date
      final baseDate = masterTodo.dueDate ?? masterTodo.createdAt;

      // Calculate the end date for instance generation
      final endDate = DateTime.now().add(Duration(days: lookAheadDays));

      // Get all occurrences within the look-ahead period
      final occurrences = RecurrenceUtils.getNextOccurrences(
        rrule,
        baseDate,
        count: 100, // Get up to 100 occurrences
        after: DateTime.now(),
      );

      if (kDebugMode) {
        logger.d('   Calculated occurrences: ${occurrences.length}');
      }

      // Filter occurrences to only those within the look-ahead period
      final upcomingOccurrences = occurrences.where((occurrence) =>
        occurrence.isBefore(endDate) || occurrence.isAtSameMomentAs(endDate)
      ).toList();

      if (kDebugMode) {
        logger.d('   Upcoming occurrences (within $lookAheadDays days): ${upcomingOccurrences.length}');
      }

      // Generate instances for occurrences that don't have instances yet
      int created = 0;
      for (final occurrence in upcomingOccurrences) {
        // Check if an instance already exists for this occurrence
        final hasInstance = existingInstances.any((instance) {
          if (instance.dueDate == null) return false;

          // Consider instances within the same day as the same occurrence
          final instanceDate = DateTime(
            instance.dueDate!.year,
            instance.dueDate!.month,
            instance.dueDate!.day,
          );
          final occurrenceDate = DateTime(
            occurrence.year,
            occurrence.month,
            occurrence.day,
          );

          return instanceDate.isAtSameMomentAs(occurrenceDate);
        });

        if (!hasInstance) {
          await _createInstance(masterTodo, occurrence);
          created++;
        }
      }

      if (kDebugMode && created > 0) {
        logger.d('✨ RecurringTodoService: Created $created new instances for todo #${masterTodo.id}');
      }
    } catch (e, stackTrace) {
      logger.e('❌ RecurringTodoService: Error generating instances for todo #${masterTodo.id}',
        error: e, stackTrace: stackTrace);
    }
  }

  /// Create a single instance from a master recurring todo
  Future<void> _createInstance(Todo masterTodo, DateTime occurrence) async {
    try {
      if (kDebugMode) {
        logger.d('🆕 RecurringTodoService: Creating instance');
        logger.d('   Master: #${masterTodo.id} - ${masterTodo.title}');
        logger.d('   Occurrence: ${occurrence.toIso8601String()}');
      }

      // Calculate notification time if the master has a notification offset
      DateTime? notificationTime;
      if (masterTodo.notificationTime != null && masterTodo.dueDate != null) {
        // Calculate the offset between due date and notification time
        final offset = masterTodo.dueDate!.difference(masterTodo.notificationTime!);

        // Apply the same offset to the occurrence
        notificationTime = occurrence.subtract(offset);

        // Only set notification if it's in the future
        if (notificationTime.isBefore(DateTime.now())) {
          notificationTime = null;
        }
      }

      // Create the instance
      await repository.createTodo(
        masterTodo.title,
        masterTodo.description,
        occurrence,
        categoryId: masterTodo.categoryId,
        notificationTime: notificationTime,
        parentRecurringTodoId: masterTodo.id,
      );

      if (kDebugMode) {
        logger.d('✅ RecurringTodoService: Instance created successfully');
      }
    } catch (e, stackTrace) {
      logger.e('❌ RecurringTodoService: Error creating instance',
        error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Generate instances for a specific master todo (called after creating a new recurring todo)
  Future<void> generateInstancesForNewMaster(Todo masterTodo) async {
    try {
      if (masterTodo.recurrenceRule == null) {
        if (kDebugMode) {
          logger.d('ℹ️ RecurringTodoService: Todo #${masterTodo.id} is not a recurring todo');
        }
        return;
      }

      if (kDebugMode) {
        logger.d('🔄 RecurringTodoService: Generating instances for new master todo #${masterTodo.id}');
      }

      // Get all todos to check for existing instances
      final todosResult = await repository.getTodos();

      await todosResult.fold(
        (failure) {
          logger.e('❌ RecurringTodoService: Failed to fetch todos');
          logger.e('   Error: $failure');
        },
        (todos) async {
          await _generateInstancesForMaster(masterTodo, todos, lookAheadDays: 30);
        },
      );
    } catch (e, stackTrace) {
      logger.e('❌ RecurringTodoService: Error generating instances for new master',
        error: e, stackTrace: stackTrace);
    }
  }
}
