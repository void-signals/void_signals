import 'dart:async';

import 'package:flutter/material.dart';
import 'package:void_signals/void_signals.dart' as signals;
import 'package:void_signals/void_signals.dart'
    show Signal, Computed, Effect, batch, untrack;

// =============================================================================
// Pagination and Infinite Scroll Support
//
// Reactive patterns for common list loading scenarios including:
// - Paginated data loading
// - Infinite scroll / load more
// - Pull-to-refresh
// =============================================================================

/// The state of a paginated data source.
enum PaginationState {
  /// Initial state, no data loaded yet.
  initial,

  /// Currently loading the first page.
  loadingFirst,

  /// Currently loading more data (not the first page).
  loadingMore,

  /// Currently refreshing (reloading from the beginning).
  refreshing,

  /// Data loaded successfully, may have more pages.
  loaded,

  /// All data loaded, no more pages available.
  loadedAll,

  /// An error occurred.
  error,
}

/// Configuration for [PaginatedSignal].
class PaginationConfig {
  /// The number of items to load per page.
  final int pageSize;

  /// The number of items from the end to trigger loading more.
  final int loadMoreThreshold;

  /// Whether to automatically load more when threshold is reached.
  final bool autoLoadMore;

  const PaginationConfig({
    this.pageSize = 20,
    this.loadMoreThreshold = 5,
    this.autoLoadMore = true,
  });
}

/// A reactive signal for paginated data.
///
/// Handles loading, refreshing, and loading more data with proper state
/// management and error handling.
///
/// Example:
/// ```dart
/// final itemsSignal = PaginatedSignal<Item>(
///   loader: (page, pageSize) async {
///     final response = await api.getItems(page: page, limit: pageSize);
///     return PaginationResult(
///       items: response.items,
///       hasMore: response.hasMore,
///     );
///   },
/// );
///
/// // Load initial data
/// await itemsSignal.loadFirst();
///
/// // In your widget
/// Watch(builder: (context, _) {
///   final state = itemsSignal.state.value;
///   final items = itemsSignal.items.value;
///
///   if (state == PaginationState.loadingFirst) {
///     return CircularProgressIndicator();
///   }
///
///   return ListView.builder(
///     itemCount: items.length + (itemsSignal.hasMore.value ? 1 : 0),
///     itemBuilder: (context, index) {
///       if (index >= items.length) {
///         // Loading indicator at the end
///         itemsSignal.loadMore();
///         return CircularProgressIndicator();
///       }
///       return ItemTile(item: items[index]);
///     },
///   );
/// });
///
/// // Pull to refresh
/// RefreshIndicator(
///   onRefresh: itemsSignal.refresh,
///   child: listView,
/// );
///
/// // Don't forget to dispose
/// itemsSignal.dispose();
/// ```
class PaginatedSignal<T> {
  final Future<PaginationResult<T>> Function(int page, int pageSize) _loader;
  final PaginationConfig config;

  final Signal<List<T>> _items;
  final Signal<PaginationState> _state;
  final Signal<Object?> _error;
  final Signal<StackTrace?> _stackTrace;
  final Signal<int> _currentPage;
  final Signal<bool> _hasMore;

  bool _isDisposed = false;

  /// Creates a [PaginatedSignal] with the given loader function.
  ///
  /// [loader] is called with the page number (0-indexed) and page size.
  PaginatedSignal({
    required Future<PaginationResult<T>> Function(int page, int pageSize)
        loader,
    this.config = const PaginationConfig(),
    List<T>? initialItems,
  })  : _loader = loader,
        _items = signals.signal(initialItems ?? []),
        _state = signals.signal(initialItems != null && initialItems.isNotEmpty
            ? PaginationState.loaded
            : PaginationState.initial),
        _error = signals.signal(null),
        _stackTrace = signals.signal(null),
        _currentPage = signals.signal(0),
        _hasMore = signals.signal(true);

  /// The list of loaded items.
  Signal<List<T>> get items => _items;

  /// The current pagination state.
  Signal<PaginationState> get state => _state;

  /// The error if any occurred.
  Signal<Object?> get error => _error;

  /// The stack trace of the error if any occurred.
  Signal<StackTrace?> get stackTrace => _stackTrace;

  /// The current page number (0-indexed).
  Signal<int> get currentPage => _currentPage;

  /// Whether there are more items to load.
  Signal<bool> get hasMore => _hasMore;

  /// Whether data is currently being loaded (first page, more, or refresh).
  Computed<bool> get isLoading => signals.computed((_) {
        final s = _state.value;
        return s == PaginationState.loadingFirst ||
            s == PaginationState.loadingMore ||
            s == PaginationState.refreshing;
      });

