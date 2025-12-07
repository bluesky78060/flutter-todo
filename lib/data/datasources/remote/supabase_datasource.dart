import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_app/core/utils/app_logger.dart';
import 'package:todo_app/domain/entities/todo.dart';
import 'package:todo_app/domain/entities/auth_user.dart' as domain;

/// Remote data source for todo operations via Supabase.
///
/// This class handles all CRUD operations for todos in the Supabase database.
/// Todos are user-specific and filtered by RLS (Row Level Security) policies.
///
/// Features:
/// - Full CRUD operations for todos
/// - Filtering by completion status
/// - Search by title/description
/// - Position-based ordering for drag-and-drop
/// - Support for recurring todos, location-based reminders, and snooze
///
/// See also:
/// - [SupabaseTodoRepository] for the repository implementation
/// - [TodoRepository] for the repository interface
class SupabaseTodoDataSource {
  /// The Supabase client used for database operations.
  final SupabaseClient client;

  /// Creates a new [SupabaseTodoDataSource] with the given [client].
  SupabaseTodoDataSource(this.client);

  /// Retrieves all todos for the current authenticated user.
  ///
  /// Todos are ordered by position (ascending) for drag-and-drop support.
  /// Returns a list of [Todo] entities.
  ///
  /// Throws an exception with detailed error message if the query fails.
  Future<List<Todo>> getTodos() async {
    try {
      if (kDebugMode) {
        logger.d('🔍 getTodos called');
      }

      final response = await client
          .from('todos')
          .select()
          .order('position', ascending: true);

      if (kDebugMode) {
        logger.d('✅ getTodos succeeded, response count: ${(response as List).length}');
      }

      return (response as List).map((json) => _todoFromJson(json)).toList();
    } catch (e, stackTrace) {
      logger.e('❌ getTodos FAILED', error: e, stackTrace: stackTrace);

      // Provide detailed error message
      if (e.toString().contains('permission')) {
        throw Exception('Permission error: Check Supabase RLS policy - $e');
      } else if (e.toString().contains('network')) {
        throw Exception('Network error: Check your internet connection - $e');
      } else if (e.toString().contains('column')) {
        throw Exception('DB schema error: Column does not exist - $e');
      } else {
        throw Exception('Supabase query failed: ${e.toString()}');
      }
    }
  }

