import 'package:void_signals/void_signals.dart' show Signal;

/// Extension methods for numeric Signal arithmetic operations.
///
/// These operations mutate the signal value in place, providing a more
/// convenient syntax for common arithmetic operations.
///
/// Note: For integer signals, consider using [IntSignalX] from
/// `state_management.dart` which provides `increment()` and `decrement()`
/// methods with optional amounts.
///
/// Example:
/// ```dart
/// final price = signal(100.0);
///
/// price.add(10.0);       // price.value is now 110.0
/// price.subtract(5.0);   // price.value is now 105.0
/// price.multiply(2.0);   // price.value is now 210.0
/// ```
extension SignalOperators<T extends num> on Signal<T> {
  /// Adds a value to the signal.
  ///
  /// Example:
  /// ```dart
  /// final count = signal(10);
  /// count.add(5);  // count.value is now 15
  /// ```
  void add(T amount) {
    value = (value + amount) as T;
  }

  /// Subtracts a value from the signal.
  ///
  /// Example:
  /// ```dart
  /// final count = signal(10);
  /// count.subtract(3);  // count.value is now 7
  /// ```
  void subtract(T amount) {
    value = (value - amount) as T;
  }

  /// Multiplies the signal value.
  ///
  /// Example:
  /// ```dart
  /// final count = signal(5);
  /// count.multiply(3);  // count.value is now 15
  /// ```
  void multiply(T factor) {
    value = (value * factor) as T;
  }
}

/// Extension methods for boolean signals.
///
/// Provides utility methods for boolean state manipulation.
///
/// Note: [BoolSignalX.toggle()] is also available in `state_management.dart`
/// and provides the same functionality.
///
/// Example:
/// ```dart
/// final isEnabled = signal(false);
///
/// isEnabled.setTrue();   // isEnabled.value is now true
/// isEnabled.setFalse();  // isEnabled.value is now false
/// ```
extension BoolSignalOperators on Signal<bool> {
  /// Sets the value to true.
  ///
  /// Example:
  /// ```dart
  /// final isActive = signal(false);
  /// isActive.setTrue();  // isActive.value is now true
  /// ```
  void setTrue() {
    value = true;
  }

  /// Sets the value to false.
  ///
  /// Example:
  /// ```dart
  /// final isActive = signal(true);
  /// isActive.setFalse();  // isActive.value is now false
  /// ```
  void setFalse() {
    value = false;
  }
}

/// Extension methods for string signals.
///
/// Provides convenient methods for common string manipulations.
///
/// Example:
/// ```dart
/// final text = signal('Hello');
///
/// text.append(' World');  // text.value is now 'Hello World'
/// text.prepend('Say: ');  // text.value is now 'Say: Hello World'
/// text.trim();            // Removes whitespace from both ends
/// text.clear();           // text.value is now ''
/// ```
extension StringSignalOperators on Signal<String> {
  /// Appends a string to the value.
  ///
  /// Example:
  /// ```dart
  /// final message = signal('Hello');
  /// message.append('!');
  /// print(message.value);  // 'Hello!'
  /// ```
  void append(String suffix) {
    value = value + suffix;
  }

  /// Prepends a string to the value.
  ///
  /// Example:
  /// ```dart
  /// final message = signal('World');
  /// message.prepend('Hello ');
  /// print(message.value);  // 'Hello World'
  /// ```
  void prepend(String prefix) {
    value = prefix + value;
  }

  /// Clears the string value.
  ///
  /// Example:
  /// ```dart
  /// final text = signal('Some content');
  /// text.clear();
  /// print(text.value);  // ''
  /// ```
  void clear() {
    value = '';
  }

  /// Trims whitespace from the value.
  ///
  /// Example:
  /// ```dart
  /// final text = signal('  Hello World  ');
  /// text.trim();
  /// print(text.value);  // 'Hello World'
  /// ```
  void trim() {
    value = value.trim();
  }
}

/// Extension methods for nullable signals.
///
/// Provides convenient methods for working with signals that may hold null values.
///
/// Note: [NullableSignalX] in `state_management.dart` provides `clear()` and
/// `orDefault()` methods for similar functionality.
///
/// Example:
/// ```dart
/// final user = signal<User?>(null);
///
/// if (user.isNull) {
///   print('No user logged in');
/// }
///
/// final currentUser = user.getOrDefault(guestUser);
/// ```
extension NullableSignalOperators<T> on Signal<T?> {
  /// Returns whether the value is null.
  ///
  /// Example:
  /// ```dart
  /// final selectedItem = signal<Item?>(null);
  /// print(selectedItem.isNull);  // true
  /// ```
  bool get isNull => value == null;

  /// Returns whether the value is not null.
  ///
  /// Example:
  /// ```dart
  /// final selectedItem = signal<Item?>(Item('test'));
  /// print(selectedItem.isNotNull);  // true
  /// ```
  bool get isNotNull => value != null;

  /// Returns the value or a default.
  ///
  /// Example:
  /// ```dart
  /// final name = signal<String?>(null);
  /// print(name.getOrDefault('Anonymous'));  // 'Anonymous'
  /// ```
  T getOrDefault(T defaultValue) {
    return value ?? defaultValue;
  }
}

/// Extension methods for list signals.
///
/// Note: [ListSignalX] in `state_management.dart` provides similar methods
/// like `add()`, `remove()`, and `clear()`.
///
/// Example:
/// ```dart
/// final selectedIds = signal<List<int>>([1, 2, 3]);
///
/// // Toggle selection
/// selectedIds.toggle(2);  // Removes 2: [1, 3]
/// selectedIds.toggle(4);  // Adds 4: [1, 3, 4]
/// ```
extension ListSignalOperators<T> on Signal<List<T>> {
  /// Toggles an element in the list (adds if absent, removes if present).
  ///
  /// Example:
  /// ```dart
  /// final tags = signal<List<String>>(['flutter', 'dart']);
  /// tags.toggle('react');   // ['flutter', 'dart', 'react']
  /// tags.toggle('flutter'); // ['dart', 'react']
  /// ```
  void toggle(T element) {
    if (value.contains(element)) {
      value = value.where((e) => e != element).toList();
    } else {
      value = [...value, element];
    }
  }
}