  /// Whether the list is empty.
  Computed<bool> get isEmpty => signals.computed((_) => _items.value.isEmpty);

  /// Whether the list is not empty.
  Computed<bool> get isNotEmpty =>
      signals.computed((_) => _items.value.isNotEmpty);

  /// The number of loaded items.
  Computed<int> get itemCount => signals.computed((_) => _items.value.length);

  /// Loads the first page of data.
  ///
  /// Clears any existing data and resets to page 0.
  Future<void> loadFirst() async {
    if (_isDisposed) return;

    batch(() {
      _state.value = PaginationState.loadingFirst;
      _error.value = null;
      _stackTrace.value = null;
    });

    try {
      final result = await _loader(0, config.pageSize);
      if (_isDisposed) return;

      batch(() {
        _items.value = result.items;
        _currentPage.value = 0;
        _hasMore.value = result.hasMore;
        _state.value =
            result.hasMore ? PaginationState.loaded : PaginationState.loadedAll;
      });
    } catch (e, s) {
      if (_isDisposed) return;
      batch(() {
        _error.value = e;
        _stackTrace.value = s;
        _state.value = PaginationState.error;
      });
    }
  }

  /// Loads the next page of data.
  ///
  /// Does nothing if already loading, no more data, or not yet loaded.
  Future<void> loadMore() async {
    if (_isDisposed) return;

    // Don't load if already loading, no more data, or in error state
    final currentState = untrack(() => _state.value);
    if (currentState == PaginationState.loadingFirst ||
        currentState == PaginationState.loadingMore ||
        currentState == PaginationState.refreshing ||
        currentState == PaginationState.loadedAll ||
        currentState == PaginationState.initial) {
      return;
    }

    if (!untrack(() => _hasMore.value)) return;

    _state.value = PaginationState.loadingMore;

    try {
      final nextPage = untrack(() => _currentPage.value) + 1;
      final result = await _loader(nextPage, config.pageSize);
      if (_isDisposed) return;

      batch(() {
        _items.value = [...untrack(() => _items.value), ...result.items];
        _currentPage.value = nextPage;
        _hasMore.value = result.hasMore;
        _state.value =
            result.hasMore ? PaginationState.loaded : PaginationState.loadedAll;
      });
    } catch (e, s) {
      if (_isDisposed) return;
      batch(() {
        _error.value = e;
        _stackTrace.value = s;
        _state.value = PaginationState.error;
      });
    }
  }

  /// Refreshes the data by reloading from the first page.
  ///
  /// Keeps existing data visible until the refresh completes.
  Future<void> refresh() async {
    if (_isDisposed) return;

    _state.value = PaginationState.refreshing;
    _error.value = null;
    _stackTrace.value = null;

    try {
      final result = await _loader(0, config.pageSize);
      if (_isDisposed) return;

      batch(() {
        _items.value = result.items;
        _currentPage.value = 0;
        _hasMore.value = result.hasMore;
        _state.value =
            result.hasMore ? PaginationState.loaded : PaginationState.loadedAll;
      });
    } catch (e, s) {
      if (_isDisposed) return;
      batch(() {
        _error.value = e;
        _stackTrace.value = s;
        _state.value = PaginationState.error;
      });
    }
  }

  /// Retries loading after an error.
  ///
  /// If [retryLoadMore] is true and we were loading more, retries loading more.
  /// Otherwise retries loading the first page.
  Future<void> retry({bool retryLoadMore = false}) async {
    if (retryLoadMore && untrack(() => _items.value).isNotEmpty) {
      await loadMore();
    } else {
      await loadFirst();
    }
  }

  /// Resets the signal to initial state.
  void reset() {
    if (_isDisposed) return;
    batch(() {
      _items.value = [];
      _state.value = PaginationState.initial;
      _error.value = null;
      _stackTrace.value = null;
      _currentPage.value = 0;
      _hasMore.value = true;
    });
  }

  /// Updates an item at the specified index.
  void updateAt(int index, T item) {
    if (_isDisposed) return;
    final list = [..._items.value];
    if (index >= 0 && index < list.length) {
      list[index] = item;
      _items.value = list;
    }
  }

  /// Removes an item at the specified index.
  void removeAt(int index) {
    if (_isDisposed) return;
    final list = [..._items.value];
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      _items.value = list;
    }
  }

  /// Adds an item to the beginning of the list.
  void prepend(T item) {
    if (_isDisposed) return;
    _items.value = [item, ..._items.value];
  }

  /// Adds an item to the end of the list.
  void append(T item) {
    if (_isDisposed) return;
    _items.value = [..._items.value, item];
  }

  /// Disposes the signal.
  void dispose() {
    _isDisposed = true;
  }
}

