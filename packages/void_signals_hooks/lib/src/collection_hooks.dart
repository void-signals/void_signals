import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:void_signals/void_signals.dart';

// =============================================================================
// Reactive Collection Types
//
// These collection types are intentionally duplicated here rather than imported
// from void_signals_flutter. This allows void_signals_hooks to be used
// independently without a direct dependency on void_signals_flutter.
//
// If you're using both packages together, prefer importing from
// void_signals_flutter to avoid ambiguity.
// =============================================================================

/// A reactive list that provides fine-grained updates.
///
/// Unlike a regular `Signal<List<T>>`, [SignalList] provides methods
/// that only trigger updates for the specific changes, enabling
/// more efficient widget rebuilds.
///
/// Example:
/// ```dart
/// class TodoListWidget extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final todos = useSignalList<String>(['Buy milk', 'Walk dog']);
///
///     return Column(
///       children: [
///         ElevatedButton(
///           onPressed: () => todos.add('New todo'),
///           child: const Text('Add'),
///         ),
///         ...todos.value.map((todo) => Text(todo)),
///       ],
///     );
///   }
/// }
/// ```
class SignalList<T> {
  final Signal<List<T>> _signal;
  final Signal<int> _version;

  /// Creates a signal list with the given initial items.
  SignalList([List<T>? initial])
      : _signal = signal(List<T>.from(initial ?? [])),
        _version = signal(0);

  /// Gets the underlying list signal.
  Signal<List<T>> get listSignal => _signal;

  /// Gets the current list value (read-only view).
  List<T> get value => List.unmodifiable(_signal.value);

  /// Gets the length of the list.
  int get length => _signal.value.length;

  /// Whether the list is empty.
  bool get isEmpty => _signal.value.isEmpty;

  /// Whether the list is not empty.
  bool get isNotEmpty => _signal.value.isNotEmpty;

  /// Gets an element at the given index.
  T operator [](int index) => _signal.value[index];

  /// Sets an element at the given index.
  void operator []=(int index, T value) {
    final list = List<T>.from(_signal.value);
    list[index] = value;
    _signal.value = list;
    _version.value++;
  }

  /// Adds an element to the end of the list.
  void add(T element) {
    _signal.value = [..._signal.value, element];
    _version.value++;
  }

  /// Adds all elements to the end of the list.
  void addAll(Iterable<T> elements) {
    _signal.value = [..._signal.value, ...elements];
    _version.value++;
  }

  /// Removes the first occurrence of an element.
  bool remove(T element) {
    final list = List<T>.from(_signal.value);
    final result = list.remove(element);
    if (result) {
      _signal.value = list;
      _version.value++;
    }
    return result;
  }

  /// Clears all elements from the list.
  void clear() {
    if (_signal.value.isNotEmpty) {
      _signal.value = [];
      _version.value++;
    }
  }
}

/// A reactive Map that provides fine-grained updates.
///
/// [SignalMap] wraps a `Signal<Map<K, V>>` and provides convenient methods
/// for map operations that automatically trigger reactive updates.
///
/// Example:
/// ```dart
/// class SettingsWidget extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final settings = useSignalMap<String, dynamic>({
///       'theme': 'dark',
///       'fontSize': 14,
///     });
///
///     return Column(
///       children: [
///         Text('Theme: ${settings['theme']}'),
///         ElevatedButton(
///           onPressed: () => settings['theme'] = 'light',
///           child: const Text('Toggle Theme'),
///         ),
///       ],
///     );
///   }
/// }
/// ```
class SignalMap<K, V> {
  final Signal<Map<K, V>> _signal;
  final Signal<int> _version;

  /// Creates a signal map with the given initial entries.
  SignalMap([Map<K, V>? initial])
      : _signal = signal(Map<K, V>.from(initial ?? {})),
        _version = signal(0);

  /// Gets the underlying map signal.
  Signal<Map<K, V>> get mapSignal => _signal;

