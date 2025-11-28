import 'package:flutter/foundation.dart';
import 'package:void_signals/void_signals.dart';

import 'debug_service.dart';

/// An observer that listens to signal lifecycle events.
///
/// Similar to Riverpod's ProviderObserver, this class allows you to
/// monitor signal creation, updates, and disposal for debugging,
/// logging, or analytics purposes.
///
/// ## Usage
///
/// ```dart
/// class MyObserver extends SignalObserver {
///   @override
///   void didAddSignal(Signal signal, String id, Object? value) {
///     print('Signal added: $id = $value');
///   }
///
///   @override
///   void didUpdateSignal(Signal signal, String id, Object? previousValue, Object? newValue) {
///     print('Signal updated: $id: $previousValue -> $newValue');
///   }
/// }
///
/// void main() {
///   VoidSignalsDebugService.addObserver(MyObserver());
///   runApp(MyApp());
/// }
/// ```
abstract class SignalObserver {
  /// Called when a signal is first tracked/added.
  ///
  /// - [signal] is the signal that was added
  /// - [id] is the unique tracking ID
  /// - [value] is the initial value of the signal
  @pragma('vm:prefer-inline')
  void didAddSignal(Signal signal, String id, Object? value) {}

  /// Called when a signal's value changes.
  ///
  /// - [signal] is the signal that was updated
  /// - [id] is the tracking ID
  /// - [previousValue] is the previous value (null if unknown)
  /// - [newValue] is the new value
  @pragma('vm:prefer-inline')
  void didUpdateSignal(
    Signal signal,
    String id,
    Object? previousValue,
    Object? newValue,
  ) {}

  /// Called when a signal is disposed/untracked.
  ///
  /// - [signal] is the signal that was disposed
  /// - [id] is the tracking ID
  @pragma('vm:prefer-inline')
  void didDisposeSignal(Signal signal, String id) {}

  /// Called when a computed is first tracked/added.
  ///
  /// - [computed] is the computed that was added
  /// - [id] is the unique tracking ID
  /// - [value] is the initial computed value
  @pragma('vm:prefer-inline')
  void didAddComputed(Computed computed, String id, Object? value) {}

  /// Called when a computed's value changes.
  ///
  /// - [computed] is the computed that was updated
  /// - [id] is the tracking ID
  /// - [previousValue] is the previous value (null if unknown)
  /// - [newValue] is the new value
  @pragma('vm:prefer-inline')
  void didUpdateComputed(
    Computed computed,
    String id,
    Object? previousValue,
    Object? newValue,
  ) {}

  /// Called when a computed is disposed/untracked.
  ///
  /// - [computed] is the computed that was disposed
  /// - [id] is the tracking ID
  @pragma('vm:prefer-inline')
  void didDisposeComputed(Computed computed, String id) {}

  /// Called when an effect is first tracked/added.
  ///
  /// - [effect] is the effect that was added
  /// - [id] is the unique tracking ID
  @pragma('vm:prefer-inline')
  void didAddEffect(Effect effect, String id) {}

  /// Called when an effect runs.
  ///
  /// - [effect] is the effect that ran
  /// - [id] is the tracking ID
  @pragma('vm:prefer-inline')
  void didRunEffect(Effect effect, String id) {}

  /// Called when an effect is disposed/stopped.
  ///
  /// - [effect] is the effect that was disposed
  /// - [id] is the tracking ID
  @pragma('vm:prefer-inline')
  void didDisposeEffect(Effect effect, String id) {}

  /// Called when a synchronous signal operation throws an error.
  ///
  /// - [signal] is the signal that failed (may be null for computed/effect errors)
  /// - [id] is the tracking ID
  /// - [error] is the error that was thrown
  /// - [stackTrace] is the stack trace
  @pragma('vm:prefer-inline')
  @pragma('vm:notify-debugger-on-exception')
  void signalDidFail(
    Object? signal,
    String id,
    Object error,
    StackTrace stackTrace,
  ) {}
}

/// A simple logging observer for debugging.
///
/// This observer prints all signal events to the debug console.
///
/// ## Usage
///
/// ```dart
/// void main() {
///   if (kDebugMode) {
///     VoidSignalsDebugService.addObserver(LoggingSignalObserver());
///   }
///   runApp(MyApp());
/// }
/// ```
class LoggingSignalObserver extends SignalObserver {
  /// Whether to log signal additions.
  final bool logAdded;

  /// Whether to log signal updates.
  final bool logUpdated;

  /// Whether to log signal disposals.
  final bool logDisposed;

  /// Whether to log effect runs.
  final bool logEffectRuns;

  /// Whether to log errors.
  final bool logErrors;

  /// Creates a logging observer with configurable options.
  LoggingSignalObserver({
    this.logAdded = true,
    this.logUpdated = true,
    this.logDisposed = true,
    this.logEffectRuns = false,
    this.logErrors = true,
  });

