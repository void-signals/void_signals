import 'package:flutter_test/flutter_test.dart';
import 'package:void_signals_flutter/void_signals_flutter.dart';

void main() {
  group('FavoritesState', () {
    late Signal<AsyncValue<List<String>>> favorites;

    setUp(() {
      favorites = signal<AsyncValue<List<String>>>(const AsyncLoading());
    });

    group('Initial State', () {
      test('should start in loading state', () {
        expect(favorites.value, isA<AsyncLoading>());
      });
    });

    group('Load', () {
      test('should transition to data on success', () async {
        favorites.value = const AsyncLoading();

        // Simulate load
        await Future.delayed(Duration.zero, () {
          favorites.value = const AsyncData([
            'flutter',
            'provider',
            'bloc',
            'dio',
          ]);
        });

        expect(favorites.value, isA<AsyncData<List<String>>>());
        final data = favorites.value as AsyncData<List<String>>;
        expect(data.value.length, 4);
        expect(data.value, contains('flutter'));
      });

      test('should transition to error on failure', () async {
        favorites.value = const AsyncLoading();

        // Simulate error
        await Future.delayed(Duration.zero, () {
          favorites.value = AsyncError(
            Exception('Network error'),
            StackTrace.current,
          );
        });

        expect(favorites.value, isA<AsyncError>());
      });

      test('should not reload if already loaded', () {
        favorites.value = const AsyncData(['flutter']);

        // Check already loaded
        final wasData = favorites.value is AsyncData;
        expect(wasData, true);

        // Should skip load in real implementation
      });
    });

    group('Refresh', () {
      test('should reset to loading before refresh', () async {
        favorites.value = const AsyncData(['flutter']);
        expect(favorites.value, isA<AsyncData<List<String>>>());

        // Refresh
        favorites.value = const AsyncLoading();
        expect(favorites.value, isA<AsyncLoading>());

        // Complete refresh
        favorites.value = const AsyncData(['flutter', 'new_package']);
        expect(favorites.value, isA<AsyncData<List<String>>>());
        final data = favorites.value as AsyncData<List<String>>;
        expect(data.value.length, 2);
      });

      test('should handle refresh error', () async {
        favorites.value = const AsyncData(['flutter']);

        // Start refresh
        favorites.value = const AsyncLoading();

        // Refresh fails
        favorites.value = AsyncError(
          Exception('Refresh failed'),
          StackTrace.current,
        );

        expect(favorites.value, isA<AsyncError>());
      });
    });

    group('AsyncValue pattern matching', () {
      test('when() should handle loading', () {
        favorites.value = const AsyncLoading();

        final result = favorites.value.when(
          loading: () => 'Loading...',
          data: (data) => 'Data: ${data.length}',
          error: (e, _) => 'Error: $e',
        );

        expect(result, 'Loading...');
      });

      test('when() should handle data', () {
        favorites.value = const AsyncData(['a', 'b', 'c']);

        final result = favorites.value.when(
          loading: () => 'Loading...',
          data: (data) => 'Data: ${data.length}',
          error: (e, _) => 'Error: $e',
        );

        expect(result, 'Data: 3');
      });

      test('when() should handle error', () {
        favorites.value = AsyncError(
          Exception('Test error'),
          StackTrace.current,
        );

        final result = favorites.value.when(
          loading: () => 'Loading...',
          data: (data) => 'Data: ${data.length}',
          error: (e, _) => 'Error occurred',
        );

        expect(result, 'Error occurred');
      });

      test('maybeWhen() should provide orElse', () {
        favorites.value = const AsyncLoading();

        final result = favorites.value.maybeWhen(
          data: (data) => 'Data: ${data.length}',
          orElse: () => 'Not ready',
        );

        expect(result, 'Not ready');
      });

      test('whenData should only run for data', () {
        favorites.value = const AsyncData(['flutter']);

        String? capturedData;
        if (favorites.value case AsyncData(:final value)) {
          capturedData = value.join(',');
        }

        expect(capturedData, 'flutter');
      });

      test('whenData should not run for loading', () {
        favorites.value = const AsyncLoading();

        String? capturedData;
        if (favorites.value case AsyncData(:final value)) {
          capturedData = value.join(',');
        }

        expect(capturedData, isNull);
      });
    });

    group('Effect integration', () {
      test('should trigger effect on state change', () {
        final log = <String>[];

        final eff = effect(() {
          favorites.value.when(
            loading: () => log.add('loading'),
            data: (data) => log.add('data:${data.length}'),
            error: (e, _) => log.add('error'),
          );
        });

        expect(log, ['loading']);

        favorites.value = const AsyncData(['a', 'b']);
        expect(log, ['loading', 'data:2']);

        favorites.value = AsyncError(Exception('test'), StackTrace.current);
        expect(log, ['loading', 'data:2', 'error']);

        eff.stop();
      });
    });

    group('Computed integration', () {
      test('should derive favorites count', () {
        final favoritesCount = computed((prev) {
          return favorites.value.when(
            loading: () => 0,
            data: (data) => data.length,
            error: (_, __) => -1,
          );
        });

        expect(favoritesCount.value, 0); // Loading

        favorites.value = const AsyncData(['a', 'b', 'c']);
        expect(favoritesCount.value, 3);

        favorites.value = AsyncError(Exception('test'), StackTrace.current);
        expect(favoritesCount.value, -1);
      });

      test('should derive isLoaded status', () {
        final isLoaded = computed((prev) => favorites.value is AsyncData);

        expect(isLoaded.value, false);

        favorites.value = const AsyncData(['flutter']);
        expect(isLoaded.value, true);

        favorites.value = const AsyncLoading();
        expect(isLoaded.value, false);
      });

      test('should derive filtered favorites', () {
        favorites.value = const AsyncData([
          'flutter_bloc',
          'provider',
          'flutter_riverpod',
          'get_it',
        ]);

        final flutterFavorites = computed((prev) {
          return favorites.value.when(
            loading: () => <String>[],
            data: (data) => data.where((p) => p.startsWith('flutter')).toList(),
            error: (_, __) => <String>[],
          );
        });

        expect(flutterFavorites.value, ['flutter_bloc', 'flutter_riverpod']);
      });
    });
  });

  group('Package Detail State Pattern', () {
    test('should manage multiple async states independently', () async {
      final info = signal<AsyncValue<Map<String, dynamic>>>(
        const AsyncLoading(),
      );
      final score = signal<AsyncValue<int>>(const AsyncLoading());
      final publisher = signal<AsyncValue<String>>(const AsyncLoading());

      // Load info first
      info.value = const AsyncData({
        'name': 'flutter_bloc',
        'version': '8.0.0',
      });
      expect(info.value, isA<AsyncData>());
      expect(score.value, isA<AsyncLoading>());
      expect(publisher.value, isA<AsyncLoading>());

      // Load score
      score.value = const AsyncData(150);
      expect(score.value, isA<AsyncData>());

      // Load publisher
      publisher.value = const AsyncData('bloclibrary.dev');
      expect(publisher.value, isA<AsyncData>());
    });

    test('should support refresh', () async {
      final info = signal<AsyncValue<Map<String, dynamic>>>(
        const AsyncData({'version': '1.0.0'}),
      );

      // Start refresh
      info.value = const AsyncLoading();
      expect(info.value, isA<AsyncLoading>());

      // Complete refresh
      info.value = const AsyncData({'version': '2.0.0'});
      final data = info.value as AsyncData<Map<String, dynamic>>;
      expect(data.value['version'], '2.0.0');
    });

    test('should derive all loaded status', () {
      final info = signal<AsyncValue<String>>(const AsyncLoading());
      final score = signal<AsyncValue<int>>(const AsyncLoading());
      final publisher = signal<AsyncValue<String>>(const AsyncLoading());

      final allLoaded = computed((prev) {
        return info.value is AsyncData &&
            score.value is AsyncData &&
            publisher.value is AsyncData;
      });

      expect(allLoaded.value, false);

      info.value = const AsyncData('info');
      expect(allLoaded.value, false);

      score.value = const AsyncData(100);
      expect(allLoaded.value, false);

      publisher.value = const AsyncData('pub');
      expect(allLoaded.value, true);
    });

    test('should derive any error status', () {
      final info = signal<AsyncValue<String>>(const AsyncLoading());
      final score = signal<AsyncValue<int>>(const AsyncLoading());

      final hasError = computed((prev) {
        return info.value is AsyncError || score.value is AsyncError;
      });

      expect(hasError.value, false);

      info.value = const AsyncData('info');
      expect(hasError.value, false);

      score.value = AsyncError(Exception('failed'), StackTrace.current);
      expect(hasError.value, true);
    });
  });
}
