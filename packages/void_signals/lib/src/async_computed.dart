import 'dart:async';

import 'api.dart';

// =============================================================================
// AsyncValue - Riverpod-style async state wrapper
// =============================================================================

/// Represents the state of an asynchronous operation.
///
/// This is similar to Riverpod's AsyncValue, providing a type-safe way to
/// handle loading, data, and error states.
///
/// Example:
/// ```dart
/// final userAsync = asyncComputed(() async {
///   return await fetchUser();
/// });
///
/// switch (userAsync()) {
///   case AsyncLoading():
///     print('Loading...');
///   case AsyncData(:final value):
///     print('User: $value');
///   case AsyncError(:final error):
///     print('Error: $error');
/// }
/// ```
sealed class AsyncValue<T> {
  const AsyncValue._();

  /// Creates a loading state.
  const factory AsyncValue.loading() = AsyncLoading<T>;

  /// Creates a data state with the given value.
  const factory AsyncValue.data(T value) = AsyncData<T>;

  /// Creates an error state with the given error and stack trace.
  const factory AsyncValue.error(Object error, StackTrace stackTrace) =
      AsyncError<T>;

  /// Creates an AsyncValue from a synchronous value.
  factory AsyncValue.guard(T Function() cb) {
    try {
      return AsyncData(cb());
    } catch (e, stack) {
      return AsyncError(e, stack);
    }
  }

  /// Creates an AsyncValue from a Future.
  static Future<AsyncValue<T>> guardAsync<T>(Future<T> Function() cb) async {
    try {
      return AsyncData(await cb());
    } catch (e, stack) {
      return AsyncError(e, stack);
    }
  }

  /// Whether this is a loading state.
  bool get isLoading => this is AsyncLoading<T>;

  /// Whether this is a data state.
  bool get hasValue => this is AsyncData<T>;

  /// Alias for [hasValue] - whether this is a data state.
  bool get hasData => hasValue;

  /// Whether this is an error state.
  bool get hasError => this is AsyncError<T>;

  /// The value if this is a data state, null otherwise.
  T? get valueOrNull => switch (this) {
        AsyncData(:final value) => value,
        _ => null,
      };

  /// The value if this is a data state, throws otherwise.
  T get requireValue => switch (this) {
        AsyncData(:final value) => value,
        AsyncLoadingWithPrevious(:final previousValue) => previousValue,
        AsyncErrorWithPrevious(:final previousValue) => previousValue,
        AsyncLoading() => throw StateError('Cannot get value while loading'),
        AsyncError(:final error, :final stackTrace) =>
          Error.throwWithStackTrace(error, stackTrace),
      };

  /// The error if this is an error state, null otherwise.
  Object? get errorOrNull => switch (this) {
        AsyncError(:final error) => error,
        _ => null,
      };

  /// The stack trace if this is an error state, null otherwise.
  StackTrace? get stackTraceOrNull => switch (this) {
        AsyncError(:final stackTrace) => stackTrace,
        _ => null,
      };

  /// Pattern match on the async state.
  R when<R>({
    required R Function() loading,
    required R Function(T value) data,
    required R Function(Object error, StackTrace stackTrace) error,
  }) {
    return switch (this) {
      AsyncLoading() => loading(),
      AsyncLoadingWithPrevious() => loading(),
      AsyncData(:final value) => data(value),
      AsyncErrorWithPrevious(error: final e, stackTrace: final s) =>
        error(e, s),
      AsyncError(error: final e, stackTrace: final s) => error(e, s),
    };
  }

  /// Pattern match with optional handlers and orElse fallback.
  R maybeWhen<R>({
    R Function()? loading,
    R Function(T value)? data,
    R Function(Object error, StackTrace stackTrace)? error,
    required R Function() orElse,
  }) {
    return switch (this) {
      AsyncLoading() => loading?.call() ?? orElse(),
      AsyncLoadingWithPrevious() => loading?.call() ?? orElse(),
      AsyncData(:final value) => data?.call(value) ?? orElse(),
      AsyncErrorWithPrevious(error: final e, stackTrace: final s) =>
        error?.call(e, s) ?? orElse(),
      AsyncError(error: final e, stackTrace: final s) =>
        error?.call(e, s) ?? orElse(),
    };
  }

