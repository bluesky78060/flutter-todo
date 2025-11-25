import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/presentation/providers/attachment_providers.dart';
import 'package:todo_app/domain/entities/attachment.dart' as entity;
import 'package:path_provider/path_provider.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:easy_localization/easy_localization.dart';

class TextViewerDialog extends ConsumerStatefulWidget {
  final entity.Attachment attachment;

  const TextViewerDialog({
    super.key,
    required this.attachment,
  });

  @override
  ConsumerState<TextViewerDialog> createState() => _TextViewerDialogState();
}

class _TextViewerDialogState extends ConsumerState<TextViewerDialog> {
  String? _textContent;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTextFile();
  }

  Future<void> _loadTextFile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final attachmentService = ref.read(attachmentServiceProvider);

      // Create temp file path
      final tempDir = await getTemporaryDirectory();
      final localPath = '${tempDir.path}/${widget.attachment.fileName}';

      print('[TextViewer] Downloading from: ${widget.attachment.storagePath}');
      print('[TextViewer] To local path: $localPath');

      // Download file from Supabase Storage
      final result = await attachmentService.downloadFile(
        storagePath: widget.attachment.storagePath,
        localPath: localPath,
      );

      await result.fold(
        (failure) {
          print('[TextViewer] Download failed: $failure');
          setState(() {
            _error = failure.toString();
            _isLoading = false;
          });
        },
        (file) async {
          print('[TextViewer] Download successful: ${file.path}');

          // Read file content
          try {
            final content = await file.readAsString();
            setState(() {
              _textContent = content;
              _isLoading = false;
            });
          } catch (e) {
            print('[TextViewer] Error reading file content: $e');
            setState(() {
              _error = 'file_content_read_failed'.tr(namedArgs: {'error': e.toString()});
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      print('[TextViewer] Error loading text file: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          // Text content
          Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      FluentIcons.document_text_24_regular,
                      color: AppColors.primaryBlue,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.attachment.fileName,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatFileSize(widget.attachment.fileSize),
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 40), // Space for close button
                  ],
                ),
              ),

              // Content area
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryBlue,
                        ),
                      )
                    : _error != null
                        ? Center(
                            child: Padding(
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
                                    'file_loading_failed'.tr(),
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _error!,
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.all(16),
                            color: Colors.grey.shade50,
                            child: SingleChildScrollView(
                              child: SelectableText(
                                _textContent ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'monospace',
                                  color: Colors.black87,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
              ),
            ],
          ),

          // Close button
          Positioned(
            top: 10,
            right: 10,
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black26,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  FluentIcons.dismiss_24_filled,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
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
