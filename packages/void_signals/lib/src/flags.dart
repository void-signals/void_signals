/// Reactive flags using extension type for zero-cost abstraction.
///
/// [ReactiveFlags] is an extension type that wraps an integer bitmask to represent
/// the state of reactive nodes in the signal graph. Using extension types allows
/// for type-safe flag operations with zero runtime overhead - they compile directly
/// to plain int operations.
///
/// Bit layout:
/// - Bit 0 (1):  mutable - Node can produce new values (Signal, Computed)
/// - Bit 1 (2):  watching - Node is actively watching for changes (Effect)
/// - Bit 2 (4):  recursedCheck - Currently being checked for recursion
/// - Bit 3 (8):  recursed - Has been recursed into during propagation
/// - Bit 4 (16): dirty - Value is stale and needs recomputation
/// - Bit 5 (32): pending - May have pending updates to process
extension type const ReactiveFlags._(int _) implements int {
  /// No flags set (value: 0)
  static const none = 0 as ReactiveFlags;

  /// Node is mutable - can produce new values (value: 1)
  static const mutable = 1 as ReactiveFlags;

  /// Node is watching for changes - active effect (value: 2)
  static const watching = 2 as ReactiveFlags;

  /// Currently being checked for recursion (value: 4)
  static const recursedCheck = 4 as ReactiveFlags;

  /// Has been recursed into during propagation (value: 8)
  static const recursed = 8 as ReactiveFlags;

  /// Value is stale and needs recomputation (value: 16)
  static const dirty = 16 as ReactiveFlags;

  /// May have pending updates to process (value: 32)
  static const pending = 32 as ReactiveFlags;

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  ReactiveFlags operator |(int other) => _ | other as ReactiveFlags;

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  ReactiveFlags operator &(int other) => _ & other as ReactiveFlags;

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @pragma('wasm:prefer-inline')
  ReactiveFlags operator ~() => ~_ as ReactiveFlags;
}
