/// Profile management service for user profile updates.
///
/// Handles user profile operations including:
/// - Display name updates
/// - Avatar image upload and management
/// - Supabase user_metadata synchronization
///
/// Uses Supabase Storage for avatar images with the 'avatars' bucket.
library;

import 'dart:typed_data';
import 'package:fpdart/fpdart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_app/core/errors/failures.dart';

/// Service for managing user profile data.
class ProfileService {
  final SupabaseClient _supabase;
  final ImagePicker _imagePicker = ImagePicker();

  static const String avatarBucket = 'avatars';
  static const int maxAvatarSizeBytes = 5 * 1024 * 1024; // 5 MB

  ProfileService(this._supabase);

  /// Converts file extension to proper MIME type.
  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg'; // Default to jpeg
    }
  }

  /// Updates the user's display name in Supabase user_metadata.
  Future<Either<Failure, Unit>> updateDisplayName(String displayName) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return const Left(AuthFailure('User not authenticated'));
      }

      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            ...user.userMetadata ?? {},
            'display_name': displayName,
          },
        ),
      );

      print('[ProfileService] Display name updated to: $displayName');
      return const Right(unit);
    } catch (e) {
      print('[ProfileService] Error updating display name: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Picks an image from the gallery for avatar.
  Future<Either<Failure, XFile>> pickAvatarImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) {
        return const Left(CacheFailure('No image selected'));
      }

      return Right(image);
    } catch (e) {
      print('[ProfileService] Error picking avatar image: $e');
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Picks an image from the camera for avatar.
  Future<Either<Failure, XFile>> pickAvatarFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) {
        return const Left(CacheFailure('No image captured'));
      }

      return Right(image);
    } catch (e) {
      print('[ProfileService] Error capturing avatar image: $e');
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Uploads avatar image to Supabase Storage and updates user_metadata.
  /// Returns the public URL of the uploaded avatar.
  Future<Either<Failure, String>> uploadAvatar(XFile imageFile) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return const Left(AuthFailure('User not authenticated'));
      }

      final bytes = await imageFile.readAsBytes();

      // Validate file size
      if (bytes.length > maxAvatarSizeBytes) {
        return const Left(CacheFailure('Image size exceeds 5MB limit'));
      }

      final fileExt = imageFile.name.split('.').last.toLowerCase();
      final fileName = '${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      print('[ProfileService] Uploading avatar to: $fileName');

      // Delete old avatar if exists
      await _deleteOldAvatars(user.id);

      // Upload new avatar
      await _supabase.storage.from(avatarBucket).uploadBinary(
        fileName,
        bytes,
        fileOptions: FileOptions(
          upsert: true,
          contentType: _getMimeType(fileExt),
        ),
      );

      // Get public URL
      final avatarUrl = _supabase.storage.from(avatarBucket).getPublicUrl(fileName);

      // Update user metadata with custom avatar URL
      // Use 'custom_avatar_url' key to prevent OAuth from overwriting it
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            ...user.userMetadata ?? {},
            'custom_avatar_url': avatarUrl,
          },
        ),
      );

      // Refresh session to update currentUser with new avatar URL
      await _supabase.auth.refreshSession();

      print('[ProfileService] Avatar uploaded successfully: $avatarUrl');
      return Right(avatarUrl);
    } catch (e) {
      print('[ProfileService] Error uploading avatar: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Uploads avatar from bytes (for web platform).
  Future<Either<Failure, String>> uploadAvatarFromBytes(
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return const Left(AuthFailure('User not authenticated'));
      }

      // Validate file size
      if (bytes.length > maxAvatarSizeBytes) {
        return const Left(CacheFailure('Image size exceeds 5MB limit'));
      }

      final fileExt = fileName.split('.').last.toLowerCase();
      final storagePath = '${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      print('[ProfileService] Uploading avatar (bytes) to: $storagePath');

      // Delete old avatar if exists
      await _deleteOldAvatars(user.id);

      // Upload new avatar
      await _supabase.storage.from(avatarBucket).uploadBinary(
        storagePath,
        bytes,
        fileOptions: FileOptions(
          upsert: true,
          contentType: _getMimeType(fileExt),
        ),
      );

      // Get public URL
      final avatarUrl = _supabase.storage.from(avatarBucket).getPublicUrl(storagePath);

      // Update user metadata with custom avatar URL
      // Use 'custom_avatar_url' key to prevent OAuth from overwriting it
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            ...user.userMetadata ?? {},
            'custom_avatar_url': avatarUrl,
          },
        ),
      );

      // Refresh session to update currentUser with new avatar URL
      await _supabase.auth.refreshSession();

      print('[ProfileService] Avatar uploaded successfully: $avatarUrl');
      return Right(avatarUrl);
    } catch (e) {
      print('[ProfileService] Error uploading avatar (bytes): $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Deletes old avatar files for the user.
  Future<void> _deleteOldAvatars(String userId) async {
    try {
      final files = await _supabase.storage.from(avatarBucket).list(path: userId);

      if (files.isNotEmpty) {
        final filePaths = files.map((f) => '$userId/${f.name}').toList();
        await _supabase.storage.from(avatarBucket).remove(filePaths);
        print('[ProfileService] Deleted ${filePaths.length} old avatar(s)');
      }
    } catch (e) {
      print('[ProfileService] Warning: Could not delete old avatars: $e');
      // Don't throw - this is not critical
    }
  }

  /// Removes the user's avatar.
  Future<Either<Failure, Unit>> removeAvatar() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return const Left(AuthFailure('User not authenticated'));
      }

      // Delete avatar files
      await _deleteOldAvatars(user.id);

      // Remove custom avatar URL from metadata
      final metadata = Map<String, dynamic>.from(user.userMetadata ?? {});
      metadata.remove('custom_avatar_url');

      await _supabase.auth.updateUser(
        UserAttributes(data: metadata),
      );

      print('[ProfileService] Avatar removed successfully');
      return const Right(unit);
    } catch (e) {
      print('[ProfileService] Error removing avatar: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Gets the current user's display name from metadata.
  String? getDisplayName() {
    final user = _supabase.auth.currentUser;
    return user?.userMetadata?['display_name'] as String?;
  }

  /// Gets the current user's avatar URL from metadata.
  /// Prioritizes custom_avatar_url (user-uploaded) over OAuth provider's avatar.
  String? getAvatarUrl() {
    final user = _supabase.auth.currentUser;
    final metadata = user?.userMetadata;
    // Check custom avatar first (won't be overwritten by OAuth)
    String? avatarUrl = metadata?['custom_avatar_url'] as String?;

    // If no custom_avatar_url, check if avatar_url is a Supabase Storage URL
    // (which means it's a user-uploaded avatar from before the migration)
    if (avatarUrl == null) {
      final legacyAvatarUrl = metadata?['avatar_url'] as String?;
      if (legacyAvatarUrl != null && _isSupabaseStorageUrl(legacyAvatarUrl)) {
        // This is a custom avatar stored in the old key, migrate it
        _migrateAvatarUrl(legacyAvatarUrl);
        return legacyAvatarUrl;
      }
      avatarUrl = legacyAvatarUrl;
    }

    // Fall back to OAuth provider's avatar
    avatarUrl ??= metadata?['picture'] as String?;
    return avatarUrl;
  }

  /// Checks if the URL is a Supabase Storage URL (user-uploaded avatar)
  bool _isSupabaseStorageUrl(String url) {
    return url.contains('supabase.co/storage') ||
           url.contains('bulwfcsyqgsvmbadhlye');
  }

  /// Migrates avatar_url to custom_avatar_url for existing users
  Future<void> _migrateAvatarUrl(String avatarUrl) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      print('[ProfileService] Migrating legacy avatar_url to custom_avatar_url');
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            ...user.userMetadata ?? {},
            'custom_avatar_url': avatarUrl,
          },
        ),
      );
      print('[ProfileService] Avatar URL migration complete');
    } catch (e) {
      print('[ProfileService] Avatar migration failed: $e');
    }
  }
}