  @override
  void didAddSignal(Signal signal, String id, Object? value) {
    if (logAdded) {
      debugPrint('[VoidSignals] Signal added: $id = $value');
    }
  }

  @override
  void didUpdateSignal(
    Signal signal,
    String id,
    Object? previousValue,
    Object? newValue,
  ) {
    if (logUpdated) {
      debugPrint(
          '[VoidSignals] Signal updated: $id: $previousValue -> $newValue');
    }
  }

  @override
  void didDisposeSignal(Signal signal, String id) {
    if (logDisposed) {
      debugPrint('[VoidSignals] Signal disposed: $id');
    }
  }

  @override
  void didAddComputed(Computed computed, String id, Object? value) {
    if (logAdded) {
      debugPrint('[VoidSignals] Computed added: $id = $value');
    }
  }

  @override
  void didUpdateComputed(
    Computed computed,
    String id,
    Object? previousValue,
    Object? newValue,
  ) {
    if (logUpdated) {
      debugPrint(
          '[VoidSignals] Computed updated: $id: $previousValue -> $newValue');
    }
  }

  @override
  void didDisposeComputed(Computed computed, String id) {
    if (logDisposed) {
      debugPrint('[VoidSignals] Computed disposed: $id');
    }
  }

  @override
  void didAddEffect(Effect effect, String id) {
    if (logAdded) {
      debugPrint('[VoidSignals] Effect added: $id');
    }
  }

  @override
  void didRunEffect(Effect effect, String id) {
    if (logEffectRuns) {
      debugPrint('[VoidSignals] Effect ran: $id');
    }
  }

  @override
  void didDisposeEffect(Effect effect, String id) {
    if (logDisposed) {
      debugPrint('[VoidSignals] Effect disposed: $id');
    }
  }

  @override
  @pragma('vm:notify-debugger-on-exception')
  void signalDidFail(
    Object? signal,
    String id,
    Object error,
    StackTrace stackTrace,
  ) {
    if (logErrors) {
      debugPrint('[VoidSignals] Error in $id: $error');
      debugPrint(stackTrace.toString());
    }
  }
}

/// An internal DevTools observer that posts events to DevTools.
class _DevToolsObserver extends SignalObserver {
  @override
  void didAddSignal(Signal signal, String id, Object? value) {
    VoidSignalsDebugService.postEvent('signal_added', {
      'id': id,
      'value': _valueToString(value),
      'type': value.runtimeType.toString(),
    });
  }

  @override
  void didUpdateSignal(
    Signal signal,
    String id,
    Object? previousValue,
    Object? newValue,
  ) {
    VoidSignalsDebugService.postEvent('signal_updated', {
      'id': id,
      'previousValue': _valueToString(previousValue),
      'newValue': _valueToString(newValue),
    });
  }

  @override
  void didDisposeSignal(Signal signal, String id) {
    VoidSignalsDebugService.postEvent('signal_disposed', {'id': id});
  }

  @override
  void didAddComputed(Computed computed, String id, Object? value) {
    VoidSignalsDebugService.postEvent('computed_added', {
      'id': id,
      'value': _valueToString(value),
      'type': value.runtimeType.toString(),
    });
  }

  @override
  void didUpdateComputed(
    Computed computed,
    String id,
    Object? previousValue,
    Object? newValue,
  ) {
    VoidSignalsDebugService.postEvent('computed_updated', {
      'id': id,
      'previousValue': _valueToString(previousValue),
      'newValue': _valueToString(newValue),
    });
  }

  @override
  void didDisposeComputed(Computed computed, String id) {
    VoidSignalsDebugService.postEvent('computed_disposed', {'id': id});
  }

  @override
  void didAddEffect(Effect effect, String id) {
    VoidSignalsDebugService.postEvent('effect_added', {'id': id});
  }

  @override
  void didRunEffect(Effect effect, String id) {
    VoidSignalsDebugService.postEvent('effect_ran', {'id': id});
  }

  @override
  void didDisposeEffect(Effect effect, String id) {
    VoidSignalsDebugService.postEvent('effect_disposed', {'id': id});
  }

  @override
  @pragma('vm:notify-debugger-on-exception')
  void signalDidFail(
    Object? signal,
    String id,
    Object error,
    StackTrace stackTrace,
  ) {
    VoidSignalsDebugService.postEvent('signal_error', {
      'id': id,
      'error': error.toString(),
      'stackTrace': stackTrace.toString(),
    });
  }

  String _valueToString(dynamic value) {
    if (value == null) return 'null';
    if (value is String) return '"$value"';
    if (value is List || value is Map) {
      try {
        return value.toString();
      } catch (e) {
        return '[${value.runtimeType}]';
      }
    }
    return value.toString();
  }
}

/// Get the internal DevTools observer.
SignalObserver get devToolsObserver => _DevToolsObserver();
