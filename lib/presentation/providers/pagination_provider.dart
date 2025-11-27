import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/domain/entities/todo.dart';
import 'package:todo_app/presentation/providers/todo_providers.dart';
import 'package:todo_app/core/utils/app_logger.dart';

// ============================================================================
// PAGINATION STATE
// ============================================================================

/// Pagination configuration
class PaginationConfig {
  static const int pageSize = 20; // 한 페이지에 표시할 아이템 수
  static const int preloadThreshold = 5; // 남은 아이템 수가 이 이하면 다음 페이지 로드
}

/// Pagination 상태 관리
class PaginationState {
  final int currentPage;
  final int pageSize;
  final bool isLoading;
  final bool hasMore;
  final List<Todo> items;

  const PaginationState({
    required this.currentPage,
    required this.pageSize,
    required this.isLoading,
    required this.hasMore,
    required this.items,
  });

  int get totalItems => items.length;

  PaginationState copyWith({
    int? currentPage,
    int? pageSize,
    bool? isLoading,
    bool? hasMore,
    List<Todo>? items,
  }) {
    return PaginationState(
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      items: items ?? this.items,
    );
  }
}

// ============================================================================
// PAGINATION NOTIFIER
// ============================================================================

class PaginationNotifier extends Notifier<PaginationState> {
  @override
  PaginationState build() {
    // 초기 로드
    _loadInitial();
    return const PaginationState(
      currentPage: 0,
      pageSize: PaginationConfig.pageSize,
      isLoading: false,
      hasMore: true,
      items: [],
    );
  }

  /// 초기 페이지 로드
  void _loadInitial() {
    loadNextPage(reset: true);
  }

  /// 다음 페이지 로드
  /// [reset]이 true면 처음부터 시작
  void loadNextPage({bool reset = false}) {
    if (state.isLoading) {
      logger.d('⏳ PaginationNotifier: Already loading, skipping');
      return;
    }

    if (!reset && !state.hasMore) {
      logger.d('⏹️ PaginationNotifier: No more items to load');
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final todosAsync = ref.watch(todosProvider);

      // Handle AsyncValue for todos
      final allTodos = todosAsync.when(
        data: (list) => list,
        loading: () => <Todo>[],
        error: (error, _) {
          logger.e('❌ PaginationNotifier: Error loading todos - $error');
          return <Todo>[];
        },
      );

      final pageNum = reset ? 0 : state.currentPage + 1;
      final startIndex = pageNum * state.pageSize;
      final endIndex = (pageNum + 1) * state.pageSize;

      if (startIndex >= allTodos.length) {
        // No more items
        state = state.copyWith(
          isLoading: false,
          hasMore: false,
        );
        logger.d('✅ PaginationNotifier: Reached end of list');
        return;
      }

      final paginatedItems = allTodos.sublist(
        startIndex,
        endIndex > allTodos.length ? allTodos.length : endIndex,
      );

      final hasMore = endIndex < allTodos.length;

      state = state.copyWith(
        currentPage: pageNum,
        isLoading: false,
        hasMore: hasMore,
        items: reset ? paginatedItems : [...state.items, ...paginatedItems],
      );

      logger.d('📄 PaginationNotifier: Loaded page $pageNum (${paginatedItems.length} items, hasMore: $hasMore)');
    } catch (e) {
      logger.e('❌ PaginationNotifier: Failed to load page - $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// 리스트 리셋 (필터 변경 등으로 인해 필요할 때)
  void reset() {
    state = const PaginationState(
      currentPage: 0,
      pageSize: PaginationConfig.pageSize,
      isLoading: false,
      hasMore: true,
      items: [],
    );
    _loadInitial();
  }

  /// 스크롤 위치 확인하여 자동 로드 (리스트 끝에 가까워지면)
  void checkAndLoadMore({required int visibleItemCount}) {
    if (!state.isLoading && state.hasMore) {
      final remainingItems = state.items.length - visibleItemCount;
      if (remainingItems <= PaginationConfig.preloadThreshold) {
        logger.d('🔄 PaginationNotifier: Auto-loading next page (${remainingItems} items remaining)');
        loadNextPage();
      }
    }
  }

  /// Get loading indicator visibility
  bool get isLoadingMore => state.isLoading;

  /// Get current page number
  int get currentPageNumber => state.currentPage;

  /// Get total loaded items
  int get totalLoadedItems => state.items.length;
}

// ============================================================================
// PROVIDERS
// ============================================================================

/// Pagination 상태 관리 Provider
final paginationProvider = NotifierProvider<PaginationNotifier, PaginationState>(
  PaginationNotifier.new,
);

/// 현재 표시되는 아이템들 Provider
final paginatedTodosProvider = Provider<List<Todo>>((ref) {
  final paginationState = ref.watch(paginationProvider);
  return paginationState.items;
});

/// Pagination 로딩 상태 Provider
final paginationLoadingProvider = Provider<bool>((ref) {
  return ref.watch(paginationProvider).isLoading;
});

/// 더 불러올 아이템이 있는지 확인 Provider
final paginationHasMoreProvider = Provider<bool>((ref) {
  return ref.watch(paginationProvider).hasMore;
});