  // Get filtered todos
  Future<List<Todo>> getFilteredTodos(String filter) async {
    try {
      if (kDebugMode) {
        logger.d('🔍 getFilteredTodos called with filter: $filter');
      }

      var query = client.from('todos').select();

      if (filter == 'pending') {
        query = query.eq('is_completed', false);
      } else if (filter == 'completed') {
        query = query.eq('is_completed', true);
      }

      if (kDebugMode) {
        logger.d('📡 Executing Supabase query...');
      }

      final response = await query.order('position', ascending: true);

      if (kDebugMode) {
        logger.d('✅ Supabase query succeeded, response count: ${(response as List).length}');
      }

      final todos = (response as List).map((json) => _todoFromJson(json)).toList();

      // Filter out master recurring todos (those with recurrence_rule but no parent)
      // Master todos are templates used only for generating instances
      final filteredTodos = todos.where((todo) {
        // Keep todos that are either:
        // 1. Not recurring (no recurrence_rule), OR
        // 2. Recurring instances (has parent_recurring_todo_id)
        return todo.recurrenceRule == null || todo.parentRecurringTodoId != null;
      }).toList();

      if (kDebugMode) {
        logger.d('✅ getFilteredTodos completed, returning ${filteredTodos.length} todos');
      }

      return filteredTodos;
    } catch (e, stackTrace) {
      logger.e('❌ getFilteredTodos FAILED', error: e, stackTrace: stackTrace);

      // Provide detailed error message
      if (e.toString().contains('permission')) {
        throw Exception('Permission error: Check Supabase RLS policy - $e');
      } else if (e.toString().contains('network')) {
        throw Exception('Network error: Check your internet connection - $e');
      } else if (e.toString().contains('column')) {
        throw Exception('DB schema error: Column does not exist - $e');
      } else {
        throw Exception('Supabase query failed: ${e.toString()}');
      }
    }
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
    String? priority,
    int? parentRecurringTodoId,
    double? locationLatitude,
    double? locationLongitude,
    String? locationName,
    double? locationRadius,
  }) async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Login required. Please log in again.');
      }

      // 최대 position 값을 구해서 새 position 계산
      final maxPositionResponse = await client
          .from('todos')
          .select('position')
          .eq('user_id', userId)
          .order('position', ascending: false)
          .limit(1);

      int newPosition = 0;
      if ((maxPositionResponse as List).isNotEmpty) {
        final maxPosition = maxPositionResponse[0]['position'] as int?;
        if (maxPosition != null) {
          newPosition = maxPosition + 1;
        }
      }

      if (kDebugMode) {
        logger.d('Creating todo: userId=$userId, title=$title, '
            'categoryId=$categoryId, dueDate=${dueDate?.toIso8601String()}, '
            'notificationTime=${notificationTime?.toIso8601String()}, '
            'recurrenceRule=$recurrenceRule, priority=$priority, parentRecurringTodoId=$parentRecurringTodoId, '
            'location=$locationLatitude,$locationLongitude, position=$newPosition');
      }

      final response = await client.from('todos').insert({
        'title': title,
        'description': description,
        'user_id': userId,
        'category_id': categoryId,
        'due_date': dueDate?.toUtc().toIso8601String(),
        'notification_time': notificationTime?.toUtc().toIso8601String(),
        'recurrence_rule': recurrenceRule,
        'priority': priority ?? 'medium',
        'parent_recurring_todo_id': parentRecurringTodoId,
        'location_latitude': locationLatitude,
        'location_longitude': locationLongitude,
        'location_name': locationName,
        'location_radius': locationRadius,
        'position': newPosition,
      }).select('id').single();

      if (kDebugMode) {
        logger.d('Todo created successfully with id: ${response['id']}, position: $newPosition');
      }
      return response['id'] as int;
    } catch (e, stackTrace) {
      logger.e('Error creating todo', error: e, stackTrace: stackTrace);

      // Supabase 에러를 좀 더 명확하게 표시
      if (e.toString().contains('permission')) {
        throw Exception('Permission error: Check Supabase RLS policy');
      } else if (e.toString().contains('network')) {
        throw Exception('Network error: Check your internet connection');
      } else {
        throw Exception('Database save failed: ${e.toString()}');
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
      'completed_at': todo.completedAt?.toUtc().toIso8601String(),
      'due_date': todo.dueDate?.toUtc().toIso8601String(),
      'notification_time': todo.notificationTime?.toUtc().toIso8601String(),
      'recurrence_rule': todo.recurrenceRule,
      'priority': todo.priority,
      'parent_recurring_todo_id': todo.parentRecurringTodoId,
      'snooze_count': todo.snoozeCount,
      'last_snooze_time': todo.lastSnoozeTime?.toUtc().toIso8601String(),
      'location_latitude': todo.locationLatitude,
      'location_longitude': todo.locationLongitude,
      'location_name': todo.locationName,
      'location_radius': todo.locationRadius,
      'position': todo.position,
    }).eq('id', todo.id);
  }

  // Delete todo
  Future<void> deleteTodo(int id) async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Login required. Please log in again.');
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
        throw Exception('Permission error: Check Supabase RLS policy');
      } else if (e.toString().contains('network')) {
        throw Exception('Network error: Check your internet connection');
      } else if (e.toString().contains('not found')) {
        throw Exception('Item not found');
      } else {
        throw Exception('Database delete failed: ${e.toString()}');
      }
    }
  }

  // Toggle completion
  Future<void> toggleCompletion(int id) async {
    final todo = await getTodoById(id);
    final newCompleted = !todo.isCompleted;

    await client.from('todos').update({
      'is_completed': newCompleted,
      'completed_at': newCompleted ? DateTime.now().toUtc().toIso8601String() : null,
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

  // Parse DateTime from Supabase as UTC and convert to local time
  // Supabase stores timestamps as UTC but returns them without timezone info
  DateTime? _parseUtcDateTime(String? dateString) {
    if (dateString == null) return null;
    // Parse as UTC, then convert to local time for display
    final parsed = DateTime.parse(dateString);
    // If already has timezone info (ends with Z or +/-), it's handled correctly
    // If not, we need to treat it as UTC
    if (dateString.endsWith('Z') || dateString.contains('+') || RegExp(r'-\d{2}:\d{2}$').hasMatch(dateString)) {
      return parsed.toLocal();
    }
    // No timezone info - treat as UTC
    return DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
      parsed.millisecond,
      parsed.microsecond,
    ).toLocal();
  }

  // Convert JSON to Todo entity
  Todo _todoFromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      isCompleted: json['is_completed'] as bool? ?? false,
      categoryId: json['category_id'] as int?,
      createdAt: _parseUtcDateTime(json['created_at'] as String) ?? DateTime.now(),
      completedAt: _parseUtcDateTime(json['completed_at'] as String?),
      dueDate: _parseUtcDateTime(json['due_date'] as String?),
      notificationTime: _parseUtcDateTime(json['notification_time'] as String?),
      recurrenceRule: json['recurrence_rule'] as String?,
      parentRecurringTodoId: json['parent_recurring_todo_id'] as int?,
      snoozeCount: json['snooze_count'] as int? ?? 0,
      lastSnoozeTime: _parseUtcDateTime(json['last_snooze_time'] as String?),
      locationLatitude: (json['location_latitude'] as num?)?.toDouble(),
      locationLongitude: (json['location_longitude'] as num?)?.toDouble(),
      locationName: json['location_name'] as String?,
      locationRadius: (json['location_radius'] as num?)?.toDouble(),
      position: json['position'] as int? ?? 0,
    );
  }
}

