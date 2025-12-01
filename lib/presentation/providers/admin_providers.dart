/// Admin dashboard state management providers using Riverpod.
///
/// Provides admin-only statistics and analytics for the application,
/// including user statistics, todo statistics, and activity patterns.
///
/// Key providers:
/// - [adminServiceProvider]: Admin service for admin checks
/// - [isAdminProvider]: Whether current user is an admin
/// - [userStatisticsProvider]: User registration and activity stats
/// - [todoStatisticsProvider]: Todo creation and completion stats
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_app/core/services/admin_service.dart';
import 'package:todo_app/data/datasources/remote/supabase_admin_datasource.dart';

/// Provides the admin service for admin-related operations.
final adminServiceProvider = Provider<AdminService>((ref) {
  final client = Supabase.instance.client;
  return AdminService(client);
});

/// Provides whether the current user is an admin.
final isAdminProvider = FutureProvider<bool>((ref) async {
  final adminService = ref.watch(adminServiceProvider);
  return await adminService.isAdmin();
});

/// Provides the Supabase admin datasource for statistics queries.
final supabaseAdminDatasourceProvider = Provider<SupabaseAdminDatasource>((ref) {
  final client = Supabase.instance.client;
  return SupabaseAdminDatasource(client);
});

/// Provides user registration and activity statistics.
final userStatisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final datasource = ref.watch(supabaseAdminDatasourceProvider);
  return await datasource.getUserStatistics();
});

/// Provides todo creation and completion statistics.
final todoStatisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final datasource = ref.watch(supabaseAdminDatasourceProvider);
  return await datasource.getTodoStatistics();
});

/// Provides category usage statistics.
final categoryStatisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final datasource = ref.watch(supabaseAdminDatasourceProvider);
  return await datasource.getCategoryStatistics();
});

/// Provides hourly activity distribution statistics.
final activityByHourProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final datasource = ref.watch(supabaseAdminDatasourceProvider);
  return await datasource.getActivityByHour();
});

/// Provides weekly completion rate statistics by day of week.
final completionByWeekdayProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final datasource = ref.watch(supabaseAdminDatasourceProvider);
  return await datasource.getCompletionByWeekday();
});
