/// A subtask entity representing a checklist item within a todo.
///
/// Subtasks allow users to break down larger todos into smaller,
/// actionable items. Each subtask can be independently completed
/// and reordered within its parent todo.
///
/// Example:
/// ```dart
/// final subtask = Subtask(
///   id: 1,
///   todoId: 42,
///   userId: 'user-uuid',
///   title: 'Buy milk',
///   isCompleted: false,
///   position: 0,
///   createdAt: DateTime.now(),
/// );
/// ```
///
/// See also:
/// - [Todo] for the parent entity
/// - [SubtaskRepository] for persistence operations
class Subtask {
  /// Unique identifier for the subtask.
  final int id;

  /// The ID of the parent todo this subtask belongs to.
  final int todoId;

  /// The UUID of the user who owns this subtask.
  final String userId;

  /// The title/description of the subtask.
  final String title;

  /// Whether this subtask has been completed.
  final bool isCompleted;

  /// Order position for drag-and-drop sorting within the todo.
  final int position;

  /// When the subtask was created.
  final DateTime createdAt;

  /// When the subtask was completed, if applicable.
  final DateTime? completedAt;

  /// Creates a new [Subtask] instance.
  const Subtask({
    required this.id,
    required this.todoId,
    required this.userId,
    required this.title,
    this.isCompleted = false,
    required this.position,
    required this.createdAt,
    this.completedAt,
  });

  factory Subtask.fromJson(Map<String, dynamic> json) {
    return Subtask(
      id: json['id'] as int,
      todoId: json['todoId'] as int,
      userId: json['userId'] as String,
      title: json['title'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
      position: json['position'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'todoId': todoId,
      'userId': userId,
      'title': title,
      'isCompleted': isCompleted,
      'position': position,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  Subtask copyWith({
    int? id,
    int? todoId,
    String? userId,
    String? title,
    bool? isCompleted,
    int? position,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return Subtask(
      id: id ?? this.id,
      todoId: todoId ?? this.todoId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Subtask &&
        other.id == id &&
        other.todoId == todoId &&
        other.userId == userId &&
        other.title == title &&
        other.isCompleted == isCompleted &&
        other.position == position &&
        other.createdAt == createdAt &&
        other.completedAt == completedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      todoId,
      userId,
      title,
      isCompleted,
      position,
      createdAt,
      completedAt,
    );
  }

  @override
  String toString() {
    return 'Subtask(id: $id, todoId: $todoId, userId: $userId, title: $title, isCompleted: $isCompleted, position: $position, createdAt: $createdAt, completedAt: $completedAt)';
  }
}
