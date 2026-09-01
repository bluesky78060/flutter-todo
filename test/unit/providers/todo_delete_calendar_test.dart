/// DTA-3-3 / DTA-3-5 배선 검증.
///
/// 서비스 쪽 삭제 규칙(routeEventDelete)은 따로 테스트하고 있다. 여기서
/// 확인하는 것은 **그 규칙이 실제로 불리는가** 다. 규칙이 아무리 옳아도
/// 삭제 경로가 부르지 않으면 사용자에게는 아무것도 고쳐지지 않는다.
///
/// 지난 두 번의 경험이 이 테스트의 이유다 — 초록불은 "가드가 동작한다" 와
/// "가드에 닿지 못한다" 를 구분해 주지 않는다.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:todo_app/core/errors/failures.dart';
import 'package:todo_app/core/services/google_calendar_service.dart';
import 'package:todo_app/domain/entities/todo.dart';
import 'package:todo_app/domain/repositories/todo_repository.dart';
import 'package:todo_app/presentation/providers/database_provider.dart';
import 'package:todo_app/presentation/providers/google_calendar_service_provider.dart';
import 'package:todo_app/presentation/providers/todo_providers.dart';

/// deleteEvent 가 어떤 ID 로 불렸는지 기록한다.
class _StubCalendarService extends GoogleCalendarService {
  _StubCalendarService({this.result = true}) : super.forTesting();

  final bool result;
  final List<String?> deleted = [];

  @override
  Future<bool> deleteEvent(String? eventId) async {
    deleted.add(eventId);
    return result;
  }
}

class _StubTodoRepository implements TodoRepository {
  _StubTodoRepository(this.todo);

  final Todo todo;
  final List<int> deletedIds = [];

  @override
  Future<Either<Failure, Todo>> getTodoById(int id) async => right(todo);

  @override
  Future<Either<Failure, Unit>> deleteTodo(int id) async {
    deletedIds.add(id);
    return right(unit);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Todo makeTodo({String? googleEventId}) => Todo(
      id: 7,
      title: '치과 예약',
      description: '',
      isCompleted: false,
      createdAt: DateTime.utc(2025, 5, 1),
      dueDate: DateTime.utc(2025, 5, 20, 10, 0),
      googleEventId: googleEventId,
    );

void main() {
  late _StubCalendarService calendar;
  late _StubTodoRepository repository;
  late ProviderContainer container;

  void build(Todo todo, {bool deleteSucceeds = true}) {
    calendar = _StubCalendarService(result: deleteSucceeds);
    repository = _StubTodoRepository(todo);
    container = ProviderContainer(
      overrides: [
        todoRepositoryProvider.overrideWithValue(repository),
        googleCalendarServiceProvider.overrideWithValue(calendar),
      ],
    );
    addTearDown(container.dispose);
  }

  group('할 일 삭제 시 캘린더 이벤트 정리', () {
    test('동기화된 할 일은 그 이벤트 ID 로 삭제를 요청한다', () async {
      build(makeTodo(googleEventId: 'evt-77'));

      await container.read(todoActionsProvider).deleteTodo(7);

      expect(calendar.deleted, ['evt-77']);
      expect(repository.deletedIds, [7], reason: '할 일 자체도 지워져야 한다');
    });

    test('동기화된 적 없는 할 일은 캘린더를 건드리지 않는다', () async {
      build(makeTodo(googleEventId: null));

      await container.read(todoActionsProvider).deleteTodo(7);

      // 지울 게 없는데 부르면 불필요한 실패 지점만 생긴다.
      expect(calendar.deleted, isEmpty);
      expect(repository.deletedIds, [7]);
    });

    test('캘린더 삭제가 실패해도 할 일 삭제는 진행한다', () async {
      // 사용자가 지우겠다고 한 것을 네트워크 사정으로 막을 수는 없다.
      build(makeTodo(googleEventId: 'evt-77'), deleteSucceeds: false);

      await container.read(todoActionsProvider).deleteTodo(7);

      expect(calendar.deleted, ['evt-77']);
      expect(repository.deletedIds, [7]);
    });
  });
}
