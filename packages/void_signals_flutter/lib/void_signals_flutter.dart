/// Flutter bindings for void_signals.
///
/// This library provides Flutter widgets and extensions for integrating
/// the void_signals reactive system with Flutter applications.
///
/// ## Quick Start - Just 2 concepts!
///
/// ```dart
/// // 1. Create signals (reactive state)
/// final count = signal(0);
///
/// // 2. Watch signals in widgets - automatic dependency tracking!
/// Watch(builder: (context, _) => Text('Count: ${count.value}'));
/// ```
///
/// That's it! When `count.value` is read inside Watch, it's automatically
/// tracked. When `count.value` changes, Watch rebuilds.
///
/// ## Core Concepts
///
/// ### signal(value) - Create reactive state
/// ```dart
/// final count = signal(0);
/// final user = signal<User?>(null);
/// final items = signal<List<Item>>([]);
///
/// // Read value (tracked inside Watch/effect)
/// print(count.value);
///
/// // Write value (triggers updates)
/// count.value = 1;
/// count.value++;
/// ```
///
/// ### Watch - Reactive widget (recommended)
/// ```dart
/// // Automatically tracks ALL signals accessed in builder
/// Watch(builder: (context, child) {
///   return Column(children: [
///     Text('Count: ${count.value}'),
///     Text('User: ${user.value?.name}'),
///     child!, // Static child won't rebuild
///   ]);
/// }, child: const ExpensiveWidget());
/// ```
///
/// ### computed - Derived values
/// ```dart
/// final count = signal(0);
/// final doubled = computed((_) => count.value * 2);
/// final isEven = computed((_) => count.value % 2 == 0);
/// ```
///
/// ### effect - Side effects
/// ```dart
/// effect(() {
///   print('Count changed: ${count.value}');
///   // Runs immediately, then whenever count changes
/// });
/// ```
///
/// ## Advanced Features
///
/// - **batch()**: Combine multiple updates into one
/// - **signal.peek()**: Read without tracking
/// - **untrack()**: Run code without tracking
/// - **SignalScope**: Override signals for specific widget subtrees
///
/// ## Simple Widget Examples
///
/// ```dart
/// // Counter
/// final count = signal(0);
///
/// class Counter extends StatelessWidget {
///   Widget build(BuildContext context) {
///     return Scaffold(
///       body: Center(
///         child: Watch(builder: (ctx, _) => Text('${count.value}')),
///       ),
///       floatingActionButton: FloatingActionButton(
///         onPressed: () => count.value++,
///         child: Icon(Icons.add),
///       ),
///     );
///   }
/// }
/// ```
library void_signals_flutter;

// Re-export core signals library
export 'package:void_signals/void_signals.dart';

// =============================================================================
// CORE WIDGETS (Recommended)
// =============================================================================

// Builder widgets - Watch is the primary recommended widget
export 'src/signal_builder.dart'
    show
        // Primary - auto-tracks all dependencies
        Watch,
        WatchValue,
        // Explicit single-signal builders (use Watch instead for most cases)
        SignalBuilder,
        ComputedBuilder,
        MultiSignalBuilder,
        SignalSelector,
        ComputedSelector;

// =============================================================================
// SCOPE MANAGEMENT (Advanced)
// =============================================================================

// Scope widgets for advanced state isolation
export 'src/flutter_scope.dart'
    show
        EffectScopeProvider,
        EffectScopeWidget,
        getEffectScope,
        requireEffectScope,
        ReactiveContextExtension;

// =============================================================================
// EXTENSIONS AND MIXINS
// =============================================================================

// Extensions for convenient signal/computed usage in Flutter
export 'src/flutter_extensions.dart'
    show
        SignalFlutterExtensions,
        ComputedFlutterExtensions,
        SignalStateMixin,
        ReactiveStateMixin,
        ReactiveScope;

// =============================================================================
// ASYNC VALUE SUPPORT
// =============================================================================

// Async value handling (loading/data/error states)
// Note: AsyncValue, AsyncLoading, AsyncData, AsyncError come from void_signals
// The flutter-specific extensions and widgets are exported here
export 'src/async_value.dart'
    show
        asyncSignal,
        asyncSignalFromStream,
        AsyncValueWidgetExtension,
        AsyncSignalBuilder;

// =============================================================================
// FORM SIGNALS
// =============================================================================

// Form validation and field management
export 'src/forms/validators.dart'
    show
        FieldValidation,
        FieldValidator,
        requiredValidator,
        emailValidator,
        minLengthValidator,
        maxLengthValidator,
        patternValidator,
        rangeValidator,
        composeValidators;
