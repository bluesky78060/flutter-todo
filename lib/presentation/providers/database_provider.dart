/// Core database and repository providers for dependency injection.
///
/// This file defines the fundamental providers that supply database access,
/// data sources, and repositories throughout the application using Riverpod.
///
/// Provider hierarchy:
/// 1. Infrastructure providers (Supabase client, local database, SharedPreferences)
/// 2. Data source providers (Supabase todo/auth data sources)
/// 3. Repository providers (todo and auth repositories)
/// 4. Service providers (recurring todo service)
///
/// All providers use Supabase for cloud-based data sync across devices.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_app/core/services/recurring_todo_service.dart';
import 'package:todo_app/data/datasources/local/app_database.dart';
import 'package:todo_app/data/datasources/remote/supabase_datasource.dart';
import 'package:todo_app/data/repositories/supabase_auth_repository.dart';
import 'package:todo_app/data/repositories/supabase_todo_repository.dart';
import 'package:todo_app/domain/repositories/auth_repository.dart';
import 'package:todo_app/domain/repositories/todo_repository.dart';

/// Provides the Supabase client instance for remote operations.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provides the local Drift database for offline-first data storage.
final localDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

/// Provides SharedPreferences for simple key-value storage.
///
/// Note: This provider must be overridden with an actual instance
/// during app initialization. Throws if accessed without override.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

/// Provides the Supabase data source for todo CRUD operations.
final supabaseTodoDataSourceProvider = Provider<SupabaseTodoDataSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseTodoDataSource(client);
});

/// Provides the Supabase data source for authentication operations.
final supabaseAuthDataSourceProvider = Provider<SupabaseAuthDataSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseAuthDataSource(client);
});

/// Provides the todo repository for todo persistence operations.
///
/// Uses Supabase for cloud-based data sync across all platforms.
final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  final dataSource = ref.watch(supabaseTodoDataSourceProvider);
  return SupabaseTodoRepository(dataSource);
});

/// Provides the auth repository for authentication operations.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dataSource = ref.watch(supabaseAuthDataSourceProvider);
  return SupabaseAuthRepository(dataSource);
});

/// Provides the recurring todo service for handling repeating tasks.
///
/// Manages creation of todo instances from RRULE patterns.
final recurringTodoServiceProvider = Provider<RecurringTodoService>((ref) {
  final repository = ref.watch(todoRepositoryProvider);
  return RecurringTodoService(repository);
});
