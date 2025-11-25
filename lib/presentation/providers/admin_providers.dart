import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_app/core/services/admin_service.dart';
import 'package:todo_app/data/datasources/remote/supabase_admin_datasource.dart';

/// Admin Service Provider
final adminServiceProvider = Provider<AdminService>((ref) {
  final client = Supabase.instance.client;
  return AdminService(client);
});

/// 현재 사용자가 관리자인지 체크하는 Provider
final isAdminProvider = FutureProvider<bool>((ref) async {
  final adminService = ref.watch(adminServiceProvider);
  return await adminService.isAdmin();
});

/// Supabase Admin Datasource Provider
final supabaseAdminDatasourceProvider = Provider<SupabaseAdminDatasource>((ref) {
  final client = Supabase.instance.client;
  return SupabaseAdminDatasource(client);
});

/// 사용자 통계 Provider
final userStatisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final datasource = ref.watch(supabaseAdminDatasourceProvider);
  return await datasource.getUserStatistics();
});

/// Todo 통계 Provider
final todoStatisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final datasource = ref.watch(supabaseAdminDatasourceProvider);
  return await datasource.getTodoStatistics();
});

/// 카테고리 통계 Provider
final categoryStatisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final datasource = ref.watch(supabaseAdminDatasourceProvider);
  return await datasource.getCategoryStatistics();
});

/// 시간대별 활동 통계 Provider
final activityByHourProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final datasource = ref.watch(supabaseAdminDatasourceProvider);
  return await datasource.getActivityByHour();
});

/// 요일별 완료율 통계 Provider
final completionByWeekdayProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final datasource = ref.watch(supabaseAdminDatasourceProvider);
  return await datasource.getCompletionByWeekday();
});
