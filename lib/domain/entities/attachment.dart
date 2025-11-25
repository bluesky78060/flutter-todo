class Attachment {
  final int id;
  final int todoId;
  final String fileName;
  final String filePath; // Local file path (if stored locally)
  final int fileSize; // File size in bytes
  final String mimeType; // MIME type (e.g., image/jpeg, application/pdf)
  final String storagePath; // Full path in Supabase Storage: {user_id}/{todo_id}/{filename}
  final DateTime createdAt;

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

  // Helper method to check if this is an image
  bool get isImage => mimeType.startsWith('image/');

  // Helper method to check if this is a PDF
  bool get isPdf => mimeType == 'application/pdf';

  // Helper method to check if this is a document
  bool get isDocument => mimeType.contains('document') ||
                          mimeType.contains('msword') ||
                          mimeType.contains('officedocument');

  // Helper method to get file extension from filename
  String get fileExtension {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  // Helper method to format file size
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
