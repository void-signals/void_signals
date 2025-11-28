import 'api.dart';

// =============================================================================
// Lifecycle Management
//
// Provides production-grade lifecycle hooks and disposal management inspired
// by Riverpod's robust patterns.
// =============================================================================

/// A callback that can be cancelled.
///
/// This is used for lifecycle callbacks like [onDispose], [onCancel], etc.
typedef DisposeCallback = void Function();

/// A link that keeps an effect or signal alive, preventing automatic disposal.
///
/// Similar to Riverpod's KeepAliveLink, this provides a way to prevent
/// automatic disposal of signals/effects until explicitly closed.
///
/// Example:
/// ```dart
/// final sig = signal(0);
/// final keepAlive = sig.keepAlive();
///
/// // Later, when you want to allow disposal:
/// keepAlive.close();
/// ```
class KeepAliveLink {
  final DisposeCallback _close;
  bool _closed = false;

  KeepAliveLink._(this._close);

  /// Whether this keep-alive link has been closed.
  bool get closed => _closed;

  /// Closes this keep-alive link, allowing the associated resource
  /// to be disposed when no longer needed.
  ///
  /// It is safe to call this method multiple times.
  @pragma('vm:prefer-inline')
  void close() {
    if (_closed) return;
    _closed = true;
    _close();
  }
}

/// Represents a subscription to a reactive value.
///
/// This provides pause/resume capabilities and lifecycle management
/// similar to Riverpod's ProviderSubscription.
///
/// Example:
/// ```dart
/// final count = signal(0);
/// final sub = count.subscribe((value) {
///   print('Value: $value');
/// });
///
/// sub.pause();   // Temporarily stop receiving updates
/// sub.resume();  // Resume receiving updates
/// sub.close();   // Stop listening permanently
/// ```
abstract class SignalSubscription<T> {
  /// Whether the subscription is closed.
  bool get closed;

  /// Whether the subscription is paused.
  bool get isPaused;

  /// Pauses the subscription.
  ///
  /// While paused, updates are queued and the last update will be
  /// delivered when resumed.
  void pause();

  /// Resumes the subscription.
  ///
  /// If any updates occurred while paused, the last update will be delivered.
  void resume();

  /// Reads the current value without creating a dependency.
  T read();

  /// Closes the subscription.
  ///
  /// It is safe to call this method multiple times.
  void close();
}

