import 'package:flutter/widgets.dart';
import 'package:void_signals/void_signals.dart';

// =============================================================================
// void_signals State Management
//
// Minimal design with user-friendly APIs:
//
// 1. signal(value) - Create a reactive signal
// 2. Watch(builder: ...) - Reactive widget that auto-tracks dependencies
// 3. signal.watch(...) - Shorthand for single signal watching
//
// Advanced features (use as needed):
// - SignalScope - Route-level state override
// - signal.scoped(context) - Get scoped signal
// =============================================================================

// =============================================================================
// SignalScope - Route-level state override (advanced feature)
// =============================================================================

/// Overrides signal values within a subtree.
///
/// This is an advanced feature for using different signal values in specific
/// pages or routes. Most applications don't need this feature.
///
/// ## Use Cases
///
/// - Using an independent counter in a detail page
/// - Using independent form state in a dialog
/// - Providing different initial values for different routes
///
/// ## Example
///
/// ```dart
/// final counter = signal(0);  // Global default value is 0
///
/// // In detail page, counter starts from 100
/// Navigator.push(context, MaterialPageRoute(
///   builder: (_) => SignalScope(
///     overrides: [counter.override(100)],
///     child: const DetailPage(),
///   ),
/// ));
///
/// // In DetailPage
/// class DetailPage extends StatelessWidget {
///   const DetailPage({super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     // Get scoped signal (value is 100)
///     final localCounter = counter.scoped(context);
///
///     return Obs(() => Text('${localCounter.value}'));
///   }
/// }
/// ```
class SignalScope extends StatefulWidget {
  /// List of signal overrides.
  final List<SignalOverrideConfig> overrides;

  /// The child widget.
  final Widget child;

  const SignalScope({
    super.key,
    required this.overrides,
    required this.child,
  });

  @override
  State<SignalScope> createState() => _SignalScopeState();
}

class _SignalScopeState extends State<SignalScope> {
  final Map<Signal<dynamic>, Signal<dynamic>> _localSignals = {};

  @override
  void initState() {
    super.initState();
    _createLocalSignals();
  }

  void _createLocalSignals() {
    for (final config in widget.overrides) {
      _localSignals[config._original] = config.createSignal();
    }
  }

  @override
  void didUpdateWidget(SignalScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if there are new override configurations
    if (!_configsEqual(oldWidget.overrides, widget.overrides)) {
      _localSignals.clear();
      _createLocalSignals();
    }
  }

  bool _configsEqual(
      List<SignalOverrideConfig> a, List<SignalOverrideConfig> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!identical(a[i]._original, b[i]._original)) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // Find parent scope
    final parent = context.dependOnInheritedWidgetOfExactType<_ScopeData>();

    return _ScopeData(
      localSignals: _localSignals,
      parent: parent,
      child: widget.child,
    );
  }
}

/// Configuration for signal overrides. Created via `signal.override(value)`.
class SignalOverrideConfig<T> {
  final Signal<T> _original;
  final T _value;

  const SignalOverrideConfig._(this._original, this._value);

  /// Creates a new signal with the override value, preserving type information.
  Signal<T> createSignal() => signal(_value);
}

class _ScopeData extends InheritedWidget {
  final Map<Signal<dynamic>, Signal<dynamic>> localSignals;
  final _ScopeData? parent;

  const _ScopeData({
    required this.localSignals,
    this.parent,
    required super.child,
  });

  /// Gets the scoped version of a signal.
  Signal<T>? getScoped<T>(Signal<T> original) {
    // First look in current scope
    final local = localSignals[original];
    if (local != null) return local as Signal<T>;
    // Then look in parent scope
    return parent?.getScoped<T>(original);
  }

  @override
  bool updateShouldNotify(_ScopeData oldWidget) {
    return localSignals != oldWidget.localSignals;
  }
}

// =============================================================================
// Signal Extensions
// =============================================================================

/// Scope extensions for Signal.
extension SignalScopeX<T> on Signal<T> {
  /// Creates an override configuration for [SignalScope].
  ///
  /// Example:
  ///
  /// ```dart
  /// SignalScope(
  ///   overrides: [counter.override(100)],
  ///   child: const MyPage(),
  /// )
  /// ```
  SignalOverrideConfig<T> override(T value) {
    return SignalOverrideConfig<T>._(this, value);
  }

  /// Gets the scoped version of this signal in the current context.
  ///
  /// If the current context is within a [SignalScope] and this signal is
  /// overridden, returns the overridden signal; otherwise returns this signal.
  ///
  /// Example:
  ///
  /// ```dart
  /// final localCounter = counter.scoped(context);
  /// ```
  Signal<T> scoped(BuildContext context) {
    final scopeData = context.dependOnInheritedWidgetOfExactType<_ScopeData>();
    return scopeData?.getScoped<T>(this) ?? this;
  }
}

/// Convenience update extension for Signal.
extension SignalUpdateX<T> on Signal<T> {
  /// Updates the value using a function.
  ///
  /// Note: This method is named `modify` to avoid conflict with
  /// the base `Signal.update(T)` method from void_signals core.
  ///
  /// Example:
  ///
  /// ```dart
  /// counter.modify((v) => v + 1);
  /// user.modify((u) => u.copyWith(name: 'New Name'));
  /// ```
  void modify(T Function(T current) updater) {
    value = updater(value);
  }
}

/// Convenience extensions for integer Signal.
extension IntSignalX on Signal<int> {
  /// Increments the value.
  void increment([int amount = 1]) => value = value + amount;

  /// Decrements the value.
  void decrement([int amount = 1]) => value = value - amount;
}

/// Convenience extensions for double Signal.
extension DoubleSignalX on Signal<double> {
  /// Increments the value.
  void increment([double amount = 1.0]) => value = value + amount;

  /// Decrements the value.
  void decrement([double amount = 1.0]) => value = value - amount;
}

/// Convenience extensions for boolean Signal.
extension BoolSignalX on Signal<bool> {
  /// Toggles the value.
  void toggle() => value = !value;
}

/// Convenience extensions for List Signal.
extension ListSignalX<E> on Signal<List<E>> {
  /// Adds an element.
  void add(E item) => value = [...value, item];

  /// Adds multiple elements.
  void addAll(Iterable<E> items) => value = [...value, ...items];

  /// Removes an element.
  void remove(E item) => value = value.where((e) => e != item).toList();

  /// Clears the list.
  void clear() => value = [];

  /// Updates the element at the specified index.
  void updateAt(int index, E item) {
    final list = [...value];
    list[index] = item;
    value = list;
  }
}

/// Convenience extensions for Map Signal.
extension MapSignalX<K, V> on Signal<Map<K, V>> {
  /// Sets a key-value pair.
  void set(K key, V val) => value = {...value, key: val};

  /// Removes a key.
  void remove(K key) {
    final map = {...value};
    map.remove(key);
    value = map;
  }

  /// Clears the map.
  void clear() => value = {};
}

/// Convenience extensions for nullable Signal.
extension NullableSignalX<T extends Object> on Signal<T?> {
  /// Clears the value (sets to null).
  void clear() => value = null;

  /// Gets the value, or returns the default value if null.
  T orDefault(T defaultValue) => value ?? defaultValue;
}
