import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/core/widget/widget_sort.dart';
import 'package:todo_app/domain/entities/todo.dart';

/// DTA-3-6 회귀 방지.
///
/// 홈 위젯이 "다음 할 일"이 아니라 **등록 순**으로 보이던 결함을 막는다.
/// 원인은 `position`(드래그 순서)으로 정렬한 것이었다. `position` 은 할 일을
/// 만들 때 증가하므로 결과적으로 등록 순이 된다.
///
/// 이 로직이 `WidgetService` 안에 있어 테스트가 없었고, 그래서 결함이
/// 오래 남아 있었다. 순수 함수로 빼낸 이유가 이것이다.
void main() {
  final today = DateTime(2026, 8, 21);

  Todo makeTodo({
    required int id,
    DateTime? dueDate,
    DateTime? startDate,
    DateTime? notificationTime,
    int position = 0,
    String? title,
  }) {
    return Todo(
      id: id,
      title: title ?? 'Todo $id',
      description: '',
      isCompleted: false,
      createdAt: DateTime(2026, 1, 1),
      dueDate: dueDate,
      startDate: startDate,
      notificationTime: notificationTime,
      position: position,
    );
  }

  List<String> titlesOf(List<Todo> todos) =>
      todos.map((t) => t.title).toList();

  group('마감이 가까운 순 (핵심)', () {
    test('11월 일정이 8월 일정보다 뒤로 간다 — 신고된 증상', () {
      // position 이 작다는 것은 먼저 등록됐다는 뜻이다.
      // 예전 구현은 이것만 보고 정렬해 11월 일정을 맨 위에 올렸다.
      final family = makeTodo(
        id: 1,
        title: '가족여행',
        dueDate: DateTime(2026, 11, 15),
        position: 0,
      );
      final bowling = makeTodo(
        id: 2,
        title: '봉화균수배 볼링대회',
        dueDate: DateTime(2026, 8, 22),
        position: 1,
      );

      final sorted = sortTodosByUpcoming([family, bowling], now: today);

      expect(
        titlesOf(sorted),
        ['봉화균수배 볼링대회', '가족여행'],
        reason: '등록이 빨라도 마감이 먼 일정은 뒤로 가야 한다',
      );
    });

    test('여러 건이 마감일 오름차순으로 정렬된다', () {
      final todos = [
        makeTodo(id: 1, dueDate: DateTime(2026, 8, 25), title: '스칼라'),
        makeTodo(id: 2, dueDate: DateTime(2026, 11, 15), title: '가족여행'),
        makeTodo(id: 3, dueDate: DateTime(2026, 8, 22), title: '볼링'),
      ];

      expect(
        titlesOf(sortTodosByUpcoming(todos, now: today)),
        ['볼링', '스칼라', '가족여행'],
      );
    });

    test('지난 일정이 앞에 온다 (가장 급한 것)', () {
      final overdue = makeTodo(id: 1, dueDate: DateTime(2026, 8, 1), title: '지남');
      final future = makeTodo(id: 2, dueDate: DateTime(2026, 8, 25), title: '앞으로');

      expect(
        titlesOf(sortTodosByUpcoming([future, overdue], now: today)),
        ['지남', '앞으로'],
      );
    });
  });

  group('기간 중인 일정 우선', () {
    test('오늘을 걸치는 범위 일정이 맨 앞에 온다', () {
      // 마감일만 보면 8/25 라 8/22 보다 뒤여야 하지만,
      // 지금 진행 중인 일정이므로 앞에 와야 한다.
      final trip = makeTodo(
        id: 1,
        title: '출장',
        startDate: DateTime(2026, 8, 19),
        dueDate: DateTime(2026, 8, 25),
      );
      final bowling = makeTodo(
        id: 2,
        title: '볼링',
        dueDate: DateTime(2026, 8, 22),
      );

      expect(
        titlesOf(sortTodosByUpcoming([bowling, trip], now: today)),
        ['출장', '볼링'],
        reason: '진행 중인 출장은 마감이 며칠 뒤여도 지금 신경 쓸 일이다',
      );
    });

    test('아직 시작 안 한 범위 일정은 우선순위를 받지 않는다', () {
      final futureTrip = makeTodo(
        id: 1,
        title: '다음달 출장',
        startDate: DateTime(2026, 9, 1),
        dueDate: DateTime(2026, 9, 5),
      );
      final bowling = makeTodo(
        id: 2,
        title: '볼링',
        dueDate: DateTime(2026, 8, 22),
      );

      expect(
        titlesOf(sortTodosByUpcoming([futureTrip, bowling], now: today)),
        ['볼링', '다음달 출장'],
      );
    });

    test('이미 끝난 범위 일정도 우선순위를 받지 않는다', () {
      final pastTrip = makeTodo(
        id: 1,
        title: '지난 출장',
        startDate: DateTime(2026, 8, 10),
        dueDate: DateTime(2026, 8, 15),
      );
      final bowling = makeTodo(
        id: 2,
        title: '볼링',
        dueDate: DateTime(2026, 8, 22),
      );

      final sorted = sortTodosByUpcoming([bowling, pastTrip], now: today);
      // 끝난 출장은 마감일(8/15)이 더 이르므로 마감일 규칙으로 앞에 온다.
      expect(titlesOf(sorted), ['지난 출장', '볼링']);
    });
  });

  group('같은 날이면 알림 시각 순', () {
    test('알림 시각이 이른 것이 먼저', () {
      final late = makeTodo(
        id: 1,
        title: '오후',
        dueDate: DateTime(2026, 8, 22),
        notificationTime: DateTime(2026, 8, 22, 15, 0),
      );
      final early = makeTodo(
        id: 2,
        title: '오전',
        dueDate: DateTime(2026, 8, 22),
        notificationTime: DateTime(2026, 8, 22, 9, 0),
      );

      expect(
        titlesOf(sortTodosByUpcoming([late, early], now: today)),
        ['오전', '오후'],
      );
    });

    test('알림 없는 종일 일정은 시각 있는 것보다 뒤', () {
      final allDay = makeTodo(id: 1, title: '종일', dueDate: DateTime(2026, 8, 22));
      final timed = makeTodo(
        id: 2,
        title: '시각',
        dueDate: DateTime(2026, 8, 22),
        notificationTime: DateTime(2026, 8, 22, 9, 0),
      );

      expect(
        titlesOf(sortTodosByUpcoming([allDay, timed], now: today)),
        ['시각', '종일'],
      );
    });
  });

  group('마감일 없는 할 일', () {
    test('맨 뒤로 간다', () {
      final noDue = makeTodo(id: 1, title: '마감없음', position: 0);
      final withDue = makeTodo(
        id: 2,
        title: '11월',
        dueDate: DateTime(2026, 11, 15),
        position: 9,
      );

      expect(
        titlesOf(sortTodosByUpcoming([noDue, withDue], now: today)),
        ['11월', '마감없음'],
        reason: '등록이 빨라도 마감 없는 것은 뒤로',
      );
    });

    test('마감일 없는 것끼리는 position 순 — 드래그 순서 존중', () {
      final second = makeTodo(id: 1, title: '두번째', position: 5);
      final first = makeTodo(id: 2, title: '첫번째', position: 1);

      expect(
        titlesOf(sortTodosByUpcoming([second, first], now: today)),
        ['첫번째', '두번째'],
      );
    });
  });

  group('buildWidgetTimeLabel — 위젯 라벨', _labelTests);

  group('원본 보존', () {
    test('입력 리스트를 변경하지 않는다', () {
      final a = makeTodo(id: 1, dueDate: DateTime(2026, 11, 15), title: 'A');
      final b = makeTodo(id: 2, dueDate: DateTime(2026, 8, 22), title: 'B');
      final original = [a, b];

      sortTodosByUpcoming(original, now: today);

      expect(titlesOf(original), ['A', 'B'], reason: '원본이 그대로여야 한다');
    });
  });
}