/// A mixin that provides lifecycle callbacks for reactive nodes.
///
/// This enables registering callbacks that run when the reactive
/// node is disposed or when listener count changes.
mixin SignalLifecycle {
  final List<DisposeCallback> _onDisposeCallbacks = [];
  final List<void Function()> _onAddListenerCallbacks = [];
  final List<void Function()> _onRemoveListenerCallbacks = [];
  final List<void Function()> _onCancelCallbacks = [];
  final List<void Function()> _onResumeCallbacks = [];
  final List<KeepAliveLink> _keepAliveLinks = [];

  bool _disposed = false;

  /// Whether this reactive node has been disposed.
  bool get disposed => _disposed;

  /// Registers a callback to be called when this node is disposed.
  ///
  /// The callback will be called synchronously when [dispose] is called.
  ///
  /// Example:
  /// ```dart
  /// final sig = signal(0);
  /// sig.onDispose(() {
  ///   print('Signal disposed');
  /// });
  /// ```
  @pragma('vm:prefer-inline')
  void onDispose(DisposeCallback callback) {
    _assertNotDisposed();
    _onDisposeCallbacks.add(callback);
  }

  /// Registers a callback to be called when a listener is added.
  ///
  /// This is useful for lazy initialization or tracking.
  @pragma('vm:prefer-inline')
  void onAddListener(void Function() callback) {
    _assertNotDisposed();
    _onAddListenerCallbacks.add(callback);
  }

  /// Registers a callback to be called when a listener is removed.
  @pragma('vm:prefer-inline')
  void onRemoveListener(void Function() callback) {
    _assertNotDisposed();
    _onRemoveListenerCallbacks.add(callback);
  }

  /// Registers a callback to be called when all listeners are paused/removed.
  ///
  /// This is useful for pausing expensive operations like streams or timers.
  @pragma('vm:prefer-inline')
  void onCancel(void Function() callback) {
    _assertNotDisposed();
    _onCancelCallbacks.add(callback);
  }

  /// Registers a callback to be called when listeners resume after being
  /// cancelled.
  @pragma('vm:prefer-inline')
  void onResume(void Function() callback) {
    _assertNotDisposed();
    _onResumeCallbacks.add(callback);
  }

  /// Creates a keep-alive link that prevents this node from being disposed.
  ///
  /// Returns a [KeepAliveLink] that can be closed when you want to allow
  /// disposal again.
  @pragma('vm:prefer-inline')
  KeepAliveLink keepAlive() {
    _assertNotDisposed();
    late KeepAliveLink link;
    link = KeepAliveLink._(() {
      _keepAliveLinks.remove(link);
    });
    _keepAliveLinks.add(link);
    return link;
  }

  /// Whether this node is being kept alive by any keep-alive links.
  bool get hasKeepAliveLinks => _keepAliveLinks.isNotEmpty;

  /// Notifies listeners that a new listener was added.
  @pragma('vm:prefer-inline')
  void notifyAddListener() {
    for (final callback in _onAddListenerCallbacks) {
      _runGuarded(callback);
    }
  }

  /// Notifies listeners that a listener was removed.
  @pragma('vm:prefer-inline')
  void notifyRemoveListener() {
    for (final callback in _onRemoveListenerCallbacks) {
      _runGuarded(callback);
    }
  }

  /// Notifies that all listeners have been cancelled.
  @pragma('vm:prefer-inline')
  void notifyCancel() {
    for (final callback in _onCancelCallbacks) {
      _runGuarded(callback);
    }
  }

  /// Notifies that listeners have resumed.
  @pragma('vm:prefer-inline')
  void notifyResume() {
    for (final callback in _onResumeCallbacks) {
      _runGuarded(callback);
    }
  }

  /// Disposes this node and calls all dispose callbacks.
  @pragma('vm:prefer-inline')
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    // Close all keep-alive links
    for (final link in _keepAliveLinks.toList()) {
      link.close();
    }
    _keepAliveLinks.clear();

    // Run dispose callbacks in reverse order (LIFO)
    for (var i = _onDisposeCallbacks.length - 1; i >= 0; i--) {
      _runGuarded(_onDisposeCallbacks[i]);
    }
    _onDisposeCallbacks.clear();
    _onAddListenerCallbacks.clear();
    _onRemoveListenerCallbacks.clear();
    _onCancelCallbacks.clear();
    _onResumeCallbacks.clear();
  }

  void _assertNotDisposed() {
    if (_disposed) {
      throw StateError(
        'Cannot use a disposed reactive node. '
        'Make sure to check "disposed" property before using it.',
      );
    }
  }

  /// Runs a callback safely, catching and reporting any errors.
  @pragma('vm:prefer-inline')
  static void _runGuarded(void Function() callback) {
    try {
      callback();
    } catch (e, stack) {
      // In production, errors in lifecycle callbacks should not crash the app
      // They are reported to the error handler if one is set
      SignalErrorHandler.instance?.handleError(e, stack);
    }
  }
}

/// Global error handler for signal operations.
///
/// This provides a centralized way to handle errors in reactive operations,
/// similar to Riverpod's error handling.
class SignalErrorHandler {
  static SignalErrorHandler? _instance;

  /// The global error handler instance.
  static SignalErrorHandler? get instance => _instance;

  final void Function(Object error, StackTrace stackTrace) _onError;

  SignalErrorHandler._(this._onError);

  /// Sets the global error handler.
  ///
  /// Example:
  /// ```dart
  /// SignalErrorHandler.setHandler((error, stack) {
  ///   print('Signal error: $error');
  ///   // Log to crash reporting service
  /// });
  /// ```
  static void setHandler(
      void Function(Object error, StackTrace stackTrace) handler) {
    _instance = SignalErrorHandler._(handler);
  }

  /// Clears the global error handler.
  static void clearHandler() {
    _instance = null;
  }

  /// Handles an error.
  @pragma('vm:prefer-inline')
  void handleError(Object error, StackTrace stackTrace) {
    _onError(error, stackTrace);
  }
}

/// A controller for managing reactive subscriptions.
///
/// This is similar to Riverpod's ProviderContainer but focused on
/// subscription management.
class SubscriptionController {
  final List<SignalSubscription> _subscriptions = [];
  bool _disposed = false;

  /// Whether this controller has been disposed.
  bool get disposed => _disposed;

  /// Adds a subscription to be managed by this controller.
  T add<T extends SignalSubscription>(T subscription) {
    if (_disposed) {
      throw StateError('Cannot add subscription to disposed controller');
    }
    _subscriptions.add(subscription);
    return subscription;
  }

  /// Pauses all managed subscriptions.
  void pauseAll() {
    for (final sub in _subscriptions) {
      if (!sub.closed) sub.pause();
    }
  }

  /// Resumes all managed subscriptions.
  void resumeAll() {
    for (final sub in _subscriptions) {
      if (!sub.closed) sub.resume();
    }
  }

  /// Closes all managed subscriptions and disposes this controller.
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    for (final sub in _subscriptions.toList()) {
      sub.close();
    }
    _subscriptions.clear();
  }
}

/// Implementation of SignalSubscription for Signal values.
class SignalSubscriptionImpl<T> implements SignalSubscription<T> {
  final Signal<T> _signal;
  final Effect _effect;
  final void Function(T? previous, T current)? _listener;
  final void Function(Object error, StackTrace stackTrace)? _onError;

