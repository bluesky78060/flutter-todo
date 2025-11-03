class AuthUser {
  final int id;
  final String email;
  final String name;
  final DateTime? createdAt;

  const AuthUser({
    required this.id,
    required this.email,
    required this.name,
    this.createdAt,
  });

  AuthUser copyWith({
    int? id,
    String? email,
    String? name,
    DateTime? createdAt,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