export 'src/forms/form_field.dart' show SignalField, SignalFieldBuilder;
export 'src/forms/form_signal.dart' show FormSignal;
export 'src/forms/signal_group.dart' show SignalGroup, signalGroup;
export 'src/forms/signal_tuple.dart'
    show
        SignalTuple2,
        SignalTuple3,
        SignalTuple4,
        signalTuple2,
        signalTuple3,
        signalTuple4;

// =============================================================================
// UTILITIES
// =============================================================================

// Signal collections
export 'src/utils/collections.dart' show SignalList, SignalMap, SignalSet;

// Signal operators
export 'src/utils/operators.dart'
    show
        SignalOperators,
        BoolSignalOperators,
        StringSignalOperators,
        NullableSignalOperators,
        ListSignalOperators;

// Time-based utilities
export 'src/utils/time_utils.dart'
    show TimedSignal, debounced, throttled, delayed;

// Combinator functions
export 'src/utils/combinators.dart'
    show
        mapped,
        filtered,
        distinctUntilChanged,
        combine2,
        combine3,
        combine4,
        withPrevious;

// Flutter controller wrappers
export 'src/utils/controllers.dart'
    show
        SignalTextController,
        SignalScrollController,
        ScrollDirection,
        SignalFocusNode,
        SignalTabController,
        SignalPageController;

// Pagination and infinite scroll
export 'src/utils/pagination.dart'
    show
        PaginationState,
        PaginationConfig,
        PaginatedSignal,
        PaginationResult,
        setupInfiniteScroll,
        InfiniteScrollList;

// Lifecycle and timers
export 'src/utils/lifecycle.dart'
    show
        appLifecycleSignal,
        AppLifecycleSignal,
        intervalSignal,
        IntervalSignal,
        countdownSignal,
        CountdownSignal,
        stopwatchSignal,
        StopwatchSignal,
        frameSignal,
        FrameSignal,
        clockSignal,
        ClockSignal,
        LifecycleAwareSignalMixin;

// Undo/Redo history
export 'src/utils/history.dart'
    show
        UndoableSignal,
        HistoryCheckpoint,
        undoable,
        UndoableSignalExtension,
        UndoGroup,
        UndoTransactionExtension,
        SaveableSignal;

// Search utilities
export 'src/utils/search.dart'
    show
        SearchState,
        SearchConfig,
        SearchSignal,
        SearchWithSuggestionsSignal,
        FilterSignal,
        SortSignal,
        SortDirection;

// =============================================================================
// STATE MANAGEMENT EXTENSIONS
// =============================================================================

// SignalScope for route-level state override (advanced feature)
export 'src/state_management.dart'
    show
        // Scope override
        SignalScope,
        SignalOverrideConfig,
        // Signal extensions
        SignalScopeX,
        SignalUpdateX,
        IntSignalX,
        DoubleSignalX,
        BoolSignalX,
        ListSignalX,
        MapSignalX,
        NullableSignalX;

// =============================================================================
// DEVTOOLS (Debug mode only)
// =============================================================================

// DevTools integration
export 'src/devtools/debug_service.dart' show VoidSignalsDebugService;
export 'src/devtools/debug_tracker.dart'
    show
        SignalDebugTracker,
        SignalDebugExtension,
        ComputedDebugExtension,
        EffectDebugExtension;
export 'src/devtools/signal_observer.dart'
    show SignalObserver, LoggingSignalObserver;

// =============================================================================
// SCHEDULER
// =============================================================================

// Flutter scheduler integration
export 'src/scheduler.dart'
    show
        ScheduledTask,
        FlutterSignalScheduler,
        SignalSchedulerScope,
        FlutterScheduledSignalExtension,
        FlutterSignalMixin,
        SignalWatcherMixin,
        SignalWatcher,
        SignalWatcherState;

// =============================================================================
// FRAME BATCHING
// =============================================================================

// Frame-level batching for cross-component updates
export 'src/frame_batch.dart' show FrameBatchScope, batchLater, queueUpdate;

// =============================================================================
// ALTERNATIVE API - Consumer Pattern
// =============================================================================

// Consumer pattern (Riverpod-style API)
// For developers familiar with Riverpod or who prefer explicit ref.watch/read.
// See consumer.dart for comparison with Watch pattern.
export 'src/consumer.dart'
    show
        SignalRef,
        ConsumerWidget,
        ConsumerStatefulWidget,
        ConsumerState,
        Consumer;
