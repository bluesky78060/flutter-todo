import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_app/data/datasources/local/app_database.dart';
import 'package:todo_app/data/datasources/remote/supabase_datasource.dart';
import 'package:todo_app/data/repositories/supabase_auth_repository.dart';
import 'package:todo_app/data/repositories/supabase_todo_repository.dart';
import 'package:todo_app/data/repositories/todo_repository_impl.dart';
import 'package:todo_app/domain/repositories/auth_repository.dart';
import 'package:todo_app/domain/repositories/todo_repository.dart';

// Supabase Client Provider
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Local Database Provider
final localDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// SharedPreferences Provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

// Supabase DataSources
final supabaseTodoDataSourceProvider = Provider<SupabaseTodoDataSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseTodoDataSource(client);
});

final supabaseAuthDataSourceProvider = Provider<SupabaseAuthDataSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseAuthDataSource(client);
});

// Repository Providers
// Web: Use Supabase for cross-browser sync
// Mobile: Use local database (notifications work better with real IDs)
final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  if (kIsWeb) {
    // Web uses Supabase for data sync across browsers
    final dataSource = ref.watch(supabaseTodoDataSourceProvider);
    return SupabaseTodoRepository(dataSource);
  } else {
    // Mobile uses local database for offline support and proper notification IDs
    final database = ref.watch(localDatabaseProvider);
    return TodoRepositoryImpl(database);
  }
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dataSource = ref.watch(supabaseAuthDataSourceProvider);
  return SupabaseAuthRepository(dataSource);
});
