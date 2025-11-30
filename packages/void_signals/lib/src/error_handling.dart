import 'dart:async';
import 'dart:math' as math;

import 'api.dart';
import 'lifecycle.dart';

// =============================================================================
// Error Handling & Retry Logic
//
// Production-grade error handling inspired by Riverpod's patterns.
// =============================================================================

/// Result type for signal operations that can fail.
///
/// Similar to Rust's Result type or Riverpod's AsyncValue.
///
/// Example:
/// ```dart
/// final result = sig.tryRead();
/// switch (result) {
///   case ResultData(:final value):
///     print('Success: $value');
///   case ResultError(:final error):
///     print('Error: $error');
/// }
/// ```
sealed class Result<T> {
  const Result._();

  /// Whether this result contains a value.
  bool get hasValue;

  /// Whether this result contains an error.
  bool get hasError;

  /// Gets the value, or throws if this is an error.
  T get value;

  /// Gets the error, or null if this is a value.
  Object? get error;

  /// Gets the stack trace if this is an error.
  StackTrace? get stackTrace;

  /// Maps the value if present.
  Result<R> map<R>(R Function(T value) mapper);

  /// Maps the error if present.
  Result<T> mapError(Object Function(Object error) mapper);

  /// Returns the value or a fallback.
  T getOrElse(T fallback);

  /// Returns the value or computes a fallback.
  T getOrElseCompute(T Function() compute);

  /// Executes a callback if this is a value.
  void ifValue(void Function(T value) callback);

  /// Executes a callback if this is an error.
  void ifError(void Function(Object error, StackTrace stackTrace) callback);

  /// Converts to an AsyncValue.
  AsyncValueLike<T> toAsyncValue();
}

/// A successful result containing a value.
final class ResultData<T> extends Result<T> {
  /// The value.
  @override
  final T value;

  /// Creates a successful result.
  const ResultData(this.value) : super._();

  @override
  bool get hasValue => true;

  @override
  bool get hasError => false;

  @override
  Object? get error => null;

  @override
  StackTrace? get stackTrace => null;

  @override
  Result<R> map<R>(R Function(T value) mapper) => ResultData(mapper(value));

  @override
  Result<T> mapError(Object Function(Object error) mapper) => this;

  @override
  T getOrElse(T fallback) => value;

  @override
  T getOrElseCompute(T Function() compute) => value;

  @override
  void ifValue(void Function(T value) callback) => callback(value);

  @override
  void ifError(void Function(Object error, StackTrace stackTrace) callback) {}

  @override
  AsyncValueLike<T> toAsyncValue() => AsyncDataLike(value);
}

/// An error result.
final class ResultError<T> extends Result<T> {
  @override
  final Object error;

  @override
  final StackTrace stackTrace;

  /// Creates an error result.
  const ResultError(this.error, this.stackTrace) : super._();

  @override
  bool get hasValue => false;

  @override
  bool get hasError => true;

  @override
  T get value => throw StateError('Cannot get value from error result: $error');

  @override
  Result<R> map<R>(R Function(T value) mapper) =>
      ResultError<R>(error, stackTrace);

  @override
  Result<T> mapError(Object Function(Object error) mapper) =>
      ResultError(mapper(error), stackTrace);

  @override
  T getOrElse(T fallback) => fallback;

  @override
  T getOrElseCompute(T Function() compute) => compute();

  @override
  void ifValue(void Function(T value) callback) {}

  @override
  void ifError(void Function(Object error, StackTrace stackTrace) callback) {
    callback(error, stackTrace);
  }

  @override
  AsyncValueLike<T> toAsyncValue() => AsyncErrorLike(error, stackTrace);
}

/// Light-weight AsyncValue-like types for Result conversion.
sealed class AsyncValueLike<T> {
  const AsyncValueLike._();
}

final class AsyncDataLike<T> extends AsyncValueLike<T> {
  final T value;
  const AsyncDataLike(this.value) : super._();
}

