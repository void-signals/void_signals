/// High-performance signal reactivity library for Dart.
///
/// This library provides a reactive system based on signals, computed values,
/// and effects. It is optimized for performance and designed to be the
/// foundation for reactive state management in Dart applications.
///
/// ## Core Concepts
///
/// - **Signal**: A reactive value that notifies subscribers when changed
/// - **Computed**: A derived value that updates automatically
/// - **Effect**: A side effect that runs when dependencies change
/// - **EffectScope**: A container for grouping related effects
///
/// ## Example
///
/// ```dart
/// import 'package:void_signals/void_signals.dart';
///
/// void main() {
///   final count = signal(0);
///   final doubled = computed((prev) => count() * 2);
///
///   effect(() {
///     print('Count: ${count()}, Doubled: ${doubled()}');
///   });
///
///   count(1); // Prints: Count: 1, Doubled: 2
/// }
/// ```
library void_signals;

// Core types and API
export 'src/api.dart'
    show
        Signal,
        Computed,
        Effect,
        EffectScope,
        signal,
        computed,
        computedFrom,
        effect,
        effectScope,
        trigger,
        batch,
        untrack,
        isSignal,
        isComputed,
        isEffect,
        isEffectScope;

// System functions for advanced usage
export 'src/system.dart'
    show getActiveSub, setActiveSub, getBatchDepth, startBatch, endBatch;

// Flags for low-level operations
export 'src/flags.dart' show ReactiveFlags;

// Node types for extension
export 'src/nodes.dart'
    show ReactiveNode, SignalNode, ComputedNode, EffectNode, ScopeNode, Link;

// Lifecycle management (Riverpod-inspired patterns)
export 'src/lifecycle.dart'
    show
        DisposeCallback,
        KeepAliveLink,
        SignalSubscription,
        SignalLifecycle,
        SignalErrorHandler,
        SubscriptionController,
        SignalSubscriptionImpl,
        SignalSubscriptionExtension,
        ComputedSubscriptionExtension;

// Error handling and retry logic
export 'src/error_handling.dart'
    show
        Result,
        ResultData,
        ResultError,
        AsyncValueLike,
        AsyncDataLike,
        AsyncErrorLike,
        runGuarded,
        runGuardedAsync,
        RetryConfig,
        retry,
        retrySync,
        AsyncState,
        AsyncSignal,
        SafeSignalExtension,
        SafeComputedExtension;

// Async computed with dependency tracking (Riverpod-style)
export 'src/async_computed.dart'
    show
        AsyncValue,
        AsyncLoading,
        AsyncLoadingWithPrevious,
        AsyncData,
        AsyncError,
        AsyncErrorWithPrevious,
        AsyncComputed,
        asyncComputed,
        StreamComputed,
        streamComputed,
        combineAsync,
        AsyncComputedListExtension,
        FutureAsyncValueExtension,
        AsyncComputedLifecycleExtension;
