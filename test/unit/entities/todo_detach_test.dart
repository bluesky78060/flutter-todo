/// DTA-2-4 회귀 방지.
///
/// thisOnly(이 항목만 수정) 경로는 Todo 를 직접 생성자로 다시 만든다.
/// 인자가 20개인데 그 결과를 단언하는 테스트가 하나도 없었다. 필드를
/// 새로 추가하면서 여기에 넣는 것을 잊으면 오류도 경고도 없이 기본값이
/// 되고, 사용자가 입력한 값이 사라진다. 실제로 그렇게 한 번 뚫렸다.
///
/// 필드를 하나씩 단언하면 그 필드만 지켜진다. 대신 "두 필드만 달라지고
/// 나머지는 그대로" 를 값 비교로 확인하면, 앞으로 추가되는 필드도 같은
/// 방식으로 누락될 때 깨진다.
library;

import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/data/datasources/remote/supabase_datasource.dart';
import 'package:todo_app/domain/entities/todo.dart';

void main() {
  // 모든 필드에 기본값과 구별되는 값을 넣는다. 기본값을 쓰면 보존에
  // 실패해도 우연히 같은 값이 나와 통과해 버린다.
  final instance = Todo(
    id: 42,
    title: '주간 회의',
    description: '팀 동기화',
    isCompleted: true,
    categoryId: 7,
    createdAt: DateTime.utc(2025, 1, 6, 9, 0),
    completedAt: DateTime.utc(2025, 1, 6, 10, 0),
    dueDate: DateTime.utc(2025, 1, 6, 10, 0),
    startDate: DateTime.utc(2025, 1, 6, 9, 0),
    notificationTime: DateTime.utc(2025, 1, 6, 8, 45),
    recurrenceRule: 'FREQ=WEEKLY;BYDAY=MO',
    parentRecurringTodoId: 11,
    snoozeCount: 2,
    lastSnoozeTime: DateTime.utc(2025, 1, 6, 8, 50),
    locationLatitude: 37.5665,
    locationLongitude: 126.9780,
    locationName: '서울',
    locationRadius: 120.0,
    position: 5,
    priority: 'high',
    googleEventId: 'evt-abc',
  );

  group('Todo.detachFromSeries', () {
    test('반복 관련 두 필드만 비운다', () {
      final detached = instance.detachFromSeries();

      expect(detached.recurrenceRule, isNull);
      expect(detached.parentRecurringTodoId, isNull);
    });

    test('나머지 필드는 하나도 잃지 않는다', () {
      final detached = instance.detachFromSeries();

      // 비운 두 필드를 되돌리면 원본과 값이 같아야 한다.
      // copyWith 는 21개 필드를 모두 덮으므로, 필드가 추가되면 이 비교
      // 범위도 함께 자란다. detach 가 새 필드를 빠뜨리면 여기서 깨진다.
      //
      // startDate 는 **일부러 넘기지 않는다.** 넘기면 detach 가 그 필드를
      // 잃었더라도 비교 직전에 되살아나 테스트가 그냥 통과한다.
      // (실제로 처음엔 넘겼고, 변이 검증에서 startDate 누락만 안 잡혀서
      //  알아챘다.) copyWith 의 sentinel 덕에 생략하면 detached 의 값이
      // 그대로 남으므로, 잃었다면 비교에서 드러난다.
      final restored = detached.copyWith(
        recurrenceRule: instance.recurrenceRule,
        parentRecurringTodoId: instance.parentRecurringTodoId,
      );

      // Todo 는 operator== 를 구현하지 않아 `==` 는 참조 비교다.
      // 그걸로 비교하면 언제나 다르다고 나와 테스트가 껍데기가 된다.
      // 저장 payload 를 기준으로 값 비교한다.
      expect(
        mapEquals(
          SupabaseTodoDataSource.buildUpdatePayload(restored),
          SupabaseTodoDataSource.buildUpdatePayload(instance),
        ),
        isTrue,
        reason: 'detachFromSeries 가 반복 외의 필드를 잃었습니다.\n'
            'before: ${SupabaseTodoDataSource.buildUpdatePayload(instance)}\n'
            'after : ${SupabaseTodoDataSource.buildUpdatePayload(restored)}',
      );
    });

    test('id 와 googleEventId 는 payload 밖이라 따로 확인한다', () {
      // buildUpdatePayload 에 없는 값들이라 위 비교가 잡지 못한다.
      final detached = instance.detachFromSeries();

      expect(detached.id, instance.id);
      expect(detached.googleEventId, instance.googleEventId);
      expect(detached.createdAt, instance.createdAt);
    });
  });
}
