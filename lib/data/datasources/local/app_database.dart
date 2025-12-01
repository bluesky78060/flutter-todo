import 'package:drift/drift.dart';

// Import conditional connection helpers
import 'connection/connection.dart'
    if (dart.library.html) 'connection/web.dart'
    if (dart.library.io) 'connection/native.dart';

part 'app_database.g.dart';

// Categories Table
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()(); // Supabase user UUID
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get color => text()(); // Hex color code
  TextColumn get icon => text().nullable()(); // Icon name or emoji
  DateTimeColumn get createdAt => dateTime()();
}

// Todos Table
class Todos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get categoryId => integer().nullable().references(Categories, #id, onDelete: KeyAction.setNull)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  DateTimeColumn get notificationTime => dateTime().nullable()();
  TextColumn get recurrenceRule => text().nullable()(); // RRULE format
  IntColumn get parentRecurringTodoId => integer().nullable()(); // Reference to parent recurring todo
  IntColumn get snoozeCount => integer().withDefault(const Constant(0))(); // Number of times snoozed
  DateTimeColumn get lastSnoozeTime => dateTime().nullable()(); // Last time snoozed
  RealColumn get locationLatitude => real().nullable()(); // Location latitude
  RealColumn get locationLongitude => real().nullable()(); // Location longitude
  TextColumn get locationName => text().nullable()(); // Human-readable location name
  RealColumn get locationRadius => real().nullable()(); // Geofence radius in meters
  DateTimeColumn get locationTriggeredAt => dateTime().nullable()(); // Last time geofence notification was triggered
  IntColumn get position => integer().withDefault(const Constant(0))(); // Order position for drag and drop sorting
}

// Users Table (for Auth)
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get email => text().unique()();
  TextColumn get password => text()(); // In production, use proper hashing
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
}

