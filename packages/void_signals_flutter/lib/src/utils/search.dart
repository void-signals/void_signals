import 'dart:async';

import 'package:void_signals/void_signals.dart' as signals;
import 'package:void_signals/void_signals.dart'
    show Signal, Computed, Effect, batch, untrack;

// =============================================================================
// Search Signal
//
// A comprehensive search solution that combines debouncing, async loading,
// and result caching for an optimal search experience.
// =============================================================================

/// The state of a search operation.
enum SearchState {
  /// No search performed yet.
  idle,

  /// Search query is being debounced (user is typing).
  debouncing,

  /// Search is in progress.
  searching,

  /// Search completed with results.
  results,

  /// Search completed with no results.
  empty,

  /// Search failed with an error.
  error,
}

/// Configuration for [SearchSignal].
class SearchConfig {
  /// The debounce duration before triggering a search.
  final Duration debounceDuration;

  /// The minimum query length to trigger a search.
  final int minQueryLength;

  /// Whether to cache results.
  final bool enableCache;

  /// The maximum number of cached results.
  final int maxCacheSize;

  /// Whether to trim whitespace from the query.
  final bool trimQuery;

  const SearchConfig({
    this.debounceDuration = const Duration(milliseconds: 300),
    this.minQueryLength = 1,
    this.enableCache = true,
    this.maxCacheSize = 50,
    this.trimQuery = true,
  });
}

/// A comprehensive reactive search signal.
///
/// Combines debouncing, async loading, caching, and state management
/// for an optimal search experience.
///
/// Example:
/// ```dart
/// final search = SearchSignal<User>(
///   searcher: (query) async {
///     return await api.searchUsers(query);
///   },
/// );
///
/// // Connect to a TextField
/// TextField(
///   onChanged: (value) => search.query.value = value,
///   decoration: InputDecoration(
///     suffixIcon: Watch(builder: (context, _) {
///       if (search.state.value == SearchState.searching) {
///         return CircularProgressIndicator();
///       }
///       return Icon(Icons.search);
///     }),
///   ),
/// );
///
/// // Display results
/// Watch(builder: (context, _) {
///   final state = search.state.value;
///   final results = search.results.value;
///
///   switch (state) {
///     case SearchState.idle:
///       return Text('Enter a search query');
///     case SearchState.debouncing:
///     case SearchState.searching:
///       return CircularProgressIndicator();
///     case SearchState.empty:
///       return Text('No results found');
///     case SearchState.error:
///       return Text('Error: ${search.error.value}');
///     case SearchState.results:
///       return ListView.builder(
///         itemCount: results.length,
///         itemBuilder: (context, index) => UserTile(user: results[index]),
///       );
///   }
/// });
///
/// // Don't forget to dispose
/// search.dispose();
/// ```
class SearchSignal<T> {
  final Future<List<T>> Function(String query) _searcher;
  final SearchConfig config;

  final Signal<String> _query;
  final Signal<List<T>> _results;
  final Signal<SearchState> _state;
  final Signal<Object?> _error;
  final Map<String, List<T>> _cache = {};
  final List<String> _cacheOrder = [];

  Timer? _debounceTimer;
  String? _lastSearchedQuery;
  Effect? _queryEffect;
  bool _isDisposed = false;

  /// Creates a [SearchSignal] with the given searcher function.
  SearchSignal({
    required Future<List<T>> Function(String query) searcher,
    this.config = const SearchConfig(),
    String initialQuery = '',
  })  : _searcher = searcher,
        _query = signals.signal(initialQuery),
        _results = signals.signal([]),
        _state = signals.signal(SearchState.idle),
        _error = signals.signal(null) {
    _setupQueryWatcher();
  }

  void _setupQueryWatcher() {
    _queryEffect = signals.effect(() {
      final query = _query.value;
      _onQueryChanged(query);
    });
  }