  /// Map the value if present.
  AsyncValue<R> map<R>(R Function(T value) mapper) {
    return switch (this) {
      AsyncLoading() => AsyncLoading<R>(),
      AsyncLoadingWithPrevious(:final previousValue) =>
        AsyncLoadingWithPrevious<R>(mapper(previousValue)),
      AsyncData(:final value) => AsyncData(mapper(value)),
      AsyncErrorWithPrevious(
        :final error,
        :final stackTrace,
        :final previousValue
      ) =>
        AsyncErrorWithPrevious<R>(error, stackTrace, mapper(previousValue)),
      AsyncError(:final error, :final stackTrace) =>
        AsyncError<R>(error, stackTrace),
    };
  }

  /// FlatMap the value if present.
  AsyncValue<R> flatMap<R>(AsyncValue<R> Function(T value) mapper) {
    return switch (this) {
      AsyncLoading() => AsyncLoading<R>(),
      AsyncLoadingWithPrevious(:final previousValue) => mapper(previousValue),
      AsyncData(:final value) => mapper(value),
      AsyncErrorWithPrevious(:final error, :final stackTrace) =>
        AsyncError<R>(error, stackTrace),
      AsyncError(:final error, :final stackTrace) =>
        AsyncError<R>(error, stackTrace),
    };
  }

  /// Returns the value or a fallback.
  T getOrElse(T fallback) => valueOrNull ?? fallback;

  /// Returns the value or computes a fallback.
  T getOrElseCompute(T Function() compute) => valueOrNull ?? compute();

  /// Alias for [getOrElseCompute] - returns the value or computes a fallback.
  T getOrCompute(T Function() compute) => getOrElseCompute(compute);

  /// Creates a copy with the previous value preserved during loading/error.
  AsyncValue<T> copyWithPrevious(
    AsyncValue<T>? previous, {
    bool isRefresh = true,
  }) {
    if (previous == null) return this;
    return switch (this) {
      AsyncLoading() when previous.hasValue =>
        AsyncLoadingWithPrevious<T>(previous.valueOrNull as T),
      AsyncError(:final error, :final stackTrace) when previous.hasValue =>
        AsyncErrorWithPrevious<T>(error, stackTrace, previous.valueOrNull as T),
      _ => this,
    };
  }
}

/// Loading state.
final class AsyncLoading<T> extends AsyncValue<T> {
  const AsyncLoading() : super._();

  @override
  String toString() => 'AsyncLoading<$T>()';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AsyncLoading<T>;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Loading state that preserves the previous value.
final class AsyncLoadingWithPrevious<T> extends AsyncValue<T> {
  /// The previous value.
  final T previousValue;

  const AsyncLoadingWithPrevious(this.previousValue) : super._();

  @override
  bool get isLoading => true;

  @override
  bool get hasValue => true;

  @override
  T? get valueOrNull => previousValue;

  @override
  String toString() => 'AsyncLoadingWithPrevious<$T>($previousValue)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AsyncLoadingWithPrevious<T> &&
          previousValue == other.previousValue;

  @override
  int get hashCode => Object.hash(runtimeType, previousValue);
}

/// Data state with a value.
final class AsyncData<T> extends AsyncValue<T> {
  /// The value.
  final T value;

  const AsyncData(this.value) : super._();

  @override
  String toString() => 'AsyncData<$T>($value)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AsyncData<T> && value == other.value;

  @override
  int get hashCode => Object.hash(runtimeType, value);
}

/// Error state with an error and stack trace.
final class AsyncError<T> extends AsyncValue<T> {
  /// The error.
  final Object error;

  /// The stack trace.
  final StackTrace stackTrace;

  const AsyncError(this.error, this.stackTrace) : super._();

  @override
  String toString() => 'AsyncError<$T>($error)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AsyncError<T> && error == other.error;

  @override
  int get hashCode => Object.hash(runtimeType, error);
}

/// Error state that preserves the previous value.
final class AsyncErrorWithPrevious<T> extends AsyncValue<T> {
  /// The error.
  final Object error;

  /// The stack trace.
  final StackTrace stackTrace;

  /// The previous value.
  final T previousValue;

