# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-11-28

### Added

- Initial stable release of void_signals
- Core reactive primitives:
  - `signal()` - Create reactive state values
  - `computed()` - Create derived values with automatic dependency tracking
  - `effect()` - Run side effects when dependencies change
  - `effectScope()` - Group and manage multiple effects
- Batch operations:
  - `batch()` - Batch multiple signal updates
  - `startBatch()` / `endBatch()` - Low-level batch control
- Utility functions:
  - `untrack()` - Read signals without creating dependencies
  - `trigger()` - Manually trigger signal subscribers
  - `peek()` - Read signal value without tracking
- Async support:
  - `AsyncValue` - Sealed class for async states (loading, data, error)
  - `asyncComputed()` - Async computed values with dependency tracking
  - `streamComputed()` - Subscribe to streams reactively
  - `combineAsync()` - Combine multiple async values
- Type checking utilities:
  - `isSignal()`, `isComputed()`, `isEffect()`, `isEffectScope()`
- Extension types for zero-cost abstractions
- Full documentation and examples

### Performance

- Based on alien-signals, one of the fastest signal implementations
- Lazy evaluation for computed values
- Efficient O(1) dependency tracking
- Minimal memory allocations

