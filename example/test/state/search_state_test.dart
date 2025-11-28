import 'package:flutter_test/flutter_test.dart';
import 'package:pub_api_client/pub_api_client.dart';
import 'package:void_signals_flutter/void_signals_flutter.dart';

// Testable version of SearchState
class TestableSearchState {
  TestableSearchState({required this.mockSearch, required this.mockNextPage});

  final Future<SearchResults> Function(String query, SearchOrder sort)
  mockSearch;
  final Future<SearchResults> Function(String url) mockNextPage;

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
  final nextPageUrl = signal<String?>(null);

  /// Whether there are more pages to load
  bool get hasMore => nextPageUrl.value != null;

  /// Perform a search
  Future<void> search(String searchQuery) async {
    query.value = searchQuery;
    packages.value = [];
    nextPageUrl.value = null;

    if (searchQuery.isEmpty) {
      results.value = const AsyncData(SearchResults(packages: []));
      return;
    }

    results.value = const AsyncLoading();

    try {
      final searchResults = await mockSearch(searchQuery, sortOrder.value);
      packages.value = searchResults.packages;
      nextPageUrl.value = searchResults.next;
      results.value = AsyncData(searchResults);
    } catch (e, st) {
      results.value = AsyncError(e, st);
    }
  }

  /// Load more results
  Future<void> loadMore() async {
    final nextUrl = nextPageUrl.value;
    if (nextUrl == null || isLoadingMore.value) return;

    isLoadingMore.value = true;

    try {
      final moreResults = await mockNextPage(nextUrl);
      packages.value = [...packages.value, ...moreResults.packages];
      nextPageUrl.value = moreResults.next;
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
    nextPageUrl.value = null;
  }
}

void main() {
  group('SearchState', () {
    late TestableSearchState searchState;
    late List<PackageResult> mockPackages;

    setUp(() {
      mockPackages = [
        PackageResult(package: 'flutter_bloc'),
        PackageResult(package: 'provider'),
        PackageResult(package: 'riverpod'),
      ];

      searchState = TestableSearchState(
        mockSearch: (query, sort) async {
          return SearchResults(
            packages: mockPackages,
            next: 'https://pub.dev/next?page=2',
          );
        },
        mockNextPage: (url) async {
          return SearchResults(
            packages: [PackageResult(package: 'dio')],
            next: null,
          );
        },
      );
    });

    group('Initial State', () {
      test('query should be empty', () {
        expect(searchState.query.value, '');
      });

      test('results should be loading', () {
        expect(searchState.results.value, isA<AsyncLoading>());
      });

      test('sortOrder should be top', () {
        expect(searchState.sortOrder.value, SearchOrder.top);
      });

      test('isLoadingMore should be false', () {
        expect(searchState.isLoadingMore.value, false);
      });

      test('packages should be empty', () {
        expect(searchState.packages.value, isEmpty);
      });

      test('hasMore should be false', () {
        expect(searchState.hasMore, false);
      });
    });

    group('search()', () {
      test('should update query value', () async {
        await searchState.search('flutter');
        expect(searchState.query.value, 'flutter');
      });

      test('should set loading state during search', () async {
        final loadingStates = <bool>[];
        effect(() {
          loadingStates.add(searchState.results.value is AsyncLoading);
        });

        await searchState.search('test');

        expect(loadingStates, contains(true));
      });

      test('should populate packages on success', () async {
        await searchState.search('flutter');

        expect(searchState.packages.value.length, 3);
        expect(searchState.packages.value[0].package, 'flutter_bloc');
      });

      test('should set AsyncData on success', () async {
        await searchState.search('flutter');

        expect(searchState.results.value, isA<AsyncData<SearchResults>>());
      });

      test('should set hasMore when next page available', () async {
        await searchState.search('flutter');

        expect(searchState.hasMore, true);
      });

      test('should handle empty query', () async {
        await searchState.search('');

        expect(searchState.query.value, '');
        expect(searchState.results.value, isA<AsyncData<SearchResults>>());
        final data = searchState.results.value as AsyncData<SearchResults>;
        expect(data.value.packages, isEmpty);
      });

      test('should handle search error', () async {
        searchState = TestableSearchState(
          mockSearch: (query, sort) async {
            throw Exception('Network error');
          },
          mockNextPage: (url) async => const SearchResults(packages: []),
        );

        await searchState.search('flutter');

        expect(searchState.results.value, isA<AsyncError>());
      });

      test('should clear previous results on new search', () async {
        await searchState.search('flutter');
        expect(searchState.packages.value.length, 3);

        // Start new search - packages should be cleared first
        searchState = TestableSearchState(
          mockSearch: (query, sort) async {
            return SearchResults(
              packages: [PackageResult(package: 'new_package')],
            );
          },
          mockNextPage: (url) async => const SearchResults(packages: []),
        );

        await searchState.search('new');
        expect(searchState.packages.value.length, 1);
        expect(searchState.packages.value[0].package, 'new_package');
      });
    });

    group('loadMore()', () {
      test('should not load if no next page', () async {
        searchState = TestableSearchState(
          mockSearch: (query, sort) async {
            return const SearchResults(packages: [], next: null);
          },
          mockNextPage: (url) async => const SearchResults(packages: []),
        );

        await searchState.search('test');
        await searchState.loadMore();

        expect(searchState.isLoadingMore.value, false);
      });

      test('should set isLoadingMore during load', () async {
        await searchState.search('flutter');

        final loadingStates = <bool>[];
        effect(() {
          loadingStates.add(searchState.isLoadingMore.value);
        });

        await searchState.loadMore();

        expect(loadingStates, contains(true));
        expect(searchState.isLoadingMore.value, false);
      });

      test('should append packages on load more', () async {
        await searchState.search('flutter');
        expect(searchState.packages.value.length, 3);

        await searchState.loadMore();
        expect(searchState.packages.value.length, 4);
        expect(searchState.packages.value.last.package, 'dio');
      });

      test('should update hasMore after load more', () async {
        await searchState.search('flutter');
        expect(searchState.hasMore, true);

        await searchState.loadMore();
        expect(searchState.hasMore, false);
      });

      test('should not load if already loading', () async {
        await searchState.search('flutter');
        searchState.isLoadingMore.value = true;

        var callCount = 0;
        searchState = TestableSearchState(
          mockSearch: (query, sort) async {
            return SearchResults(
              packages: mockPackages,
              next: 'https://pub.dev/next',
            );
          },
          mockNextPage: (url) async {
            callCount++;
            return const SearchResults(packages: []);
          },
        );

        await searchState.search('test');
        searchState.isLoadingMore.value = true;
        await searchState.loadMore();

        // Should not call mockNextPage when already loading
        expect(callCount, 0);
      });

      test('should silently fail on pagination error', () async {
        searchState = TestableSearchState(
          mockSearch: (query, sort) async {
            return SearchResults(
              packages: mockPackages,
              next: 'https://pub.dev/next',
            );
          },
          mockNextPage: (url) async {
            throw Exception('Pagination error');
          },
        );

        await searchState.search('flutter');
        expect(searchState.packages.value.length, 3);

        await searchState.loadMore();

        // Should not change packages on error
        expect(searchState.packages.value.length, 3);
        expect(searchState.isLoadingMore.value, false);
      });
    });

    group('changeSortOrder()', () {
      test('should update sort order', () async {
        expect(searchState.sortOrder.value, SearchOrder.top);

        await searchState.changeSortOrder(SearchOrder.downloads);

        expect(searchState.sortOrder.value, SearchOrder.downloads);
      });

      test('should not re-search if query is empty', () async {
        var searchCalled = false;
        searchState = TestableSearchState(
          mockSearch: (query, sort) async {
            searchCalled = true;
            return const SearchResults(packages: []);
          },
          mockNextPage: (url) async => const SearchResults(packages: []),
        );

        await searchState.changeSortOrder(SearchOrder.downloads);

        expect(searchCalled, false);
      });

      test('should re-search if query is not empty', () async {
        var searchSortOrder = SearchOrder.top;
        searchState = TestableSearchState(
          mockSearch: (query, sort) async {
            searchSortOrder = sort;
            return const SearchResults(packages: []);
          },
          mockNextPage: (url) async => const SearchResults(packages: []),
        );

        await searchState.search('flutter');
        await searchState.changeSortOrder(SearchOrder.downloads);

        expect(searchSortOrder, SearchOrder.downloads);
      });

      test('should not re-search if same order', () async {
        var searchCount = 0;
        searchState = TestableSearchState(
          mockSearch: (query, sort) async {
            searchCount++;
            return const SearchResults(packages: []);
          },
          mockNextPage: (url) async => const SearchResults(packages: []),
        );

        await searchState.search('flutter');
        expect(searchCount, 1);

        await searchState.changeSortOrder(SearchOrder.top);
        expect(searchCount, 1); // Should not increment
      });
    });

    group('clear()', () {
      test('should reset all state', () async {
        await searchState.search('flutter');
        expect(searchState.query.value, 'flutter');
        expect(searchState.packages.value.length, 3);
        expect(searchState.hasMore, true);

        searchState.clear();

        expect(searchState.query.value, '');
        expect(searchState.packages.value, isEmpty);
        expect(searchState.hasMore, false);
        expect(searchState.results.value, isA<AsyncData<SearchResults>>());
      });
    });

    group('batch updates', () {
      test('search should batch state updates', () async {
        var effectRuns = 0;
        effect(() {
          // Access all signals
          searchState.query.value;
          searchState.results.value;
          searchState.packages.value;
          effectRuns++;
        });

        // Initial effect run
        expect(effectRuns, 1);

        await searchState.search('flutter');

        // Ideally should be 2-3 due to async nature, not 10+
        expect(effectRuns, lessThan(10));
      });
    });
  });

  group('FavoritesState-like pattern', () {
    late Signal<AsyncValue<List<String>>> favorites;

    setUp(() {
      favorites = signal<AsyncValue<List<String>>>(const AsyncLoading());
    });

    test('should start in loading state', () {
      expect(favorites.value, isA<AsyncLoading>());
    });

    test('should handle data state', () {
      favorites.value = const AsyncData(['flutter', 'provider', 'bloc']);

      expect(favorites.value, isA<AsyncData<List<String>>>());
      final data = favorites.value as AsyncData<List<String>>;
      expect(data.value.length, 3);
    });

    test('should handle error state', () {
      favorites.value = AsyncError(Exception('Failed'), StackTrace.current);

      expect(favorites.value, isA<AsyncError>());
    });

    test('should support when() pattern', () {
      favorites.value = const AsyncData(['flutter']);

      final result = favorites.value.when(
        loading: () => 'loading',
        data: (data) => 'data: ${data.length}',
        error: (e, _) => 'error: $e',
      );

      expect(result, 'data: 1');
    });
  });

  group('PackageDetailState-like pattern', () {
    test('should support parallel loading', () async {
      final info = signal<AsyncValue<String>>(const AsyncLoading());
      final score = signal<AsyncValue<int>>(const AsyncLoading());
      final publisher = signal<AsyncValue<String>>(const AsyncLoading());

      // Simulate parallel load
      await Future.wait([
        Future.delayed(const Duration(milliseconds: 10), () {
          info.value = const AsyncData('Package Info');
        }),
        Future.delayed(const Duration(milliseconds: 20), () {
          score.value = const AsyncData(100);
        }),
        Future.delayed(const Duration(milliseconds: 15), () {
          publisher.value = const AsyncData('Publisher');
        }),
      ]);

      expect(info.value, isA<AsyncData<String>>());
      expect(score.value, isA<AsyncData<int>>());
      expect(publisher.value, isA<AsyncData<String>>());
    });

    test('should handle partial failure', () async {
      final info = signal<AsyncValue<String>>(const AsyncLoading());
      final score = signal<AsyncValue<int>>(const AsyncLoading());

      info.value = const AsyncData('Info');
      score.value = AsyncError(Exception('Score failed'), StackTrace.current);

      expect(info.value, isA<AsyncData<String>>());
      expect(score.value, isA<AsyncError>());
    });
  });
}
