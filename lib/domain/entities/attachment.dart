/// A file attachment entity associated with a todo.
///
/// Attachments allow users to add files (images, documents, PDFs, etc.)
/// to their todos. The file content is stored in Supabase Storage, while
/// this entity holds the metadata.
///
/// Example:
/// ```dart
/// final attachment = Attachment(
///   id: 1,
///   todoId: 42,
///   fileName: 'receipt.pdf',
///   filePath: '/local/path/receipt.pdf',
///   fileSize: 102400,
///   mimeType: 'application/pdf',
///   storagePath: 'user-uuid/42/receipt.pdf',
///   createdAt: DateTime.now(),
/// );
/// ```
class Attachment {
  /// Unique identifier for the attachment.
  final int id;

  /// The ID of the todo this attachment belongs to.
  final int todoId;

  /// The original filename.
  final String fileName;

  /// Local file path (if stored locally).
  final String filePath;

  /// File size in bytes.
  final int fileSize;

  /// MIME type (e.g., "image/jpeg", "application/pdf").
  final String mimeType;

  /// Full path in Supabase Storage: `{user_id}/{todo_id}/{filename}`.
  final String storagePath;

  /// When the attachment was created.
  final DateTime createdAt;

  /// Creates a new [Attachment] instance.
  const Attachment({
    required this.id,
    required this.todoId,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.mimeType,
    required this.storagePath,
    required this.createdAt,
  });

  /// Creates a copy of this attachment with the given fields replaced.
  Attachment copyWith({
    int? id,
    int? todoId,
    String? fileName,
    String? filePath,
    int? fileSize,
    String? mimeType,
    String? storagePath,
    DateTime? createdAt,
  }) {
    return Attachment(
      id: id ?? this.id,
      todoId: todoId ?? this.todoId,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      storagePath: storagePath ?? this.storagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Whether this attachment is an image file.
  bool get isImage => mimeType.startsWith('image/');

  /// Whether this attachment is a PDF file.
  bool get isPdf => mimeType == 'application/pdf';

  /// Whether this attachment is a document (Word, Excel, etc.).
  bool get isDocument => mimeType.contains('document') ||
                          mimeType.contains('msword') ||
                          mimeType.contains('officedocument');

  /// The file extension extracted from the filename.
  String get fileExtension {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  /// Human-readable formatted file size (e.g., "1.5 MB", "256 KB").
  String get formattedFileSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
