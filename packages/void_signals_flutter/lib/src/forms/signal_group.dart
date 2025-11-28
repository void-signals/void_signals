import 'package:void_signals/void_signals.dart';

/// A group of related signals accessed by key.
///
/// Due to Dart's type system, use [get]/[set] to access values (not signals).
///
/// Example:
/// ```dart
/// final form = SignalGroup({'name': '', 'age': 0});
///
/// // Read/write values
/// form['name'] = 'Alice';
/// print(form['age']);  // 0
///
/// // Batch update
/// form.update({'name': 'Bob', 'age': 25});
///
/// // Watch changes
/// form.watch((values) => print(values));
/// ```
class SignalGroup<K> {
  final Map<K, Signal<dynamic>> _signals;

  /// Creates from initial values.
  SignalGroup(Map<K, dynamic> values)
      : _signals = values.map((k, v) => MapEntry(k, signal(v)));

  /// Gets value by key.
  T? get<T>(K key) => _signals[key]?.value as T?;

  /// Sets value by key.
  void set<T>(K key, T value) => _signals[key]?.value = value;

  /// Operator [] for getting values.
  dynamic operator [](K key) => _signals[key]?.value;

  /// Operator []= for setting values.
  void operator []=(K key, dynamic value) => _signals[key]?.value = value;

  /// All current values.
  Map<K, dynamic> get values => _signals.map((k, s) => MapEntry(k, s.value));

  /// Batch update multiple values.
  void update(Map<K, dynamic> updates) {
    batch(() {
      for (final e in updates.entries) {
        _signals[e.key]?.value = e.value;
      }
    });
  }

  /// Watch all values.
  Effect watch(void Function(Map<K, dynamic> values) callback) {
    return effect(() => callback(values));
  }

  /// Create computed from values.
  Computed<R> combine<R>(R Function(Map<K, dynamic> values) fn) {
    return computed((_) => fn(values));
  }

  /// Raw signal access (for watching).
  Signal<dynamic>? raw(K key) => _signals[key];

  Iterable<K> get keys => _signals.keys;
  int get length => _signals.length;
  bool containsKey(K key) => _signals.containsKey(key);
}

/// Creates a signal group.
SignalGroup<K> signalGroup<K>(Map<K, dynamic> values) => SignalGroup(values);
