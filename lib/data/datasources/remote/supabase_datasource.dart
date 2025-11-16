import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_app/core/utils/app_logger.dart';
import 'package:todo_app/domain/entities/todo.dart';
import 'package:todo_app/domain/entities/auth_user.dart' as domain;

class SupabaseTodoDataSource {
  final SupabaseClient client;

  SupabaseTodoDataSource(this.client);

  // Get all todos for current user
  Future<List<Todo>> getTodos() async {
    final response = await client
        .from('todos')
        .select()
        .order('created_at', ascending: false);

    return (response as List).map((json) => _todoFromJson(json)).toList();
  }

  // Get filtered todos
  Future<List<Todo>> getFilteredTodos(String filter) async {
    var query = client.from('todos').select();

    if (filter == 'pending') {
      query = query.eq('is_completed', false);
    } else if (filter == 'completed') {
      query = query.eq('is_completed', true);
    }

    final response = await query.order('created_at', ascending: false);
    final todos = (response as List).map((json) => _todoFromJson(json)).toList();

    // Filter out master recurring todos (those with recurrence_rule but no parent)
    // Master todos are templates used only for generating instances
    return todos.where((todo) {
      // Keep todos that are either:
      // 1. Not recurring (no recurrence_rule), OR
      // 2. Recurring instances (has parent_recurring_todo_id)
      return todo.recurrenceRule == null || todo.parentRecurringTodoId != null;
    }).toList();
  }

  // Get single todo by ID
  Future<Todo> getTodoById(int id) async {
    final response = await client.from('todos').select().eq('id', id).single();
    return _todoFromJson(response);
  }

  // Create new todo and return the created ID
  Future<int> createTodo(
    String title,
    String description,
    DateTime? dueDate, {
    int? categoryId,
    DateTime? notificationTime,
    String? recurrenceRule,
    int? parentRecurringTodoId,
  }) async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('로그인이 필요합니다. 다시 로그인해주세요.');
      }

      if (kDebugMode) {
        logger.d('Creating todo: userId=$userId, title=$title, '
            'categoryId=$categoryId, dueDate=${dueDate?.toIso8601String()}, '
            'notificationTime=${notificationTime?.toIso8601String()}, '
            'recurrenceRule=$recurrenceRule, parentRecurringTodoId=$parentRecurringTodoId');
      }

      final response = await client.from('todos').insert({
        'title': title,
        'description': description,
        'user_id': userId,
        'category_id': categoryId,
        'due_date': dueDate?.toIso8601String(),
        'notification_time': notificationTime?.toIso8601String(),
        'recurrence_rule': recurrenceRule,
        'parent_recurring_todo_id': parentRecurringTodoId,
      }).select('id').single();

      if (kDebugMode) {
        logger.d('Todo created successfully with id: ${response['id']}');
      }
      return response['id'] as int;
    } catch (e, stackTrace) {
      logger.e('Error creating todo', error: e, stackTrace: stackTrace);

      // Supabase 에러를 좀 더 명확하게 표시
      if (e.toString().contains('permission')) {
        throw Exception('권한 오류: Supabase RLS 정책을 확인하세요');
      } else if (e.toString().contains('network')) {
        throw Exception('네트워크 오류: 인터넷 연결을 확인하세요');
      } else {
        throw Exception('DB 저장 실패: ${e.toString()}');
      }
    }
  }

  // Update todo
  Future<void> updateTodo(Todo todo) async {
    await client.from('todos').update({
      'title': todo.title,
      'description': todo.description,
      'is_completed': todo.isCompleted,
      'category_id': todo.categoryId,
      'completed_at': todo.completedAt?.toIso8601String(),
      'due_date': todo.dueDate?.toIso8601String(),
      'notification_time': todo.notificationTime?.toIso8601String(),
      'recurrence_rule': todo.recurrenceRule,
      'parent_recurring_todo_id': todo.parentRecurringTodoId,
    }).eq('id', todo.id);
  }

  // Delete todo
  Future<void> deleteTodo(int id) async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('로그인이 필요합니다. 다시 로그인해주세요.');
      }

      if (kDebugMode) {
        logger.d('Deleting todo: todoId=$id, userId=$userId');
      }

      await client.from('todos').delete().eq('id', id);

      if (kDebugMode) {
        logger.d('Todo deleted successfully: $id');
      }
    } catch (e, stackTrace) {
      logger.e('Error deleting todo', error: e, stackTrace: stackTrace);

      // Supabase 에러를 좀 더 명확하게 표시
      if (e.toString().contains('permission')) {
        throw Exception('권한 오류: Supabase RLS 정책을 확인하세요');
      } else if (e.toString().contains('network')) {
        throw Exception('네트워크 오류: 인터넷 연결을 확인하세요');
      } else if (e.toString().contains('not found')) {
        throw Exception('항목을 찾을 수 없습니다');
      } else {
        throw Exception('DB 삭제 실패: ${e.toString()}');
      }
    }
  }

  // Toggle completion
  Future<void> toggleCompletion(int id) async {
    final todo = await getTodoById(id);
    final newCompleted = !todo.isCompleted;

    await client.from('todos').update({
      'is_completed': newCompleted,
      'completed_at': newCompleted ? DateTime.now().toIso8601String() : null,
    }).eq('id', id);
  }

  // Delete all completed todos and return count
  Future<int> deleteCompletedTodos() async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Get completed todos count first
    final completedTodos = await client
        .from('todos')
        .select()
        .eq('user_id', user.id)
        .eq('is_completed', true);

    final count = (completedTodos as List).length;

    // Delete completed todos
    await client
        .from('todos')
        .delete()
        .eq('user_id', user.id)
        .eq('is_completed', true);

    return count;
  }

  // Search todos by title or description
  Future<List<Todo>> searchTodos(String query) async {
    if (query.trim().isEmpty) {
      // Return all todos if query is empty
      return getTodos();
    }

    final searchPattern = '%$query%';

    final response = await client
        .from('todos')
        .select()
        .or('title.ilike.$searchPattern,description.ilike.$searchPattern')
        .order('created_at', ascending: false);

    final todos = (response as List).map((json) => _todoFromJson(json)).toList();

    // Filter out master recurring todos (same logic as getFilteredTodos)
    return todos.where((todo) {
      return todo.recurrenceRule == null || todo.parentRecurringTodoId != null;
    }).toList();
  }

  // Convert JSON to Todo entity
  Todo _todoFromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      isCompleted: json['is_completed'] as bool? ?? false,
      categoryId: json['category_id'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      notificationTime: json['notification_time'] != null
          ? DateTime.parse(json['notification_time'] as String)
          : null,
      recurrenceRule: json['recurrence_rule'] as String?,
      parentRecurringTodoId: json['parent_recurring_todo_id'] as int?,
    );
  }
}

