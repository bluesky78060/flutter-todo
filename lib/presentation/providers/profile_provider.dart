/// Profile state management providers using Riverpod.
///
/// Provides profile operations including:
/// - Display name updates
/// - Avatar image upload
/// - Profile data synchronization
library;

import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_app/core/errors/failures.dart';
import 'package:todo_app/core/services/profile_service.dart';
import 'package:todo_app/core/utils/app_logger.dart';
import 'package:todo_app/presentation/providers/auth_providers.dart';

/// Helper function to extract error message from Failure.
String _getFailureMessage(Failure failure) {
  if (failure is ServerFailure) return failure.message;
  if (failure is AuthFailure) return failure.message;
  if (failure is CacheFailure) return failure.message;
  if (failure is NetworkFailure) return failure.message;
  if (failure is ValidationFailure) return failure.message;
  if (failure is DatabaseFailure) return failure.message;
  return 'An error occurred';
}

/// Provider for the ProfileService instance.
final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService(Supabase.instance.client);
});

/// Profile state class for managing profile data.
class ProfileState {
  final String? displayName;
  final String? avatarUrl;
  final bool isLoading;
  final String? error;

  const ProfileState({
    this.displayName,
    this.avatarUrl,
    this.isLoading = false,
    this.error,
  });

  ProfileState copyWith({
    String? displayName,
    String? avatarUrl,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for profile state management.
class ProfileNotifier extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    // Load initial profile data
    final service = ref.watch(profileServiceProvider);
    return ProfileState(
      displayName: service.getDisplayName(),
      avatarUrl: service.getAvatarUrl(),
    );
  }

  /// Updates the user's display name.
  Future<bool> updateDisplayName(String displayName) async {
    state = state.copyWith(isLoading: true, error: null);

    final service = ref.read(profileServiceProvider);
    final result = await service.updateDisplayName(displayName);

    return result.fold(
      (failure) {
        final message = _getFailureMessage(failure);
        logger.e('[ProfileNotifier] Failed to update display name: $message');
        state = state.copyWith(isLoading: false, error: message);
        return false;
      },
      (_) {
        logger.d('[ProfileNotifier] Display name updated to: $displayName');
        state = state.copyWith(
          displayName: displayName,
          isLoading: false,
        );
        return true;
      },
    );
  }

  /// Picks and uploads avatar from gallery.
  Future<bool> pickAndUploadAvatar() async {
    state = state.copyWith(isLoading: true, error: null);

    final service = ref.read(profileServiceProvider);
    final pickResult = await service.pickAvatarImage();

    return pickResult.fold(
      (failure) {
        final message = _getFailureMessage(failure);
        logger.d('[ProfileNotifier] Image pick cancelled or failed: $message');
        state = state.copyWith(isLoading: false);
        return false;
      },
      (imageFile) async {
        final uploadResult = await service.uploadAvatar(imageFile);

        return uploadResult.fold(
          (failure) {
            final message = _getFailureMessage(failure);
            logger.e('[ProfileNotifier] Failed to upload avatar: $message');
            state = state.copyWith(isLoading: false, error: message);
            return false;
          },
          (avatarUrl) {
            logger.d('[ProfileNotifier] Avatar uploaded: $avatarUrl');
            state = state.copyWith(
              avatarUrl: avatarUrl,
              isLoading: false,
            );
            // Refresh currentUserProvider to update avatar in other screens
            ref.invalidate(currentUserProvider);
            return true;
          },
        );
      },
    );
  }

  /// Picks and uploads avatar from camera.
  Future<bool> pickAndUploadAvatarFromCamera() async {
    state = state.copyWith(isLoading: true, error: null);

    final service = ref.read(profileServiceProvider);
    final pickResult = await service.pickAvatarFromCamera();

    return pickResult.fold(
      (failure) {
        final message = _getFailureMessage(failure);
        logger.d('[ProfileNotifier] Camera capture cancelled or failed: $message');
        state = state.copyWith(isLoading: false);
        return false;
      },
      (imageFile) async {
        final uploadResult = await service.uploadAvatar(imageFile);

        return uploadResult.fold(
          (failure) {
            final message = _getFailureMessage(failure);
            logger.e('[ProfileNotifier] Failed to upload avatar: $message');
            state = state.copyWith(isLoading: false, error: message);
            return false;
          },
          (avatarUrl) {
            logger.d('[ProfileNotifier] Avatar uploaded: $avatarUrl');
            state = state.copyWith(
              avatarUrl: avatarUrl,
              isLoading: false,
            );
            // Refresh currentUserProvider to update avatar in other screens
            ref.invalidate(currentUserProvider);
            return true;
          },
        );
      },
    );
  }

  /// Uploads avatar from bytes (for web platform).
  Future<bool> uploadAvatarFromBytes(Uint8List bytes, String fileName) async {
    state = state.copyWith(isLoading: true, error: null);

    final service = ref.read(profileServiceProvider);
    final result = await service.uploadAvatarFromBytes(bytes, fileName);

    return result.fold(
      (failure) {
        final message = _getFailureMessage(failure);
        logger.e('[ProfileNotifier] Failed to upload avatar: $message');
        state = state.copyWith(isLoading: false, error: message);
        return false;
      },
      (avatarUrl) {
        logger.d('[ProfileNotifier] Avatar uploaded: $avatarUrl');
        state = state.copyWith(
          avatarUrl: avatarUrl,
          isLoading: false,
        );
        // Refresh currentUserProvider to update avatar in other screens
        ref.invalidate(currentUserProvider);
        return true;
      },
    );
  }

  /// Removes the user's avatar.
  Future<bool> removeAvatar() async {
    state = state.copyWith(isLoading: true, error: null);

    final service = ref.read(profileServiceProvider);
    final result = await service.removeAvatar();

    return result.fold(
      (failure) {
        final message = _getFailureMessage(failure);
        logger.e('[ProfileNotifier] Failed to remove avatar: $message');
        state = state.copyWith(isLoading: false, error: message);
        return false;
      },
      (_) {
        logger.d('[ProfileNotifier] Avatar removed');
        state = state.copyWith(
          avatarUrl: null,
          isLoading: false,
        );
        // Refresh currentUserProvider to update avatar in other screens
        ref.invalidate(currentUserProvider);
        return true;
      },
    );
  }

  /// Refreshes profile data from Supabase.
  void refresh() {
    final service = ref.read(profileServiceProvider);
    state = ProfileState(
      displayName: service.getDisplayName(),
      avatarUrl: service.getAvatarUrl(),
    );
  }
}

/// Provider for profile state management.
final profileProvider = NotifierProvider<ProfileNotifier, ProfileState>(() {
  return ProfileNotifier();
});
