import 'package:void_signals/void_signals.dart' as signals;
import 'package:void_signals/void_signals.dart' show Signal, Computed, batch;

/// A reactive list that provides fine-grained updates.
///
/// Unlike a regular `Signal<List<T>>`, [SignalList] provides methods
/// that only trigger updates for the specific changes, enabling
/// more efficient widget rebuilds.
///
/// Example:
/// ```dart
/// final items = SignalList<String>(['a', 'b', 'c']);
///
/// items.add('d');           // Notifies subscribers
/// items.removeAt(0);        // Notifies subscribers
/// items[1] = 'updated';     // Notifies subscribers
///
/// // Batch multiple operations
/// items.batch((list) {
///   list.add('x');
///   list.add('y');
///   list.removeWhere((e) => e == 'a');
/// });
/// ```
class SignalList<T> {
  final Signal<List<T>> _signal;
  final Signal<int> _version;

  /// Creates a signal list with the given initial items.
  SignalList([List<T>? initial])
      : _signal = signals.signal(List<T>.from(initial ?? [])),
        _version = signals.signal(0);

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
    final list = List<T>.from(_signal.value)..add(element);
    _signal.value = list;
    _version.value++;
  }

  /// Adds all elements to the end of the list.
  void addAll(Iterable<T> elements) {
    final list = List<T>.from(_signal.value)..addAll(elements);
    _signal.value = list;
    _version.value++;
  }

  /// Inserts an element at the given index.
  void insert(int index, T element) {
    final list = List<T>.from(_signal.value)..insert(index, element);
    _signal.value = list;
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

  /// Removes the element at the given index.
  T removeAt(int index) {
    final list = List<T>.from(_signal.value);
    final removed = list.removeAt(index);
    _signal.value = list;
    _version.value++;
    return removed;
  }

  /// Removes the last element.
  T removeLast() {
    final list = List<T>.from(_signal.value);
    final removed = list.removeLast();
    _signal.value = list;
    _version.value++;
    return removed;
  }

  /// Removes all elements that satisfy the predicate.
  void removeWhere(bool Function(T element) test) {
    final list = List<T>.from(_signal.value);
    final lengthBefore = list.length;
    list.removeWhere(test);
    if (list.length != lengthBefore) {
      _signal.value = list;
      _version.value++;
    }
  }

  /// Clears all elements from the list.
  void clear() {
    if (_signal.value.isNotEmpty) {
      _signal.value = [];
      _version.value++;
    }
  }

  /// Replaces the entire list.
  void replace(List<T> newList) {
    _signal.value = List<T>.from(newList);
    _version.value++;
  }

  /// Performs multiple operations in a batch.
  void batchOp(void Function(List<T> list) operations) {
    batch(() {
      final list = List<T>.from(_signal.value);
      operations(list);
      _signal.value = list;
      _version.value++;
    });
  }

  /// Returns the first element, or null if empty.
  T? get firstOrNull => isEmpty ? null : _signal.value.first;

  /// Returns the last element, or null if empty.
  T? get lastOrNull => isEmpty ? null : _signal.value.last;

  /// Returns a new list with elements that satisfy the predicate.
  List<T> where(bool Function(T element) test) {
    return _signal.value.where(test).toList();
  }

  /// Returns a new list with transformed elements.
  List<R> map<R>(R Function(T element) mapper) {
    return _signal.value.map(mapper).toList();
  }

  /// Returns whether any element satisfies the predicate.
  bool any(bool Function(T element) test) {
    return _signal.value.any(test);
  }

  /// Returns whether all elements satisfy the predicate.
  bool every(bool Function(T element) test) {
    return _signal.value.every(test);
  }

  /// Creates a computed that watches the list.
  Computed<R> select<R>(R Function(List<T> list) selector) {
    return signals.computed((_) => selector(_signal.value));
  }

  /// Creates a computed for the list length.
  Computed<int> get lengthComputed {
    return signals.computed((_) => _signal.value.length);
  }
}

/// A reactive map that provides fine-grained updates.
///
/// Example:
/// ```dart
/// final settings = SignalMap<String, dynamic>({
///   'theme': 'dark',
///   'fontSize': 14,
/// });
///
/// settings['language'] = 'en';  // Notifies subscribers
/// settings.remove('theme');      // Notifies subscribers
/// ```
class SignalMap<K, V> {
  final Signal<Map<K, V>> _signal;
  final Signal<int> _version;

  /// Creates a signal map with the given initial entries.
  SignalMap([Map<K, V>? initial])
      : _signal = signals.signal(Map<K, V>.from(initial ?? {})),
        _version = signals.signal(0);

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