  const AsyncErrorWithPrevious(this.error, this.stackTrace, this.previousValue)
      : super._();

  @override
  bool get hasError => true;

  @override
  bool get hasValue => true;

  @override
  T? get valueOrNull => previousValue;

  @override
  Object? get errorOrNull => error;

  @override
  StackTrace? get stackTraceOrNull => stackTrace;

  @override
  String toString() =>
      'AsyncErrorWithPrevious<$T>(error: $error, previous: $previousValue)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AsyncErrorWithPrevious<T> &&
          error == other.error &&
          previousValue == other.previousValue;

  @override
  int get hashCode => Object.hash(runtimeType, error, previousValue);
}

// =============================================================================
// AsyncComputed - Computed that handles async operations
// =============================================================================

/// A computed value that handles async operations with proper dependency tracking.
///
/// `AsyncComputed` automatically tracks dependencies and re-runs the async
/// computation when any dependency changes. It properly handles:
/// - Loading states
/// - Error states with retry support
/// - Cancellation when dependencies change
/// - Preserving previous values during refreshes
///
/// Example with async dependencies:
/// ```dart
/// // Basic async computed
/// final user = asyncComputed(() async {
///   final userId = userIdSignal();  // Sync dependency
///   return await fetchUser(userId);
/// });
///
/// // Async computed depending on another async computed
/// final userPosts = asyncComputed(() async {
///   final userData = await user.future;  // Wait for user to complete
///   return await fetchPosts(userData.id);
/// });
///
/// // Chained async dependencies
/// final dashboardData = asyncComputed(() async {
///   final [userData, postsData] = await Future.wait([
///     user.future,
///     userPosts.future,
///   ]);
///   return DashboardData(user: userData, posts: postsData);
/// });
/// ```
class AsyncComputed<T> {
  final Future<T> Function() _compute;
  final Signal<AsyncValue<T>> _state;
  final Signal<int> _trigger;
  Effect? _effect;
  int _currentVersion = 0;
  Completer<T>? _completer;
  bool _disposed = false;

  /// Creates an async computed value.
  ///
  /// The [compute] function is called whenever any of its synchronous
  /// dependencies change. For async dependencies, use [future] to wait
  /// for them.
  ///
  /// **Important**: Signal dependencies are tracked during the synchronous
  /// part of the computation (before any `await`). Make sure to read all
  /// signals you depend on before the first `await`:
  ///
  /// ```dart
  /// final computed = asyncComputed(() async {
  ///   // Good: signal read before await
  ///   final id = userId();
  ///   final data = await fetchData(id);
  ///   return data;
  /// });
  /// ```
  AsyncComputed(Future<T> Function() compute)
      : _compute = compute,
        _state = signal(const AsyncLoading()),
        _trigger = signal(0) {
    _startTracking();
  }

  void _startTracking() {
    // Create an effect that will track signal reads within _compute()
    // The effect runs synchronously and tracks any signals read during
    // the synchronous part of _compute() (before first await)
    _effect = effect(() {
      // Read trigger to allow manual refresh
      _trigger();

      // Increment version for this computation
      final version = ++_currentVersion;
      final previousValue = _state.peek();

      // Set loading state immediately
      _state.update(AsyncLoading<T>().copyWithPrevious(previousValue));

      // Create a new completer for this computation
      final completer = _completer = Completer<T>();

      // Immediately attach an error handler to prevent unhandled exceptions
      // when errors are reported synchronously before anyone listens to the future
      completer.future.ignore();

      // Start the async computation
      // Signal reads in _compute() before the first await will be tracked
      // by this effect
      //
      // We wrap everything in a try-catch to prevent synchronous errors from
      // propagating out of the effect, since effect() doesn't catch exceptions
      try {
        final future = _compute();

        // Handle the async result in a microtask to avoid blocking the effect
        future.then((value) {
          if (_disposed) return;
          if (version == _currentVersion && !completer.isCompleted) {
            _state.update(AsyncData(value));
            completer.complete(value);
          }
        }).catchError((Object error, StackTrace stackTrace) {
          if (_disposed) return;
          if (version == _currentVersion && !completer.isCompleted) {
            _state.update(AsyncError<T>(error, stackTrace)
                .copyWithPrevious(previousValue));
            completer.completeError(error, stackTrace);
          }
        });
      } catch (e, stack) {
        // Handle synchronous errors - update state and completer
        // but don't rethrow to prevent propagating out of effect
        if (version == _currentVersion && !completer.isCompleted) {
          _state
              .update(AsyncError<T>(e, stack).copyWithPrevious(previousValue));
          completer.completeError(e, stack);
        }
        // Don't rethrow - we've handled the error by updating state
      }
    });
  }

