import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:todo_app/core/utils/app_logger.dart';
import 'package:todo_app/core/widget/widget_pending_sync.dart';
import 'package:todo_app/presentation/providers/todo_providers.dart';
import 'package:todo_app/presentation/providers/widget_provider.dart';

const _appGroupId = 'group.kr.bluesky.dodo';

/// 홈 위젯에서 누른 완료를 앱이 대신 반영한다.
///
/// 위젯(iOS `CompleteTodoIntent`, Android `WidgetActionReceiver`)은 서버를
/// 건드리지 않고 `pending_syncs` 에 목표 상태만 쌓아 둔다. 여기서 그것을 비운다.
///
/// **반영 대상은 Supabase 다.** `todoRepositoryProvider` 는 `SupabaseTodoRepository`
/// 를 돌려준다 — Drift 용 `TodoRepositoryImpl` 은 todo 경로에 연결되어 있지 않다.
/// 즉 네트워크가 없으면 반영할 수 없다. 그래서 **실패한 항목은 큐에 남긴다.**
class WidgetSyncService {
  final Ref _ref;

  /// 중복 실행 방지.
  ///
  /// `todo_list_screen` 이 initState 지연 콜백과 `AppLifecycleState.resumed`
  /// 두 곳에서 부르는데 서로를 기다리지 않는다. 둘이 겹치면 같은 항목을
  /// 두 번 반영하게 된다.
  Future<void>? _inFlight;

  WidgetSyncService(this._ref);

  /// Process any pending syncs from widget actions
  /// Called when app resumes from background
  Future<void> processPendingSyncs() {
    final running = _inFlight;
    if (running != null) {
      logger.d('📱 WidgetSyncService: Already processing, joining in-flight run');
      return running;
    }
    final run = _processPendingSyncs().whenComplete(() => _inFlight = null);
    _inFlight = run;
    return run;
  }

  Future<void> _processPendingSyncs() async {
    if (kIsWeb) return; // 위젯은 Android·iOS 만

    String? pendingSyncsRaw;
    try {
      // 플러그인의 groupId 는 **프로세스 단위 static** 이라, 앱을 새로 띄운 뒤
      // 아직 아무도 설정하지 않았으면 읽기가 -7 로 실패한다.
      // widget_service 가 먼저 부르리라 기대하면 안 된다 — 그쪽은 Supabase
      // 왕복을 먼저 하므로 이 코드가 앞설 수 있다.
      await HomeWidget.setAppGroupId(_appGroupId);
      pendingSyncsRaw = await HomeWidget.getWidgetData<String>('pending_syncs');
    } catch (e) {
      // 읽지 못했을 뿐이다. **큐를 지우면 안 된다** — 여기서 지우면 위젯에서
      // 누른 완료가 영영 사라진다. 다음 진입에서 다시 시도한다.
      logger.w('📱 WidgetSyncService: Error reading pending_syncs, will retry: $e');
      return;
    }

    try {
      logger.d('📱 WidgetSyncService: Checking pending syncs, raw: $pendingSyncsRaw');

      if (pendingSyncsRaw == null || pendingSyncsRaw.isEmpty) {
        logger.d('📱 WidgetSyncService: No pending syncs');
        return;
      }

      final pendingSyncs = parsePendingSyncs(pendingSyncsRaw);

      if (pendingSyncs.isEmpty) {
        // 파싱 결과가 비었다는 것은 내용이 전부 쓰레기라는 뜻이다.
        // 이건 지워도 안전하다 — 살릴 정보가 없다.
        logger.w('📱 WidgetSyncService: No valid pending syncs, clearing garbage');
        await _writeQueue(const []);
        return;
      }

      logger.d('📱 WidgetSyncService: Processing ${pendingSyncs.length} pending syncs');

      final todoActions = _ref.read(todoActionsProvider);

      /// 반영하지 못한 것들. 성공한 것만 큐에서 빠진다.
      final unresolved = <PendingSync>[];

      for (final sync in pendingSyncs) {
        try {
          logger.d(
              '📱 WidgetSyncService: Syncing todo ${sync.todoId} (completed=${sync.isCompleted})');

          // **반드시 set 이어야 한다.** toggleCompletion 은 현재 값을 읽어
          // 뒤집으므로, 위젯에서 누른 뒤 앱이 반영하기까지 사이에 값이 바뀌면
          // 사용자가 완료한 것을 도로 미완료로 되돌린다.
          //
          // set 은 몇 번을 불러도 같은 결과라 재시도에도 안전하다.
          await todoActions.setCompletion(sync.todoId, sync.isCompleted);

          logger.d('✅ WidgetSyncService: Synced todo ${sync.todoId}');
        } catch (e) {
          // 네트워크 오류인지 삭제된 할 일인지 구분할 수 없다.
          // SupabaseTodoRepository 가 모든 예외를 DatabaseFailure 로 뭉갠다.
          // 구분이 안 되면 **남기는 쪽**이 옳다 — 버리면 완료가 사라진다.
          logger.e('❌ WidgetSyncService: Failed to sync $sync, keeping in queue', error: e);
          unresolved.add(sync);
        }
      }

      await _writeQueue(unresolved);

      // Refresh todos to update UI
      _ref.invalidate(todosProvider);
      logger.d('✅ WidgetSyncService: Refreshed todos');
    } catch (e, st) {
      logger.e('❌ WidgetSyncService: Error processing pending syncs', error: e, stackTrace: st);
    }
  }

  /// 큐를 [remaining] 으로 다시 쓴다.
  ///
  /// 이미 삭제된 할 일처럼 영원히 실패하는 항목이 있을 수 있으므로 상한을 둔다.
  /// 상한이 없으면 앱을 오래 안 여는 사용자에게 문자열이 무한히 자란다.
  Future<void> _writeQueue(List<PendingSync> remaining) async {
    final kept = capPendingSyncs(remaining);
    if (kept.length < remaining.length) {
      logger.w('📱 WidgetSyncService: Dropped ${remaining.length - kept.length} '
          'oldest pending syncs (queue cap $kPendingSyncQueueCap)');
    }
    await HomeWidget.saveWidgetData('pending_syncs', formatPendingSyncs(kept));
    logger.d('✅ WidgetSyncService: Queue now holds ${kept.length} item(s)');
  }

  /// Check if widget needs full refresh and update it
  /// Called when app resumes to load next items after widget completion
  Future<void> checkAndRefreshWidget() async {
    if (kIsWeb) return;

    try {
      await HomeWidget.setAppGroupId(_appGroupId);
      final needsRefresh =
          await HomeWidget.getWidgetData<bool>('pending_widget_refresh') ?? false;

      if (!needsRefresh) return;

      logger.d('📱 WidgetSyncService: Widget needs refresh, updating...');

      // Trigger full widget update with fresh data from database
      final widgetService = _ref.read(widgetServiceProvider);
      await widgetService.updateWidget();

      // 플래그는 **갱신에 성공한 뒤** 내린다. 먼저 내리면 updateWidget 이
      // 실패했을 때 슬롯이 영영 다시 채워지지 않아 위젯이 빈 채로 남는다.
      await HomeWidget.saveWidgetData<bool>('pending_widget_refresh', false);

      logger.d('✅ WidgetSyncService: Widget refreshed with next items');
    } catch (e) {
      logger.e('❌ WidgetSyncService: Error checking widget refresh', error: e);
    }
  }
}

/// Provider for WidgetSyncService
final widgetSyncServiceProvider = Provider<WidgetSyncService>((ref) {
  return WidgetSyncService(ref);
});