  bool _closed = false;
  int _pauseCount = 0;
  (T?, T)? _missedUpdate;

  SignalSubscriptionImpl({
    required Signal<T> signal,
    required Effect effect,
    void Function(T? previous, T current)? listener,
    void Function(Object error, StackTrace stackTrace)? onError,
  })  : _signal = signal,
        _effect = effect,
        _listener = listener,
        _onError = onError;

  @override
  bool get closed => _closed;

  @override
  bool get isPaused => _pauseCount > 0;

  @override
  void pause() {
    if (_closed) return;
    _pauseCount++;
  }

  @override
  void resume() {
    if (_closed) return;
    if (_pauseCount > 0) {
      _pauseCount--;
      if (_pauseCount == 0 && _missedUpdate != null) {
        final (prev, current) = _missedUpdate!;
        _missedUpdate = null;
        _notifyListener(prev, current);
      }
    }
  }

  @override
  T read() {
    if (_closed) {
      throw StateError('Cannot read from closed subscription');
    }
    return _signal.peek();
  }

  @override
  void close() {
    if (_closed) return;
    _closed = true;
    _effect.stop();
    _missedUpdate = null;
  }

  /// Called internally when the signal value changes.
  void notifyUpdate(T? previous, T current) {
    if (_closed) return;

    if (isPaused) {
      _missedUpdate = (previous, current);
      return;
    }

    _notifyListener(previous, current);
  }

  void _notifyListener(T? previous, T current) {
    final listener = _listener;
    if (listener != null) {
      try {
        listener(previous, current);
      } catch (e, stack) {
        final onError = _onError;
        if (onError != null) {
          onError(e, stack);
        } else {
          SignalErrorHandler.instance?.handleError(e, stack);
        }
      }
    }
  }
}

// =============================================================================
// Signal Extensions for Lifecycle
// =============================================================================

/// Extension to add subscription capabilities to Signal.
extension SignalSubscriptionExtension<T> on Signal<T> {
  /// Creates a subscription that listens to this signal.
  ///
  /// The [listener] is called immediately with the current value (if
  /// [fireImmediately] is true) and whenever the value changes.
  ///
  /// Example:
  /// ```dart
  /// final count = signal(0);
  /// final sub = count.subscribe(
  ///   (previous, current) => print('Changed: $previous -> $current'),
  ///   fireImmediately: true,
  /// );
  ///
  /// count.value = 1;  // Prints: Changed: 0 -> 1
  /// sub.close();
  /// ```
  SignalSubscription<T> subscribe(
    void Function(T? previous, T current) listener, {
    void Function(Object error, StackTrace stackTrace)? onError,
    bool fireImmediately = false,
  }) {
    T? lastValue = peek();
    bool isInitialized = false;

    late SignalSubscriptionImpl<T> subscription;

    final eff = effect(() {
      final newValue = value;
      // Skip the first run during initialization
      if (!isInitialized) return;
      if (!subscription.closed) {
        subscription.notifyUpdate(lastValue, newValue);
        lastValue = newValue;
      }
    });

    subscription = SignalSubscriptionImpl<T>(
      signal: this,
      effect: eff,
      listener: listener,
      onError: onError,
    );

    // Mark as initialized after subscription is created
    isInitialized = true;

    if (fireImmediately) {
      subscription.notifyUpdate(null, peek());
    }

    return subscription;
  }
}

/// Extension to add subscription capabilities to Computed.
extension ComputedSubscriptionExtension<T> on Computed<T> {
  /// Creates a subscription that listens to this computed value.
  SignalSubscription<T> subscribe(
    void Function(T? previous, T current) listener, {
    void Function(Object error, StackTrace stackTrace)? onError,
    bool fireImmediately = false,
  }) {
    // Create a wrapper signal for the computed value
    final wrapper = signal<T>(value);
    T? lastValue = peek();
    bool isInitialized = false;

    // Create an effect that updates the wrapper when computed changes
    final eff = effect(() {
      final newValue = value;
      // Skip the first run during initialization
      if (!isInitialized) return;
      if (lastValue != newValue) {
        final prev = lastValue;
        lastValue = newValue;
        wrapper.value = newValue;

        try {
          listener(prev, newValue);
        } catch (e, stack) {
          if (onError != null) {
            onError(e, stack);
          } else {
            SignalErrorHandler.instance?.handleError(e, stack);
          }
        }
      }
    });

    final subscription = SignalSubscriptionImpl<T>(
      signal: wrapper,
      effect: eff,
      listener: null, // Already handled in effect
      onError: onError,
    );

    // Mark as initialized after subscription is created
    isInitialized = true;

    if (fireImmediately && peek() != null) {
      listener(null, peek()!);
    }

    return subscription;
  }
}
