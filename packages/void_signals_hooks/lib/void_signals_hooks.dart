/// Flutter hooks integration for void_signals.
///
/// This library provides integration between void_signals and flutter_hooks,
/// allowing you to conveniently use reactive signals in HookWidget.
///
/// ## Core Hooks
///
/// - [useSignal]: Creates and memoizes a signal
/// - [useComputed]: Creates and memoizes a computed value
/// - [useWatch]: Watches a signal and rebuilds when it changes
/// - [useSignalEffect]: Creates a side effect
///
/// ## Example
///
/// ```dart
/// class Counter extends HookWidget {
///   const Counter({super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     final count = useSignal(0);
///     final value = useWatch(count);
///
///     return Column(
///       children: [
///         Text('Count: $value'),
///         ElevatedButton(
///           onPressed: () => count.value++,
///           child: const Text('Increment'),
///         ),
///       ],
///     );
///   }
/// }
/// ```
library void_signals_hooks;

// Core library re-exports
export 'package:void_signals/void_signals.dart';
export 'package:flutter_hooks/flutter_hooks.dart'
    hide Reducer, useDebounced, usePrevious;

// Core hooks
export 'src/core_hooks.dart'
    show
        useSignal,
        useComputed,
        useComputedSimple,
        useSignalEffect,
        useWatch,
        useWatchComputed,
        useEffectScope,
        useReactive,
        useSelect,
        useSelectComputed,
        useBatch,
        useUntrack,
        useSignalFromStream,
        useSignalFromFuture;

// Collection hooks
export 'src/collection_hooks.dart'
    show
        SignalList,
        SignalMap,
        SignalSet,
        useSignalList,
        useSignalMap,
        useSignalSet;

// Utility hooks
export 'src/utility_hooks.dart'
    show useDebounced, useThrottled, useCombine2, useCombine3, usePrevious;

// Async hooks
export 'src/async_hooks.dart'
    show
        AsyncStatus,
        UseAsyncState,
        UseAsyncController,
        ValueRef,
        useAsync,
        useAsyncData,
        useLatest,
        useListener,
        useToggle,
        useCounter,
        useInterval,
        useTimeout;
