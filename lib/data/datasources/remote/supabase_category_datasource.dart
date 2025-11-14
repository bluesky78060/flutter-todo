import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_app/core/utils/app_logger.dart';

class SupabaseCategoryDataSource {
  final SupabaseClient client;

  SupabaseCategoryDataSource(this.client);

  // Get all categories for current user
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await client
          .from('categories')
          .select()
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      AppLogger.error('Failed to fetch categories from Supabase', error: e);
      rethrow;
    }
  }

  // Create category in Supabase
  Future<Map<String, dynamic>> createCategory({
    required String userId,
    required String name,
    required String color,
    String? icon,
  }) async {
    try {
      final response = await client.from('categories').insert({
        'user_id': userId,
        'name': name,
        'color': color,
        'icon': icon,
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      AppLogger.info('✅ Category created in Supabase: $name');
      return response as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('❌ Failed to create category in Supabase', error: e);
      rethrow;
    }
  }

  // Update category in Supabase
  Future<void> updateCategory({
    required int id,
    required String name,
    required String color,
    String? icon,
  }) async {
    try {
      await client.from('categories').update({
        'name': name,
        'color': color,
        'icon': icon,
      }).eq('id', id);

      AppLogger.info('✅ Category updated in Supabase: $name');
    } catch (e) {
      AppLogger.error('❌ Failed to update category in Supabase', error: e);
      rethrow;
    }
  }

  // Delete category from Supabase
  Future<void> deleteCategory(int id) async {
    try {
      await client.from('categories').delete().eq('id', id);
      AppLogger.info('✅ Category deleted from Supabase: $id');
    } catch (e) {
      AppLogger.error('❌ Failed to delete category from Supabase', error: e);
      rethrow;
    }
  }

  // Sync local category to Supabase (upsert)
  Future<void> syncCategory({
    required int localId,
    required String userId,
    required String name,
    required String color,
    String? icon,
    required DateTime createdAt,
  }) async {
    try {
      // Try to upsert with the same local ID
      await client.from('categories').upsert({
        'id': localId,
        'user_id': userId,
        'name': name,
        'color': color,
        'icon': icon,
        'created_at': createdAt.toIso8601String(),
      });

      AppLogger.info('✅ Category synced to Supabase: $name (ID: $localId)');
    } catch (e) {
      AppLogger.error('❌ Failed to sync category to Supabase', error: e);
      rethrow;
    }
  }
}
