import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/core/widget/widget_pending_sync.dart';

/// DTA-3-7 회귀 방지 — 위젯에서 넘어온 완료 요청 파싱.
///
/// 이 문자열은 **네이티브 코드가 쓰고 Dart 가 읽는** 유일한 접점이다.
/// iOS `CompleteTodoIntent`, Android `WidgetActionReceiver` 양쪽이 같은
/// 형식으로 쓴다. 여기가 깨지면 위젯에서 누른 완료가 조용히 사라진다.
void main() {
  group('정상 입력', () {
    test('한 건', () {
      expect(parsePendingSyncs('7:true'), [const PendingSync(7, true)]);
    });

    test('여러 건은 쓰인 순서를 지킨다', () {
      expect(
        parsePendingSyncs('7:true,9:false,3:true'),
        [
          const PendingSync(7, true),
          const PendingSync(9, false),
          const PendingSync(3, true),
        ],
      );
    });

    test('공백이 섞여 있어도 읽는다', () {
      expect(parsePendingSyncs(' 7 : true '), [const PendingSync(7, true)]);
    });
  });

  group('빈 입력', () {
    test('null', () => expect(parsePendingSyncs(null), isEmpty));
    test('빈 문자열', () => expect(parsePendingSyncs(''), isEmpty));
    test('쉼표만', () => expect(parsePendingSyncs(',,,'), isEmpty));
  });

  group('중복 — 마지막 것이 이긴다', () {
    test('같은 id 가 두 번 나오면 뒤엣것을 쓴다', () {
      expect(
        parsePendingSyncs('7:true,7:false'),
        [const PendingSync(7, false)],
        reason: '사용자가 마지막으로 누른 것이 의도다. '
            '첫 항목을 살리면 정반대로 반영된다',
      );
    });

    test('덮어써도 원래 자리를 지킨다', () {
      expect(
        parsePendingSyncs('7:true,9:true,7:false'),
        [const PendingSync(7, false), const PendingSync(9, true)],
      );
    });
  });

  group('깨진 항목은 버리되 나머지는 살린다', () {
    test('콜론 없는 항목', () {
      expect(
        parsePendingSyncs('7:true,garbage,9:false'),
        [const PendingSync(7, true), const PendingSync(9, false)],
        reason: '하나 깨졌다고 나머지 완료 처리까지 잃으면 안 된다',
      );
    });

    test('숫자가 아닌 id', () {
      expect(parsePendingSyncs('abc:true,9:true'), [const PendingSync(9, true)]);
    });

    test('콜론이 여러 개면 버린다', () {
      expect(parsePendingSyncs('7:true:extra,9:true'),
          [const PendingSync(9, true)]);
    });

    test('전부 깨졌으면 빈 목록', () {
      expect(parsePendingSyncs('garbage,abc:true:x'), isEmpty);
    });
  });

  group('formatPendingSyncs — 저장 형식으로 되돌린다', () {
    test('parse 의 역이다 — 왕복해도 같다', () {
      const raw = '7:true,9:false';
      expect(formatPendingSyncs(parsePendingSyncs(raw)), raw);
    });

    test('빈 목록은 빈 문자열', () {
      expect(formatPendingSyncs(const []), '');
    });

    test('Swift·Kotlin 이 쓰는 형식과 같다', () {
      // 위젯 쪽 enqueue 가 "id:true" 로 쓴다. 여기서 다르게 쓰면
      // 다음 진입에서 자기가 쓴 것을 못 읽는다.
      expect(formatPendingSyncs([const PendingSync(7, true)]), '7:true');
    });
  });

  group('capPendingSyncs — 큐가 무한히 자라지 않는다', () {
    test('상한 이하면 그대로', () {
      final syncs = [const PendingSync(1, true), const PendingSync(2, true)];
      expect(capPendingSyncs(syncs, cap: 5), syncs);
    });

    test('상한을 넘으면 오래된 것부터 버린다', () {
      final syncs = List.generate(5, (i) => PendingSync(i, true));
      expect(
        capPendingSyncs(syncs, cap: 2).map((s) => s.todoId),
        [3, 4],
        reason: '최근 조작이 사용자 의도에 가깝다',
      );
    });

    test('삭제된 할 일처럼 영원히 실패하는 항목이 쌓여도 상한에서 멈춘다', () {
      final syncs = List.generate(200, (i) => PendingSync(i, true));
      expect(capPendingSyncs(syncs).length, kPendingSyncQueueCap);
    });
  });

  group("완료 여부는 'true' 만 참", () {
    test("'false' 는 미완료", () {
      expect(parsePendingSyncs('7:false').single.isCompleted, isFalse);
    });

    test("예상 못한 값은 미완료로 떨어뜨린다", () {
      // 위젯 쪽 버그로 이상한 값이 와도 멀쩡한 할 일을 완료로 바꾸지 않는다.
      expect(parsePendingSyncs('7:TRUE').single.isCompleted, isFalse);
      expect(parsePendingSyncs('7:1').single.isCompleted, isFalse);
    });
  });
}
