/// 홈 위젯에서 넘어온 완료 요청 한 건.
///
/// 위젯(iOS `CompleteTodoIntent`, Android `WidgetActionReceiver`)은 서버를
/// 직접 건드리지 않고 App Group / SharedPreferences 의 `pending_syncs` 에
/// `"id:completed"` 형식으로 쌓아 둔다. 앱이 다시 열릴 때 여기를 비운다.
///
/// 반영 대상은 **Supabase 뿐이다.** `todoRepositoryProvider` 가
/// `SupabaseTodoRepository` 를 돌려주고, Drift 용 `TodoRepositoryImpl` 은
/// todo 경로에 연결되어 있지 않다. 네트워크가 없으면 반영되지 않으므로
/// 실패한 항목은 큐에 남는다.
class PendingSync {
  /// 대상 할 일의 id.
  final int todoId;

  /// **목표 상태**다. "뒤집어라"가 아니라 "이 값으로 만들어라".
  final bool isCompleted;

  const PendingSync(this.todoId, this.isCompleted);

  @override
  bool operator ==(Object other) =>
      other is PendingSync &&
      other.todoId == todoId &&
      other.isCompleted == isCompleted;

  @override
  int get hashCode => Object.hash(todoId, isCompleted);

  @override
  String toString() => 'PendingSync($todoId, $isCompleted)';
}

/// 큐에 남겨 둘 항목 수 상한.
///
/// 이미 삭제된 할 일처럼 **영원히 실패하는 항목**이 있을 수 있다. 상한이 없으면
/// 앱을 오래 열지 않는 사용자에게 이 문자열이 끝없이 자란다.
const int kPendingSyncQueueCap = 50;

/// 상한을 넘으면 **오래된 것부터** 버린다. 최근 조작이 사용자 의도에 가깝다.
List<PendingSync> capPendingSyncs(
  List<PendingSync> syncs, {
  int cap = kPendingSyncQueueCap,
}) {
  if (syncs.length <= cap) return syncs;
  return syncs.sublist(syncs.length - cap);
}

/// 저장 형식(`"7:true,9:false"`)으로 되돌린다. [parsePendingSyncs] 의 역이다.
String formatPendingSyncs(List<PendingSync> syncs) =>
    syncs.map((s) => '${s.todoId}:${s.isCompleted}').join(',');

/// `"7:true,9:false"` 를 파싱한다.
///
/// 같은 id 가 여러 번 나오면 **마지막 것만** 남긴다. 위젯 쪽에서도 중복을
/// 지우지만, 앱을 오래 안 열어 쌓였거나 두 플랫폼의 옛 데이터가 남아 있을 수
/// 있다. 첫 항목을 살리면 사용자가 마지막으로 누른 것과 반대가 된다.
///
/// 깨진 항목(빈 문자열, 콜론 없음, 숫자가 아닌 id)은 조용히 버린다.
/// 하나가 깨졌다고 나머지 완료 처리까지 잃는 편이 더 나쁘다.
List<PendingSync> parsePendingSyncs(String? raw) {
  if (raw == null || raw.isEmpty) return const [];

  // 삽입 순서를 지키면서 id 별로 덮어쓰기 위해 LinkedHashMap(기본 Map)을 쓴다.
  final byId = <int, PendingSync>{};

  for (final entry in raw.split(',')) {
    final trimmed = entry.trim();
    if (trimmed.isEmpty) continue;

    final parts = trimmed.split(':');
    if (parts.length != 2) continue;

    final id = int.tryParse(parts[0].trim());
    if (id == null) continue;

    // 'true' 만 완료로 본다. 오타나 예상 못한 값은 미완료로 떨어뜨린다.
    byId[id] = PendingSync(id, parts[1].trim() == 'true');
  }

  return byId.values.toList(growable: false);
}