// Subtasks Table
class Subtasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get todoId => integer().references(Todos, #id, onDelete: KeyAction.cascade)();
  TextColumn get userId => text()(); // Supabase user UUID
  TextColumn get title => text().withLength(min: 1, max: 200)();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get position => integer()(); // For ordering subtasks
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

// Attachments Table (for file attachments)
class Attachments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get todoId => integer().references(Todos, #id, onDelete: KeyAction.cascade)();
  TextColumn get userId => text()(); // Supabase user UUID
  TextColumn get fileName => text().withLength(min: 1, max: 255)();
  TextColumn get filePath => text()(); // Local file path (if stored locally)
  IntColumn get fileSize => integer()(); // File size in bytes
  TextColumn get mimeType => text()(); // MIME type (e.g., image/jpeg, application/pdf)
  TextColumn get storagePath => text()(); // Full path in Supabase Storage: {user_id}/{todo_id}/{filename}
  DateTimeColumn get createdAt => dateTime()();
}

@DriftDatabase(tables: [Categories, Todos, Users, Subtasks, Attachments])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 11;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (migrator, from, to) async {
        if (from < 2) {
          // Add notificationTime column to existing todos table
          await migrator.addColumn(todos, todos.notificationTime);
        }
        if (from < 3) {
          // Add categories table
          await migrator.createTable(categories);
          // Add categoryId column to todos table
          await migrator.addColumn(todos, todos.categoryId);
        }
        if (from < 4) {
          // Add recurrence fields for recurring todos
          await migrator.addColumn(todos, todos.recurrenceRule);
          await migrator.addColumn(todos, todos.parentRecurringTodoId);
        }
        if (from < 5) {
          // Add subtasks table
          await migrator.createTable(subtasks);
        }
        if (from < 6) {
          // Add snooze fields for notification snoozing
          await migrator.addColumn(todos, todos.snoozeCount);
          await migrator.addColumn(todos, todos.lastSnoozeTime);
        }
        if (from < 7) {
          // Add location-based notification fields
          await migrator.addColumn(todos, todos.locationLatitude);
          await migrator.addColumn(todos, todos.locationLongitude);
          await migrator.addColumn(todos, todos.locationName);
          await migrator.addColumn(todos, todos.locationRadius);
        }
        if (from < 8) {
          // Add position column for drag and drop sorting
          await migrator.addColumn(todos, todos.position);
        }
        if (from < 9) {
          // Add attachments table for file attachments
          await migrator.createTable(attachments);
        }
        if (from < 10) {
          // Add locationTriggeredAt field to track last geofence notification time
          await migrator.addColumn(todos, todos.locationTriggeredAt);
        }
        if (from < 11) {
          // Migrate DateTime columns from INTEGER (unix timestamp) to TEXT (ISO 8601)
          // This preserves timezone information and fixes UTC/local time issues
          await _migrateDateTimeColumnsToText(migrator);
        }
      },
    );
  }

  /// Migrate all DateTime columns from INTEGER to TEXT format
  /// This is required when enabling store_date_time_values_as_text option
  Future<void> _migrateDateTimeColumnsToText(Migrator migrator) async {
    // Helper function to convert unix timestamp to ISO 8601 text
    // datetime(unixTimestamp, 'unixepoch') converts to datetime, then we format as ISO 8601
    const dateTimeConversion = "datetime(old_value, 'unixepoch')";

    // Categories table - created_at column
    await customStatement('''
      UPDATE categories
      SET created_at = $dateTimeConversion
      WHERE typeof(created_at) = 'integer'
    '''.replaceAll('old_value', 'created_at'));

    // Todos table - multiple DateTime columns
    final todoDateColumns = [
      'created_at',
      'completed_at',
      'due_date',
      'notification_time',
      'last_snooze_time',
      'location_triggered_at',
    ];

    for (final column in todoDateColumns) {
      await customStatement('''
        UPDATE todos
        SET $column = datetime($column, 'unixepoch')
        WHERE typeof($column) = 'integer'
      ''');
    }

    // Users table - created_at column
    await customStatement('''
      UPDATE users
      SET created_at = datetime(created_at, 'unixepoch')
      WHERE typeof(created_at) = 'integer'
    ''');

    // Subtasks table - created_at, completed_at columns
    await customStatement('''
      UPDATE subtasks
      SET created_at = datetime(created_at, 'unixepoch')
      WHERE typeof(created_at) = 'integer'
    ''');
    await customStatement('''
      UPDATE subtasks
      SET completed_at = datetime(completed_at, 'unixepoch')
      WHERE typeof(completed_at) = 'integer'
    ''');

    // Attachments table - created_at column
    await customStatement('''
      UPDATE attachments
      SET created_at = datetime(created_at, 'unixepoch')
      WHERE typeof(created_at) = 'integer'
    ''');
  }

  // Get all todos
  Future<List<Todo>> getAllTodos() => select(todos).get();

  // Get todo by id
  Future<Todo?> getTodoById(int id) =>
      (select(todos)..where((t) => t.id.equals(id))).getSingleOrNull();

  // Get filtered todos
  Future<List<Todo>> getFilteredTodos(String filter) {
    if (filter == 'completed') {
      return (select(todos)..where((t) => t.isCompleted.equals(true))).get();
    } else if (filter == 'pending') {
      return (select(todos)..where((t) => t.isCompleted.equals(false))).get();
    }
    return getAllTodos();
  }

  // Get maximum position value
  Future<int> getMaxTodoPosition() async {
    final maxPositionTodo = await (select(todos)
          ..orderBy([(t) => OrderingTerm(expression: t.position, mode: OrderingMode.desc)])
          ..limit(1))
        .getSingleOrNull();
    return maxPositionTodo?.position ?? -1;
  }

  // Insert todo
  Future<int> insertTodo(TodosCompanion todo) => into(todos).insert(todo);

  // Update todo
  Future<bool> updateTodo(Todo todo) => update(todos).replace(todo);

  // Delete todo
  Future<int> deleteTodo(int id) =>
      (delete(todos)..where((t) => t.id.equals(id))).go();

  // Toggle completion
  Future<bool> toggleTodoCompletion(int id) async {
    final todo = await getTodoById(id);
    if (todo == null) return false;

    return update(todos).replace(
      todo.copyWith(
        isCompleted: !todo.isCompleted,
        completedAt: Value(!todo.isCompleted ? DateTime.now() : null),
      ),
    );
  }

  // Auth methods
  Future<User?> getUserByEmail(String email) =>
      (select(users)..where((u) => u.email.equals(email))).getSingleOrNull();

  Future<User?> getUserById(int id) =>
      (select(users)..where((u) => u.id.equals(id))).getSingleOrNull();

  Future<int> insertUser(UsersCompanion user) => into(users).insert(user);

  // Category methods
  Future<List<Category>> getAllCategories() => select(categories).get();

  Future<Category?> getCategoryById(int id) =>
      (select(categories)..where((c) => c.id.equals(id))).getSingleOrNull();

  Future<int> insertCategory(CategoriesCompanion category) =>
      into(categories).insert(category);

  // Insert category with specific ID (for Supabase sync)
  Future<void> insertCategoryWithId(CategoriesCompanion category) =>
      into(categories).insert(category, mode: InsertMode.insertOrReplace);

  Future<bool> updateCategory(Category category) =>
      update(categories).replace(category);

  Future<bool> updateCategoryFromCompanion(CategoriesCompanion category) {
    if (category.id.present) {
      return update(categories).replace(
        Category(
          id: category.id.value,
          userId: category.userId.value,
          name: category.name.value,
          color: category.color.value,
          icon: category.icon.present ? category.icon.value : null,
          createdAt: category.createdAt.value,
        ),
      );
    }
    return Future.value(false);
  }

  Future<int> deleteCategory(int id) =>
      (delete(categories)..where((c) => c.id.equals(id))).go();

  // Get todos by category
  Future<List<Todo>> getTodosByCategory(int categoryId) =>
      (select(todos)..where((t) => t.categoryId.equals(categoryId))).get();

  // Get all todos with location settings (for geofencing)
  Future<List<Todo>> getTodosWithLocation() => (select(todos)
        ..where((t) => t.locationLatitude.isNotNull())
        ..where((t) => t.locationLongitude.isNotNull()))
      .get();

  // Backup/Restore methods
  Future<int> deleteAllTodos() => delete(todos).go();

  Future<int> deleteAllCategories() => delete(categories).go();

  Future<bool> updateTodoFromCompanion(TodosCompanion todo) {
    if (todo.id.present) {
      return update(todos).replace(
        Todo(
          id: todo.id.value,
          title: todo.title.value,
          description: todo.description.value,
          isCompleted: todo.isCompleted.value,
          categoryId: todo.categoryId.present ? todo.categoryId.value : null,
          createdAt: todo.createdAt.value,
          completedAt: todo.completedAt.present ? todo.completedAt.value : null,
          dueDate: todo.dueDate.present ? todo.dueDate.value : null,
          notificationTime: todo.notificationTime.present ? todo.notificationTime.value : null,
          recurrenceRule: todo.recurrenceRule.present ? todo.recurrenceRule.value : null,
          parentRecurringTodoId: todo.parentRecurringTodoId.present ? todo.parentRecurringTodoId.value : null,
          snoozeCount: todo.snoozeCount.present ? todo.snoozeCount.value : 0,
          lastSnoozeTime: todo.lastSnoozeTime.present ? todo.lastSnoozeTime.value : null,
          locationLatitude: todo.locationLatitude.present ? todo.locationLatitude.value : null,
          locationLongitude: todo.locationLongitude.present ? todo.locationLongitude.value : null,
          locationName: todo.locationName.present ? todo.locationName.value : null,
          locationRadius: todo.locationRadius.present ? todo.locationRadius.value : null,
          locationTriggeredAt: todo.locationTriggeredAt.present ? todo.locationTriggeredAt.value : null,
          position: todo.position.present ? todo.position.value : 0,
        ),
      );
    }
    return Future.value(false);
  }

  // Subtask methods
  Future<List<Subtask>> getSubtasksByTodoId(int todoId) =>
      (select(subtasks)
            ..where((s) => s.todoId.equals(todoId))
            ..orderBy([(s) => OrderingTerm(expression: s.position)]))
          .get();

  Future<Subtask?> getSubtaskById(int id) =>
      (select(subtasks)..where((s) => s.id.equals(id))).getSingleOrNull();

  Future<int> insertSubtask(SubtasksCompanion subtask) =>
      into(subtasks).insert(subtask);

  Future<bool> updateSubtask(Subtask subtask) =>
      update(subtasks).replace(subtask);

  Future<int> deleteSubtask(int id) =>
      (delete(subtasks)..where((s) => s.id.equals(id))).go();

  Future<bool> toggleSubtaskCompletion(int id) async {
    final subtask = await getSubtaskById(id);
    if (subtask == null) return false;

    return update(subtasks).replace(
      subtask.copyWith(
        isCompleted: !subtask.isCompleted,
        completedAt: Value(!subtask.isCompleted ? DateTime.now() : null),
      ),
    );
  }

  Future<int> deleteSubtasksByTodoId(int todoId) =>
      (delete(subtasks)..where((s) => s.todoId.equals(todoId))).go();

  // Get subtask completion statistics for a todo
  Future<Map<String, int>> getSubtaskStats(int todoId) async {
    final allSubtasks = await getSubtasksByTodoId(todoId);
    final completedCount = allSubtasks.where((s) => s.isCompleted).length;
    return {
      'total': allSubtasks.length,
      'completed': completedCount,
    };
  }

  // Attachment methods
  Future<List<Attachment>> getAttachmentsByTodoId(int todoId) =>
      (select(attachments)..where((a) => a.todoId.equals(todoId))).get();

  Future<Attachment?> getAttachmentById(int id) =>
      (select(attachments)..where((a) => a.id.equals(id))).getSingleOrNull();

  Future<int> insertAttachment(AttachmentsCompanion attachment) =>
      into(attachments).insert(attachment);

  Future<bool> updateAttachment(Attachment attachment) =>
      update(attachments).replace(attachment);

  Future<int> deleteAttachment(int id) =>
      (delete(attachments)..where((a) => a.id.equals(id))).go();

  Future<int> deleteAttachmentsByTodoId(int todoId) =>
      (delete(attachments)..where((a) => a.todoId.equals(todoId))).go();

  // Get attachment count for a todo
  Future<int> getAttachmentCount(int todoId) async {
    final allAttachments = await getAttachmentsByTodoId(todoId);
    return allAttachments.length;
  }

  // Get total file size for a todo's attachments
  Future<int> getTotalFileSize(int todoId) async {
    final allAttachments = await getAttachmentsByTodoId(todoId);
    return allAttachments.fold<int>(0, (sum, a) => sum + a.fileSize);
  }

  // Batch update todo positions (performance optimization)
  Future<void> batchUpdateTodoPositions(List<Todo> todosList) async {
    await batch((batch) {
      for (final todo in todosList) {
        batch.update(
          todos,
          TodosCompanion(position: Value(todo.position ?? 0)),
          where: (tbl) => tbl.id.equals(todo.id),
        );
      }
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    return openConnection();
  });
}
