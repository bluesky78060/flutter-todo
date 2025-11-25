import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_app/core/errors/failures.dart';
import 'package:mime/mime.dart';

class AttachmentService {
  final SupabaseClient _supabase;
  final ImagePicker _imagePicker = ImagePicker();
  static const String bucketName = 'todo-attachments';

  AttachmentService(this._supabase);

  /// Pick image from gallery
  Future<Either<Failure, File>> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) {
        return const Left(CacheFailure('No image selected'));
      }

      return Right(File(image.path));
    } catch (e) {
      print('[AttachmentService] Error picking image from gallery: $e');
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Pick image from camera
  Future<Either<Failure, File>> pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) {
        return const Left(CacheFailure('No image captured'));
      }

      return Right(File(image.path));
    } catch (e) {
      print('[AttachmentService] Error picking image from camera: $e');
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Pick any file type
  Future<Either<Failure, File>> pickFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return const Left(CacheFailure('No file selected'));
      }

      final filePath = result.files.first.path;
      if (filePath == null) {
        return const Left(CacheFailure('Invalid file path'));
      }

      return Right(File(filePath));
    } catch (e) {
      print('Error picking file: $e');
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Upload file to Supabase Storage
  /// Returns storage path: {user_id}/{todo_id}/{filename}
  Future<Either<Failure, String>> uploadFile({
    required File file,
    required int todoId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return const Left(AuthFailure('User not authenticated'));
      }

      final fileName = file.path.split('/').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${timestamp}_$fileName';
      final storagePath = '$userId/$todoId/$uniqueFileName';

      print('Uploading file to: $storagePath');

      await _supabase.storage.from(bucketName).upload(
            storagePath,
            file,
            fileOptions: FileOptions(
              upsert: false,
              contentType: _getMimeType(file.path),
            ),
          );

      print('File uploaded successfully: $storagePath');
      return Right(storagePath);
    } catch (e) {
      print('Error uploading file: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Download file from Supabase Storage
  Future<Either<Failure, File>> downloadFile({
    required String storagePath,
    required String localPath,
  }) async {
    try {
      print('Downloading file from: $storagePath');

      final bytes = await _supabase.storage.from(bucketName).download(storagePath);

      final file = File(localPath);
      await file.writeAsBytes(bytes);

      print('File downloaded successfully to: $localPath');
      return Right(file);
    } catch (e) {
      print('Error downloading file: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Get public URL for a file (if bucket is public)
  String getPublicUrl(String storagePath) {
    return _supabase.storage.from(bucketName).getPublicUrl(storagePath);
  }

  /// Get signed URL for private file access (expires in 1 hour)
  Future<Either<Failure, String>> getSignedUrl(String storagePath) async {
    try {
      final signedUrl = await _supabase.storage.from(bucketName).createSignedUrl(
            storagePath,
            3600, // 1 hour
          );

      return Right(signedUrl);
    } catch (e) {
      print('Error creating signed URL: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Delete file from Supabase Storage
  Future<Either<Failure, Unit>> deleteFile(String storagePath) async {
    try {
      print('Deleting file: $storagePath');

      await _supabase.storage.from(bucketName).remove([storagePath]);

      print('File deleted successfully: $storagePath');
      return const Right(unit);
    } catch (e) {
      print('Error deleting file: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Delete all files for a todo
  Future<Either<Failure, Unit>> deleteFilesByTodoId(int todoId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return const Left(AuthFailure('User not authenticated'));
      }

      final folderPath = '$userId/$todoId/';
      print('Deleting all files in folder: $folderPath');

      final files = await _supabase.storage.from(bucketName).list(path: folderPath);

      if (files.isEmpty) {
        print('No files to delete');
        return const Right(unit);
      }

      final filePaths = files.map((file) => '$folderPath${file.name}').toList();
      await _supabase.storage.from(bucketName).remove(filePaths);

      print('Deleted ${filePaths.length} files');
      return const Right(unit);
    } catch (e) {
      print('Error deleting files by todo ID: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Get MIME type from file path
  /// Maps unsupported MIME types to supported ones for Supabase Storage
  String _getMimeType(String filePath) {
    final mimeType = lookupMimeType(filePath);

    if (mimeType == null) {
      return 'application/octet-stream';
    }

    // Map unsupported MIME types to supported ones
    // Supabase Storage may block certain MIME types by default
    if (mimeType == 'application/json') {
      return 'text/plain'; // Upload JSON as text/plain
    }

    // Add other MIME type mappings if needed
    // Example: if (mimeType == 'application/xml') return 'text/xml';

    return mimeType;
  }

  /// Get file size in bytes
  int getFileSize(File file) {
    return file.lengthSync();
  }
}
