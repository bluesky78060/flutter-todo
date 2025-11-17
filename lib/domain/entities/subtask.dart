class Subtask {
  final int id;
  final int todoId;
  final String userId;
  final String title;
  final bool isCompleted;
  final int position;
  final DateTime createdAt;
  final DateTime? completedAt;

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
