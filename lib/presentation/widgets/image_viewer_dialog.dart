import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/presentation/providers/attachment_providers.dart';
import 'package:todo_app/presentation/providers/image_cache_provider.dart';
import 'package:todo_app/domain/entities/attachment.dart' as entity;
import 'package:path_provider/path_provider.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:todo_app/core/utils/app_logger.dart';

class ImageViewerDialog extends ConsumerStatefulWidget {
  final entity.Attachment attachment;

  const ImageViewerDialog({
    super.key,
    required this.attachment,
  });

  @override
  ConsumerState<ImageViewerDialog> createState() => _ImageViewerDialogState();
}

class _ImageViewerDialogState extends ConsumerState<ImageViewerDialog> {
  File? _imageFile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final attachmentService = ref.read(attachmentServiceProvider);
      final imageCacheService = await ref.read(imageCacheServiceProvider.future);

      logger.d('📥 이미지 로드 시작: ${widget.attachment.fileName}');

      // Create temp file path
      final tempDir = await getTemporaryDirectory();
      final localPath = '${tempDir.path}/${widget.attachment.fileName}';

      logger.d('📍 다운로드 경로: ${widget.attachment.storagePath} → $localPath');

      // Download file from Supabase Storage
      final result = await attachmentService.downloadFile(
        storagePath: widget.attachment.storagePath,
        localPath: localPath,
      );

      result.fold(
        (failure) {
          logger.e('❌ 이미지 다운로드 실패: $failure');
          setState(() {
            _error = failure.toString();
            _isLoading = false;
          });
        },
        (file) async {
          try {
            logger.d('✅ 이미지 다운로드 성공: ${file.path}');

            // 이미지를 캐시에 저장
            final cachedFile = await imageCacheService.cacheLocalFile(file);

            // 이미지 최적화 (메모리 효율)
            final optimizedFile = await imageCacheService.getOptimizedImage(cachedFile);

            logger.d('💾 이미지 캐시 및 최적화 완료');

            if (mounted) {
              setState(() {
                _imageFile = optimizedFile;
                _isLoading = false;
              });
            }
          } catch (e) {
            logger.e('❌ 이미지 캐싱/최적화 실패: $e');
            if (mounted) {
              setState(() {
                _imageFile = file; // 캐싱 실패 시 원본 사용
                _isLoading = false;
              });
            }
          }
        },
      );
    } catch (e) {
      logger.e('❌ 이미지 로드 오류: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          // Image content
          Center(
            child: _isLoading
                ? const CircularProgressIndicator(
                    color: AppColors.primaryBlue,
                  )
                : _error != null
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              FluentIcons.error_circle_24_filled,
                              color: Colors.red,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'image_loading_failed'.tr(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : _imageFile != null
                        ? InteractiveViewer(
                            minScale: 0.5,
                            maxScale: 4.0,
                            child: Image.file(
                              _imageFile!,
                              fit: BoxFit.contain,
                            ),
                          )
                        : const SizedBox.shrink(),
          ),

          // Close button
          Positioned(
            top: 10,
            right: 10,
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  FluentIcons.dismiss_24_filled,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // File info at bottom
          if (!_isLoading && _error == null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.attachment.fileName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatFileSize(widget.attachment.fileSize),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
