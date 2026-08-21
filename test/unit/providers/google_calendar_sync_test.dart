import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:todo_app/core/errors/failures.dart';
import 'package:todo_app/core/services/google_calendar_service.dart';
import 'package:todo_app/domain/entities/todo.dart';
import 'package:todo_app/domain/repositories/todo_repository.dart';
import 'package:todo_app/presentation/providers/database_provider.dart';
import 'package:todo_app/presentation/providers/google_calendar_provider.dart';

/// DTA-3-1 코드 리뷰 MAJOR-N1 회귀 방지.
///
/// 이 계층에는 테스트가 하나도 없었고, 바로 그 사각지대에서 결함이 두 번 살아남았다.
/// `getFilteredTodos` 가 `Left` 를 낼 때 실패를 **삼키지 않고 던지는지** 가 핵심이다.
/// 삼키면 호출부에는 "대상 0건" 으로 보여 사용자에게 틀린 원인이 표시된다.
class _StubTodoRepository implements TodoRepository {
  _StubTodoRepository(this.result);

  final Either<Failure, List<Todo>> result;

  /// `getFilteredTodos` 가 실제로 불렸는지 기록한다.
  /// 이게 없으면 "저장소를 읽지 않는다" 는 테스트 이름이 거짓이 된다.
  bool wasRead = false;

  @override
  Future<Either<Failure, List<Todo>>> getFilteredTodos(String filter) async {
    wasRead = true;
    return result;
  }

  // 이 테스트가 부르지 않는 나머지 메서드는 구현하지 않는다.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Todo makeTodo({
  required int id,
  DateTime? dueDate,
  bool isCompleted = false,
  String? recurrenceRule,
  int? parentRecurringTodoId,
}) {
  return Todo(
    id: id,
    title: 'Todo $id',
    description: '',
    isCompleted: isCompleted,
    createdAt: DateTime(2025, 1, 1),
    dueDate: dueDate,
    recurrenceRule: recurrenceRule,
    parentRecurringTodoId: parentRecurringTodoId,
  );
}

void main() {
  late _StubTodoRepository stub;

  ProviderContainer makeContainer(Either<Failure, List<Todo>> repoResult) {
    stub = _StubTodoRepository(repoResult);
    return ProviderContainer(
      overrides: [todoRepositoryProvider.overrideWithValue(stub)],
    );
  }

  group('syncAllTodos — 연결 상태', () {
    test('연결되어 있지 않으면 notConnected 를 돌려주고 저장소를 읽지 않는다', () async {
      final container = makeContainer(right(<Todo>[]));
      addTearDown(container.dispose);

      final result = await container
          .read(googleCalendarProvider.notifier)
          .syncAllTodos();

      expect(result.notConnected, isTrue);
      expect(result.succeeded, 0);
      expect(
        stub.wasRead,
        isFalse,
        reason: '미연결이면 저장소를 읽기 전에 빠져나가야 한다. '
            '순서가 바뀌어도 이 어서션이 잡는다',
      );
    });
  });

  group('syncAllTodos — 저장소 실패 (MAJOR-N1)', () {
    test('getFilteredTodos 가 Left 를 내면 예외를 던진다', () async {
      final container =
          makeContainer(left(const DatabaseFailure('Network error')));
      addTearDown(container.dispose);

      final notifier = container.read(googleCalendarProvider.notifier)
        ..debugSetConnected(isConnected: true);

      expect(
        () => notifier.syncAllTodos(),
        throwsA(isA<Exception>()),
        reason: '실패를 빈 목록으로 삼키면 호출부에 "대상 0건" 으로 보여 '
            '"등록할 할 일이 없습니다" 라는 틀린 원인이 사용자에게 표시된다',
      );
    });

    test('저장소 실패를 성공 결과로 위장하지 않는다', () async {
      final container =
          makeContainer(left(const DatabaseFailure('permission denied')));
      addTearDown(container.dispose);

      final notifier = container.read(googleCalendarProvider.notifier)
        ..debugSetConnected(isConnected: true);

      CalendarSyncResult? returned;
      Object? thrown;
      try {
        returned = await notifier.syncAllTodos();
      } catch (e) {
        thrown = e;
      }

      expect(
        returned,
        isNull,
        reason: 'succeeded 0 / failed 0 인 결과를 정상 반환하면 안 된다',
      );
      // 아무 예외나 통과시키면 스텁의 NoSuchMethodError 로도 초록이 된다.
      expect(thrown, isA<Exception>());
      expect(thrown.toString(), contains('permission denied'),
          reason: '실패 원인이 그대로 전달되어야 화면이 사용자에게 보여 줄 수 있다');
    });
  });
}