  void _onQueryChanged(String rawQuery) {
    if (_isDisposed) return;

    final query = config.trimQuery ? rawQuery.trim() : rawQuery;

    // Cancel any pending debounce
    _debounceTimer?.cancel();

    // Check minimum length
    if (query.length < config.minQueryLength) {
      if (query.isEmpty) {
        batch(() {
          _results.value = [];
          _state.value = SearchState.idle;
          _error.value = null;
        });
      }
      return;
    }

    // Check cache
    if (config.enableCache && _cache.containsKey(query)) {
      batch(() {
        _results.value = _cache[query]!;
        _state.value =
            _cache[query]!.isEmpty ? SearchState.empty : SearchState.results;
      });
      return;
    }

    // Set debouncing state
    _state.value = SearchState.debouncing;

    // Debounce the search
    _debounceTimer = Timer(config.debounceDuration, () {
      _performSearch(query);
    });
  }

  String _normalizeQuery(String rawQuery) {
    return config.trimQuery ? rawQuery.trim() : rawQuery;
  }

  Future<void> _performSearch(String query) async {
    if (_isDisposed) return;
    // Compare normalized queries to handle trim correctly
    if (query != _normalizeQuery(untrack(() => _query.value))) return;

    _state.value = SearchState.searching;
    _lastSearchedQuery = query;

    try {
      final results = await _searcher(query);
      if (_isDisposed) return;
      // Compare normalized queries to handle trim correctly
      if (query != _normalizeQuery(untrack(() => _query.value))) return;

      // Cache results
      if (config.enableCache) {
        _addToCache(query, results);
      }

      batch(() {
        _results.value = results;
        _state.value =
            results.isEmpty ? SearchState.empty : SearchState.results;
        _error.value = null;
      });
    } catch (e) {
      if (_isDisposed) return;
      // Compare normalized queries to handle trim correctly
      if (query != _normalizeQuery(untrack(() => _query.value))) return;

      batch(() {
        _error.value = e;
        _state.value = SearchState.error;
      });
    }
  }

  void _addToCache(String query, List<T> results) {
    // Remove oldest if at capacity
    if (_cacheOrder.length >= config.maxCacheSize) {
      final oldest = _cacheOrder.removeAt(0);
      _cache.remove(oldest);
    }

    _cache[query] = results;
    _cacheOrder.add(query);
  }

  /// The search query signal.
  Signal<String> get query => _query;

  /// The search results.
  Signal<List<T>> get results => _results;

  /// The current search state.
  Signal<SearchState> get state => _state;

  /// The error if any occurred.
  Signal<Object?> get error => _error;

  /// Whether a search is in progress.
  Computed<bool> get isSearching =>
      signals.computed((_) => _state.value == SearchState.searching);

  /// Whether results are available.
  Computed<bool> get hasResults =>
      signals.computed((_) => _state.value == SearchState.results);

  /// Whether the search is empty (query entered but no results).
  Computed<bool> get isEmpty =>
      signals.computed((_) => _state.value == SearchState.empty);

  /// The number of results.
  Computed<int> get resultCount =>
      signals.computed((_) => _results.value.length);

  /// Clears the search query and results.
  void clear() {
    if (_isDisposed) return;
    _debounceTimer?.cancel();
    batch(() {
      _query.value = '';
      _results.value = [];
      _state.value = SearchState.idle;
      _error.value = null;
    });
  }

  /// Clears the cache.
  void clearCache() {
    _cache.clear();
    _cacheOrder.clear();
  }

  /// Forces a search with the current query.
  Future<void> search() async {
    if (_isDisposed) return;
    _debounceTimer?.cancel();
    final query = config.trimQuery ? _query.value.trim() : _query.value;
    if (query.length >= config.minQueryLength) {
      await _performSearch(query);
    }
  }

  /// Retries the last failed search.
  Future<void> retry() async {
    if (_lastSearchedQuery != null) {
      await _performSearch(_lastSearchedQuery!);
    }
  }

  /// Disposes the search signal.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _debounceTimer?.cancel();
    _queryEffect?.stop();
    _cache.clear();
    _cacheOrder.clear();
  }
}