/// The result of a pagination loader.
class PaginationResult<T> {
  /// The items loaded in this page.
  final List<T> items;

  /// Whether there are more items to load.
  final bool hasMore;

  /// The total number of items (if known).
  final int? total;

  const PaginationResult({
    required this.items,
    required this.hasMore,
    this.total,
  });

  /// Creates a [PaginationResult] with an empty list and no more items.
  const PaginationResult.empty()
      : items = const [],
        hasMore = false,
        total = 0;
}

/// A mixin that provides infinite scroll behavior for [ScrollController].
///
/// Use this with [SignalScrollController] or any [ScrollController] to
/// automatically trigger loading more when the user scrolls near the end.
///
/// Example:
/// ```dart
/// class _MyListState extends State<MyList> {
///   late final SignalScrollController scrollController;
///   late final PaginatedSignal<Item> items;
///
///   @override
///   void initState() {
///     super.initState();
///     scrollController = SignalScrollController();
///     items = PaginatedSignal<Item>(
///       loader: (page, pageSize) => api.getItems(page, pageSize),
///     );
///
///     // Setup infinite scroll
///     setupInfiniteScroll(
///       scrollController: scrollController.controller,
///       onLoadMore: items.loadMore,
///       hasMore: () => items.hasMore.value,
///       isLoading: () => items.isLoading.value,
///     );
///
///     items.loadFirst();
///   }
/// }
/// ```
Effect setupInfiniteScroll({
  required ScrollController scrollController,
  required Future<void> Function() onLoadMore,
  required bool Function() hasMore,
  required bool Function() isLoading,
  double threshold = 200.0,
}) {
  void checkAndLoad() {
    if (!scrollController.hasClients) return;
    if (isLoading() || !hasMore()) return;

    final position = scrollController.position;
    final maxScroll = position.maxScrollExtent;
    final currentScroll = position.pixels;

    if (maxScroll - currentScroll <= threshold) {
      onLoadMore();
    }
  }

  scrollController.addListener(checkAndLoad);

  return signals.effect(() {
    // This effect just keeps the infinite scroll logic running
    // The actual check is done in the scroll listener
  });
}

/// A widget that provides infinite scroll behavior.
///
/// Wraps a [ListView] or similar scrollable widget and automatically
/// triggers loading more when the user scrolls near the end.
///
/// Example:
/// ```dart
/// final items = PaginatedSignal<Item>(
///   loader: (page, pageSize) => api.getItems(page, pageSize),
/// );
///
/// InfiniteScrollList<Item>(
///   paginatedSignal: items,
///   itemBuilder: (context, item, index) => ItemTile(item: item),
///   loadingBuilder: (context) => CircularProgressIndicator(),
///   emptyBuilder: (context) => Text('No items'),
///   errorBuilder: (context, error, retry) => ElevatedButton(
///     onPressed: retry,
///     child: Text('Retry'),
///   ),
/// )
/// ```
class InfiniteScrollList<T> extends StatefulWidget {
  /// The paginated signal to use.
  final PaginatedSignal<T> paginatedSignal;

  /// Builder for each item.
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// Builder for the loading indicator.
  final Widget Function(BuildContext context)? loadingBuilder;

  /// Builder for the empty state.
  final Widget Function(BuildContext context)? emptyBuilder;

  /// Builder for the error state.
  final Widget Function(BuildContext context, Object error, VoidCallback retry)?
      errorBuilder;

  /// Builder for the loading more indicator at the bottom.
  final Widget Function(BuildContext context)? loadingMoreBuilder;

  /// The scroll physics.
  final ScrollPhysics? physics;

  /// The padding around the list.
  final EdgeInsetsGeometry? padding;

  /// Whether to shrink wrap the list.
  final bool shrinkWrap;

  /// The threshold in pixels from the bottom to trigger loading more.
  final double loadMoreThreshold;

  /// An optional header widget.
  final Widget? header;

  /// An optional footer widget (shown after all items are loaded).
  final Widget? footer;

  /// Separator between items.
  final Widget Function(BuildContext context, int index)? separatorBuilder;

  const InfiniteScrollList({
    super.key,
    required this.paginatedSignal,
    required this.itemBuilder,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.loadingMoreBuilder,
    this.physics,
    this.padding,
    this.shrinkWrap = false,
    this.loadMoreThreshold = 200.0,
    this.header,
    this.footer,
    this.separatorBuilder,
  });

  @override
  State<InfiniteScrollList<T>> createState() => _InfiniteScrollListState<T>();
}

class _InfiniteScrollListState<T> extends State<InfiniteScrollList<T>> {
  final ScrollController _scrollController = ScrollController();
  Effect? _scrollEffect;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final maxScroll = position.maxScrollExtent;
    final currentScroll = position.pixels;

