/// A category entity for organizing todos.
///
/// Categories allow users to group and organize their todos by topic,
/// project, or any other classification. Each category has a distinct
/// color for visual identification.
///
/// Example:
/// ```dart
/// final workCategory = Category(
///   id: 1,
///   userId: 'user-uuid',
///   name: 'Work',
///   color: '#FF5722',
///   createdAt: DateTime.now(),
/// );
/// ```
class Category {
  /// Unique identifier for the category.
  final int id;

  /// The UUID of the user who owns this category.
  final String userId;

  /// The display name of the category.
  final String name;

  /// Hex color code for the category (e.g., "#FF5722").
  final String color;

  /// Optional icon identifier for the category.
  final String? icon;

  /// When the category was created.
  final DateTime createdAt;

  /// Creates a new [Category] instance.
  const Category({
    required this.id,
    required this.userId,
    required this.name,
    required this.color,
    this.icon,
    required this.createdAt,
  });

  /// Creates a copy of this category with the given fields replaced.
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
