class AuthUser {
  @Deprecated('Use uuid instead. This field will be removed in future versions.')
  final int id;  // Legacy field for backward compatibility
  final String uuid;  // Supabase UUID - primary identifier
  final String email;
  final String name;
  final DateTime? createdAt;

  const AuthUser({
    @Deprecated('Use uuid instead') required this.id,
    required this.uuid,
    required this.email,
    required this.name,
    this.createdAt,
  });

  AuthUser copyWith({
    int? id,
    String? uuid,
    String? email,
    String? name,
    DateTime? createdAt,
  }) {
    return AuthUser(
      // ignore: deprecated_member_use_from_same_package
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      email: email ?? this.email,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
