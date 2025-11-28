import 'package:void_signals_flutter/void_signals_flutter.dart';

import '../data/pub_repository.dart';

/// State for flutter favorites
class FavoritesState {
  FavoritesState._();

  static final FavoritesState instance = FavoritesState._();

  /// Flutter favorites packages
  final favorites = signal<AsyncValue<List<String>>>(const AsyncLoading());

  /// Load flutter favorites
  Future<void> load() async {
    if (favorites.value is AsyncData) return; // Already loaded

    favorites.value = const AsyncLoading();

    try {
      final result = await pubRepository.flutterFavorites();
      favorites.value = AsyncData(result);
    } catch (e, st) {
      favorites.value = AsyncError(e, st);
    }
  }

  /// Refresh favorites
  Future<void> refresh() async {
    favorites.value = const AsyncLoading();
    try {
      final result = await pubRepository.flutterFavorites();
      favorites.value = AsyncData(result);
    } catch (e, st) {
      favorites.value = AsyncError(e, st);
    }
  }
}

/// Global favorites state
final favoritesState = FavoritesState.instance;
