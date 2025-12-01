/// PDF document viewer dialog for attachment PDFs.
///
/// Downloads and displays PDF attachments from Supabase Storage
/// using Syncfusion PDF viewer component.
///
/// Features:
/// - Downloads PDF from Supabase Storage to temp directory
/// - Full PDF rendering with Syncfusion Flutter PDF Viewer
/// - Double-tap to zoom functionality
/// - Text selection support for copying content
/// - Loading indicator while downloading
/// - Error display for failed loads
/// - File info overlay (name, size)
///
/// Dependencies:
/// - syncfusion_flutter_pdfviewer package
///
/// See also:
/// - [ImageViewerDialog] for image attachment viewing
/// - [TextViewerDialog] for text file viewing
/// - [attachmentServiceProvider] for download functionality
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:todo_app/core/theme/app_colors.dart';
import 'package:todo_app/presentation/providers/attachment_providers.dart';
import 'package:todo_app/domain/entities/attachment.dart' as entity;
import 'package:path_provider/path_provider.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

/// Dialog for viewing PDF document attachments.
class PdfViewerDialog extends ConsumerStatefulWidget {
  final entity.Attachment attachment;

  const PdfViewerDialog({
    super.key,
    required this.attachment,
  });

  @override
  ConsumerState<PdfViewerDialog> createState() => _PdfViewerDialogState();
}

class _PdfViewerDialogState extends ConsumerState<PdfViewerDialog> {
  File? _pdfFile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final attachmentService = ref.read(attachmentServiceProvider);

      // Create temp file path
      final tempDir = await getTemporaryDirectory();
      final localPath = '${tempDir.path}/${widget.attachment.fileName}';

      print('[PdfViewer] Downloading from: ${widget.attachment.storagePath}');
      print('[PdfViewer] To local path: $localPath');

      // Download file from Supabase Storage
      final result = await attachmentService.downloadFile(
        storagePath: widget.attachment.storagePath,
        localPath: localPath,
      );

      result.fold(
        (failure) {
          print('[PdfViewer] Download failed: $failure');
          setState(() {
            _error = failure.toString();
            _isLoading = false;
          });
        },
        (file) {
          print('[PdfViewer] Download successful: ${file.path}');
          setState(() {
            _pdfFile = file;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      print('[PdfViewer] Error loading PDF: $e');
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
          // PDF content
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryBlue,
              ),
            )
          else if (_error != null)
            Center(
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
                    const Text(
                      'Unable to load PDF',
                      style: TextStyle(
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
          else if (_pdfFile != null)
            SfPdfViewer.file(
              _pdfFile!,
              enableDoubleTapZooming: true,
              enableTextSelection: true,
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
