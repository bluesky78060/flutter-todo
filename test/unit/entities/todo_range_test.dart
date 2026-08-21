import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/domain/entities/todo.dart';

/// DTA-3-4 회귀 방지 — 엔티티 계층.
///
/// 가장 중요한 것은 **하위호환**이다. `startDate == null` 이면 기존과 완전히
/// 동일하게 동작해야 한다. 이 전제가 `dueDate` 255곳에 대한 파급 차단 장치다.
void main() {
  Todo makeTodo({DateTime? startDate, DateTime? dueDate}) => Todo(
        id: 1,
        title: 'T',
        description: '',
        isCompleted: false,
        createdAt: DateTime(2025, 1, 1),
        dueDate: dueDate,
        startDate: startDate,
      );

  group('isRanged', () {
    test('startDate 와 dueDate 가 모두 있어야 범위다', () {
      expect(
        makeTodo(
                startDate: DateTime(2025, 8, 21),
                dueDate: DateTime(2025, 8, 25))
            .isRanged,
        isTrue,
      );
    });

    test('startDate 만 있으면 범위가 아니다 — 끝을 알 수 없다', () {
      expect(makeTodo(startDate: DateTime(2025, 8, 21)).isRanged, isFalse);
    });

    test('startDate 가 없으면 범위가 아니다', () {
      expect(makeTodo(dueDate: DateTime(2025, 8, 25)).isRanged, isFalse);
    });
  });

  group('occursOn — 하위호환 (startDate == null)', () {
    final todo = makeTodo(dueDate: DateTime(2025, 8, 25, 14, 30));

    test('마감일 당일만 true', () {
      expect(todo.occursOn(DateTime(2025, 8, 25)), isTrue);
    });

    test('하루 전은 false', () {
      expect(todo.occursOn(DateTime(2025, 8, 24)), isFalse);
    });

    test('하루 후는 false', () {
      expect(todo.occursOn(DateTime(2025, 8, 26)), isFalse);
    });

    test('시각이 달라도 같은 날이면 true', () {
      expect(todo.occursOn(DateTime(2025, 8, 25, 23, 59)), isTrue);
    });

    test('dueDate 가 없으면 항상 false', () {
      expect(makeTodo().occursOn(DateTime(2025, 8, 25)), isFalse);
    });
  });

  group('occursOn — 범위', () {
    final todo = makeTodo(
      startDate: DateTime(2025, 8, 21),
      dueDate: DateTime(2025, 8, 25),
    );

    test('시작일 포함', () => expect(todo.occursOn(DateTime(2025, 8, 21)), isTrue));
    test('중간 포함', () => expect(todo.occursOn(DateTime(2025, 8, 23)), isTrue));
    test('종료일 포함', () => expect(todo.occursOn(DateTime(2025, 8, 25)), isTrue));

    test('시작 하루 전은 false', () {
      expect(todo.occursOn(DateTime(2025, 8, 20)), isFalse);
    });

    test('종료 하루 후는 false', () {
      expect(todo.occursOn(DateTime(2025, 8, 26)), isFalse);
    });

    test('월 경계를 넘는 범위', () {
      final t = makeTodo(
        startDate: DateTime(2025, 2, 27),
        dueDate: DateTime(2025, 3, 2),
      );
      expect(t.occursOn(DateTime(2025, 2, 28)), isTrue);
      expect(t.occursOn(DateTime(2025, 3, 1)), isTrue);
      expect(t.occursOn(DateTime(2025, 3, 3)), isFalse);
    });
  });

  group('copyWith — sentinel (CRITICAL-1 회귀 방지)', () {
    final ranged = makeTodo(
      startDate: DateTime(2025, 8, 21),
      dueDate: DateTime(2025, 8, 25),
    );

    test('startDate 를 명시하지 않으면 기존 값이 유지된다', () {
      expect(ranged.copyWith(title: 'X').startDate, DateTime(2025, 8, 21));
    });

    test('startDate 에 null 을 넘기면 실제로 null 이 된다', () {
      final cleared = ranged.copyWith(startDate: null);

      expect(
        cleared.startDate,
        isNull,
        reason: '일반적인 `x ?? this.x` 패턴이면 옛 값이 살아남아 '
            '사용자가 범위를 해제할 수 없다',
      );
      expect(cleared.isRanged, isFalse);
      expect(cleared.dueDate, DateTime(2025, 8, 25), reason: 'dueDate 는 유지');
    });

    test('startDate 를 다른 값으로 바꿀 수 있다', () {
      expect(
        ranged.copyWith(startDate: DateTime(2025, 8, 22)).startDate,
        DateTime(2025, 8, 22),
      );
    });
  });
}
