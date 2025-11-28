import 'package:flutter/foundation.dart';
import 'package:void_signals/void_signals.dart';

import 'debug_service.dart';

/// Signal origin enum for better tracking and filtering.
enum SignalOrigin {
  /// Signal created in application code
  app,

  /// Signal created via flutter_hooks
  hook,

  /// Signal created via Consumer/ConsumerWidget
  consumer,

  /// Signal created via Watch widget
  watch,

  /// Signal created in unknown context
  unknown,
}

/// Tracks signals, computeds, and effects for debugging purposes.
///
/// This tracker uses identity-based deduplication to prevent duplicate
/// tracking of the same signal instances. It also integrates with the
/// observer pattern to notify DevTools of lifecycle events.
///
/// ## Auto-tracking mode
///
/// Enable auto-tracking to automatically track all signals without
/// explicit `.tracked()` calls:
///
/// ```dart
/// VoidSignalsDebugService.initialize(autoTrack: true);
/// ```
class SignalDebugTracker {
  final Map<String, _TrackedSignal> _signals = {};
  final Map<String, _TrackedComputed> _computeds = {};
  final Map<String, _TrackedEffect> _effects = {};

  /// Maps signal identity to tracking ID for deduplication
  final Map<int, String> _signalIdentityMap = {};
  final Map<int, String> _computedIdentityMap = {};
  final Map<int, String> _effectIdentityMap = {};

  /// Value history for time-travel debugging
  final List<_ValueHistoryEntry> _valueHistory = [];
  static const int _maxHistoryEntries = 500;

  /// Widget associations for tracing signals to their source widgets
  final Map<String, String> _widgetAssociations = {};

  int _idCounter = 0;
  bool _autoTrackEnabled = false;

  /// Enable or disable auto-tracking.
  set autoTrack(bool value) {
    _autoTrackEnabled = value;
  }

  /// Whether auto-tracking is enabled.
  bool get autoTrack => _autoTrackEnabled;

  /// Register a signal for tracking.
  /// Returns existing ID if already tracked.
  @pragma('vm:prefer-inline')
  String trackSignal<T>(
    Signal<T> signal, {
    String? label,
    SignalOrigin origin = SignalOrigin.app,
    String? widgetName,
  }) {
    if (!kDebugMode) return '';

    final identity = identityHashCode(signal);

    // Check if already tracked
    if (_signalIdentityMap.containsKey(identity)) {
      final existingId = _signalIdentityMap[identity]!;
      // Update label if provided
      if (label != null && _signals[existingId] != null) {
        _signals[existingId]!.label = label;
      }
      if (widgetName != null) {
        _widgetAssociations[existingId] = widgetName;
      }
      return existingId;
    }

    final id = 'signal_${_idCounter++}';
    final value = signal.peek();
    _signals[id] = _TrackedSignal(
      id: id,
      signal: signal,
      label: label,
      origin: origin,
      createdAt: DateTime.now(),
      stackTrace: kDebugMode ? StackTrace.current.toString() : null,
    );
    _signalIdentityMap[identity] = id;

    if (widgetName != null) {
      _widgetAssociations[id] = widgetName;
    }

    // Notify observers
    VoidSignalsDebugService.notifySignalAdded(signal, id, value);

    return id;
  }

  /// Register a computed for tracking.
  /// Returns existing ID if already tracked.
  @pragma('vm:prefer-inline')
  String trackComputed<T>(
    Computed<T> computed, {
    String? label,
    SignalOrigin origin = SignalOrigin.app,
  }) {
    if (!kDebugMode) return '';

    final identity = identityHashCode(computed);

    // Check if already tracked
    if (_computedIdentityMap.containsKey(identity)) {
      final existingId = _computedIdentityMap[identity]!;
      if (label != null && _computeds[existingId] != null) {
        _computeds[existingId]!.label = label;
      }
      return existingId;
    }

    final id = 'computed_${_idCounter++}';
    final value = computed.peek();

    // Extract dependency information
    final dependencyIds = _extractDependencyIds(computed);

    _computeds[id] = _TrackedComputed(
      id: id,
      computed: computed,
      label: label,
      origin: origin,
      dependencyIds: dependencyIds,
      createdAt: DateTime.now(),
    );
    _computedIdentityMap[identity] = id;

    // Notify observers
    VoidSignalsDebugService.notifyComputedAdded(computed, id, value);

    return id;
  }

