import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_app/core/utils/app_logger.dart';

/// Remote data source for category operations via Supabase.
///
/// This class handles all CRUD operations for categories in the Supabase database.
/// Categories are user-specific and filtered by RLS (Row Level Security) policies.
///
/// See also:
/// - [CategoryRepositoryImpl] for the local-first repository implementation
/// - [CategoryRepository] for the repository interface
class SupabaseCategoryDataSource {
  /// The Supabase client used for database operations.
  final SupabaseClient client;

  /// Creates a new [SupabaseCategoryDataSource] with the given [client].
  SupabaseCategoryDataSource(this.client);

  /// Retrieves all categories for the current authenticated user.
  ///
  /// Categories are ordered by creation date (newest first).
  /// Returns a list of category data maps.
  ///
  /// Throws an exception if the query fails.
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

  /// Creates a new category in Supabase.
  ///
  /// Parameters:
  /// - [userId]: The UUID of the user creating the category
  /// - [name]: The display name of the category
  /// - [color]: The hex color code for the category
  /// - [icon]: Optional icon identifier for the category
  ///
  /// Returns the created category data including the generated ID.
  /// Throws an exception if the insert fails.
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
        'created_at': DateTime.now().toUtc().toIso8601String(),
      }).select().single();

      AppLogger.info('✅ Category created in Supabase: $name');
      return response as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('❌ Failed to create category in Supabase', error: e);
      rethrow;
    }
  }

  /// Updates an existing category in Supabase.
  ///
  /// Parameters:
  /// - [id]: The ID of the category to update
  /// - [name]: The new display name
  /// - [color]: The new hex color code
  /// - [icon]: Optional new icon identifier
  ///
  /// Throws an exception if the update fails.
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

  /// Deletes a category from Supabase.
  ///
  /// Parameters:
  /// - [id]: The ID of the category to delete
  ///
  /// Note: This may fail if todos are still associated with this category.
  /// Throws an exception if the delete fails.
  Future<void> deleteCategory(int id) async {
    try {
      await client.from('categories').delete().eq('id', id);
      AppLogger.info('✅ Category deleted from Supabase: $id');
    } catch (e) {
      AppLogger.error('❌ Failed to delete category from Supabase', error: e);
      rethrow;
    }
  }

  /// Syncs a local category to Supabase using upsert.
  ///
  /// This method is used for local-first sync scenarios where
  /// the category may or may not exist in Supabase.
  ///
  /// Parameters:
  /// - [localId]: The local database ID to use as the Supabase ID
  /// - [userId]: The UUID of the user owning the category
  /// - [name]: The category name
  /// - [color]: The hex color code
  /// - [icon]: Optional icon identifier
  /// - [createdAt]: The original creation timestamp
  ///
  /// Throws an exception if the upsert fails.
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
        'created_at': createdAt.toUtc().toIso8601String(),
      });

      AppLogger.info('✅ Category synced to Supabase: $name (ID: $localId)');
    } catch (e) {
      AppLogger.error('❌ Failed to sync category to Supabase', error: e);
      rethrow;
    }
  }
}