/// Remote data source for authentication operations via Supabase.
///
/// This class handles all authentication operations including:
/// - Email/password authentication
/// - User registration
/// - Session management
/// - Auth state changes stream
///
/// See also:
/// - [SupabaseAuthRepository] for the repository implementation
/// - [AuthRepository] for the repository interface
class SupabaseAuthDataSource {
  /// The Supabase client used for authentication operations.
  final SupabaseClient client;

  /// Creates a new [SupabaseAuthDataSource] with the given [client].
  SupabaseAuthDataSource(this.client);

  /// Retrieves the currently authenticated user.
  ///
  /// Returns an [AuthUser] if logged in, null otherwise.
  Future<domain.AuthUser?> getCurrentUser() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    // Get avatar URL from various possible sources in user metadata
    // Priority: custom_avatar_url (user-uploaded) > Supabase Storage URL in avatar_url > OAuth provider's avatar
    final metadata = user.userMetadata;
    String? avatarUrl = metadata?['custom_avatar_url'] as String?;  // User-uploaded avatar (won't be overwritten by OAuth)

    // If no custom_avatar_url, check if avatar_url is a Supabase Storage URL (legacy custom avatar)
    if (avatarUrl == null) {
      final legacyAvatarUrl = metadata?['avatar_url'] as String?;
      if (legacyAvatarUrl != null && _isSupabaseStorageUrl(legacyAvatarUrl)) {
        avatarUrl = legacyAvatarUrl;  // Use legacy custom avatar
      } else {
        avatarUrl = legacyAvatarUrl;  // Use OAuth avatar_url
      }
    }

    avatarUrl ??= metadata?['picture'] as String?;     // Google OAuth uses 'picture' key
    avatarUrl ??= metadata?['avatar'] as String?;      // Some providers use 'avatar' key

    // Get display name from various possible sources
    String? displayName = metadata?['display_name'] as String?;
    displayName ??= metadata?['full_name'] as String?;

    return domain.AuthUser(
      // ignore: deprecated_member_use_from_same_package
      id: user.id.hashCode,  // Legacy: hash UUID to int for backward compatibility
      uuid: user.id,  // Primary: use Supabase UUID
      email: user.email ?? '',
      name: metadata?['name'] as String? ?? user.email ?? '',
      displayName: displayName,
      avatarUrl: avatarUrl,
      createdAt: user.createdAt.isNotEmpty ? DateTime.parse(user.createdAt) : null,
    );
  }

  /// Checks if the URL is a Supabase Storage URL (user-uploaded avatar)
  bool _isSupabaseStorageUrl(String url) {
    return url.contains('supabase.co/storage') ||
           url.contains('bulwfcsyqgsvmbadhlye');
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

      // Get avatar URL with same priority as getCurrentUser()
      final metadata = user.userMetadata;
      String? avatarUrl = metadata?['custom_avatar_url'] as String?;

      // If no custom_avatar_url, check if avatar_url is a Supabase Storage URL (legacy custom avatar)
      if (avatarUrl == null) {
        final legacyAvatarUrl = metadata?['avatar_url'] as String?;
        if (legacyAvatarUrl != null && _isSupabaseStorageUrl(legacyAvatarUrl)) {
          avatarUrl = legacyAvatarUrl;  // Use legacy custom avatar
        } else {
          avatarUrl = legacyAvatarUrl;  // Use OAuth avatar_url
        }
      }

      avatarUrl ??= metadata?['picture'] as String?;
      avatarUrl ??= metadata?['avatar'] as String?;

      // Get display name from various possible sources
      String? displayName = metadata?['display_name'] as String?;
      displayName ??= metadata?['full_name'] as String?;

      return domain.AuthUser(
        // ignore: deprecated_member_use_from_same_package
        id: user.id.hashCode,  // Legacy: hash UUID to int
        uuid: user.id,  // Primary: Supabase UUID
        email: user.email ?? '',
        name: metadata?['name'] as String? ?? user.email ?? '',
        displayName: displayName,
        avatarUrl: avatarUrl,
        createdAt: user.createdAt.isNotEmpty ? DateTime.parse(user.createdAt) : null,
      );
    });
  }
}