/// A search signal with suggestion support.
///
/// Extends [SearchSignal] with support for search suggestions and
/// recent search history.
///
/// Example:
/// ```dart
/// final search = SearchWithSuggestionsSignal<User>(
///   searcher: (query) => api.searchUsers(query),
///   suggester: (query) => api.getSuggestions(query),
/// );
///
/// // Show suggestions while typing
/// Watch(builder: (context, _) {
///   if (search.showSuggestions.value) {
///     return ListView(
///       children: [
///         ...search.suggestions.value.map((s) => ListTile(
///           title: Text(s),
///           onTap: () => search.selectSuggestion(s),
///         )),
///       ],
///     );
///   }
///   return SearchResults(results: search.results.value);
/// });
/// ```
class SearchWithSuggestionsSignal<T> extends SearchSignal<T> {
  final Future<List<String>> Function(String query)? _suggester;
  final Signal<List<String>> _suggestions;
  final Signal<List<String>> _recentSearches;
  final Signal<bool> _showSuggestions;
  final int _maxRecentSearches;

  /// Creates a [SearchWithSuggestionsSignal].
  SearchWithSuggestionsSignal({
    required super.searcher,
    Future<List<String>> Function(String query)? suggester,
    super.config,
    super.initialQuery,
    int maxRecentSearches = 10,
  })  : _suggester = suggester,
        _suggestions = signals.signal([]),
        _recentSearches = signals.signal([]),
        _showSuggestions = signals.signal(false),
        _maxRecentSearches = maxRecentSearches;

  /// The search suggestions.
  Signal<List<String>> get suggestions => _suggestions;

  /// Recent search queries.
  Signal<List<String>> get recentSearches => _recentSearches;

  /// Whether to show suggestions instead of results.
  Signal<bool> get showSuggestions => _showSuggestions;

  /// Fetches suggestions for the current query.
  Future<void> fetchSuggestions() async {
    if (_suggester == null) return;

    final query = this.query.value.trim();
    if (query.isEmpty) {
      _suggestions.value = [];
      return;
    }

    try {
      final suggestions = await _suggester(query);
      _suggestions.value = suggestions;
    } catch (_) {
      // Silently fail for suggestions
    }
  }

  /// Selects a suggestion and performs a search.
  void selectSuggestion(String suggestion) {
    query.value = suggestion;
    _showSuggestions.value = false;
    _addToRecentSearches(suggestion);
    search();
  }

  /// Called when a search is submitted.
  void submit() {
    final query = this.query.value.trim();
    if (query.isNotEmpty) {
      _addToRecentSearches(query);
      _showSuggestions.value = false;
      search();
    }
  }

  void _addToRecentSearches(String query) {
    final recent = List<String>.from(_recentSearches.value);
    recent.remove(query); // Remove if exists
    recent.insert(0, query);
    if (recent.length > _maxRecentSearches) {
      recent.removeLast();
    }
    _recentSearches.value = recent;
  }

  /// Clears recent searches.
  void clearRecentSearches() {
    _recentSearches.value = [];
  }

  /// Removes a specific recent search.
  void removeRecentSearch(String query) {
    _recentSearches.value =
        _recentSearches.value.where((q) => q != query).toList();
  }

  /// Shows suggestions mode.
  void showSuggestionsMode() {
    _showSuggestions.value = true;
  }

  /// Hides suggestions mode.
  void hideSuggestionsMode() {
    _showSuggestions.value = false;
  }
}

/// A filter signal that works alongside search.
///
/// Provides reactive filtering capabilities for search results.
///
/// Example:
/// ```dart
/// final search = SearchSignal<Product>(
///   searcher: (query) => api.searchProducts(query),
/// );
///
/// final filters = FilterSignal<Product>(
///   source: search.results,
///   filters: {
///     'inStock': (product) => product.inStock,
///     'onSale': (product) => product.onSale,
///   },
/// );
///
/// // Toggle filters
/// filters.toggle('inStock');
///
/// // Watch filtered results
/// Watch(builder: (context, _) {
///   return ListView(
///     children: filters.filtered.value.map((p) => ProductTile(product: p)).toList(),
///   );
/// });
/// ```
class FilterSignal<T> {
  final Signal<List<T>> _source;
  final Map<String, bool Function(T)> _filterFunctions;
  final Signal<Set<String>> _activeFilters;
  late final Computed<List<T>> _filtered;

  /// Creates a [FilterSignal].
  FilterSignal({
    required Signal<List<T>> source,
    required Map<String, bool Function(T)> filters,
    Set<String>? initialActiveFilters,
  })  : _source = source,
        _filterFunctions = filters,
        _activeFilters = signals.signal(initialActiveFilters ?? {}) {
    _filtered = signals.computed((_) {
      var items = _source.value;
      final active = _activeFilters.value;

      for (final filterName in active) {
        final filter = _filterFunctions[filterName];
        if (filter != null) {
          items = items.where(filter).toList();
        }
      }

      return items;
    });
  }

