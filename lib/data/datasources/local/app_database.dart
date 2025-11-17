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

@DriftDatabase(tables: [Categories, Todos, Users, Subtasks])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 5;

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
      },
    );
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
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    return openConnection();
  });
}
