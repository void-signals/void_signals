import 'package:pub_api_client/pub_api_client.dart';
import 'package:void_signals_flutter/void_signals_flutter.dart';

import '../data/pub_repository.dart';

/// Package detail state for a single package.
///
/// This state class creates signals but no effects, so no explicit
/// dispose is required. The signals will be garbage collected when
/// the state instance is no longer referenced.
class PackageDetailState {
  final String packageName;

  PackageDetailState(this.packageName);

  /// Package info
  late final info = signal<AsyncValue<PubPackage>>(const AsyncLoading());

  /// Package score
  late final score = signal<AsyncValue<PackageScore>>(const AsyncLoading());

  /// Package publisher
  late final publisher = signal<AsyncValue<PackagePublisher>>(
    const AsyncLoading(),
  );

  /// Load all package details
  Future<void> load() async {
    await Future.wait([_loadInfo(), _loadScore(), _loadPublisher()]);
  }

  Future<void> _loadInfo() async {
    try {
      final result = await pubRepository.packageInfo(packageName);
      info.value = AsyncData(result);
    } catch (e, st) {
      info.value = AsyncError(e, st);
    }
  }

  Future<void> _loadScore() async {
    try {
      final result = await pubRepository.packageScore(packageName);
      score.value = AsyncData(result);
    } catch (e, st) {
      score.value = AsyncError(e, st);
    }
  }

  Future<void> _loadPublisher() async {
    try {
      final result = await pubRepository.packagePublisher(packageName);
      publisher.value = AsyncData(result);
    } catch (e, st) {
      publisher.value = AsyncError(e, st);
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    info.value = const AsyncLoading();
    score.value = const AsyncLoading();
    publisher.value = const AsyncLoading();
    await load();
  }
}