  /// Gets the current map value (read-only view).
  Map<K, V> get value => Map.unmodifiable(_signal.value);

  /// Gets the number of entries.
  int get length => _signal.value.length;

  /// Whether the map is empty.
  bool get isEmpty => _signal.value.isEmpty;

  /// Whether the map is not empty.
  bool get isNotEmpty => _signal.value.isNotEmpty;

  /// Gets all keys.
  Iterable<K> get keys => _signal.value.keys;

  /// Gets all values.
  Iterable<V> get values => _signal.value.values;

  /// Gets an entry by key.
  V? operator [](K key) => _signal.value[key];

  /// Returns whether the map contains the given key.
  bool containsKey(K key) => _signal.value.containsKey(key);

  /// Sets an entry by key.
  void operator []=(K key, V value) {
    _signal.value = {..._signal.value, key: value};
    _version.value++;
  }

  /// Removes an entry by key.
  V? remove(K key) {
    final map = Map<K, V>.from(_signal.value);
    final removed = map.remove(key);
    if (removed != null || _signal.value.containsKey(key)) {
      _signal.value = map;
      _version.value++;
    }
    return removed;
  }

  /// Clears all entries.
  void clear() {
    if (_signal.value.isNotEmpty) {
      _signal.value = {};
      _version.value++;
    }
  }
}

/// A reactive Set that provides fine-grained updates.
///
/// [SignalSet] wraps a `Signal<Set<T>>` and provides convenient methods
/// for set operations that automatically trigger reactive updates.
///
/// Example:
/// ```dart
/// class TagSelectorWidget extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final selectedTags = useSignalSet<String>();
///
///     return Wrap(
///       children: ['Flutter', 'Dart', 'Signals'].map((tag) {
///         return FilterChip(
///           label: Text(tag),
///           selected: selectedTags.contains(tag),
///           onSelected: (_) => selectedTags.toggle(tag),
///         );
///       }).toList(),
///     );
///   }
/// }
/// ```
class SignalSet<T> {
  final Signal<Set<T>> _signal;
  final Signal<int> _version;

  /// Creates a signal set with the given initial elements.
  SignalSet([Set<T>? initial])
      : _signal = signal(Set<T>.from(initial ?? {})),
        _version = signal(0);

  /// Gets the underlying set signal.
  Signal<Set<T>> get setSignal => _signal;

  /// Gets the current set value (read-only view).
  Set<T> get value => Set.unmodifiable(_signal.value);

  /// Gets the number of elements.
  int get length => _signal.value.length;

  /// Whether the set is empty.
  bool get isEmpty => _signal.value.isEmpty;

  /// Whether the set is not empty.
  bool get isNotEmpty => _signal.value.isNotEmpty;

  /// Returns whether the set contains the given element.
  bool contains(T element) => _signal.value.contains(element);

  /// Adds an element to the set.
  bool add(T element) {
    final set = Set<T>.from(_signal.value);
    final result = set.add(element);
    if (result) {
      _signal.value = set;
      _version.value++;
    }
    return result;
  }

  /// Removes an element from the set.
  bool remove(T element) {
    final set = Set<T>.from(_signal.value);
    final result = set.remove(element);
    if (result) {
      _signal.value = set;
      _version.value++;
    }
    return result;
  }

  /// Clears all elements.
  void clear() {
    if (_signal.value.isNotEmpty) {
      _signal.value = {};
      _version.value++;
    }
  }

  /// Toggles an element (adds if absent, removes if present).
  bool toggle(T element) {
    if (contains(element)) {
      remove(element);
      return false;
    } else {
      add(element);
      return true;
    }
  }
}

// =============================================================================
// Collection Hooks
// =============================================================================

