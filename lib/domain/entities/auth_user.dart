/// An authenticated user entity.
///
/// Represents a user who has logged in to the application, containing
/// their profile information and authentication identifiers.
///
/// The primary identifier is [uuid] (Supabase UUID). The legacy [id] field
/// is deprecated and will be removed in future versions.
///
/// Example:
/// ```dart
/// final user = AuthUser(
///   id: 12345,  // Deprecated
///   uuid: 'abc-123-def-456',
///   email: 'user@example.com',
///   name: 'John Doe',
///   displayName: 'Johnny',
///   avatarUrl: 'https://example.com/avatar.png',
/// );
/// ```
class AuthUser {
  /// Legacy integer ID for backward compatibility.
  @Deprecated('Use uuid instead. This field will be removed in future versions.')
  final int id;

  /// Supabase UUID - the primary user identifier.
  final String uuid;

  /// The user's email address.
  final String email;

  /// The user's display name (from OAuth provider or email).
  final String name;

  /// Custom display name set by the user.
  final String? displayName;

  /// URL to the user's profile avatar image.
  final String? avatarUrl;

  /// When the user account was created.
  final DateTime? createdAt;

  /// Creates a new [AuthUser] instance.
  const AuthUser({
    @Deprecated('Use uuid instead') required this.id,
    required this.uuid,
    required this.email,
    required this.name,
    this.displayName,
    this.avatarUrl,
    this.createdAt,
  });

  /// Returns the display name if set, otherwise falls back to name.
  String get effectiveName => displayName?.isNotEmpty == true ? displayName! : name;

  /// Creates a copy of this user with the given fields replaced.
  AuthUser copyWith({
    int? id,
    String? uuid,
    String? email,
    String? name,
    String? displayName,
    String? avatarUrl,
    DateTime? createdAt,
  }) {
    return AuthUser(
      // ignore: deprecated_member_use_from_same_package
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      email: email ?? this.email,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
