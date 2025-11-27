import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/services/image_cache_service.dart';

/// ImageCacheService 싱글톤 provider
final imageCacheServiceProvider = FutureProvider<ImageCacheService>((ref) async {
  final service = ImageCacheService();
  await service.initialize();

  // 앱이 종료될 때 서비스 정리
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// 이미지 URL로부터 캐시된 파일 가져오기
final cachedImageFileProvider =
    FutureProvider.family<File, String>((ref, imageUrl) async {
  final service = await ref.watch(imageCacheServiceProvider.future);
  return service.getImage(imageUrl);
});

/// 로컬 파일을 캐시에 저장
final cachedLocalFileProvider =
    FutureProvider.family<File, File>((ref, sourceFile) async {
  final service = await ref.watch(imageCacheServiceProvider.future);
  return service.cacheLocalFile(sourceFile);
});

/// 이미지 최적화 (해상도 축소)
final optimizedImageProvider =
    FutureProvider.family<File, File>((ref, imageFile) async {
  final service = await ref.watch(imageCacheServiceProvider.future);
  return service.getOptimizedImage(imageFile);
});

/// 캐시 통계 정보
final imageCacheStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = await ref.watch(imageCacheServiceProvider.future);
  return service.getCacheStats();
});

/// 캐시 초기화 액션
class ImageCacheActions {
  final Ref ref;

  ImageCacheActions(this.ref);

  /// 전체 캐시 삭제
  Future<void> clearAllCache() async {
    final service = await ref.read(imageCacheServiceProvider.future);
    await service.clearCache();

    // 통계 정보 리프레시
    ref.invalidate(imageCacheStatsProvider);
  }

  /// 특정 파일 삭제
  Future<void> removeFile(String filePath) async {
    final service = await ref.read(imageCacheServiceProvider.future);
    await service.removeFile(filePath);

    // 통계 정보 리프레시
    ref.invalidate(imageCacheStatsProvider);
  }
}

/// 캐시 액션 provider
final imageCacheActionsProvider = Provider<ImageCacheActions>((ref) {
  return ImageCacheActions(ref);
});
