/// Pagination state management for efficient todo list rendering.
///
/// Implements infinite scroll pagination with configurable page sizes
/// and preload thresholds for smooth user experience.
///
/// Key providers:
/// - [paginationProvider]: Main pagination state notifier
/// - [paginatedTodosProvider]: Currently visible paginated items
/// - [paginationLoadingProvider]: Loading state indicator
/// - [paginationHasMoreProvider]: More items availability check
///
/// Performance benefits:
/// - Reduces initial load time for large lists
/// - Smooth scrolling with preload threshold
/// - Memory efficient rendering
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/domain/entities/todo.dart';
import 'package:todo_app/presentation/providers/todo_providers.dart';
import 'package:todo_app/core/utils/app_logger.dart';

// ============================================================================
// PAGINATION STATE
// ============================================================================

/// Configuration constants for pagination behavior.
///
/// Adjust these values based on device performance and UX requirements.
class PaginationConfig {
  /// Number of items to load per page.
  static const int pageSize = 20;

  /// Number of remaining items before triggering next page load.
  static const int preloadThreshold = 5;
}

/// Immutable state class for pagination tracking.
///
/// Tracks the current pagination position, loading state,
/// and whether more items are available.
class PaginationState {
  /// Current page number (0-indexed).
  final int currentPage;

  /// Number of items per page.
  final int pageSize;

  /// Whether a page load is in progress.
  final bool isLoading;

  /// Whether more pages are available.
  final bool hasMore;

  /// Accumulated loaded items.
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

/// Notifier for managing pagination state and page loading.
///
/// Handles automatic preloading when approaching list end,
/// manual page loading, and state reset for filter changes.
///
/// Usage:
/// ```dart
/// // Load next page manually
/// ref.read(paginationProvider.notifier).loadNextPage();
///
/// // Check and auto-load based on scroll position
/// ref.read(paginationProvider.notifier).checkAndLoadMore(visibleItemCount: 15);
///
/// // Reset on filter change
/// ref.read(paginationProvider.notifier).reset();
/// ```
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

  /// Loads the initial page of data.
  void _loadInitial() {
    loadNextPage(reset: true);
  }

  /// Loads the next page of items.
  ///
  /// [reset] if true, clears existing items and loads from page 0.
  /// Skips if already loading or no more items available.
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

  /// Resets pagination state and reloads from the beginning.
  ///
  /// Call this when filters change or data needs to be refreshed.
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

  /// Checks scroll position and triggers auto-load if near list end.
  ///
  /// [visibleItemCount] the number of items currently visible on screen.
  /// Loads next page when remaining items fall below [PaginationConfig.preloadThreshold].
  void checkAndLoadMore({required int visibleItemCount}) {
    if (!state.isLoading && state.hasMore) {
      final remainingItems = state.items.length - visibleItemCount;
      if (remainingItems <= PaginationConfig.preloadThreshold) {
        logger.d('🔄 PaginationNotifier: Auto-loading next page ($remainingItems items remaining)');
        loadNextPage();
      }
    }
  }

  /// Whether a loading indicator should be shown.
  bool get isLoadingMore => state.isLoading;

  /// Current page number (0-indexed).
  int get currentPageNumber => state.currentPage;

  /// Total number of items loaded across all pages.
  int get totalLoadedItems => state.items.length;
}

// ============================================================================
// PROVIDERS
// ============================================================================

/// Main pagination state provider.
///
/// Manages page loading, state tracking, and automatic preloading.
final paginationProvider = NotifierProvider<PaginationNotifier, PaginationState>(
  PaginationNotifier.new,
);

/// Provides the currently loaded and paginated todo items.
///
/// UI should use this provider for list rendering instead of [todosProvider]
/// when pagination is enabled.
final paginatedTodosProvider = Provider<List<Todo>>((ref) {
  final paginationState = ref.watch(paginationProvider);
  return paginationState.items;
});

/// Provides the current loading state for pagination.
///
/// Use this to show/hide loading indicators at list bottom.
final paginationLoadingProvider = Provider<bool>((ref) {
  return ref.watch(paginationProvider).isLoading;
});

/// Indicates whether more items are available to load.
///
/// Use this to conditionally render "load more" UI elements.
final paginationHasMoreProvider = Provider<bool>((ref) {
  return ref.watch(paginationProvider).hasMore;
});
