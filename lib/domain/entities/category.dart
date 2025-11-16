class Category {
  final int id;
  final String userId;
  final String name;
  final String color;
  final String? icon;
  final DateTime createdAt;

  const Category({
    required this.id,
    required this.userId,
    required this.name,
    required this.color,
    this.icon,
    required this.createdAt,
  });

  Category copyWith({
    int? id,
    String? userId,
    String? name,
    String? color,
    String? icon,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