/// DTA-3-6 회귀 방지 — 위젯 라벨.
///
/// 예전에는 알림 시간이 있으면 **날짜를 버리고 시각만** 넣었다.
/// 위젯이 "오늘 것만" 보여줄 때는 문제없었지만, 다가오는 일정까지 올라오면서
/// 8/25 일정이 `09:00` 으로만 보여 며칠 뒤인지 알 수 없었다.
void _labelTests() {
  final today = DateTime(2026, 8, 21);

  Todo makeTodo({
    DateTime? dueDate,
    DateTime? startDate,
    DateTime? notificationTime,
  }) =>
      Todo(
        id: 1,
        title: 'T',
        description: '',
        isCompleted: false,
        createdAt: DateTime(2026, 1, 1),
        dueDate: dueDate,
        startDate: startDate,
        notificationTime: notificationTime,
      );

  test('오늘 일정은 시각만 — 오늘인 건 자명하다', () {
    final label = buildWidgetTimeLabel(
      makeTodo(
        dueDate: DateTime(2026, 8, 21),
        notificationTime: DateTime(2026, 8, 21, 9, 0),
      ),
      now: today,
    );
    expect(label, '09:00');
  });

  test('다른 날 + 알림 있음 → 날짜와 시각을 함께 보여 준다', () {
    final label = buildWidgetTimeLabel(
      makeTodo(
        dueDate: DateTime(2026, 8, 25),
        notificationTime: DateTime(2026, 8, 25, 9, 0),
      ),
      now: today,
    );
    expect(
      label,
      '8/25 09:00',
      reason: '예전에는 "09:00" 만 나와서 며칠 뒤인지 알 수 없었다',
    );
  });

  test('다른 날 + 알림 없음 → 날짜만', () {
    final label = buildWidgetTimeLabel(
      makeTodo(dueDate: DateTime(2026, 11, 15)),
      now: today,
    );
    expect(label, '11/15');
  });

  test('오늘 + 알림 없는 종일 → 빈 문자열', () {
    final label = buildWidgetTimeLabel(
      makeTodo(dueDate: DateTime(2026, 8, 21)),
      now: today,
    );
    expect(label, '');
  });

  test('진행 중인 범위 일정은 종료일을 보여 준다', () {
    final label = buildWidgetTimeLabel(
      makeTodo(
        startDate: DateTime(2026, 8, 19),
        dueDate: DateTime(2026, 8, 25),
        notificationTime: DateTime(2026, 8, 19, 9, 0),
      ),
      now: today,
    );
    expect(label, '~8/25', reason: '진행 중이면 언제까지인지가 가장 쓸모 있다');
  });

  test('아직 시작 안 한 범위 일정은 일반 규칙을 따른다', () {
    final label = buildWidgetTimeLabel(
      makeTodo(
        startDate: DateTime(2026, 9, 1),
        dueDate: DateTime(2026, 9, 5),
      ),
      now: today,
    );
    expect(label, '9/5');
  });

  test('마감일이 없으면 빈 문자열', () {
    expect(buildWidgetTimeLabel(makeTodo(), now: today), '');
  });
}