  /// Register an effect for tracking.
  /// Returns existing ID if already tracked.
  @pragma('vm:prefer-inline')
  String trackEffect(
    Effect effect, {
    String? label,
    SignalOrigin origin = SignalOrigin.app,
  }) {
    if (!kDebugMode) return '';

    final identity = identityHashCode(effect);

    // Check if already tracked
    if (_effectIdentityMap.containsKey(identity)) {
      final existingId = _effectIdentityMap[identity]!;
      if (label != null && _effects[existingId] != null) {
        _effects[existingId]!.label = label;
      }
      return existingId;
    }

    final id = 'effect_${_idCounter++}';

    // Extract dependency information
    final dependencyIds = _extractEffectDependencyIds(effect);

    _effects[id] = _TrackedEffect(
      id: id,
      effect: effect,
      label: label,
      origin: origin,
      dependencyIds: dependencyIds,
      createdAt: DateTime.now(),
    );
    _effectIdentityMap[identity] = id;

    // Notify observers
    VoidSignalsDebugService.notifyEffectAdded(effect, id);

    return id;
  }

  /// Extract dependency IDs from a computed by traversing its dependency links.
  List<String> _extractDependencyIds(Computed computed) {
    if (!kDebugMode) return [];

    final ids = <String>[];

    try {
      // Access the internal node to get dependencies
      // This is a bit hacky but necessary for real dependency tracking
      final node = _getComputedNode(computed);
      if (node != null) {
        var link = node.deps;
        while (link != null) {
          final depNode = link.dep;
          final depId = _findIdForNode(depNode);
          if (depId != null) {
            ids.add(depId);
          }
          link = link.nextDep;
        }
      }
    } catch (e) {
      // Silently ignore if we can't extract dependencies
    }

    return ids;
  }

  /// Extract dependency IDs from an effect.
  List<String> _extractEffectDependencyIds(Effect effect) {
    if (!kDebugMode) return [];

    final ids = <String>[];

    try {
      final node = _getEffectNode(effect);
      if (node != null) {
        var link = node.deps;
        while (link != null) {
          final depNode = link.dep;
          final depId = _findIdForNode(depNode);
          if (depId != null) {
            ids.add(depId);
          }
          link = link.nextDep;
        }
      }
    } catch (e) {
      // Silently ignore
    }

    return ids;
  }

  /// Find the tracking ID for a reactive node.
  String? _findIdForNode(ReactiveNode node) {
    // Check signals
    for (final entry in _signals.entries) {
      final signalNode = _getSignalNode(entry.value.signal);
      if (identical(signalNode, node)) {
        return entry.key;
      }
    }

    // Check computeds
    for (final entry in _computeds.entries) {
      final computedNode = _getComputedNode(entry.value.computed);
      if (identical(computedNode, node)) {
        return entry.key;
      }
    }

    return null;
  }

  /// Get the internal SignalNode from a Signal.
  SignalNode? _getSignalNode(Signal signal) {
    try {
      // Access internal node - this depends on implementation
      return (signal as dynamic)._node as SignalNode?;
    } catch (e) {
      return null;
    }
  }

  /// Get the internal ComputedNode from a Computed.
  ComputedNode? _getComputedNode(Computed computed) {
    try {
      return (computed as dynamic)._node as ComputedNode?;
    } catch (e) {
      return null;
    }
  }

  /// Get the internal EffectNode from an Effect.
  EffectNode? _getEffectNode(Effect effect) {
    try {
      return (effect as dynamic)._node as EffectNode?;
    } catch (e) {
      return null;
    }
  }

