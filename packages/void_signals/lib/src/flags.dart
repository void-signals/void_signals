/// Reactive flags using extension type for zero-cost abstraction.
///
/// [ReactiveFlags] is an extension type that wraps an integer bitmask to represent
/// the state of reactive nodes in the signal graph. Using extension types allows
/// for type-safe flag operations with zero runtime overhead.
///
/// These flags are used internally to track:
/// - Whether a node is mutable (signals and computed values)
/// - Whether an effect is actively watching for changes
/// - Whether a node is dirty and needs recomputation
/// - Whether updates are pending
///
/// Example:
/// ```dart
/// // Check if a node is dirty
/// if (flags.isDirty) {
///   // Recompute value
/// }
///
/// // Combine flags
/// final newFlags = ReactiveFlags.mutable | ReactiveFlags.dirty;
///
/// // Check for multiple flags
/// if (flags.hasAll(ReactiveFlags.mutable | ReactiveFlags.watching)) {
///   // Node is both mutable and watching
/// }
/// ```
extension type const ReactiveFlags(int _value) {
  /// No flags set
  static const ReactiveFlags none = ReactiveFlags(0);

  /// Node is mutable (Signal or Computed)
  static const ReactiveFlags mutable = ReactiveFlags(1);

  /// Node is watching for changes (Effect)
  static const ReactiveFlags watching = ReactiveFlags(2);

  /// Node is currently being checked for recursion
  static const ReactiveFlags recursedCheck = ReactiveFlags(4);

  /// Node has been recursed into
  static const ReactiveFlags recursed = ReactiveFlags(8);

  /// Node value is dirty and needs update
  static const ReactiveFlags dirty = ReactiveFlags(16);

  /// Node may have pending updates
  static const ReactiveFlags pending = ReactiveFlags(32);

  // Pre-computed combinations for performance
  static const ReactiveFlags mutableDirty =
      ReactiveFlags(17); // mutable | dirty
  static const ReactiveFlags watchingRecursedCheck =
      ReactiveFlags(6); // watching | recursedCheck

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  ReactiveFlags operator |(ReactiveFlags other) =>
      ReactiveFlags(_value | other._value);

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  ReactiveFlags operator &(ReactiveFlags other) =>
      ReactiveFlags(_value & other._value);

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  ReactiveFlags operator ~() => ReactiveFlags(~_value);

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  bool has(ReactiveFlags flag) => (_value & flag._value) != 0;

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  bool hasAll(ReactiveFlags flags) => (_value & flags._value) == flags._value;

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  bool hasNone(ReactiveFlags flags) => (_value & flags._value) == 0;

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  ReactiveFlags set(ReactiveFlags flag) => this | flag;

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  ReactiveFlags remove(ReactiveFlags flag) =>
      ReactiveFlags(_value & ~flag._value);

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  bool get isNone => _value == 0;

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  bool get isDirty => has(dirty);

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  bool get isPending => has(pending);

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  bool get isMutable => has(mutable);

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  bool get isWatching => has(watching);

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  bool get isRecursedCheck => has(recursedCheck);

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  bool get isRecursed => has(recursed);
}
