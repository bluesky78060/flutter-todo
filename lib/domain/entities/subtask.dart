import 'package:freezed_annotation/freezed_annotation.dart';

part 'subtask.freezed.dart';
part 'subtask.g.dart';

@freezed
class Subtask with _$Subtask {
  const factory Subtask({
    required int id,
    required int todoId,
    required String userId,
    required String title,
    @Default(false) bool isCompleted,
    required int position,
    required DateTime createdAt,
    DateTime? completedAt,
  }) = _Subtask;

  factory Subtask.fromJson(Map<String, dynamic> json) =>
      _$SubtaskFromJson(json);
}
