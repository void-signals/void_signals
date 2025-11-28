import 'package:pub_api_client/pub_api_client.dart';

/// Singleton instance of the PubClient
final pubClient = PubClient();

/// Repository for fetching package data from pub.dev
class PubRepository {
  final PubClient _client;

  PubRepository([PubClient? client]) : _client = client ?? pubClient;

  /// Search for packages
  Future<SearchResults> search(
    String query, {
    int page = 1,
    SearchOrder sort = SearchOrder.top,
    List<String> topics = const [],
  }) {
    return _client.search(query, page: page, sort: sort, topics: topics);
  }

  /// Get next page of search results
  Future<SearchResults> nextPage(String nextUrl) {
    return _client.nextPage(nextUrl);
  }

  /// Get package info
  Future<PubPackage> packageInfo(String name) {
    return _client.packageInfo(name);
  }

  /// Get package score
  Future<PackageScore> packageScore(String name) {
    return _client.packageScore(name);
  }

  /// Get package metrics
  Future<PackageMetrics?> packageMetrics(String name) {
    return _client.packageMetrics(name);
  }

  /// Get package publisher
  Future<PackagePublisher> packagePublisher(String name) {
    return _client.packagePublisher(name);
  }

  /// Fetch flutter favorites
  Future<List<String>> flutterFavorites() {
    return _client.fetchFlutterFavorites();
  }
}

/// Global repository instance
final pubRepository = PubRepository();