    if (maxScroll - currentScroll <= widget.loadMoreThreshold) {
      widget.paginatedSignal.loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _scrollEffect?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InfiniteScrollListContent<T>(
      paginatedSignal: widget.paginatedSignal,
      itemBuilder: widget.itemBuilder,
      loadingBuilder: widget.loadingBuilder,
      emptyBuilder: widget.emptyBuilder,
      errorBuilder: widget.errorBuilder,
      loadingMoreBuilder: widget.loadingMoreBuilder,
      physics: widget.physics,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      header: widget.header,
      footer: widget.footer,
      separatorBuilder: widget.separatorBuilder,
      scrollController: _scrollController,
    );
  }
}

class _InfiniteScrollListContent<T> extends StatefulWidget {
  final PaginatedSignal<T> paginatedSignal;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;
  final Widget Function(BuildContext context, Object error, VoidCallback retry)?
      errorBuilder;
  final Widget Function(BuildContext context)? loadingMoreBuilder;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final Widget? header;
  final Widget? footer;
  final Widget Function(BuildContext context, int index)? separatorBuilder;
  final ScrollController scrollController;

  const _InfiniteScrollListContent({
    required this.paginatedSignal,
    required this.itemBuilder,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.loadingMoreBuilder,
    this.physics,
    this.padding,
    required this.shrinkWrap,
    this.header,
    this.footer,
    this.separatorBuilder,
    required this.scrollController,
  });

  @override
  State<_InfiniteScrollListContent<T>> createState() =>
      _InfiniteScrollListContentState<T>();
}

class _InfiniteScrollListContentState<T>
    extends State<_InfiniteScrollListContent<T>> {
  Effect? _effect;
  late List<T> _items;
  late PaginationState _state;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _items = widget.paginatedSignal.items.value;
    _state = widget.paginatedSignal.state.value;
    _error = widget.paginatedSignal.error.value;
    _setupEffect();
  }

  void _setupEffect() {
    _effect = signals.effect(() {
      final items = widget.paginatedSignal.items.value;
      final state = widget.paginatedSignal.state.value;
      final error = widget.paginatedSignal.error.value;

      if (_items != items || _state != state || _error != error) {
        _items = items;
        _state = state;
        _error = error;
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _effect?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Handle loading first
    if (_state == PaginationState.loadingFirst) {
      return widget.loadingBuilder?.call(context) ??
          const Center(child: CircularProgressIndicator());
    }

    // Handle error with no data
    if (_state == PaginationState.error && _items.isEmpty) {
      return widget.errorBuilder?.call(
            context,
            _error ?? 'Unknown error',
            () => widget.paginatedSignal.retry(),
          ) ??
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Error: $_error'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => widget.paginatedSignal.retry(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
    }

    // Handle empty state
    if (_items.isEmpty && _state != PaginationState.initial) {
      return widget.emptyBuilder?.call(context) ??
          const Center(child: Text('No items'));
    }

    // Build the list
    final hasLoadingMore = _state == PaginationState.loadingMore;
    final hasMore = widget.paginatedSignal.hasMore.value;
    final hasHeader = widget.header != null;
    final hasFooter = widget.footer != null &&
        (_state == PaginationState.loadedAll || !hasMore);

    int itemCount = _items.length;
    if (hasHeader) itemCount++;
    if (hasLoadingMore || hasFooter) itemCount++;

    if (widget.separatorBuilder != null) {
      return ListView.separated(
        controller: widget.scrollController,
        physics: widget.physics,
        padding: widget.padding,
        shrinkWrap: widget.shrinkWrap,
        itemCount: itemCount,
        separatorBuilder: widget.separatorBuilder!,
        itemBuilder: (context, index) =>
            _buildItem(context, index, hasHeader, hasLoadingMore, hasFooter),
      );
    }

    return ListView.builder(
      controller: widget.scrollController,
      physics: widget.physics,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      itemCount: itemCount,
      itemBuilder: (context, index) =>
          _buildItem(context, index, hasHeader, hasLoadingMore, hasFooter),
    );
  }

  Widget _buildItem(BuildContext context, int index, bool hasHeader,
      bool hasLoadingMore, bool hasFooter) {
    // Header
    if (hasHeader && index == 0) {
      return widget.header!;
    }

    final itemIndex = hasHeader ? index - 1 : index;

    // Loading more or footer
    if (itemIndex >= _items.length) {
      if (hasLoadingMore) {
        return widget.loadingMoreBuilder?.call(context) ??
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
      }
      if (hasFooter) {
        return widget.footer!;
      }
      return const SizedBox.shrink();
    }

    return widget.itemBuilder(context, _items[itemIndex], itemIndex);
  }
}
