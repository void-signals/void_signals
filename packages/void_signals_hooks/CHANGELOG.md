# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-11-28

### Added

- Initial stable release of void_signals_hooks
- Core hooks:
  - `useSignal()` - Create and memoize a signal
  - `useComputed()` - Create memoized computed values
  - `useComputedSimple()` - Simplified computed without previous value
  - `useWatch()` - Watch signal and trigger rebuilds
  - `useWatchComputed()` - Watch computed values
  - `useReactive()` - Create signal and watch in one call
  - `useSignalEffect()` - Side effects with dependency tracking
  - `useEffectScope()` - Group effects for cleanup
- Selection hooks:
  - `useSelect()` - Select part of signal value
  - `useSelectComputed()` - Select from computed values
- Utility hooks:
  - `useBatch()` - Batch signal updates
  - `useUntrack()` - Read without dependencies
  - `useSignalFromStream()` - Create signal from stream
  - `useSignalFromFuture()` - Create signal from future
- Time-based hooks:
  - `useDebounced()` - Debounced signal
  - `useThrottled()` - Throttled signal
- Combinator hooks:
  - `useCombine2()` / `useCombine3()` - Combine signals
  - `usePrevious()` - Track current and previous values
- Collection hooks:
  - `useSignalList()` - Reactive list
  - `useSignalMap()` - Reactive map
  - `useSignalSet()` - Reactive set

### Features

- Automatic cleanup when widget unmounts
- Memoization across rebuilds
- Full integration with flutter_hooks

