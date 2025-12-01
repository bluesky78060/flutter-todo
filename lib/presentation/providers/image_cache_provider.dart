/// Image caching providers for efficient attachment image management.
///
/// Provides disk-based image caching with automatic lifecycle management,
/// image optimization, and cache statistics.
///
/// Key providers:
/// - [imageCacheServiceProvider]: Singleton cache service instance
/// - [cachedImageFileProvider]: Retrieve cached image by URL
/// - [optimizedImageProvider]: Get resized/compressed image
/// - [imageCacheStatsProvider]: Cache usage statistics
/// - [imageCacheActionsProvider]: Cache management operations
///
/// See also:
/// - [ImageCacheService] for underlying caching implementation
/// - [attachmentServiceProvider] for attachment management
library;

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/services/image_cache_service.dart';

/// Provides the singleton image cache service instance.
///
/// Initializes on first access and automatically disposes when
/// the provider is no longer needed.
final imageCacheServiceProvider = FutureProvider<ImageCacheService>((ref) async {
  final service = ImageCacheService();
  await service.initialize();

  // Cleanup service resources when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Retrieves a cached image file by its URL.
///
/// Downloads and caches the image if not already cached.
/// Returns the local file path for efficient image rendering.
final cachedImageFileProvider =
    FutureProvider.family<File, String>((ref, imageUrl) async {
  final service = await ref.watch(imageCacheServiceProvider.future);
  return service.getImage(imageUrl);
});

/// Caches a local file to the image cache directory.
///
/// Useful for caching user-selected images from device gallery.
final cachedLocalFileProvider =
    FutureProvider.family<File, File>((ref, sourceFile) async {
  final service = await ref.watch(imageCacheServiceProvider.future);
  return service.cacheLocalFile(sourceFile);
});

/// Provides an optimized (resized/compressed) version of an image.
///
/// Reduces image resolution for faster loading and lower memory usage.
/// Original file remains unchanged.
final optimizedImageProvider =
    FutureProvider.family<File, File>((ref, imageFile) async {
  final service = await ref.watch(imageCacheServiceProvider.future);
  return service.getOptimizedImage(imageFile);
});

/// Provides cache statistics including file count and total size.
///
/// Useful for displaying cache usage in settings and for cache management.
final imageCacheStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = await ref.watch(imageCacheServiceProvider.future);
  return service.getCacheStats();
});

/// Action class for cache management operations.
///
/// Provides methods for clearing cache and removing specific files.
class ImageCacheActions {
  final Ref ref;

  ImageCacheActions(this.ref);

  /// Clears all cached images from disk.
  ///
  /// Invalidates [imageCacheStatsProvider] after completion.
  Future<void> clearAllCache() async {
    final service = await ref.read(imageCacheServiceProvider.future);
    await service.clearCache();

    // Refresh cache statistics
    ref.invalidate(imageCacheStatsProvider);
  }

  /// Removes a specific cached file by its path.
  ///
  /// [filePath] the absolute path to the cached file.
  Future<void> removeFile(String filePath) async {
    final service = await ref.read(imageCacheServiceProvider.future);
    await service.removeFile(filePath);

    // Refresh cache statistics
    ref.invalidate(imageCacheStatsProvider);
  }
}

/// Provides the cache actions instance for cache management.
final imageCacheActionsProvider = Provider<ImageCacheActions>((ref) {
  return ImageCacheActions(ref);
});