class SupabaseAuthDataSource {
  final SupabaseClient client;

  SupabaseAuthDataSource(this.client);

  // Get current user
  Future<domain.AuthUser?> getCurrentUser() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    return domain.AuthUser(
      // ignore: deprecated_member_use_from_same_package
      id: user.id.hashCode,  // Legacy: hash UUID to int for backward compatibility
      uuid: user.id,  // Primary: use Supabase UUID
      email: user.email ?? '',
      name: user.userMetadata?['name'] as String? ?? user.email ?? '',
      createdAt: user.createdAt.isNotEmpty ? DateTime.parse(user.createdAt) : null,
    );
  }

  // Login
  Future<void> login(String email, String password) async {
    await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Register
  Future<void> register(String email, String password, String name) async {
    await client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );
  }

  // Logout
  Future<void> logout() async {
    await client.auth.signOut();
  }

  // Check if authenticated
  bool isAuthenticated() {
    return client.auth.currentUser != null;
  }

  // Listen to auth state changes
  Stream<domain.AuthUser?> authStateChanges() {
    return client.auth.onAuthStateChange.map((data) {
      final user = data.session?.user;
      if (user == null) return null;

      return domain.AuthUser(
        // ignore: deprecated_member_use_from_same_package
        id: user.id.hashCode,  // Legacy: hash UUID to int
        uuid: user.id,  // Primary: Supabase UUID
        email: user.email ?? '',
        name: user.userMetadata?['name'] as String? ?? user.email ?? '',
        createdAt: user.createdAt.isNotEmpty ? DateTime.parse(user.createdAt) : null,
      );
    });
  }
}