final class AsyncErrorLike<T> extends AsyncValueLike<T> {
  final Object error;
  final StackTrace stackTrace;
  const AsyncErrorLike(this.error, this.stackTrace) : super._();
}

/// Runs a function and catches any errors.
///
/// Returns a [Result] that contains either the value or the error.
///
/// Example:
/// ```dart
/// final result = runGuarded(() => someOperationThatMightFail());
/// result.ifValue((value) => print('Success: $value'));
/// result.ifError((error, stack) => print('Error: $error'));
/// ```
Result<T> runGuarded<T>(T Function() fn) {
  try {
    return ResultData(fn());
  } catch (e, stack) {
    return ResultError(e, stack);
  }
}

/// Runs an async function and catches any errors.
Future<Result<T>> runGuardedAsync<T>(Future<T> Function() fn) async {
  try {
    return ResultData(await fn());
  } catch (e, stack) {
    return ResultError(e, stack);
  }
}

// =============================================================================
// Retry Logic
// =============================================================================

/// Configuration for retry behavior.
///
/// Inspired by Riverpod's defaultRetry function.
class RetryConfig {
  /// Maximum number of retry attempts.
  final int maxAttempts;

  /// Base delay between retries.
  final Duration baseDelay;

  /// Maximum delay between retries.
  final Duration maxDelay;

  /// Whether to use exponential backoff.
  final bool exponentialBackoff;

  /// Jitter factor (0.0 to 1.0) to randomize delays.
  final double jitter;

  /// Function to determine if an error should be retried.
  final bool Function(Object error, int attempt)? shouldRetry;

  /// Creates a retry configuration.
  const RetryConfig({
    this.maxAttempts = 3,
    this.baseDelay = const Duration(milliseconds: 100),
    this.maxDelay = const Duration(seconds: 10),
    this.exponentialBackoff = true,
    this.jitter = 0.1,
    this.shouldRetry,
  });

  /// Default retry configuration.
  static const defaultConfig = RetryConfig();

  /// No retry configuration.
  static const noRetry = RetryConfig(maxAttempts: 0);

  /// Computes the delay for a given attempt number.
  Duration computeDelay(int attempt) {
    if (!exponentialBackoff) {
      return _applyJitter(baseDelay);
    }

    final exponentialDelay = baseDelay * math.pow(2, attempt - 1).toInt();
    final cappedDelay = Duration(
      microseconds:
          math.min(exponentialDelay.inMicroseconds, maxDelay.inMicroseconds),
    );
    return _applyJitter(cappedDelay);
  }

  Duration _applyJitter(Duration delay) {
    if (jitter <= 0) return delay;
    final random = math.Random();
    final jitterAmount =
        (delay.inMicroseconds * jitter * random.nextDouble()).round().toInt();
    return Duration(
      microseconds: delay.inMicroseconds + jitterAmount,
    );
  }
}

/// Retries a function with exponential backoff.
///
/// Similar to Riverpod's retry pattern for async providers.
///
/// Example:
/// ```dart
/// final result = await retry(
///   () => fetchDataFromServer(),
///   config: RetryConfig(maxAttempts: 3),
/// );
/// ```
Future<T> retry<T>(
  Future<T> Function() fn, {
  RetryConfig config = RetryConfig.defaultConfig,
  void Function(Object error, int attempt)? onRetry,
}) async {
  int attempt = 0;

  while (true) {
    attempt++;
    try {
      return await fn();
    } catch (e, stack) {
      final shouldRetry = config.shouldRetry?.call(e, attempt) ?? true;

      if (!shouldRetry || attempt >= config.maxAttempts) {
        // Report to error handler
        SignalErrorHandler.instance?.handleError(e, stack);
        rethrow;
      }

      onRetry?.call(e, attempt);

      final delay = config.computeDelay(attempt);
      await Future.delayed(delay);
    }
  }
}