  /// The filtered results.
  Computed<List<T>> get filtered => _filtered;

  /// The currently active filter names.
  Signal<Set<String>> get activeFilters => _activeFilters;

  /// All available filter names.
  Set<String> get availableFilters => _filterFunctions.keys.toSet();

  /// Whether a filter is active.
  bool isActive(String filterName) => _activeFilters.value.contains(filterName);

  /// Activates a filter.
  void activate(String filterName) {
    if (_filterFunctions.containsKey(filterName)) {
      _activeFilters.value = {..._activeFilters.value, filterName};
    }
  }

  /// Deactivates a filter.
  void deactivate(String filterName) {
    final filters = Set<String>.from(_activeFilters.value);
    filters.remove(filterName);
    _activeFilters.value = filters;
  }

  /// Toggles a filter.
  void toggle(String filterName) {
    if (isActive(filterName)) {
      deactivate(filterName);
    } else {
      activate(filterName);
    }
  }

  /// Clears all active filters.
  void clearAll() {
    _activeFilters.value = {};
  }

  /// Sets the active filters.
  void setFilters(Set<String> filterNames) {
    _activeFilters.value = filterNames.intersection(availableFilters);
  }

  /// The number of active filters.
  int get activeCount => _activeFilters.value.length;

  /// Whether any filters are active.
  bool get hasActiveFilters => _activeFilters.value.isNotEmpty;
}

/// A sort signal that works alongside search.
///
/// Example:
/// ```dart
/// final search = SearchSignal<Product>(...);
///
/// final sorter = SortSignal<Product>(
///   source: search.results,
///   comparators: {
///     'name': (a, b) => a.name.compareTo(b.name),
///     'price': (a, b) => a.price.compareTo(b.price),
///     'rating': (a, b) => b.rating.compareTo(a.rating),
///   },
/// );
///
/// // Sort by price
/// sorter.sortBy('price');
///
/// // Toggle sort direction
/// sorter.toggleDirection();
/// ```
class SortSignal<T> {
  final Signal<List<T>> _source;
  final Map<String, int Function(T, T)> _comparators;
  final Signal<String?> _currentSort;
  final Signal<SortDirection> _direction;
  late final Computed<List<T>> _sorted;

  /// Creates a [SortSignal].
  SortSignal({
    required Signal<List<T>> source,
    required Map<String, int Function(T, T)> comparators,
    String? initialSort,
    SortDirection initialDirection = SortDirection.ascending,
  })  : _source = source,
        _comparators = comparators,
        _currentSort = signals.signal(initialSort),
        _direction = signals.signal(initialDirection) {
    _sorted = signals.computed((_) {
      final items = List<T>.from(_source.value);
      final sortKey = _currentSort.value;
      final direction = _direction.value;

      if (sortKey == null) return items;

      final comparator = _comparators[sortKey];
      if (comparator == null) return items;

      items.sort((a, b) {
        final result = comparator(a, b);
        return direction == SortDirection.ascending ? result : -result;
      });

      return items;
    });
  }

  /// The sorted results.
  Computed<List<T>> get sorted => _sorted;

  /// The current sort key.
  Signal<String?> get currentSort => _currentSort;

  /// The current sort direction.
  Signal<SortDirection> get direction => _direction;

  /// All available sort keys.
  Set<String> get availableSorts => _comparators.keys.toSet();

  /// Sorts by the given key.
  void sortBy(String key, {SortDirection? direction}) {
    if (_comparators.containsKey(key)) {
      batch(() {
        _currentSort.value = key;
        if (direction != null) {
          _direction.value = direction;
        }
      });
    }
  }

  /// Toggles the sort direction.
  void toggleDirection() {
    _direction.value = _direction.value == SortDirection.ascending
        ? SortDirection.descending
        : SortDirection.ascending;
  }

  /// Clears the current sort.
  void clearSort() {
    _currentSort.value = null;
  }
}

/// Sort direction.
enum SortDirection {
  ascending,
  descending,
}
