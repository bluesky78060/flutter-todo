import 'package:drift/drift.dart';
import 'package:drift/web.dart';

part 'app_database.g.dart';

// Todos Table
class Todos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  DateTimeColumn get notificationTime => dateTime().nullable()();
}

// Users Table (for Auth)
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get email => text().unique()();
  TextColumn get password => text()(); // In production, use proper hashing
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
}

@DriftDatabase(tables: [Todos, Users])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (migrator, from, to) async {
        if (from < 2) {
          // Add notificationTime column to existing todos table
          await migrator.addColumn(todos, todos.notificationTime);
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
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    return WebDatabase(
      'app_database',
      logStatements: false,
    );
  });
}
