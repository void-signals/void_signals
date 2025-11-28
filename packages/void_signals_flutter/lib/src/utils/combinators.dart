import 'package:void_signals/void_signals.dart' as signals;
import 'package:void_signals/void_signals.dart' show Signal, Computed;

/// Creates a computed signal that mirrors another signal with a transformation.
///
/// This is useful for deriving a new value from an existing signal without
/// modifying the original.
///
/// Example:
/// ```dart
/// final price = signal(100.0);
/// final formattedPrice = mapped(price, (p) => '\$${p.toStringAsFixed(2)}');
///
/// print(formattedPrice.value);  // '$100.00'
/// price.value = 49.99;
/// print(formattedPrice.value);  // '$49.99'
/// ```
Computed<R> mapped<T, R>(Signal<T> source, R Function(T value) mapper) {
  return signals.computed((_) => mapper(source.value));
}

/// Creates a computed signal that filters values based on a predicate.
///
/// The computed only updates when the source signal's value satisfies
/// the predicate. If the predicate returns false, the computed retains
/// its previous value.
///
/// Example:
/// ```dart
/// final input = signal(0);
/// // Only track positive values
/// final positiveOnly = filtered(input, (v) => v > 0);
///
/// input.value = 5;   // positiveOnly.value = 5
/// input.value = -3;  // positiveOnly.value = 5 (unchanged)
/// input.value = 10;  // positiveOnly.value = 10
/// ```
Computed<T> filtered<T>(Signal<T> source, bool Function(T value) predicate) {
  return signals.computed((prev) {
    final value = source.value;
    if (predicate(value)) {
      return value;
    }
    // Return previous value if predicate fails
    // On first call, prev is null, so use source's initial value if it matches
    return prev ?? (predicate(source.peek()) ? source.peek() : value);
  });
}

/// Creates a computed signal that only updates when the value actually changes.
///
/// Uses a custom equality function to determine if values are different.
/// This is useful for preventing unnecessary updates when the "same" value
/// is set multiple times.
///
/// Example:
/// ```dart
/// final user = signal(User(name: 'John', id: 1));
///
/// // Only update when id changes, ignore name changes
/// final distinctUser = distinctUntilChanged(
///   user,
///   (prev, curr) => prev.id == curr.id,
/// );
///
/// user.value = User(name: 'John Doe', id: 1);  // No update (same id)
/// user.value = User(name: 'Jane', id: 2);       // Updates (different id)
/// ```
Computed<T> distinctUntilChanged<T>(
  Signal<T> source, [
  bool Function(T previous, T current)? equals,
]) {
  return signals.computed((prev) {
    final value = source.value;
    final eq = equals ?? (a, b) => a == b;

    // On first call, prev is null, so always return the current value
    if (prev == null) {
      return value;
    }

    // Only return new value if it's different
    if (!eq(prev, value)) {
      return value;
    }

    // Return previous value if equal
    return prev;
  });
}

/// Combines two signals into one computed value.
///
/// The computed updates whenever either of the source signals changes.
///
/// Example:
/// ```dart
/// final firstName = signal('John');
/// final lastName = signal('Doe');
///
/// final fullName = combine2(firstName, lastName, (f, l) => '$f $l');
/// print(fullName.value);  // 'John Doe'
///
/// firstName.value = 'Jane';
/// print(fullName.value);  // 'Jane Doe'
/// ```
Computed<R> combine2<T1, T2, R>(
  Signal<T1> s1,
  Signal<T2> s2,
  R Function(T1 v1, T2 v2) combiner,
) {
  return signals.computed((_) => combiner(s1.value, s2.value));
}

/// Combines three signals into one computed value.
///
/// The computed updates whenever any of the source signals changes.
///
/// Example:
/// ```dart
/// final r = signal(255);
/// final g = signal(128);
/// final b = signal(0);
///
/// final color = combine3(r, g, b, (r, g, b) => Color.fromRGBO(r, g, b, 1.0));
/// ```
Computed<R> combine3<T1, T2, T3, R>(
  Signal<T1> s1,
  Signal<T2> s2,
  Signal<T3> s3,
  R Function(T1 v1, T2 v2, T3 v3) combiner,
) {
  return signals.computed((_) => combiner(s1.value, s2.value, s3.value));
}

/// Combines four signals into one computed value.
///
/// The computed updates whenever any of the source signals changes.
///
/// Example:
/// ```dart
/// final x = signal(0.0);
/// final y = signal(0.0);
/// final width = signal(100.0);
/// final height = signal(50.0);
///
/// final rect = combine4(x, y, width, height, (x, y, w, h) {
///   return Rect.fromLTWH(x, y, w, h);
/// });
/// ```
Computed<R> combine4<T1, T2, T3, T4, R>(
  Signal<T1> s1,
  Signal<T2> s2,
  Signal<T3> s3,
  Signal<T4> s4,
  R Function(T1 v1, T2 v2, T3 v3, T4 v4) combiner,
) {
  return signals
      .computed((_) => combiner(s1.value, s2.value, s3.value, s4.value));
}

/// Creates a pair of computed values that track the current and previous values.
///
/// Returns a tuple of `(current, previous)` where:
/// - `current`: A computed that always has the current signal value
/// - `previous`: A computed that has the previous value (null on first access)
///
/// This is useful for animations, comparisons, or undo functionality.
///
/// Example:
/// ```dart
/// final count = signal(0);
/// final (current, previous) = withPrevious(count);
///
/// print(current.value);   // 0
/// print(previous.value);  // null
///
/// count.value = 5;
/// print(current.value);   // 5
/// print(previous.value);  // 0
///
/// count.value = 10;
/// print(current.value);   // 10
/// print(previous.value);  // 5
/// ```
(Computed<T>, Computed<T?>) withPrevious<T>(Signal<T> source) {
  // Use a class to track state across computed evaluations
  T? lastKnownValue;
  bool hasLastValue = false;

  final previousComputed = signals.computed<T?>((_) {
    final current = source.value;
    final prev = hasLastValue ? lastKnownValue : null;
    lastKnownValue = current;
    hasLastValue = true;
    return prev;
  });

  return (
    signals.computed((_) => source.value),
    previousComputed,
  );
}