  /// Sets an entry by key.
  void operator []=(K key, V value) {
    final map = Map<K, V>.from(_signal.value);
    map[key] = value;
    _signal.value = map;
    _version.value++;
  }

  /// Returns whether the map contains the given key.
  bool containsKey(K key) => _signal.value.containsKey(key);

  /// Returns whether the map contains the given value.
  bool containsValue(V value) => _signal.value.containsValue(value);

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

  /// Adds all entries from another map.
  void addAll(Map<K, V> other) {
    final map = Map<K, V>.from(_signal.value)..addAll(other);
    _signal.value = map;
    _version.value++;
  }

  /// Updates an entry using a function.
  void update(K key, V Function(V value) update, {V Function()? ifAbsent}) {
    final map = Map<K, V>.from(_signal.value);
    map.update(key, update, ifAbsent: ifAbsent);
    _signal.value = map;
    _version.value++;
  }

  /// Clears all entries.
  void clear() {
    if (_signal.value.isNotEmpty) {
      _signal.value = {};
      _version.value++;
    }
  }

  /// Replaces the entire map.
  void replace(Map<K, V> newMap) {
    _signal.value = Map<K, V>.from(newMap);
    _version.value++;
  }

  /// Performs multiple operations in a batch.
  void batchOp(void Function(Map<K, V> map) operations) {
    batch(() {
      final map = Map<K, V>.from(_signal.value);
      operations(map);
      _signal.value = map;
      _version.value++;
    });
  }

  /// Creates a computed that watches the map.
  Computed<R> select<R>(R Function(Map<K, V> map) selector) {
    return signals.computed((_) => selector(_signal.value));
  }
}

/// A reactive set that provides fine-grained updates.
///
/// [SignalSet] wraps a `Signal<Set<T>>` and provides convenient methods
/// for set operations that automatically trigger reactive updates.
///
/// Example:
/// ```dart
/// final selectedTags = SignalSet<String>({'flutter', 'dart'});
///
/// // Add an element
/// selectedTags.add('signals');  // Now contains: {flutter, dart, signals}
///
/// // Check and toggle
/// if (selectedTags.contains('flutter')) {
///   selectedTags.toggle('flutter');  // Removes it
/// }
///
/// // Watch changes
/// effect(() {
///   print('Selected: ${selectedTags.value}');
/// });
/// ```
class SignalSet<T> {
  final Signal<Set<T>> _signal;
  final Signal<int> _version;

  /// Creates a signal set with the given initial elements.
  SignalSet([Set<T>? initial])
      : _signal = signals.signal(Set<T>.from(initial ?? {})),
        _version = signals.signal(0);

  /// Gets the underlying set signal.
  Signal<Set<T>> get setSignal => _signal;

  /// Gets the current set value (read-only view).
  Set<T> get value => Set.unmodifiable(_signal.value);

  /// Gets the number of elements in the set.
  int get length => _signal.value.length;

  /// Whether the set is empty.
  bool get isEmpty => _signal.value.isEmpty;

  /// Whether the set is not empty.
  bool get isNotEmpty => _signal.value.isNotEmpty;

  /// Returns whether the set contains the given element.
  bool contains(T element) => _signal.value.contains(element);

  /// Adds an element to the set.
  ///
  /// Returns true if the element was added (not already present).
  bool add(T element) {
    final set = Set<T>.from(_signal.value);
    final result = set.add(element);
    if (result) {
      _signal.value = set;
      _version.value++;
    }
    return result;
  }

  /// Adds all elements to the set.
  void addAll(Iterable<T> elements) {
    final set = Set<T>.from(_signal.value)..addAll(elements);
    _signal.value = set;
    _version.value++;
  }

  /// Removes an element from the set.
  ///
  /// Returns true if the element was removed (was present).
  bool remove(T element) {
    final set = Set<T>.from(_signal.value);
    final result = set.remove(element);
    if (result) {
      _signal.value = set;
      _version.value++;
    }
    return result;
  }

  /// Clears all elements from the set.
  void clear() {
    if (_signal.value.isNotEmpty) {
      _signal.value = {};
      _version.value++;
    }
  }

  /// Toggles an element (adds if absent, removes if present).
  ///
  /// Returns true if the element is now in the set, false otherwise.
  bool toggle(T element) {
    if (contains(element)) {
      remove(element);
      return false;
    } else {
      add(element);
      return true;
    }
  }

  /// Replaces the entire set with a new one.
  void replace(Set<T> newSet) {
    _signal.value = Set<T>.from(newSet);
    _version.value++;
  }
}