  /// Untrack a signal by ID.
  @pragma('vm:prefer-inline')
  void untrackSignal(String id) {
    final tracked = _signals.remove(id);
    if (tracked != null) {
      _signalIdentityMap.remove(identityHashCode(tracked.signal));
      _widgetAssociations.remove(id);
      // Notify observers
      VoidSignalsDebugService.notifySignalDisposed(tracked.signal, id);
    }
  }

  /// Untrack a computed by ID.
  @pragma('vm:prefer-inline')
  void untrackComputed(String id) {
    final tracked = _computeds.remove(id);
    if (tracked != null) {
      _computedIdentityMap.remove(identityHashCode(tracked.computed));
      // Notify observers
      VoidSignalsDebugService.notifyComputedDisposed(tracked.computed, id);
    }
  }

  /// Untrack an effect by ID.
  @pragma('vm:prefer-inline')
  void untrackEffect(String id) {
    final tracked = _effects.remove(id);
    if (tracked != null) {
      _effectIdentityMap.remove(identityHashCode(tracked.effect));
      // Notify observers
      VoidSignalsDebugService.notifyEffectDisposed(tracked.effect, id);
    }
  }

  /// Get signal info by ID.
  Map<String, dynamic>? getSignalById(String id) {
    final tracked = _signals[id];
    if (tracked == null) return null;
    return tracked.toJson();
  }

