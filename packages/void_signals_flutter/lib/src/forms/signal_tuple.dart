import 'package:void_signals/void_signals.dart';

/// A tuple of 2 signals with type safety.
///
/// [SignalTuple2] provides a convenient way to manage two related signals
/// together with type-safe access and batch operations.
///
/// Example:
/// ```dart
/// // Create a tuple for coordinates
/// final position = SignalTuple2<double, double>(0.0, 0.0);
///
/// // Access individual signals
/// position.$1.value = 10.0;  // x coordinate
/// position.$2.value = 20.0;  // y coordinate
///
/// // Get all values as a record
/// final (x, y) = position.values;
/// print('Position: ($x, $y)');
///
/// // Batch update both values
/// position.update(15.0, 25.0);
///
/// // Create a computed from both values
/// final distance = position.combine((x, y) => sqrt(x * x + y * y));
///
/// // Watch both values
/// position.watch((x, y) {
///   print('Position changed to ($x, $y)');
/// });
/// ```
class SignalTuple2<T1, T2> {
  /// The first signal in the tuple.
  final Signal<T1> $1;

  /// The second signal in the tuple.
  final Signal<T2> $2;

  /// Creates a new tuple with two signals initialized to the given values.
  SignalTuple2(T1 v1, T2 v2)
      : $1 = signal(v1),
        $2 = signal(v2);

  /// Gets all values as a Dart 3 record.
  ///
  /// Example:
  /// ```dart
  /// final (first, second) = tuple.values;
  /// ```
  (T1, T2) get values => ($1.value, $2.value);

  /// Updates all values in a batch.
  void update(T1 v1, T2 v2) {
    batch(() {
      $1.value = v1;
      $2.value = v2;
    });
  }

  /// Creates a computed from all values.
  Computed<R> combine<R>(R Function(T1 v1, T2 v2) combiner) {
    return computed((_) => combiner($1.value, $2.value));
  }

  /// Creates an effect that watches all values.
  Effect watch(void Function(T1 v1, T2 v2) callback) {
    return effect(() => callback($1.value, $2.value));
  }
}

/// A tuple of 3 signals with type safety.
///
/// [SignalTuple3] provides a convenient way to manage three related signals
/// together with type-safe access and batch operations.
///
/// Example:
/// ```dart
/// // Create a tuple for RGB color
/// final color = SignalTuple3<int, int, int>(255, 128, 0);
///
/// // Get all values
/// final (r, g, b) = color.values;
/// print('RGB: $r, $g, $b');
///
/// // Create a combined value
/// final hexColor = color.combine((r, g, b) {
///   return '#${r.toRadixString(16)}${g.toRadixString(16)}${b.toRadixString(16)}';
/// });
/// ```
class SignalTuple3<T1, T2, T3> {
  /// The first signal in the tuple.
  final Signal<T1> $1;

  /// The second signal in the tuple.
  final Signal<T2> $2;

  /// The third signal in the tuple.
  final Signal<T3> $3;

  /// Creates a new tuple with three signals initialized to the given values.
  SignalTuple3(T1 v1, T2 v2, T3 v3)
      : $1 = signal(v1),
        $2 = signal(v2),
        $3 = signal(v3);

  /// Gets all values as a Dart 3 record.
  (T1, T2, T3) get values => ($1.value, $2.value, $3.value);

  /// Updates all values in a batch.
  void update(T1 v1, T2 v2, T3 v3) {
    batch(() {
      $1.value = v1;
      $2.value = v2;
      $3.value = v3;
    });
  }

  /// Creates a computed from all values.
  Computed<R> combine<R>(R Function(T1 v1, T2 v2, T3 v3) combiner) {
    return computed((_) => combiner($1.value, $2.value, $3.value));
  }

  /// Creates an effect that watches all values.
  Effect watch(void Function(T1 v1, T2 v2, T3 v3) callback) {
    return effect(() => callback($1.value, $2.value, $3.value));
  }
}

/// A tuple of 4 signals with type safety.
///
/// [SignalTuple4] provides a convenient way to manage four related signals
/// together with type-safe access and batch operations.
///
/// Example:
/// ```dart
/// // Create a tuple for a rectangle
/// final rect = SignalTuple4<double, double, double, double>(0, 0, 100, 50);
///
/// // Get all values
/// final (x, y, width, height) = rect.values;
///
/// // Create a computed area
/// final area = rect.combine((x, y, w, h) => w * h);
/// print('Area: ${area.value}');  // 5000
/// ```
class SignalTuple4<T1, T2, T3, T4> {
  /// The first signal in the tuple.
  final Signal<T1> $1;

  /// The second signal in the tuple.
  final Signal<T2> $2;

  /// The third signal in the tuple.
  final Signal<T3> $3;

  /// The fourth signal in the tuple.
  final Signal<T4> $4;

  /// Creates a new tuple with four signals initialized to the given values.
  SignalTuple4(T1 v1, T2 v2, T3 v3, T4 v4)
      : $1 = signal(v1),
        $2 = signal(v2),
        $3 = signal(v3),
        $4 = signal(v4);

  /// Gets all values as a Dart 3 record.
  (T1, T2, T3, T4) get values => ($1.value, $2.value, $3.value, $4.value);

  /// Updates all values in a batch.
  void update(T1 v1, T2 v2, T3 v3, T4 v4) {
    batch(() {
      $1.value = v1;
      $2.value = v2;
      $3.value = v3;
      $4.value = v4;
    });
  }

  /// Creates a computed from all values.
  Computed<R> combine<R>(R Function(T1 v1, T2 v2, T3 v3, T4 v4) combiner) {
    return computed((_) => combiner($1.value, $2.value, $3.value, $4.value));
  }

  /// Creates an effect that watches all values.
  Effect watch(void Function(T1 v1, T2 v2, T3 v3, T4 v4) callback) {
    return effect(() => callback($1.value, $2.value, $3.value, $4.value));
  }
}

/// Creates a type-safe tuple of 2 signals.
///
/// This is a convenience function for creating [SignalTuple2] instances.
///
/// Example:
/// ```dart
/// final coords = signalTuple2(0.0, 0.0);
/// coords.$1.value = 10.0;  // x
/// coords.$2.value = 20.0;  // y
/// ```
SignalTuple2<T1, T2> signalTuple2<T1, T2>(T1 v1, T2 v2) {
  return SignalTuple2(v1, v2);
}

/// Creates a type-safe tuple of 3 signals.
///
/// This is a convenience function for creating [SignalTuple3] instances.
///
/// Example:
/// ```dart
/// final rgb = signalTuple3(255, 128, 0);
/// ```
SignalTuple3<T1, T2, T3> signalTuple3<T1, T2, T3>(T1 v1, T2 v2, T3 v3) {
  return SignalTuple3(v1, v2, v3);
}

/// Creates a type-safe tuple of 4 signals.
///
/// This is a convenience function for creating [SignalTuple4] instances.
///
/// Example:
/// ```dart
/// final rect = signalTuple4(0.0, 0.0, 100.0, 50.0);
/// ```
SignalTuple4<T1, T2, T3, T4> signalTuple4<T1, T2, T3, T4>(
    T1 v1, T2 v2, T3 v3, T4 v4) {
  return SignalTuple4(v1, v2, v3, v4);
}
