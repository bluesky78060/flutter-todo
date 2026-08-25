import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/data/datasources/remote/supabase_datasource.dart';
import 'package:todo_app/domain/entities/todo.dart';

/// DTA-3-4 회귀 방지 — Supabase payload 계층.
///
/// `start_date` 키를 넣을지 말지가 이 기능의 핵심 판단이다.
///
/// - 값이 없고 해제 의도도 없으면 **키 자체를 넣지 않는다.**
///   `start_date` 컬럼이 아직 없는 프로젝트에서 PostgREST 가 payload 전체를
///   거부하기 때문이다. 키를 빼면 기존 할 일 생성·수정이 그대로 동작한다.
/// - 해제할 때는 **명시적으로 null 을 보내야** 한다. 키를 빼면 DB 의 옛 값이
///   그대로 남아 다음 실행 때 범위가 되살아난다.
void main() {
  Todo makeTodo({DateTime? startDate, DateTime? dueDate}) => Todo(
        id: 42,
        title: 'T',
        description: '',
        isCompleted: false,
        createdAt: DateTime(2025, 1, 1),
        dueDate: dueDate,
        startDate: startDate,
      );

  group('buildCreatePayload', () {
    test('startDate 가 없으면 start_date 키가 아예 없다', () {
      final payload = SupabaseTodoDataSource.buildCreatePayload(
        userId: 'u1',
        title: 'T',
        description: '',
        position: 0,
        dueDate: DateTime(2025, 8, 25),
      );

      expect(
        payload.containsKey('start_date'),
        isFalse,
        reason: '키가 있으면 컬럼이 없는 프로젝트에서 할 일 생성이 통째로 실패한다',
      );
      expect(payload['due_date'], isNotNull, reason: '나머지는 정상 동작해야 한다');
    });

    test('startDate 가 있으면 UTC ISO 문자열로 들어간다', () {
      final payload = SupabaseTodoDataSource.buildCreatePayload(
        userId: 'u1',
        title: 'T',
        description: '',
        position: 0,
        startDate: DateTime.utc(2025, 8, 21),
        dueDate: DateTime.utc(2025, 8, 25),
      );

      expect(payload['start_date'], '2025-08-21T00:00:00.000Z');
    });
  });

  group('buildUpdatePayload', () {
    test('범위가 아니고 해제 의도도 없으면 start_date 키가 없다', () {
      final payload = SupabaseTodoDataSource.buildUpdatePayload(
        makeTodo(dueDate: DateTime(2025, 8, 25)),
      );

      expect(payload.containsKey('start_date'), isFalse);
    });

    test('범위면 start_date 가 들어간다', () {
      final payload = SupabaseTodoDataSource.buildUpdatePayload(
        makeTodo(
          startDate: DateTime.utc(2025, 8, 21),
          dueDate: DateTime.utc(2025, 8, 25),
        ),
      );

      expect(payload['start_date'], '2025-08-21T00:00:00.000Z');
    });

    test('해제 시 명시적으로 null 을 보낸다 (키 생략이 아니다)', () {
      final payload = SupabaseTodoDataSource.buildUpdatePayload(
        makeTodo(dueDate: DateTime(2025, 8, 25)),
        clearStartDate: true,
      );

      expect(
        payload.containsKey('start_date'),
        isTrue,
        reason: '키를 빼면 DB 의 옛 값이 남아 다음 실행 때 범위가 되살아난다',
      );
      expect(payload['start_date'], isNull);
    });

    test('범위가 있으면 clearStartDate 가 켜져 있어도 값이 우선한다', () {
      final payload = SupabaseTodoDataSource.buildUpdatePayload(
        makeTodo(
          startDate: DateTime.utc(2025, 8, 21),
          dueDate: DateTime.utc(2025, 8, 25),
        ),
        clearStartDate: true,
      );

      expect(payload['start_date'], isNotNull);
    });

    test('기존 필드는 그대로 실린다 (회귀 방지)', () {
      final payload = SupabaseTodoDataSource.buildUpdatePayload(
        makeTodo(dueDate: DateTime(2025, 8, 25)),
      );

      for (final key in [
        'title',
        'description',
        'is_completed',
        'due_date',
        'priority',
        'position',
      ]) {
        expect(payload.containsKey(key), isTrue, reason: '$key 가 빠졌다');
      }
    });
  });
}
