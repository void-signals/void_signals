import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import 'debug_tracker.dart';
import 'signal_observer.dart';

/// Debug service that exposes signal information to DevTools.
///
/// This service registers VM service extensions that allow the DevTools
/// extension to query signal state information. It also supports
/// observer pattern similar to Riverpod's ProviderObserver.
///
/// ## Usage
///
/// Call [VoidSignalsDebugService.initialize] in your app's main function
/// to enable DevTools integration:
///
/// ```dart
/// void main() {
///   VoidSignalsDebugService.initialize();
///   // Optionally add observers for logging/analytics
///   VoidSignalsDebugService.addObserver(LoggingSignalObserver());
///   runApp(MyApp());
/// }
/// ```
class VoidSignalsDebugService {
  static VoidSignalsDebugService? _instance;
  static SignalDebugTracker? _tracker;
  static final List<SignalObserver> _observers = [];
  static bool _devToolsObserverAdded = false;

  VoidSignalsDebugService._();

  /// The global debug tracker instance.
  @pragma('vm:prefer-inline')
  static SignalDebugTracker get tracker {
    _tracker ??= SignalDebugTracker();
    return _tracker!;
  }

  /// Add an observer to receive signal lifecycle events.
  ///
  /// Observers are notified of signal additions, updates, and disposals.
  /// This is similar to Riverpod's ProviderObserver pattern.
  ///
  /// ```dart
  /// VoidSignalsDebugService.addObserver(LoggingSignalObserver());
  /// ```
  static void addObserver(SignalObserver observer) {
    if (!_observers.contains(observer)) {
      _observers.add(observer);
    }
  }

  /// Remove an observer.
  static void removeObserver(SignalObserver observer) {
    _observers.remove(observer);
  }

  /// Get all registered observers.
  static List<SignalObserver> get observers => List.unmodifiable(_observers);

  /// Initialize the debug service.
  ///
  /// This registers VM service extensions for DevTools communication.
  /// Only has effect in debug mode.
  static void initialize() {
    if (!kDebugMode) return;
    if (_instance != null) return;

    _instance = VoidSignalsDebugService._();
    _instance!._registerExtensions();

    // Add the internal DevTools observer for postEvent
    if (!_devToolsObserverAdded) {
      _observers.add(devToolsObserver);
      _devToolsObserverAdded = true;
    }
  }

  void _registerExtensions() {
    // Register the service extension for getting signals info
    developer.registerExtension(
      'ext.void_signals.getSignalsInfo',
      _handleGetSignalsInfo,
    );

    // Register extension for getting a specific signal
    developer.registerExtension(
      'ext.void_signals.getSignal',
      _handleGetSignal,
    );

    // Register extension for setting a signal value
    developer.registerExtension(
      'ext.void_signals.setSignalValue',
      _handleSetSignalValue,
    );

    // Register extension for subscribing to real-time updates
    developer.registerExtension(
      'ext.void_signals.subscribe',
      _handleSubscribe,
    );

    debugPrint('VoidSignals DevTools service initialized');
  }

  /// Post an event to DevTools for real-time updates.
  ///
  /// This uses developer.postEvent to send events to the DevTools extension.
  @pragma('vm:prefer-inline')
  static void postEvent(String eventKind, Map<String, dynamic> eventData) {
    if (!kDebugMode) return;
    try {
      developer.postEvent('void_signals.$eventKind', eventData);
    } catch (e) {
      // Silently ignore if DevTools is not connected
    }
  }

  /// Notify all observers that a signal was added.
  @pragma('vm:prefer-inline')
  static void notifySignalAdded(dynamic signal, String id, Object? value) {
    if (!kDebugMode) return;
    for (final observer in _observers) {
      try {
        observer.didAddSignal(signal, id, value);
      } catch (e, stack) {
        _handleObserverError(observer, e, stack);
      }
    }
  }