  /// The current async state.
  AsyncValue<T> call() => _state();

  /// The current async state.
  AsyncValue<T> get value => _state();

  /// A Future that completes with the next value.
  ///
  /// Use this to create async dependencies:
  /// ```dart
  /// final derived = asyncComputed(() async {
  ///   final base = await baseComputed.future;  // Creates dependency
  ///   return transform(base);
  /// });
  /// ```
  Future<T> get future {
    final current = _state.syncPeek();
    if (current is AsyncData<T>) {
      return Future.value(current.value);
    }
    if (current is AsyncError<T>) {
      return Future.error(current.error, current.stackTrace);
    }
    // Loading state - return the pending future
    return _completer?.future ?? _createPendingFuture();
  }

  Future<T> _createPendingFuture() {
    final completer = Completer<T>();
    late Effect listener;
    listener = effect(() {
      final state = _state();
      if (state is AsyncData<T>) {
        completer.complete(state.value);
        listener.stop();
      } else if (state is AsyncError<T>) {
        completer.completeError(state.error, state.stackTrace);
        listener.stop();
      }
    });
    return completer.future;
  }

  /// Whether the computation is currently loading.
  bool get isLoading => _state.syncPeek().isLoading;

  /// Whether the computation has a value.
  bool get hasValue => _state.syncPeek().hasValue;

  /// Whether the computation has an error.
  bool get hasError => _state.syncPeek().hasError;

  /// The current value, or null if loading/error.
  T? get valueOrNull => _state.syncPeek().valueOrNull;

  /// Forces a re-computation.
  void refresh() {
    _trigger.value++;
  }

  /// Stops the async computed and cleans up resources.
  void dispose() {
    _disposed = true;
    _effect?.stop();
    _effect = null;
    _completer = null;
  }

  /// The state signal for watching.
  Signal<AsyncValue<T>> get stateSignal => _state;
}

/// Creates an async computed value.
///
/// This is the recommended way to handle async operations with proper
/// dependency tracking.
///
/// Example:
/// ```dart
/// final userId = signal(1);
///
/// final user = asyncComputed(() async {
///   final id = userId();  // Creates dependency on userId
///   return await fetchUser(id);
/// });
///
/// // When userId changes, user will automatically re-fetch
/// userId.value = 2;
/// ```
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
AsyncComputed<T> asyncComputed<T>(Future<T> Function() compute) =>
    AsyncComputed<T>(compute);

// =============================================================================
// StreamComputed - Computed that handles streams
// =============================================================================

/// A computed value that wraps a Stream with proper lifecycle management.
///
/// Example:
/// ```dart
/// final messages = streamComputed(() {
///   final roomId = roomSignal();  // Sync dependency
///   return chatService.messagesStream(roomId);
/// });
/// ```
class StreamComputed<T> {
  final Stream<T> Function() _createStream;
  final Signal<AsyncValue<T>> _state;
  final Signal<int> _trigger;
  Effect? _effect;
  StreamSubscription<T>? _subscription;
  int _currentVersion = 0;
  bool _disposed = false;

  /// Creates a stream computed value.
  StreamComputed(Stream<T> Function() createStream)
      : _createStream = createStream,
        _state = signal(const AsyncLoading()),
        _trigger = signal(0) {
    _startTracking();
  }

  void _startTracking() {
    _effect = effect(() {
      _trigger();
      _subscribeToStream();
    });
  }