  /// Set a signal value by ID (for DevTools editing).
  bool setSignalValue(String id, String valueString) {
    final tracked = _signals[id];
    if (tracked == null) return false;

    try {
      // Try to parse the value based on signal type
      final signal = tracked.signal;
      final currentValue = signal.peek();

      if (currentValue is int) {
        signal.value = int.parse(valueString) as dynamic;
      } else if (currentValue is double) {
        signal.value = double.parse(valueString) as dynamic;
      } else if (currentValue is bool) {
        signal.value = (valueString.toLowerCase() == 'true') as dynamic;
      } else if (currentValue is String) {
        signal.value = valueString as dynamic;
      } else {
        // For other types, we can't easily parse
        return false;
      }

      tracked.lastUpdated = DateTime.now();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Notify that a signal was updated.
  @pragma('vm:prefer-inline')
  void notifySignalUpdated(
    String id, {
    Object? previousValue,
    Object? newValue,
    String? triggerSource,
  }) {
    if (!kDebugMode) return;

    final tracked = _signals[id];
    if (tracked != null) {
      final prevValue = previousValue ?? tracked.lastValue;
      tracked.lastValue = newValue;
      tracked.lastUpdated = DateTime.now();
      tracked.updateCount++;

      // Record in history for time-travel debugging
      _addToHistory(_ValueHistoryEntry(
        signalId: id,
        oldValue: _valueToString(prevValue),
        newValue: _valueToString(newValue),
        timestamp: DateTime.now(),
        triggerSource: triggerSource,
      ));

      // Notify observers
      VoidSignalsDebugService.notifySignalUpdated(
        tracked.signal,
        id,
        prevValue,
        newValue,
      );
    }
  }

  /// Notify that an effect ran.
  @pragma('vm:prefer-inline')
  void notifyEffectRan(String id) {
    if (!kDebugMode) return;

    final tracked = _effects[id];
    if (tracked != null) {
      tracked.lastRun = DateTime.now();
      tracked.runCount++;
      // Notify observers
      VoidSignalsDebugService.notifyEffectRan(tracked.effect, id);
    }
  }

  /// Add an entry to the value history.
  void _addToHistory(_ValueHistoryEntry entry) {
    _valueHistory.add(entry);
    // Trim history if it gets too long
    while (_valueHistory.length > _maxHistoryEntries) {
      _valueHistory.removeAt(0);
    }
  }

  /// Get the value history for time-travel debugging.
  List<Map<String, dynamic>> getValueHistory() {
    return _valueHistory.map((e) => e.toJson()).toList();
  }

  /// Clear value history.
  void clearHistory() {
    _valueHistory.clear();
  }

  /// Restore signal values to a specific point in history.
  /// Returns a map of signal IDs to their restored values.
  Map<String, String> restoreToHistoryIndex(int index) {
    if (index < 0 || index >= _valueHistory.length) {
      return {};
    }

    // Build state at the given index
    final snapshot = <String, String>{};
    for (int i = 0; i <= index; i++) {
      final entry = _valueHistory[i];
      snapshot[entry.signalId] = entry.newValue;
    }

    // Apply the snapshot
    for (final entry in snapshot.entries) {
      setSignalValue(entry.key, entry.value);
    }

    return snapshot;
  }

  /// Convert all tracking data to JSON for DevTools.
  Map<String, dynamic> toJson() {
    // Refresh dependency information
    _refreshDependencies();

    return {
      'signals': _signals.values.map((s) => s.toJson()).toList(),
      'computeds': _computeds.values.map((c) => c.toJson()).toList(),
      'effects': _effects.values.map((e) => e.toJson()).toList(),
      'valueHistory': getValueHistory(),
      'widgetAssociations': _widgetAssociations,
      'stats': {
        'totalSignals': _signals.length,
        'totalComputeds': _computeds.length,
        'totalEffects': _effects.length,
        'historyEntries': _valueHistory.length,
      },
    };
  }

  /// Refresh dependency information for all computeds and effects.
  void _refreshDependencies() {
    for (final computed in _computeds.values) {
      computed.dependencyIds = _extractDependencyIds(computed.computed);
    }
    for (final effect in _effects.values) {
      effect.dependencyIds = _extractEffectDependencyIds(effect.effect);
    }
  }

  /// Clear all tracked items.
  void clear() {
    _signals.clear();
    _computeds.clear();
    _effects.clear();
    _signalIdentityMap.clear();
    _computedIdentityMap.clear();
    _effectIdentityMap.clear();
    _valueHistory.clear();
    _widgetAssociations.clear();
  }

  /// Check if a signal is already tracked.
  bool isSignalTracked(Signal signal) {
    return _signalIdentityMap.containsKey(identityHashCode(signal));
  }

  /// Check if a computed is already tracked.
  bool isComputedTracked(Computed computed) {
    return _computedIdentityMap.containsKey(identityHashCode(computed));
  }

  /// Check if an effect is already tracked.
  bool isEffectTracked(Effect effect) {
    return _effectIdentityMap.containsKey(identityHashCode(effect));
  }

  /// Get the ID for a signal if tracked.
  String? getIdForSignal(Signal signal) {
    return _signalIdentityMap[identityHashCode(signal)];
  }

  /// Get the ID for a computed if tracked.
  String? getIdForComputed(Computed computed) {
    return _computedIdentityMap[identityHashCode(computed)];
  }

  /// Get the ID for an effect if tracked.
  String? getIdForEffect(Effect effect) {
    return _effectIdentityMap[identityHashCode(effect)];
  }

  String _valueToString(dynamic value) {
    if (value == null) return 'null';
    if (value is String) return value;
    return value.toString();
  }
}

/// Value history entry for time-travel debugging.
class _ValueHistoryEntry {
  final String signalId;
  final String oldValue;
  final String newValue;
  final DateTime timestamp;
  final String? triggerSource;

  _ValueHistoryEntry({
    required this.signalId,
    required this.oldValue,
    required this.newValue,
    required this.timestamp,
    this.triggerSource,
  });

  Map<String, dynamic> toJson() {
    return {
      'signalId': signalId,
      'oldValue': oldValue,
      'newValue': newValue,
      'timestamp': timestamp.toIso8601String(),
      'triggerSource': triggerSource,
    };
  }
}

class _TrackedSignal<T> {
  final String id;
  final Signal<T> signal;
  String? label;
  final SignalOrigin origin;
  final DateTime createdAt;
  final String? stackTrace;
  DateTime? lastUpdated;
  Object? lastValue;
  int updateCount = 0;

  _TrackedSignal({
    required this.id,
    required this.signal,
    this.label,
    this.origin = SignalOrigin.app,
    required this.createdAt,
    this.stackTrace,
  }) : lastValue = signal.peek();

  Map<String, dynamic> toJson() {
    final value = signal.peek();
    return {
      'id': id,
      'name': 'Signal<${value.runtimeType}>',
      'label': label,
      'value': _valueToString(value),
      'type': value.runtimeType.toString(),
      'origin': origin.name,
      'subscriberCount': signal.hasSubscribers ? 1 : 0,
      'dependencyIds': <String>[],
      'lastUpdated': lastUpdated?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'stackTrace': stackTrace,
      'updateCount': updateCount,
    };
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

class _TrackedComputed<T> {
  final String id;
  final Computed<T> computed;
  String? label;
  final SignalOrigin origin;
  List<String> dependencyIds;
  final DateTime createdAt;
  DateTime? lastComputed;

  _TrackedComputed({
    required this.id,
    required this.computed,
    this.label,
    this.origin = SignalOrigin.app,
    this.dependencyIds = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    final value = computed.peek();
    return {
      'id': id,
      'name': 'Computed<${value.runtimeType}>',
      'label': label,
      'value': _valueToString(value),
      'type': value.runtimeType.toString(),
      'origin': origin.name,
      'subscriberCount': computed.hasSubscribers ? 1 : 0,
      'dependencyIds': dependencyIds,
      'isDirty': false,
      'createdAt': createdAt.toIso8601String(),
      'lastComputed': lastComputed?.toIso8601String(),
    };
  }

  String _valueToString(dynamic value) {
    if (value == null) return 'null';
    if (value is String) return '"$value"';
    return value.toString();
  }
}

class _TrackedEffect {
  final String id;
  final Effect effect;
  String? label;
  final SignalOrigin origin;
  List<String> dependencyIds;
  final DateTime createdAt;
  DateTime? lastRun;
  int runCount = 0;
  bool isActive = true;

  _TrackedEffect({
    required this.id,
    required this.effect,
    this.label,
    this.origin = SignalOrigin.app,
    this.dependencyIds = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': 'Effect',
      'label': label,
      'origin': origin.name,
      'dependencyIds': dependencyIds,
      'runCount': runCount,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastRun': lastRun?.toIso8601String(),
    };
  }
}

/// Extension to make tracking easier.
extension SignalDebugExtension<T> on Signal<T> {
  /// Track this signal with the debug tracker.
  Signal<T> tracked({String? label}) {
    if (kDebugMode) {
      VoidSignalsDebugService.tracker.trackSignal(this, label: label);
    }
    return this;
  }

  /// Track this signal with origin information.
  Signal<T> trackedWithOrigin({
    String? label,
    SignalOrigin origin = SignalOrigin.app,
    String? widgetName,
  }) {
    if (kDebugMode) {
      VoidSignalsDebugService.tracker.trackSignal(
        this,
        label: label,
        origin: origin,
        widgetName: widgetName,
      );
    }
    return this;
  }
}

/// Extension to make tracking easier for computed.
extension ComputedDebugExtension<T> on Computed<T> {
  /// Track this computed with the debug tracker.
  Computed<T> tracked({String? label}) {
    if (kDebugMode) {
      VoidSignalsDebugService.tracker.trackComputed(this, label: label);
    }
    return this;
  }

  /// Track this computed with origin information.
  Computed<T> trackedWithOrigin({
    String? label,
    SignalOrigin origin = SignalOrigin.app,
  }) {
    if (kDebugMode) {
      VoidSignalsDebugService.tracker.trackComputed(
        this,
        label: label,
        origin: origin,
      );
    }
    return this;
  }
}

/// Extension to make tracking easier for effects.
extension EffectDebugExtension on Effect {
  /// Track this effect with the debug tracker.
  Effect tracked({String? label}) {
    if (kDebugMode) {
      VoidSignalsDebugService.tracker.trackEffect(this, label: label);
    }
    return this;
  }

  /// Track this effect with origin information.
  Effect trackedWithOrigin({
    String? label,
    SignalOrigin origin = SignalOrigin.app,
  }) {
    if (kDebugMode) {
      VoidSignalsDebugService.tracker.trackEffect(
        this,
        label: label,
        origin: origin,
      );
    }
    return this;
  }
}