/// Creates and memoizes a [SignalList].
///
/// The list remains the same instance throughout the widget's lifecycle,
/// but its contents can be reactively updated.
///
/// Example:
/// ```dart
/// class ShoppingListWidget extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final items = useSignalList<String>(['Apple', 'Banana']);
///
///     return Column(
///       children: [
///         ...items.value.map((item) => Text(item)),
///         ElevatedButton(
///           onPressed: () => items.add('Orange'),
///           child: const Text('Add Orange'),
///         ),
///       ],
///     );
///   }
/// }
/// ```
SignalList<T> useSignalList<T>([List<T>? initial]) {
  return use(_SignalListHook<T>(initial));
}

/// Creates and memoizes a [SignalMap].
///
/// The map remains the same instance throughout the widget's lifecycle,
/// but its entries can be reactively updated.
///
/// Example:
/// ```dart
/// class FormWidget extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final formData = useSignalMap<String, String>({'name': '', 'email': ''});
///
///     return Column(
///       children: [
///         TextField(
///           onChanged: (v) => formData['name'] = v,
///           decoration: const InputDecoration(labelText: 'Name'),
///         ),
///         TextField(
///           onChanged: (v) => formData['email'] = v,
///           decoration: const InputDecoration(labelText: 'Email'),
///         ),
///       ],
///     );
///   }
/// }
/// ```
SignalMap<K, V> useSignalMap<K, V>([Map<K, V>? initial]) {
  return use(_SignalMapHook<K, V>(initial));
}

/// Creates and memoizes a [SignalSet].
///
/// The set remains the same instance throughout the widget's lifecycle,
/// but its elements can be reactively updated.
///
/// Example:
/// ```dart
/// class MultiSelectWidget extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final selection = useSignalSet<int>();
///
///     return ListView.builder(
///       itemCount: 10,
///       itemBuilder: (context, index) {
///         return CheckboxListTile(
///           value: selection.contains(index),
///           onChanged: (_) => selection.toggle(index),
///           title: Text('Item $index'),
///         );
///       },
///     );
///   }
/// }
/// ```
SignalSet<T> useSignalSet<T>([Set<T>? initial]) {
  return use(_SignalSetHook<T>(initial));
}

// =============================================================================
// Hook Implementations
// =============================================================================

class _SignalListHook<T> extends Hook<SignalList<T>> {
  const _SignalListHook(this.initial);
  final List<T>? initial;

  @override
  _SignalListHookState<T> createState() => _SignalListHookState<T>();
}

class _SignalListHookState<T>
    extends HookState<SignalList<T>, _SignalListHook<T>> {
  late SignalList<T> _list;

  @override
  void initHook() => _list = SignalList<T>(hook.initial);

  @override
  SignalList<T> build(BuildContext context) => _list;

  @override
  String get debugLabel => 'useSignalList<$T>';
}

class _SignalMapHook<K, V> extends Hook<SignalMap<K, V>> {
  const _SignalMapHook(this.initial);
  final Map<K, V>? initial;

  @override
  _SignalMapHookState<K, V> createState() => _SignalMapHookState<K, V>();
}

class _SignalMapHookState<K, V>
    extends HookState<SignalMap<K, V>, _SignalMapHook<K, V>> {
  late SignalMap<K, V> _map;

  @override
  void initHook() => _map = SignalMap<K, V>(hook.initial);

  @override
  SignalMap<K, V> build(BuildContext context) => _map;

  @override
  String get debugLabel => 'useSignalMap<$K, $V>';
}

class _SignalSetHook<T> extends Hook<SignalSet<T>> {
  const _SignalSetHook(this.initial);
  final Set<T>? initial;

  @override
  _SignalSetHookState<T> createState() => _SignalSetHookState<T>();
}

class _SignalSetHookState<T>
    extends HookState<SignalSet<T>, _SignalSetHook<T>> {
  late SignalSet<T> _set;

  @override
  void initHook() => _set = SignalSet<T>(hook.initial);

  @override
  SignalSet<T> build(BuildContext context) => _set;

  @override
  String get debugLabel => 'useSignalSet<$T>';
}