  void _subscribeToStream() {
    if (_disposed) return;

    final version = ++_currentVersion;
    final previousValue = _state.peek();

    // Cancel previous subscription
    _subscription?.cancel();

    // Set loading state
    _state.update(AsyncLoading<T>().copyWithPrevious(previousValue));

    try {
      final stream = _createStream();
      _subscription = stream.listen(
        (value) {
          if (_disposed) return;
          if (version == _currentVersion) {
            _state.update(AsyncData(value));
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          if (_disposed) return;
          if (version == _currentVersion) {
            _state.update(AsyncError<T>(error, stackTrace)
                .copyWithPrevious(previousValue));
          }
        },
      );
    } catch (error, stackTrace) {
      if (version == _currentVersion) {
        _state.update(
            AsyncError<T>(error, stackTrace).copyWithPrevious(previousValue));
      }
    }
  }

  /// The current async state.
  AsyncValue<T> call() => _state();

  /// The current async state.
  AsyncValue<T> get value => _state();

  /// Whether the stream is currently loading.
  bool get isLoading => _state.syncPeek().isLoading;

  /// Whether the stream has emitted a value.
  bool get hasValue => _state.syncPeek().hasValue;

  /// Whether the stream has an error.
  bool get hasError => _state.syncPeek().hasError;

  /// The current value, or null if loading/error.
  T? get valueOrNull => _state.syncPeek().valueOrNull;

  /// Forces a re-subscription to the stream.
  void refresh() {
    _trigger.value++;
  }

  /// Stops listening to the stream and cleans up resources.
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    _subscription = null;
    _effect?.stop();
    _effect = null;
  }

  /// The state signal for watching.
  Signal<AsyncValue<T>> get stateSignal => _state;
}

/// Creates a stream computed value.
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
StreamComputed<T> streamComputed<T>(Stream<T> Function() createStream) =>
    StreamComputed<T>(createStream);

// =============================================================================
// Async Dependency Helpers
// =============================================================================

/// Combines multiple AsyncValues into one.
///
/// Returns loading if any is loading, error if any has error,
/// data only if all have data.
///
/// Example:
/// ```dart
/// final combined = combineAsync([
///   user(),
///   posts(),
///   comments(),
/// ], (values) => Dashboard(
///   user: values[0] as User,
///   posts: values[1] as List<Post>,
///   comments: values[2] as List<Comment>,
/// ));
/// ```
AsyncValue<R> combineAsync<R>(
  List<AsyncValue<Object?>> values,
  R Function(List<Object?> values) combiner,
) {
  // Check for any loading state
  final loading = values.whereType<AsyncLoading>().firstOrNull ??
      values.whereType<AsyncLoadingWithPrevious>().firstOrNull;
  if (loading != null) {
    return const AsyncLoading();
  }

  // Check for any error state
  for (final value in values) {
    if (value is AsyncError) {
      return AsyncError(value.error, value.stackTrace);
    }
    if (value is AsyncErrorWithPrevious) {
      return AsyncError(value.error, value.stackTrace);
    }
  }

  // All values are data
  final dataValues = values.map((v) => v.valueOrNull).toList();
  try {
    return AsyncData(combiner(dataValues));
  } catch (e, stack) {
    return AsyncError(e, stack);
  }
}

/// Extension for working with multiple async computeds.
extension AsyncComputedListExtension<T> on List<AsyncComputed<T>> {
  /// Waits for all async computeds to complete.
  Future<List<T>> get allFutures => Future.wait(map((c) => c.future));

  /// Combines all async states.
  AsyncValue<List<T>> get combined {
    final values = map((c) => c.value).toList();
    return combineAsync<List<T>>(
      values.cast<AsyncValue<Object?>>(),
      (vals) => vals.cast<T>(),
    );
  }
}

// =============================================================================
// Guard helpers for async operations
// =============================================================================

/// Safely awaits a Future, catching errors and returning an AsyncValue.
extension FutureAsyncValueExtension<T> on Future<T> {
  /// Converts this Future to an AsyncValue.
  Future<AsyncValue<T>> toAsyncValue() async {
    try {
      return AsyncData(await this);
    } catch (e, stack) {
      return AsyncError(e, stack);
    }
  }
}

/// Extension for AsyncComputed to add lifecycle management.
extension AsyncComputedLifecycleExtension<T> on AsyncComputed<T> {
  /// Disposes this async computed when the given scope is stopped.
  void disposeWith(EffectScope scope) {
    // This would require changes to EffectScope to support disposal callbacks
    // For now, users should call dispose() manually
  }
}
