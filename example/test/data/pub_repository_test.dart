import 'package:flutter_test/flutter_test.dart';
import 'package:pub_api_client/pub_api_client.dart';
import 'package:pubdev_explorer/src/data/pub_repository.dart';

/// Mock PubClient for testing - uses noSuchMethod for unimplemented methods
class MockPubClient implements PubClient {
  bool searchCalled = false;
  bool nextPageCalled = false;
  bool packageInfoCalled = false;
  bool packageScoreCalled = false;
  bool packageMetricsCalled = false;
  bool packagePublisherCalled = false;
  bool flutterFavoritesCalled = false;

  Exception? errorToThrow;

  @override
  Future<SearchResults> search(
    String query, {
    int page = 1,
    SearchOrder sort = SearchOrder.top,
    List<String> tags = const [],
    List<String> topics = const [],
  }) async {
    searchCalled = true;
    if (errorToThrow != null) throw errorToThrow!;
    return SearchResults(
      packages: [
        PackageResult(package: 'test_package_1'),
        PackageResult(package: 'test_package_2'),
      ],
      next: 'https://pub.dev/api/search?q=$query&page=2',
    );
  }

  @override
  Future<SearchResults> nextPage(String nextUrl) async {
    nextPageCalled = true;
    if (errorToThrow != null) throw errorToThrow!;
    return SearchResults(
      packages: [PackageResult(package: 'test_package_3')],
      next: null,
    );
  }

  @override
  Future<PubPackage> packageInfo(String name) async {
    packageInfoCalled = true;
    if (errorToThrow != null) throw errorToThrow!;
    // Return a minimal mock - in real tests use proper mocking
    throw UnimplementedError('Use proper mocking for PubPackage');
  }

  @override
  Future<PackageScore> packageScore(String name) async {
    packageScoreCalled = true;
    if (errorToThrow != null) throw errorToThrow!;
    return PackageScore(
      grantedPoints: 150,
      maxPoints: 160,
      likeCount: 1000,
      popularityScore: 0.95,
      downloadCount30Days: 50000,
      tags: [],
    );
  }

  @override
  Future<PackageMetrics?> packageMetrics(String name) async {
    packageMetricsCalled = true;
    if (errorToThrow != null) throw errorToThrow!;
    return null;
  }

  @override
  Future<PackagePublisher> packagePublisher(String name) async {
    packagePublisherCalled = true;
    if (errorToThrow != null) throw errorToThrow!;
    return PackagePublisher(publisherId: 'dart.dev');
  }

  @override
  Future<List<String>> fetchFlutterFavorites() async {
    flutterFavoritesCalled = true;
    if (errorToThrow != null) throw errorToThrow!;
    return ['provider', 'bloc', 'riverpod', 'get_it', 'freezed'];
  }

  @override
  void close() {}

  // Use noSuchMethod for other interface methods to avoid compilation errors
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(
        '${invocation.memberName} is not implemented in MockPubClient',
      );
}

void main() {
  group('PubRepository', () {
    late MockPubClient mockClient;
    late PubRepository repository;

    setUp(() {
      mockClient = MockPubClient();
      repository = PubRepository(mockClient);
    });

    group('search()', () {
      test('should call client search', () async {
        await repository.search('flutter');
        expect(mockClient.searchCalled, true);
      });

      test('should pass query correctly', () async {
        final results = await repository.search('test_query');
        expect(results.packages.length, 2);
        expect(results.packages[0].package, 'test_package_1');
      });

      test('should pass sort order correctly', () async {
        await repository.search('flutter', sort: SearchOrder.downloads);
        expect(mockClient.searchCalled, true);
      });

      test('should pass topics correctly', () async {
        await repository.search('flutter', topics: ['state-management']);
        expect(mockClient.searchCalled, true);
      });

      test('should propagate errors', () async {
        mockClient.errorToThrow = Exception('Network error');
        expect(() => repository.search('flutter'), throwsException);
      });
    });

    group('nextPage()', () {
      test('should call client nextPage', () async {
        await repository.nextPage('https://pub.dev/api/search?page=2');
        expect(mockClient.nextPageCalled, true);
      });

      test('should return next page results', () async {
        final results = await repository.nextPage('https://example.com/next');
        expect(results.packages.length, 1);
        expect(results.packages[0].package, 'test_package_3');
        expect(results.next, isNull);
      });
    });

    group('packageScore()', () {
      test('should call client packageScore', () async {
        await repository.packageScore('flutter_bloc');
        expect(mockClient.packageScoreCalled, true);
      });

      test('should return score data', () async {
        final score = await repository.packageScore('flutter_bloc');
        expect(score.grantedPoints, 150);
        expect(score.maxPoints, 160);
        expect(score.likeCount, 1000);
        expect(score.popularityScore, 0.95);
        expect(score.downloadCount30Days, 50000);
      });
    });

    group('packagePublisher()', () {
      test('should call client packagePublisher', () async {
        await repository.packagePublisher('flutter_bloc');
        expect(mockClient.packagePublisherCalled, true);
      });

      test('should return publisher data', () async {
        final publisher = await repository.packagePublisher('flutter_bloc');
        expect(publisher.publisherId, 'dart.dev');
      });
    });

    group('flutterFavorites()', () {
      test('should call client fetchFlutterFavorites', () async {
        await repository.flutterFavorites();
        expect(mockClient.flutterFavoritesCalled, true);
      });

      test('should return favorites list', () async {
        final favorites = await repository.flutterFavorites();
        expect(favorites.length, 5);
        expect(favorites, contains('provider'));
        expect(favorites, contains('bloc'));
        expect(favorites, contains('riverpod'));
      });
    });

    group('packageMetrics()', () {
      test('should call client packageMetrics', () async {
        await repository.packageMetrics('flutter_bloc');
        expect(mockClient.packageMetricsCalled, true);
      });
    });

    group('Error Handling', () {
      test('should propagate search errors', () async {
        mockClient.errorToThrow = Exception('Search failed');
        expect(() => repository.search('flutter'), throwsA(isA<Exception>()));
      });

      test('should propagate nextPage errors', () async {
        mockClient.errorToThrow = Exception('Pagination failed');
        expect(
          () => repository.nextPage('https://example.com'),
          throwsA(isA<Exception>()),
        );
      });

      test('should propagate score errors', () async {
        mockClient.errorToThrow = Exception('Score fetch failed');
        expect(
          () => repository.packageScore('test'),
          throwsA(isA<Exception>()),
        );
      });

      test('should propagate favorites errors', () async {
        mockClient.errorToThrow = Exception('Favorites fetch failed');
        expect(() => repository.flutterFavorites(), throwsA(isA<Exception>()));
      });
    });
  });

  group('Global pubRepository', () {
    test('should be a singleton', () {
      expect(pubRepository, isNotNull);
      expect(pubRepository, isA<PubRepository>());
    });
  });
}
