import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_signals_flutter/void_signals_flutter.dart';

void main() {
  group('SearchConfig', () {
    test('should have correct default values', () {
      const config = SearchConfig();
      expect(
          config.debounceDuration, equals(const Duration(milliseconds: 300)));
      expect(config.minQueryLength, equals(1));
      expect(config.enableCache, isTrue);
      expect(config.maxCacheSize, equals(50));
      expect(config.trimQuery, isTrue);
    });

    test('should accept custom values', () {
      const config = SearchConfig(
        debounceDuration: Duration(milliseconds: 500),
        minQueryLength: 3,
        enableCache: false,
        maxCacheSize: 100,
        trimQuery: false,
      );
      expect(
          config.debounceDuration, equals(const Duration(milliseconds: 500)));
      expect(config.minQueryLength, equals(3));
      expect(config.enableCache, isFalse);
      expect(config.maxCacheSize, equals(100));
      expect(config.trimQuery, isFalse);
    });
  });

  group('SearchState enum', () {
    test('should have all expected values', () {
      expect(SearchState.values.length, equals(6));
      expect(SearchState.idle, isNotNull);
      expect(SearchState.debouncing, isNotNull);
      expect(SearchState.searching, isNotNull);
      expect(SearchState.results, isNotNull);
      expect(SearchState.empty, isNotNull);
      expect(SearchState.error, isNotNull);
    });
  });

  group('SearchSignal', () {
    test('should start in idle state', () {
      final search = SearchSignal<String>(
        searcher: (query) async => [],
      );

      expect(search.state.value, equals(SearchState.idle));
      expect(search.results.value, isEmpty);
      expect(search.error.value, isNull);
      search.dispose();
    });

    test('should debounce search query', () async {
      var searchCount = 0;
      final search = SearchSignal<String>(
        searcher: (query) async {
          searchCount++;
          return ['Result for $query'];
        },
        config: const SearchConfig(
          debounceDuration: Duration(milliseconds: 100),
        ),
      );

      search.query.value = 'a';
      search.query.value = 'ab';
      search.query.value = 'abc';

      await Future.delayed(const Duration(milliseconds: 50));
      expect(searchCount, equals(0));

      await Future.delayed(const Duration(milliseconds: 150));
      expect(searchCount, equals(1));
      expect(search.results.value, equals(['Result for abc']));
      search.dispose();
    });

    test('should not search for short queries', () async {
      var searchCount = 0;
      final search = SearchSignal<String>(
        searcher: (query) async {
          searchCount++;
          return [];
        },
        config: const SearchConfig(
          minQueryLength: 3,
          debounceDuration: Duration(milliseconds: 50),
        ),
      );

      search.query.value = 'a';
      await Future.delayed(const Duration(milliseconds: 100));
      expect(searchCount, equals(0));

      search.query.value = 'ab';
      await Future.delayed(const Duration(milliseconds: 100));
      expect(searchCount, equals(0));

      search.query.value = 'abc';
      await Future.delayed(const Duration(milliseconds: 100));
      expect(searchCount, equals(1));
      search.dispose();
    });

    test('should return to idle state on empty query', () async {
      final search = SearchSignal<String>(
        searcher: (query) async => ['Result'],
        config: const SearchConfig(
          debounceDuration: Duration(milliseconds: 50),
        ),
      );

      search.query.value = 'test';
      await Future.delayed(const Duration(milliseconds: 100));
      expect(search.state.value, equals(SearchState.results));

      search.query.value = '';
      await Future.delayed(const Duration(milliseconds: 50));
      expect(search.state.value, equals(SearchState.idle));
      expect(search.results.value, isEmpty);
      search.dispose();
    });

    test('should cache results', () async {
      var searchCount = 0;
      final search = SearchSignal<String>(
        searcher: (query) async {
          searchCount++;
          return ['Result for $query'];
        },
        config: const SearchConfig(
          debounceDuration: Duration(milliseconds: 50),
          enableCache: true,
        ),
      );

      search.query.value = 'test';
      await Future.delayed(const Duration(milliseconds: 100));
      expect(searchCount, equals(1));

      search.query.value = '';
      await Future.delayed(const Duration(milliseconds: 50));

      search.query.value = 'test';
      await Future.delayed(const Duration(milliseconds: 100));
      // Should use cache, not search again
      expect(searchCount, equals(1));
      expect(search.results.value, equals(['Result for test']));
      search.dispose();
    });

    test('should not cache when disabled', () async {
      var searchCount = 0;
      final search = SearchSignal<String>(
        searcher: (query) async {
          searchCount++;
          return ['Result for $query'];
        },
        config: const SearchConfig(
          debounceDuration: Duration(milliseconds: 50),
          enableCache: false,
        ),
      );

      search.query.value = 'test';
      await Future.delayed(const Duration(milliseconds: 100));
      expect(searchCount, equals(1));

      search.query.value = '';
      await Future.delayed(const Duration(milliseconds: 50));

      search.query.value = 'test';
      await Future.delayed(const Duration(milliseconds: 100));
      expect(searchCount, equals(2));
      search.dispose();
    });

    test('should handle search errors', () async {
      final search = SearchSignal<String>(
        searcher: (query) async {
          throw Exception('Network error');
        },
        config: const SearchConfig(
          debounceDuration: Duration(milliseconds: 50),
        ),
      );

      search.query.value = 'test';
      await Future.delayed(const Duration(milliseconds: 100));

      expect(search.state.value, equals(SearchState.error));
      expect(search.error.value, isNotNull);
      search.dispose();
    });

    test('should show empty state when no results', () async {
      final search = SearchSignal<String>(
        searcher: (query) async => [],
        config: const SearchConfig(
          debounceDuration: Duration(milliseconds: 50),
        ),
      );

      search.query.value = 'nonexistent';
      await Future.delayed(const Duration(milliseconds: 100));

      expect(search.state.value, equals(SearchState.empty));
      expect(search.isEmpty.value, isTrue);
      search.dispose();
    });

    test('should compute isSearching correctly', () async {
      final completer = Completer<List<String>>();
      final search = SearchSignal<String>(
        searcher: (query) => completer.future,
        config: const SearchConfig(
          debounceDuration: Duration(milliseconds: 50),
        ),
      );

      expect(search.isSearching.value, isFalse);

      search.query.value = 'test';
      await Future.delayed(const Duration(milliseconds: 60));

      expect(search.isSearching.value, isTrue);

      completer.complete(['Result']);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(search.isSearching.value, isFalse);
      search.dispose();
    });

    test('should compute hasResults correctly', () async {
      final search = SearchSignal<String>(
        searcher: (query) async => ['Result'],
        config: const SearchConfig(
          debounceDuration: Duration(milliseconds: 50),
        ),
      );

      expect(search.hasResults.value, isFalse);

      search.query.value = 'test';
      await Future.delayed(const Duration(milliseconds: 100));

      expect(search.hasResults.value, isTrue);
      search.dispose();
    });

    test('should compute resultCount correctly', () async {
      final search = SearchSignal<String>(
        searcher: (query) async => ['A', 'B', 'C'],
        config: const SearchConfig(
          debounceDuration: Duration(milliseconds: 50),
        ),
      );

      expect(search.resultCount.value, equals(0));

      search.query.value = 'test';
      await Future.delayed(const Duration(milliseconds: 100));

      expect(search.resultCount.value, equals(3));
      search.dispose();
    });

    test('should clear query and results', () async {
      final search = SearchSignal<String>(
        searcher: (query) async => ['Result'],
        config: const SearchConfig(
          debounceDuration: Duration(milliseconds: 50),
        ),
      );

      search.query.value = 'test';
      await Future.delayed(const Duration(milliseconds: 100));

      search.clear();
      expect(search.query.value, isEmpty);
      expect(search.results.value, isEmpty);
      expect(search.state.value, equals(SearchState.idle));
      search.dispose();
    });

    test('should clear cache', () async {
      var searchCount = 0;
      final search = SearchSignal<String>(
        searcher: (query) async {
          searchCount++;
          return ['Result'];
        },
        config: const SearchConfig(
          debounceDuration: Duration(milliseconds: 50),
          enableCache: true,
        ),
      );

      search.query.value = 'test';
      await Future.delayed(const Duration(milliseconds: 100));
      expect(searchCount, equals(1));

      search.clearCache();
      search.query.value = '';
      await Future.delayed(const Duration(milliseconds: 50));
      search.query.value = 'test';
      await Future.delayed(const Duration(milliseconds: 100));

      expect(searchCount, equals(2));
      search.dispose();
    });

    test('should force search immediately', () async {
      var searchCount = 0;
      final search = SearchSignal<String>(
        searcher: (query) async {
          searchCount++;
          return ['Result'];
        },
        config: const SearchConfig(
          debounceDuration: Duration(milliseconds: 200),
        ),
      );

      search.query.value = 'test';
      await search.search(); // Force immediate search

      expect(searchCount, equals(1));
      search.dispose();
    });

    test('should retry failed search', () async {
      var shouldFail = true;
      final search = SearchSignal<String>(
        searcher: (query) async {
          if (shouldFail) {
            throw Exception('Error');
          }
          return ['Result'];
        },
        config: const SearchConfig(
          debounceDuration: Duration(milliseconds: 50),
        ),
      );

      search.query.value = 'test';
      await Future.delayed(const Duration(milliseconds: 100));
      expect(search.state.value, equals(SearchState.error));

      shouldFail = false;
      await search.retry();
      expect(search.state.value, equals(SearchState.results));
      search.dispose();
    });

    test('should trim query by default', () async {
      final completer = Completer<void>();
      String? receivedQuery;
      final search = SearchSignal<String>(
        searcher: (query) async {
          receivedQuery = query;
          if (!completer.isCompleted) completer.complete();
          return [];
        },
        config: const SearchConfig(
          debounceDuration: Duration(milliseconds: 50),
          trimQuery: true,
        ),
      );

      search.query.value = '  test  ';

      // Allow microtasks to run (for effect to trigger)
      await Future.delayed(Duration.zero);

      // Wait for debounce + search to complete
      await completer.future.timeout(
        const Duration(milliseconds: 500),
        onTimeout: () => throw TimeoutException('Search was not triggered'),
      );

      expect(receivedQuery, equals('test'));
      search.dispose();
    });

    test('should not trim query when disabled', () async {
      final completer = Completer<void>();
      String? receivedQuery;
      final search = SearchSignal<String>(
        searcher: (query) async {
          receivedQuery = query;
          if (!completer.isCompleted) completer.complete();
          return [];
        },
        config: const SearchConfig(
          debounceDuration: Duration(milliseconds: 50),
          trimQuery: false,
        ),
      );

      search.query.value = '  test  ';

      // Allow microtasks to run (for effect to trigger)
      await Future.delayed(Duration.zero);

      // Wait for debounce + search to complete
      await completer.future.timeout(
        const Duration(milliseconds: 500),
        onTimeout: () => throw TimeoutException('Search was not triggered'),
      );

      expect(receivedQuery, equals('  test  '));
      search.dispose();
    });

    test('should limit cache size', () async {
      var searchCount = 0;
      final search = SearchSignal<String>(
        searcher: (query) async {
          searchCount++;
          return ['Result for $query'];
        },
        config: const SearchConfig(
          debounceDuration: Duration(milliseconds: 20),
          enableCache: true,
          maxCacheSize: 3,
        ),
      );

      for (int i = 1; i <= 5; i++) {
        search.query.value = 'query$i';
        await Future.delayed(const Duration(milliseconds: 50));
      }

      expect(searchCount, equals(5));

      // First two should have been evicted
      search.query.value = 'query1';
      await Future.delayed(const Duration(milliseconds: 50));
      expect(searchCount, equals(6)); // Not cached

      // Last one should still be cached
      search.query.value = 'query5';
      await Future.delayed(const Duration(milliseconds: 50));
      expect(searchCount, equals(6)); // Still cached
      search.dispose();
    });

    test('should dispose properly', () {
      final search = SearchSignal<String>(
        searcher: (query) async => [],
      );

      search.dispose();
      // Double dispose should not throw
      search.dispose();
    });
  });

  group('SearchWithSuggestionsSignal', () {
    test('should track suggestions', () async {
      final search = SearchWithSuggestionsSignal<String>(
        searcher: (query) async => [],
        suggester: (query) async => ['Suggestion 1', 'Suggestion 2'],
      );

      expect(search.suggestions.value, isEmpty);

      search.query.value = 'test';
      await search.fetchSuggestions();

      expect(
          search.suggestions.value, equals(['Suggestion 1', 'Suggestion 2']));
      search.dispose();
    });

    test('should track recent searches', () {
      final search = SearchWithSuggestionsSignal<String>(
        searcher: (query) async => [],
      );

      expect(search.recentSearches.value, isEmpty);
      search.dispose();
    });

    test('should select suggestion', () async {
      final search = SearchWithSuggestionsSignal<String>(
        searcher: (query) async => ['Result'],
        config: const SearchConfig(
          debounceDuration: Duration(milliseconds: 50),
        ),
      );

      search.selectSuggestion('Selected Term');
      expect(search.query.value, equals('Selected Term'));
      expect(search.showSuggestions.value, isFalse);

      await Future.delayed(const Duration(milliseconds: 100));
      expect(search.recentSearches.value.contains('Selected Term'), isTrue);
      search.dispose();
    });

    test('should submit search', () async {
      final search = SearchWithSuggestionsSignal<String>(
        searcher: (query) async => ['Result'],
        config: const SearchConfig(
          debounceDuration: Duration(milliseconds: 50),
        ),
      );

      search.query.value = 'test query';
      search.submit();

      expect(search.showSuggestions.value, isFalse);
      expect(search.recentSearches.value.contains('test query'), isTrue);
      search.dispose();
    });

    test('should limit recent searches', () {
      final search = SearchWithSuggestionsSignal<String>(
        searcher: (query) async => [],
        maxRecentSearches: 3,
      );

      for (int i = 1; i <= 5; i++) {
        search.query.value = 'query$i';
        search.submit();
      }

      expect(search.recentSearches.value.length, equals(3));
      expect(search.recentSearches.value.first, equals('query5'));
      search.dispose();
    });

    test('should clear recent searches', () {
      final search = SearchWithSuggestionsSignal<String>(
        searcher: (query) async => [],
      );

      search.query.value = 'test';
      search.submit();
      expect(search.recentSearches.value, isNotEmpty);

      search.clearRecentSearches();
      expect(search.recentSearches.value, isEmpty);
      search.dispose();
    });

    test('should remove specific recent search', () {
      final search = SearchWithSuggestionsSignal<String>(
        searcher: (query) async => [],
      );

      search.query.value = 'test1';
      search.submit();
      search.query.value = 'test2';
      search.submit();

      search.removeRecentSearch('test1');
      expect(search.recentSearches.value.contains('test1'), isFalse);
      expect(search.recentSearches.value.contains('test2'), isTrue);
      search.dispose();
    });

    test('should toggle suggestions mode', () {
      final search = SearchWithSuggestionsSignal<String>(
        searcher: (query) async => [],
      );

      expect(search.showSuggestions.value, isFalse);

      search.showSuggestionsMode();
      expect(search.showSuggestions.value, isTrue);

      search.hideSuggestionsMode();
      expect(search.showSuggestions.value, isFalse);
      search.dispose();
    });

    test('should not add duplicate recent searches', () {
      final search = SearchWithSuggestionsSignal<String>(
        searcher: (query) async => [],
      );

      search.query.value = 'test';
      search.submit();
      search.query.value = 'other';
      search.submit();
      search.query.value = 'test';
      search.submit();

      expect(
        search.recentSearches.value.where((q) => q == 'test').length,
        equals(1),
      );
      expect(search.recentSearches.value.first, equals('test'));
      search.dispose();
    });
  });

  group('FilterSignal', () {
    test('should create with filters', () {
      final source = signal<List<int>>([1, 2, 3, 4, 5]);
      final filter = FilterSignal<int>(
        source: source,
        filters: {
          'even': (n) => n.isEven,
          'greaterThan3': (n) => n > 3,
        },
      );

      expect(filter.availableFilters, equals({'even', 'greaterThan3'}));
      expect(filter.activeFilters.value, isEmpty);
      expect(filter.filtered.value, equals([1, 2, 3, 4, 5]));
    });

    test('should activate filter', () {
      final source = signal<List<int>>([1, 2, 3, 4, 5]);
      final filter = FilterSignal<int>(
        source: source,
        filters: {'even': (n) => n.isEven},
      );

      filter.activate('even');
      expect(filter.filtered.value, equals([2, 4]));
      expect(filter.isActive('even'), isTrue);
    });

    test('should deactivate filter', () {
      final source = signal<List<int>>([1, 2, 3, 4, 5]);
      final filter = FilterSignal<int>(
        source: source,
        filters: {'even': (n) => n.isEven},
        initialActiveFilters: {'even'},
      );

      expect(filter.filtered.value, equals([2, 4]));

      filter.deactivate('even');
      expect(filter.filtered.value, equals([1, 2, 3, 4, 5]));
      expect(filter.isActive('even'), isFalse);
    });

    test('should toggle filter', () {
      final source = signal<List<int>>([1, 2, 3, 4, 5]);
      final filter = FilterSignal<int>(
        source: source,
        filters: {'even': (n) => n.isEven},
      );

      filter.toggle('even');
      expect(filter.isActive('even'), isTrue);

      filter.toggle('even');
      expect(filter.isActive('even'), isFalse);
    });

    test('should apply multiple filters', () {
      final source = signal<List<int>>([1, 2, 3, 4, 5, 6]);
      final filter = FilterSignal<int>(
        source: source,
        filters: {
          'even': (n) => n.isEven,
          'greaterThan3': (n) => n > 3,
        },
      );

      filter.activate('even');
      filter.activate('greaterThan3');
      expect(filter.filtered.value, equals([4, 6]));
    });

    test('should clear all filters', () {
      final source = signal<List<int>>([1, 2, 3, 4, 5]);
      final filter = FilterSignal<int>(
        source: source,
        filters: {
          'even': (n) => n.isEven,
          'greaterThan3': (n) => n > 3,
        },
        initialActiveFilters: {'even', 'greaterThan3'},
      );

      filter.clearAll();
      expect(filter.activeFilters.value, isEmpty);
      expect(filter.filtered.value, equals([1, 2, 3, 4, 5]));
    });

    test('should set filters', () {
      final source = signal<List<int>>([1, 2, 3, 4, 5]);
      final filter = FilterSignal<int>(
        source: source,
        filters: {
          'even': (n) => n.isEven,
          'greaterThan3': (n) => n > 3,
        },
      );

      filter.setFilters({'even', 'greaterThan3'});
      expect(filter.activeFilters.value, equals({'even', 'greaterThan3'}));
    });

    test('should ignore invalid filter names', () {
      final source = signal<List<int>>([1, 2, 3, 4, 5]);
      final filter = FilterSignal<int>(
        source: source,
        filters: {'even': (n) => n.isEven},
      );

      filter.activate('nonexistent');
      expect(filter.activeFilters.value, isEmpty);
    });

    test('should report activeCount and hasActiveFilters', () {
      final source = signal<List<int>>([1, 2, 3, 4, 5]);
      final filter = FilterSignal<int>(
        source: source,
        filters: {
          'even': (n) => n.isEven,
          'odd': (n) => n.isOdd,
        },
      );

      expect(filter.activeCount, equals(0));
      expect(filter.hasActiveFilters, isFalse);

      filter.activate('even');
      expect(filter.activeCount, equals(1));
      expect(filter.hasActiveFilters, isTrue);

      filter.activate('odd');
      expect(filter.activeCount, equals(2));
    });

    test('should react to source changes', () {
      final source = signal<List<int>>([1, 2, 3]);
      final filter = FilterSignal<int>(
        source: source,
        filters: {'even': (n) => n.isEven},
        initialActiveFilters: {'even'},
      );

      expect(filter.filtered.value, equals([2]));

      source.value = [1, 2, 3, 4, 5, 6];
      expect(filter.filtered.value, equals([2, 4, 6]));
    });
  });

  group('SortSignal', () {
    test('should create with comparators', () {
      final source = signal<List<int>>([3, 1, 2]);
      final sort = SortSignal<int>(
        source: source,
        comparators: {
          'value': (a, b) => a.compareTo(b),
        },
      );

      expect(sort.availableSorts, equals({'value'}));
      expect(sort.currentSort.value, isNull);
      expect(sort.sorted.value, equals([3, 1, 2]));
    });

    test('should sort ascending', () {
      final source = signal<List<int>>([3, 1, 2]);
      final sort = SortSignal<int>(
        source: source,
        comparators: {'value': (a, b) => a.compareTo(b)},
      );

      sort.sortBy('value');
      expect(sort.sorted.value, equals([1, 2, 3]));
    });

    test('should sort descending', () {
      final source = signal<List<int>>([3, 1, 2]);
      final sort = SortSignal<int>(
        source: source,
        comparators: {'value': (a, b) => a.compareTo(b)},
      );

      sort.sortBy('value', direction: SortDirection.descending);
      expect(sort.sorted.value, equals([3, 2, 1]));
    });

    test('should toggle direction', () {
      final source = signal<List<int>>([3, 1, 2]);
      final sort = SortSignal<int>(
        source: source,
        comparators: {'value': (a, b) => a.compareTo(b)},
        initialSort: 'value',
      );

      expect(sort.direction.value, equals(SortDirection.ascending));
      expect(sort.sorted.value, equals([1, 2, 3]));

      sort.toggleDirection();
      expect(sort.direction.value, equals(SortDirection.descending));
      expect(sort.sorted.value, equals([3, 2, 1]));
    });

    test('should clear sort', () {
      final source = signal<List<int>>([3, 1, 2]);
      final sort = SortSignal<int>(
        source: source,
        comparators: {'value': (a, b) => a.compareTo(b)},
        initialSort: 'value',
      );

      sort.clearSort();
      expect(sort.currentSort.value, isNull);
      expect(sort.sorted.value, equals([3, 1, 2]));
    });

    test('should ignore invalid sort keys', () {
      final source = signal<List<int>>([3, 1, 2]);
      final sort = SortSignal<int>(
        source: source,
        comparators: {'value': (a, b) => a.compareTo(b)},
      );

      sort.sortBy('nonexistent');
      expect(sort.currentSort.value, isNull);
    });

    test('should react to source changes', () {
      final source = signal<List<int>>([3, 1, 2]);
      final sort = SortSignal<int>(
        source: source,
        comparators: {'value': (a, b) => a.compareTo(b)},
        initialSort: 'value',
      );

      expect(sort.sorted.value, equals([1, 2, 3]));

      source.value = [5, 4, 6];
      expect(sort.sorted.value, equals([4, 5, 6]));
    });

    test('should sort complex objects', () {
      final source = signal<List<Map<String, dynamic>>>([
        {'name': 'Charlie', 'age': 30},
        {'name': 'Alice', 'age': 25},
        {'name': 'Bob', 'age': 35},
      ]);

      final sort = SortSignal<Map<String, dynamic>>(
        source: source,
        comparators: {
          'name': (a, b) =>
              (a['name'] as String).compareTo(b['name'] as String),
          'age': (a, b) => (a['age'] as int).compareTo(b['age'] as int),
        },
      );

      sort.sortBy('name');
      expect(sort.sorted.value.map((m) => m['name']).toList(),
          equals(['Alice', 'Bob', 'Charlie']));

      sort.sortBy('age');
      expect(sort.sorted.value.map((m) => m['age']).toList(),
          equals([25, 30, 35]));
    });
  });

  group('SortDirection enum', () {
    test('should have correct values', () {
      expect(SortDirection.values.length, equals(2));
      expect(SortDirection.ascending, isNotNull);
      expect(SortDirection.descending, isNotNull);
    });
  });

  group('Edge cases', () {
    test('SearchSignal should handle rapid query changes', () async {
      var searchCount = 0;
      final search = SearchSignal<String>(
        searcher: (query) async {
          searchCount++;
          await Future.delayed(const Duration(milliseconds: 50));
          return ['Result for $query'];
        },
        config: const SearchConfig(
          debounceDuration: Duration(milliseconds: 100),
        ),
      );

      for (int i = 0; i < 10; i++) {
        search.query.value = 'query$i';
        await Future.delayed(const Duration(milliseconds: 20));
      }

      await Future.delayed(const Duration(milliseconds: 200));
      // Only the last query should be searched
      expect(searchCount, equals(1));
      search.dispose();
    });

    test('FilterSignal should handle empty source', () {
      final source = signal<List<int>>([]);
      final filter = FilterSignal<int>(
        source: source,
        filters: {'even': (n) => n.isEven},
        initialActiveFilters: {'even'},
      );

      expect(filter.filtered.value, isEmpty);
    });

    test('SortSignal should handle empty source', () {
      final source = signal<List<int>>([]);
      final sort = SortSignal<int>(
        source: source,
        comparators: {'value': (a, b) => a.compareTo(b)},
        initialSort: 'value',
      );

      expect(sort.sorted.value, isEmpty);
    });

    test('SearchSignal should handle special characters in query', () async {
      String? receivedQuery;
      final search = SearchSignal<String>(
        searcher: (query) async {
          receivedQuery = query;
          return [];
        },
        config: const SearchConfig(
          debounceDuration: Duration(milliseconds: 50),
        ),
      );

      search.query.value = 'test@#\$%^&*()';
      await Future.delayed(const Duration(milliseconds: 100));

      expect(receivedQuery, equals('test@#\$%^&*()'));
      search.dispose();
    });

    test('SearchSignal should handle unicode queries', () async {
      String? receivedQuery;
      final search = SearchSignal<String>(
        searcher: (query) async {
          receivedQuery = query;
          return [];
        },
        config: const SearchConfig(
          debounceDuration: Duration(milliseconds: 50),
        ),
      );

      search.query.value = '你好世界 🌍';
      await Future.delayed(const Duration(milliseconds: 100));

      expect(receivedQuery, equals('你好世界 🌍'));
      search.dispose();
    });
  });
}
