/// 쓰기 payload 와 읽기 매핑이 어긋나지 않는지 지키는 테스트.
///
/// 이 테스트가 존재하는 이유(DTA-3-2): buildUpdatePayload 는 'priority' 를
/// 보내는데 읽기 쪽에는 그 키가 없었다. 값이 DB 에는 저장되지만 다시
/// 불러오면 엔티티 기본값 'medium' 으로 돌아왔다. 오류도 경고도 나지 않아
/// 아무도 몰랐다.
///
/// 필드 하나를 콕 집어 단언하면 그 필드만 지켜진다. 대신 왕복시켜
/// 비교하면 **앞으로 추가되는 필드**도 같은 방식으로 누락될 때 깨진다.
library;

import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/data/datasources/remote/supabase_datasource.dart';
import 'package:todo_app/domain/entities/todo.dart';

/// buildUpdatePayload 가 만든 payload 를 Supabase 가 돌려주는 행 모양으로
/// 맞춘다. id 와 created_at 은 payload 에 없고 DB 가 채우는 값이다.
Map<String, dynamic> asRow(Map<String, dynamic> payload, Todo todo) => {
      ...payload,
      'id': todo.id,
      'created_at': todo.createdAt.toUtc().toIso8601String(),
    };

/// 두 Todo 가 **값으로** 같은지 본다.
///
/// Todo 는 operator== 를 구현하지 않아 `a == b` 는 참조 비교다. 그걸로
/// 비교하면 서로 다른 인스턴스는 언제나 다르다고 나와, 이 테스트가
/// 결코 실패하지 않는 껍데기가 된다.
///
/// buildUpdatePayload 를 비교 기준으로 쓴다. 저장되는 모든 필드를 담고
/// 있고, 필드가 추가되면 payload 에도 추가되므로 비교 범위가 함께 자란다.
bool sameTodo(Todo a, Todo b) => mapEquals(
      SupabaseTodoDataSource.buildUpdatePayload(a),
      SupabaseTodoDataSource.buildUpdatePayload(b),
    );

void main() {
  group('SupabaseTodoDataSource 쓰기/읽기 왕복', () {
    // 모든 필드에 기본값과 구별되는 값을 넣는다. 기본값을 쓰면 매핑이
    // 빠져 있어도 우연히 같은 값이 나와 테스트가 통과해 버린다.
    final todo = Todo(
      id: 42,
      title: '출장',
      description: '부산 지사 방문',
      isCompleted: true,
      categoryId: 7,
      createdAt: DateTime.utc(2025, 3, 1, 9, 0),
      completedAt: DateTime.utc(2025, 3, 5, 18, 30),
      dueDate: DateTime.utc(2025, 3, 5, 17, 0),
      startDate: DateTime.utc(2025, 3, 3, 9, 0),
      notificationTime: DateTime.utc(2025, 3, 5, 16, 0),
      recurrenceRule: 'FREQ=WEEKLY',
      parentRecurringTodoId: 11,
      snoozeCount: 3,
      lastSnoozeTime: DateTime.utc(2025, 3, 4, 8, 15),
      locationLatitude: 35.1796,
      locationLongitude: 129.0756,
      locationName: '부산',
      locationRadius: 250.0,
      position: 5,
      priority: 'high', // 기본값 'medium' 과 달라야 누락을 잡는다
    );

    test('buildUpdatePayload 가 보낸 값이 todoFromJson 으로 그대로 돌아온다', () {
      final payload = SupabaseTodoDataSource.buildUpdatePayload(todo);
      final restored = SupabaseTodoDataSource.todoFromJson(asRow(payload, todo));

      expect(restored.title, todo.title);
      expect(restored.description, todo.description);
      expect(restored.isCompleted, todo.isCompleted);
      expect(restored.categoryId, todo.categoryId);
      expect(restored.recurrenceRule, todo.recurrenceRule);
      expect(restored.parentRecurringTodoId, todo.parentRecurringTodoId);
      expect(restored.snoozeCount, todo.snoozeCount);
      expect(restored.locationLatitude, todo.locationLatitude);
      expect(restored.locationLongitude, todo.locationLongitude);
      expect(restored.locationName, todo.locationName);
      expect(restored.locationRadius, todo.locationRadius);
      expect(restored.position, todo.position);
      expect(restored.priority, todo.priority);

      // DateTime 은 UTC 로 보내고 로컬로 읽어 오므로 시각으로 비교한다.
      expect(restored.completedAt!.isAtSameMomentAs(todo.completedAt!), isTrue);
      expect(restored.dueDate!.isAtSameMomentAs(todo.dueDate!), isTrue);
      expect(restored.startDate!.isAtSameMomentAs(todo.startDate!), isTrue);
      expect(
        restored.notificationTime!.isAtSameMomentAs(todo.notificationTime!),
        isTrue,
      );
      expect(
        restored.lastSnoozeTime!.isAtSameMomentAs(todo.lastSnoozeTime!),
        isTrue,
      );
    });

    test('쓰기 payload 의 모든 키를 읽기가 소비한다', () {
      final payload = SupabaseTodoDataSource.buildUpdatePayload(todo);

      // 키를 하나씩 빼고 읽어서, 빠뜨린 키가 결과를 바꾸는지 본다.
      // 결과가 그대로라면 그 키는 읽기에서 쓰이지 않는다는 뜻이다.
      //
      // 키를 빼서 예외가 나는 경우도 "읽는다" 로 친다. 필수 필드는
      // non-nullable 캐스트라 없으면 던진다 — 그것도 소비의 증거다.
      final ignored = <String>[];
      final reference = SupabaseTodoDataSource.todoFromJson(asRow(payload, todo));
      for (final key in payload.keys) {
        final without = asRow(payload, todo)..remove(key);
        try {
          if (sameTodo(SupabaseTodoDataSource.todoFromJson(without), reference)) {
            ignored.add(key);
          }
        } catch (_) {
          // 던졌다 = 그 키를 읽는다
        }
      }

      expect(
        ignored,
        isEmpty,
        reason: '쓰기에는 있지만 읽기가 무시하는 키: $ignored\n'
            'todoFromJson 에 해당 키 매핑을 추가하십시오.',
      );
    });

    test('priority 가 없는 행은 엔티티 기본값 medium 이 된다', () {
      final payload = SupabaseTodoDataSource.buildUpdatePayload(todo);
      final row = asRow(payload, todo)..remove('priority');

      expect(SupabaseTodoDataSource.todoFromJson(row).priority, 'medium');
    });
  });
}