/// Retries a synchronous function.
T retrySync<T>(
  T Function() fn, {
  RetryConfig config = RetryConfig.defaultConfig,
  void Function(Object error, int attempt)? onRetry,
}) {
  int attempt = 0;

  while (true) {
    attempt++;
    try {
      return fn();
    } catch (e, stack) {
      final shouldRetry = config.shouldRetry?.call(e, attempt) ?? true;

      if (!shouldRetry || attempt >= config.maxAttempts) {
        SignalErrorHandler.instance?.handleError(e, stack);
        rethrow;
      }

      onRetry?.call(e, attempt);
      // No delay for sync retry
    }
  }
}

// =============================================================================
// Async Signal with Error Handling
// =============================================================================

/// State of an async operation.
enum AsyncState {
  /// Initial state, not yet started.
  idle,

  /// Currently loading.
  loading,

  /// Successfully completed.
  data,

  /// Completed with error.
  error,

  /// Loading while showing previous data.
  refreshing,
}

/// A signal that handles async operations with proper error handling.
///
/// This provides a more robust alternative to simple async signals,
/// with built-in retry logic, error handling, and state management.
///
/// Example:
/// ```dart
/// final usersSignal = AsyncSignal<List<User>>.autoRefresh(
///   fetch: () => api.fetchUsers(),
///   config: RetryConfig(maxAttempts: 3),
/// );
///
/// // In widget:
/// switch (usersSignal.state) {
///   case AsyncState.loading:
///     return CircularProgressIndicator();
///   case AsyncState.data:
///     return UserList(usersSignal.data!);
///   case AsyncState.error:
///     return ErrorWidget(usersSignal.error!);
/// }
/// ```
class AsyncSignal<T> {
  /// The internal value signal.
  final Signal<T?> _value;

  /// The internal error signal.
  final Signal<Object?> _error;

  /// The internal stack trace signal.
  final Signal<StackTrace?> _stackTrace;

  /// The internal state signal.
  final Signal<AsyncState> _state;

  /// The fetch function.
  final Future<T> Function()? _fetch;

  /// The retry configuration.
  final RetryConfig _retryConfig;

  /// The effect that handles auto-refresh.
  Effect? _refreshEffect;

  /// Completer for pending operations.
  Completer<T>? _pendingOperation;

  AsyncSignal._({
    T? initialValue,
    Future<T> Function()? fetch,
    RetryConfig retryConfig = RetryConfig.defaultConfig,
    bool autoStart = false,
  })  : _value = signal(initialValue),
        _error = signal(null),
        _stackTrace = signal(null),
        _state =
            signal(initialValue != null ? AsyncState.data : AsyncState.idle),
        _fetch = fetch,
        _retryConfig = retryConfig {
    if (autoStart && _fetch != null) {
      refresh();
    }
  }

  /// Creates an async signal that fetches immediately.
  factory AsyncSignal.autoRefresh({
    required Future<T> Function() fetch,
    T? initialValue,
    RetryConfig retryConfig = RetryConfig.defaultConfig,
  }) {
    return AsyncSignal._(
      initialValue: initialValue,
      fetch: fetch,
      retryConfig: retryConfig,
      autoStart: true,
    );
  }

  /// Creates an async signal that doesn't fetch until [refresh] is called.
  factory AsyncSignal.lazy({
    required Future<T> Function() fetch,
    T? initialValue,
    RetryConfig retryConfig = RetryConfig.defaultConfig,
  }) {
    return AsyncSignal._(
      initialValue: initialValue,
      fetch: fetch,
      retryConfig: retryConfig,
      autoStart: false,
    );
  }

  /// Creates an async signal from a future.
  factory AsyncSignal.fromFuture(
    Future<T> future, {
    T? initialValue,
  }) {
    final sig = AsyncSignal<T>._(initialValue: initialValue);
    sig._handleFuture(future);
    return sig;
  }

  /// Creates an async signal from a stream.
  factory AsyncSignal.fromStream(
    Stream<T> stream, {
    T? initialValue,
  }) {
    final sig = AsyncSignal<T>._(initialValue: initialValue);
    sig._handleStream(stream);
    return sig;
  }

  /// The current state.
  AsyncState get state => _state.value;

  /// Whether currently loading.
  bool get isLoading =>
      _state.value == AsyncState.loading ||
      _state.value == AsyncState.refreshing;

