import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:todo_app/core/utils/app_logger.dart';

/// 이미지 캐싱 및 메모리 관리 서비스
class ImageCacheService {
  // 캐시 설정
  static const int maxCacheSizeMB = 100;
  static const int maxCacheDuration = 30; // 일 단위
  static const int maxImageWidthPx = 1200;
  static const int maxImageHeightPx = 1200;

  late final CacheManager _cacheManager;
  late final String _appCacheDir;

  /// 초기화
  Future<void> initialize() async {
    try {
      final cacheDir = await getApplicationCacheDirectory();
      _appCacheDir = '${cacheDir.path}/images';

      // 이미지 캐시 디렉토리 생성
      final imageDir = Directory(_appCacheDir);
      if (!imageDir.existsSync()) {
        await imageDir.create(recursive: true);
      }

      // 커스텀 CacheManager 설정
      _cacheManager = CacheManager(
        Config(
          'image_cache',
          stalePeriod: const Duration(days: maxCacheDuration),
          maxNrOfCacheObjects: 200, // 최대 200개 이미지
          fileService: HttpFileService(),
        ),
      );

      logger.d('✅ ImageCacheService 초기화 완료 (캐시 디렉토리: $_appCacheDir)');

      // 캐시 크기 관리
      await _manageCacheSize();
    } catch (e) {
      logger.e('❌ ImageCacheService 초기화 실패: $e');
      rethrow;
    }
  }

  /// URL에서 이미지 다운로드 및 캐싱
  Future<File> getImage(String imageUrl) async {
    try {
      logger.d('📥 이미지 캐시 요청: $imageUrl');

      final file = await _cacheManager.getSingleFile(imageUrl);

      logger.d('✅ 이미지 캐시 완료: ${file.path}');
      return file;
    } catch (e) {
      logger.e('❌ 이미지 캐시 실패: $e');
      rethrow;
    }
  }

  /// 로컬 파일을 캐시에 저장
  Future<File> cacheLocalFile(File sourceFile) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${sourceFile.path.split('/').last}';
      final cachedPath = '$_appCacheDir/$fileName';
      final cachedFile = File(cachedPath);

      // 파일 복사
      await sourceFile.copy(cachedFile.path);

      logger.d('💾 로컬 파일 캐시 완료: $cachedPath');
      return cachedFile;
    } catch (e) {
      logger.e('❌ 로컬 파일 캐시 실패: $e');
      rethrow;
    }
  }

  /// 이미지 해상도 최적화 (메모리 효율)
  Future<File> getOptimizedImage(File imageFile) async {
    try {
      logger.d('🔧 ${tr('image_optimization_start')}: ${imageFile.path}');

      // 원본 이미지 읽기
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception(tr('image_decoding_failed'));
      }

      // 해상도 계산 (최대 1200x1200)
      int newWidth = image.width;
      int newHeight = image.height;

      if (image.width > maxImageWidthPx || image.height > maxImageHeightPx) {
        final aspectRatio = image.width / image.height;
        if (aspectRatio > 1) {
          newWidth = maxImageWidthPx;
          newHeight = (maxImageWidthPx / aspectRatio).toInt();
        } else {
          newHeight = maxImageHeightPx;
          newWidth = (maxImageHeightPx * aspectRatio).toInt();
        }
      }

      // 이미지 리사이징
      final resized = img.copyResize(
        image,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.average,
      );

      // 최적화된 파일 저장
      final optimizedPath = '${imageFile.path}.optimized.jpg';
      final optimizedFile = File(optimizedPath);
      await optimizedFile.writeAsBytes(img.encodeJpg(resized, quality: 85));

      logger.d('✅ 이미지 최적화 완료: $image.width}x${image.height} → $newWidth}x$newHeight');

      return optimizedFile;
    } catch (e) {
      logger.e('❌ 이미지 최적화 실패: $e');
      return imageFile; // 실패 시 원본 반환
    }
  }

  /// 캐시 크기 관리 (100MB 초과 시 삭제)
  Future<void> _manageCacheSize() async {
    try {
      final cacheDir = Directory(_appCacheDir);
      if (!cacheDir.existsSync()) return;

      final files = cacheDir.listSync(recursive: true);
      int totalSize = 0;

      // 전체 캐시 크기 계산
      for (final file in files) {
        if (file is File) {
          totalSize += await file.length();
        }
      }

      final totalSizeMB = totalSize / (1024 * 1024);
      logger.d('📊 캐시 크기: ${totalSizeMB.toStringAsFixed(2)} MB');

      // 100MB 초과 시 오래된 파일부터 삭제
      if (totalSizeMB > maxCacheSizeMB) {
        logger.d('🧹 캐시 정리 시작 (현재: ${totalSizeMB.toStringAsFixed(2)}MB > 제한: ${maxCacheSizeMB}MB)');

        // 파일을 수정 시간순으로 정렬
        final fileList = files.whereType<File>().toList();
        fileList.sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));

        // 오래된 파일부터 삭제
        int freedSize = 0;
        for (final file in fileList) {
          if (totalSizeMB - (freedSize / (1024 * 1024)) <= maxCacheSizeMB * 0.8) {
            break; // 80% 수준까지만 삭제
          }

          final fileSize = await file.length();
          await file.delete();
          freedSize += fileSize;
          logger.d('🗑️ 캐시 파일 삭제: ${file.path}');
        }

        logger.d('✅ 캐시 정리 완료 (${(freedSize / (1024 * 1024)).toStringAsFixed(2)} MB 해제)');
      }
    } catch (e) {
      logger.e('❌ 캐시 정리 실패: $e');
    }
  }

  /// 전체 캐시 초기화
  Future<void> clearCache() async {
    try {
      await _cacheManager.emptyCache();
      final cacheDir = Directory(_appCacheDir);
      if (cacheDir.existsSync()) {
        await cacheDir.delete(recursive: true);
      }
      logger.d('🧹 전체 캐시 초기화 완료');
    } catch (e) {
      logger.e('❌ 캐시 초기화 실패: $e');
    }
  }

  /// 캐시 통계
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final cacheDir = Directory(_appCacheDir);
      if (!cacheDir.existsSync()) {
        return {'total_size_mb': 0, 'file_count': 0};
      }

      final files = cacheDir.listSync(recursive: true);
      int totalSize = 0;
      int fileCount = 0;

      for (final file in files) {
        if (file is File) {
          totalSize += await file.length();
          fileCount++;
        }
      }

      return {
        'total_size_mb': totalSize / (1024 * 1024),
        'file_count': fileCount,
        'cache_dir': _appCacheDir,
        'max_cache_mb': maxCacheSizeMB,
      };
    } catch (e) {
      logger.e('❌ 캐시 통계 조회 실패: $e');
      return {'error': e.toString()};
    }
  }

  /// 단일 파일 캐시 삭제
  Future<void> removeFile(String filePath) async {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        await file.delete();
        logger.d('🗑️ 캐시 파일 삭제: $filePath');
      }
    } catch (e) {
      logger.e('❌ 파일 삭제 실패: $e');
    }
  }

  /// 종료 및 리소스 정리
  void dispose() {
    logger.d('🔒 ImageCacheService 종료');
  }
}