  /// Notify all observers that a signal was updated.
  @pragma('vm:prefer-inline')
  static void notifySignalUpdated(
    dynamic signal,
    String id,
    Object? previousValue,
    Object? newValue,
  ) {
    if (!kDebugMode) return;
    for (final observer in _observers) {
      try {
        observer.didUpdateSignal(signal, id, previousValue, newValue);
      } catch (e, stack) {
        _handleObserverError(observer, e, stack);
      }
    }
  }

  /// Notify all observers that a signal was disposed.
  @pragma('vm:prefer-inline')
  static void notifySignalDisposed(dynamic signal, String id) {
    if (!kDebugMode) return;
    for (final observer in _observers) {
      try {
        observer.didDisposeSignal(signal, id);
      } catch (e, stack) {
        _handleObserverError(observer, e, stack);
      }
    }
  }

  /// Notify all observers that a computed was added.
  @pragma('vm:prefer-inline')
  static void notifyComputedAdded(dynamic computed, String id, Object? value) {
    if (!kDebugMode) return;
    for (final observer in _observers) {
      try {
        observer.didAddComputed(computed, id, value);
      } catch (e, stack) {
        _handleObserverError(observer, e, stack);
      }
    }
  }

  /// Notify all observers that a computed was updated.
  @pragma('vm:prefer-inline')
  static void notifyComputedUpdated(
    dynamic computed,
    String id,
    Object? previousValue,
    Object? newValue,
  ) {
    if (!kDebugMode) return;
    for (final observer in _observers) {
      try {
        observer.didUpdateComputed(computed, id, previousValue, newValue);
      } catch (e, stack) {
        _handleObserverError(observer, e, stack);
      }
    }
  }

  /// Notify all observers that a computed was disposed.
  @pragma('vm:prefer-inline')
  static void notifyComputedDisposed(dynamic computed, String id) {
    if (!kDebugMode) return;
    for (final observer in _observers) {
      try {
        observer.didDisposeComputed(computed, id);
      } catch (e, stack) {
        _handleObserverError(observer, e, stack);
      }
    }
  }

  /// Notify all observers that an effect was added.
  @pragma('vm:prefer-inline')
  static void notifyEffectAdded(dynamic effect, String id) {
    if (!kDebugMode) return;
    for (final observer in _observers) {
      try {
        observer.didAddEffect(effect, id);
      } catch (e, stack) {
        _handleObserverError(observer, e, stack);
      }
    }
  }

  /// Notify all observers that an effect ran.
  @pragma('vm:prefer-inline')
  static void notifyEffectRan(dynamic effect, String id) {
    if (!kDebugMode) return;
    for (final observer in _observers) {
      try {
        observer.didRunEffect(effect, id);
      } catch (e, stack) {
        _handleObserverError(observer, e, stack);
      }
    }
  }

  /// Notify all observers that an effect was disposed.
  @pragma('vm:prefer-inline')
  static void notifyEffectDisposed(dynamic effect, String id) {
    if (!kDebugMode) return;
    for (final observer in _observers) {
      try {
        observer.didDisposeEffect(effect, id);
      } catch (e, stack) {
        _handleObserverError(observer, e, stack);
      }
    }
  }

  /// Notify all observers that an error occurred.
  @pragma('vm:prefer-inline')
  @pragma('vm:notify-debugger-on-exception')
  static void notifyError(
    Object? signal,
    String id,
    Object error,
    StackTrace stackTrace,
  ) {
    if (!kDebugMode) return;
    for (final observer in _observers) {
      try {
        observer.signalDidFail(signal, id, error, stackTrace);
      } catch (e, stack) {
        _handleObserverError(observer, e, stack);
      }
    }
  }

  static void _handleObserverError(
    SignalObserver observer,
    Object error,
    StackTrace stackTrace,
  ) {
    debugPrint(
        '[VoidSignals] Observer error in ${observer.runtimeType}: $error');
  }

