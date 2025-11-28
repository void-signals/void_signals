# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-11-28

### Added

- Initial stable release of void_signals_flutter
- Core widgets:
  - `Watch` - Reactive widget that rebuilds on signal changes
  - `Obs` - Shorthand for Watch widget
  - `SignalBuilder` - Builder pattern for signal reactivity
  - `SignalSelector` - Selective rebuilds for performance optimization
  - `SignalScope` - Route-level state override and dependency injection
- Consumer pattern (Riverpod-style API):
  - `Consumer` / `ConsumerWidget` / `ConsumerStatefulWidget`
  - `SignalRef` with `watch()`, `read()`, `listen()` methods
- Time-based utilities:
  - `debounced()` - Debounce signal updates
  - `throttled()` - Throttle signal updates
- Form validation:
  - `SignalField` - Form field with validation
  - `SignalFieldBuilder` - Builder for form fields
  - Validators: `requiredValidator`, `emailValidator`, etc.
- Convenience extensions:
  - Integer: `increment()`, `decrement()`
  - Boolean: `toggle()`
  - List: `add()`, `remove()`, `clear()`
  - Map: `set()`, `remove()`
  - Nullable: `clear()`, `orDefault()`
  - Transform: `modify()`
- Frame synchronization:
  - `batch()` - Synchronous batching
  - `batchLater()` - Deferred flush to microtask
  - `queueUpdate()` - Fully deferred updates
  - `FrameBatchScope` - Manual control over update queue
- DevTools integration:
  - `VoidSignalsDebugService` - Debug service for DevTools
  - `.tracked()` extension for signal debugging

### Performance

- Automatic frame synchronization with Flutter lifecycle
- Multiple rapid updates batched automatically
- Updates during build phase deferred to next frame