  /// Whether has data.
  bool get hasData => _value.value != null;

  /// Whether has error.
  bool get hasError => _error.value != null;

  /// The current data, or null.
  T? get data => _value.value;

  /// The current error, or null.
  Object? get error => _error.value;

  /// The current stack trace, or null.
  StackTrace? get stackTrace => _stackTrace.value;

  /// The state signal for watching.
  Signal<AsyncState> get stateSignal => _state;

  /// The value signal for watching.
  Signal<T?> get valueSignal => _value;

  /// The error signal for watching.
  Signal<Object?> get errorSignal => _error;

  /// Refreshes the data.
  Future<T> refresh() async {
    if (_fetch == null) {
      throw StateError('Cannot refresh: no fetch function provided');
    }

    // If already loading, return pending operation
    if (_pendingOperation != null) {
      return _pendingOperation!.future;
    }

    final completer = Completer<T>();
    _pendingOperation = completer;

    // Set state based on whether we have existing data
    if (_value.value != null) {
      _state.value = AsyncState.refreshing;
    } else {
      _state.value = AsyncState.loading;
    }

    try {
      final result = await retry(
        _fetch,
        config: _retryConfig,
      );

      _value.value = result;
      _error.value = null;
      _stackTrace.value = null;
      _state.value = AsyncState.data;
      completer.complete(result);
    } catch (e, stack) {
      _error.value = e;
      _stackTrace.value = stack;
      _state.value = AsyncState.error;
      completer.completeError(e, stack);
    } finally {
      _pendingOperation = null;
    }

    // Return the completer's future so errors are properly propagated
    return completer.future;
  }

  /// Sets the value directly.
  void setValue(T value) {
    _value.value = value;
    _error.value = null;
    _stackTrace.value = null;
    _state.value = AsyncState.data;
  }

  /// Sets an error directly.
  void setError(Object error, [StackTrace? stackTrace]) {
    _error.value = error;
    _stackTrace.value = stackTrace ?? StackTrace.current;
    _state.value = AsyncState.error;
  }

  /// Resets to initial state.
  void reset() {
    _value.value = null;
    _error.value = null;
    _stackTrace.value = null;
    _state.value = AsyncState.idle;
  }

  void _handleFuture(Future<T> future) {
    _state.value = AsyncState.loading;
    future.then((value) {
      _value.value = value;
      _state.value = AsyncState.data;
    }).catchError((Object e, StackTrace stack) {
      _error.value = e;
      _stackTrace.value = stack;
      _state.value = AsyncState.error;
    });
  }

  void _handleStream(Stream<T> stream) {
    _state.value = AsyncState.loading;
    stream.listen(
      (value) {
        _value.value = value;
        _state.value = AsyncState.data;
      },
      onError: (Object e, StackTrace stack) {
        _error.value = e;
        _stackTrace.value = stack;
        _state.value = AsyncState.error;
      },
    );
  }

  /// Disposes the async signal.
  void dispose() {
    _refreshEffect?.stop();
    _refreshEffect = null;
  }
}

// =============================================================================
// Extensions
// =============================================================================

/// Extension to add error-safe operations to Signal.
extension SafeSignalExtension<T> on Signal<T> {
  /// Tries to read the value, returning a Result.
  Result<T> tryRead() {
    return runGuarded(() => peek());
  }

  /// Tries to update the value, returning a Result.
  Result<void> tryUpdate(T newValue) {
    return runGuarded(() => value = newValue);
  }

  /// Updates the value with error handling.
  void updateSafe(T newValue, {void Function(Object error)? onError}) {
    try {
      value = newValue;
    } catch (e, stack) {
      onError?.call(e);
      SignalErrorHandler.instance?.handleError(e, stack);
    }
  }
}

/// Extension to add error-safe operations to Computed.
extension SafeComputedExtension<T> on Computed<T> {
  /// Tries to read the value, returning a Result.
  Result<T> tryRead() {
    return runGuarded(() => value);
  }
}