  Future<developer.ServiceExtensionResponse> _handleSubscribe(
    String method,
    Map<String, String> parameters,
  ) async {
    // DevTools can call this to indicate it's ready to receive events
    return developer.ServiceExtensionResponse.result(
      '{"subscribed": true}',
    );
  }

  Future<developer.ServiceExtensionResponse> _handleGetSignalsInfo(
    String method,
    Map<String, String> parameters,
  ) async {
    try {
      final data = tracker.toJson();
      return developer.ServiceExtensionResponse.result(
        _jsonEncode(data),
      );
    } catch (e, stack) {
      return developer.ServiceExtensionResponse.error(
        developer.ServiceExtensionResponse.extensionError,
        'Failed to get signals info: $e\n$stack',
      );
    }
  }

  Future<developer.ServiceExtensionResponse> _handleGetSignal(
    String method,
    Map<String, String> parameters,
  ) async {
    try {
      final id = parameters['id'];
      if (id == null) {
        return developer.ServiceExtensionResponse.error(
          developer.ServiceExtensionResponse.invalidParams,
          'Missing required parameter: id',
        );
      }

      final signal = tracker.getSignalById(id);
      if (signal == null) {
        return developer.ServiceExtensionResponse.error(
          developer.ServiceExtensionResponse.extensionError,
          'Signal not found: $id',
        );
      }

      return developer.ServiceExtensionResponse.result(
        _jsonEncode(signal),
      );
    } catch (e, stack) {
      return developer.ServiceExtensionResponse.error(
        developer.ServiceExtensionResponse.extensionError,
        'Failed to get signal: $e\n$stack',
      );
    }
  }

  Future<developer.ServiceExtensionResponse> _handleSetSignalValue(
    String method,
    Map<String, String> parameters,
  ) async {
    try {
      final id = parameters['id'];
      final value = parameters['value'];

      if (id == null || value == null) {
        return developer.ServiceExtensionResponse.error(
          developer.ServiceExtensionResponse.invalidParams,
          'Missing required parameters: id, value',
        );
      }

      final success = tracker.setSignalValue(id, value);
      if (!success) {
        return developer.ServiceExtensionResponse.error(
          developer.ServiceExtensionResponse.extensionError,
          'Failed to set signal value: signal not found or type mismatch',
        );
      }

      return developer.ServiceExtensionResponse.result(
        '{"success": true}',
      );
    } catch (e, stack) {
      return developer.ServiceExtensionResponse.error(
        developer.ServiceExtensionResponse.extensionError,
        'Failed to set signal value: $e\n$stack',
      );
    }
  }

  String _jsonEncode(Map<String, dynamic> data) {
    // Simple JSON encoder that handles basic types
    final buffer = StringBuffer();
    _writeJson(buffer, data);
    return buffer.toString();
  }

  void _writeJson(StringBuffer buffer, dynamic value) {
    if (value == null) {
      buffer.write('null');
    } else if (value is bool) {
      buffer.write(value ? 'true' : 'false');
    } else if (value is num) {
      buffer.write(value);
    } else if (value is String) {
      buffer.write('"');
      buffer.write(_escapeString(value));
      buffer.write('"');
    } else if (value is List) {
      buffer.write('[');
      for (int i = 0; i < value.length; i++) {
        if (i > 0) buffer.write(',');
        _writeJson(buffer, value[i]);
      }
      buffer.write(']');
    } else if (value is Map) {
      buffer.write('{');
      int i = 0;
      value.forEach((key, val) {
        if (i > 0) buffer.write(',');
        buffer.write('"');
        buffer.write(_escapeString(key.toString()));
        buffer.write('":');
        _writeJson(buffer, val);
        i++;
      });
      buffer.write('}');
    } else {
      buffer.write('"');
      buffer.write(_escapeString(value.toString()));
      buffer.write('"');
    }
  }

  String _escapeString(String s) {
    return s
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }
}
