import 'package:supabase_flutter/supabase_flutter.dart';
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
    return (response as List).map((json) => _todoFromJson(json)).toList();
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
  }) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated. Please login first.');
    }

    final response = await client.from('todos').insert({
      'title': title,
      'description': description,
      'user_id': userId,
      'category_id': categoryId,
      'due_date': dueDate?.toIso8601String(),
      'notification_time': notificationTime?.toIso8601String(),
    }).select('id').single();

    return response['id'] as int;
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
    }).eq('id', todo.id);
  }

  // Delete todo
  Future<void> deleteTodo(int id) async {
    await client.from('todos').delete().eq('id', id);
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
      id: 0, // Supabase uses UUID, but keeping int for compatibility
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
        id: 0,
        email: user.email ?? '',
        name: user.userMetadata?['name'] as String? ?? user.email ?? '',
        createdAt: user.createdAt.isNotEmpty ? DateTime.parse(user.createdAt) : null,
      );
    });
  }
}
