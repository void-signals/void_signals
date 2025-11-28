import 'package:pub_api_client/pub_api_client.dart';
import 'package:void_signals_flutter/void_signals_flutter.dart';

import '../data/pub_repository.dart';

/// Search state management using void_signals
class SearchState {
  SearchState._();

  static final SearchState instance = SearchState._();

  /// Current search query
  final query = signal('');

  /// Current search results
  final results = signal<AsyncValue<SearchResults>>(const AsyncLoading());

  /// Current sort order
  final sortOrder = signal(SearchOrder.top);

  /// Whether we're loading more results
  final isLoadingMore = signal(false);

  /// All loaded packages (accumulated from pagination)
  final packages = signal<List<PackageResult>>([]);

  /// Next page URL for pagination
  final _nextPageUrl = signal<String?>(null);

  /// Whether there are more pages to load
  bool get hasMore => _nextPageUrl.value != null;

  /// Perform a search
  Future<void> search(String searchQuery) async {
    query.value = searchQuery;
    packages.value = [];
    _nextPageUrl.value = null;

    if (searchQuery.isEmpty) {
      results.value = const AsyncData(SearchResults(packages: []));
      return;
    }

    results.value = const AsyncLoading();

    try {
      final searchResults = await pubRepository.search(
        searchQuery,
        sort: sortOrder.value,
      );
      packages.value = searchResults.packages;
      _nextPageUrl.value = searchResults.next;
      results.value = AsyncData(searchResults);
    } catch (e, st) {
      results.value = AsyncError(e, st);
    }
  }

  /// Load more results
  Future<void> loadMore() async {
    final nextUrl = _nextPageUrl.value;
    if (nextUrl == null || isLoadingMore.value) return;

    isLoadingMore.value = true;

    try {
      final moreResults = await pubRepository.nextPage(nextUrl);
      packages.value = [...packages.value, ...moreResults.packages];
      _nextPageUrl.value = moreResults.next;
    } catch (e) {
      // Silently fail for pagination errors
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Change sort order and re-search
  Future<void> changeSortOrder(SearchOrder order) async {
    if (sortOrder.value == order) return;
    sortOrder.value = order;
    if (query.value.isNotEmpty) {
      await search(query.value);
    }
  }

  /// Clear search
  void clear() {
    query.value = '';
    results.value = const AsyncData(SearchResults(packages: []));
    packages.value = [];
    _nextPageUrl.value = null;
  }
}

/// Global search state
final searchState = SearchState.instance;
