import 'package:flutter/widgets.dart';
import 'package:void_signals/void_signals.dart';
import 'signal_builder.dart';

/// Extensions for Signal to integrate with Flutter widgets.
extension SignalFlutterExtensions<T> on Signal<T> {
  /// Creates a reactive widget that rebuilds when this signal changes.
  ///
  /// This is a shorthand for watching a single signal with a simple builder.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final counter = signal(0);
  ///
  /// // Simple text display
  /// counter.watch((value) => Text('Count: $value'));
  ///
  /// // With context
  /// counter.watch((value, context) => Text(
  ///   'Count: $value',
  ///   style: Theme.of(context).textTheme.headlineMedium,
  /// ));
  ///
  /// // With static child for optimization
  /// counter.watch(
  ///   (value, context, child) => Column(
  ///     children: [
  ///       Text('Count: $value'),
  ///       child!, // Won't rebuild
  ///     ],
  ///   ),
  ///   child: const ExpensiveWidget(),
  /// );
  /// ```
  Widget watch(
    dynamic builder, {
    Widget? child,
    Key? key,
  }) {
    final signal = this;
    // Support different builder signatures for convenience
    if (builder is Widget Function(T)) {
      return WatchValue<T>(
        key: key,
        getter: () => signal.value,
        builder: (context, value) => builder(value),
      );
    } else if (builder is Widget Function(T, BuildContext)) {
      return WatchValue<T>(
        key: key,
        getter: () => signal.value,
        builder: (context, value) => builder(value, context),
      );
    } else if (builder is Widget Function(T, BuildContext, Widget?)) {
      return Watch(
        key: key,
        child: child,
        builder: (context, child) => builder(signal.value, context, child),
      );
    } else {
      throw ArgumentError(
        'Invalid builder type. Expected one of:\n'
        '  Widget Function(T value)\n'
        '  Widget Function(T value, BuildContext context)\n'
        '  Widget Function(T value, BuildContext context, Widget? child)',
      );
    }
  }

  /// Creates a SignalBuilder widget that rebuilds when this signal changes.
  ///
  /// Example:
  /// ```dart
  /// final count = signal(0);
  /// // In a widget:
  /// count.builder((context, value) => Text('$value'))
  /// ```
  Widget builder(
    Widget Function(BuildContext context, T value) builder, {
    Widget? child,
  }) {
    return SignalBuilder<T>(
      signal: this,
      builder: (context, value, child) => builder(context, value),
      child: child,
    );
  }

  /// Creates a SignalBuilder with a child widget for optimization.
  ///
  /// The child widget will not be rebuilt when the signal changes.
  Widget builderWithChild({
    required Widget child,
    required Widget Function(BuildContext context, T value, Widget child)
        builder,
  }) {
    return SignalBuilder<T>(
      signal: this,
      builder: (context, value, child) => builder(context, value, child!),
      child: child,
    );
  }

  /// Creates a SignalSelector widget that only rebuilds when the selected
  /// value changes.
  ///
  /// This is useful for performance optimization when you only need a
  /// derived value from the signal.
  ///
  /// Example:
  /// ```dart
  /// final user = signal(User(name: 'John', age: 30));
  /// // Only rebuilds when the name changes:
  /// user.select(
  ///   (u) => u.name,
  ///   (context, name) => Text(name),
  /// )
  /// ```
  Widget select<R>(
    R Function(T value) selector,
    Widget Function(BuildContext context, R value) builder, {
    Widget? child,
  }) {
    return SignalSelector<T, R>(
      signal: this,
      selector: selector,
      builder: (context, value, child) => builder(context, value),
      child: child,
    );
  }

  /// Creates a SignalSelector with a child widget for optimization.
  Widget selectWithChild<R>({
    required R Function(T value) selector,
    required Widget child,
    required Widget Function(BuildContext context, R value, Widget child)
        builder,
  }) {
    return SignalSelector<T, R>(
      signal: this,
      selector: selector,
      builder: (context, value, child) => builder(context, value, child!),
      child: child,
    );
  }
}

/// Extensions for Computed to integrate with Flutter widgets.
extension ComputedFlutterExtensions<T> on Computed<T> {
  /// Creates a reactive widget that rebuilds when this computed changes.
  ///
  /// This is a shorthand for watching a computed value.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final count = signal(0);
  /// final doubled = computed((_) => count.value * 2);
  ///
  /// doubled.watch((value) => Text('Doubled: $value'));
  /// ```
  Widget watch(
    dynamic builder, {
    Widget? child,
    Key? key,
  }) {
    final computed = this;
    if (builder is Widget Function(T)) {
      return WatchValue<T>(
        key: key,
        getter: () => computed.value,
        builder: (context, value) => builder(value),
      );
    } else if (builder is Widget Function(T, BuildContext)) {
      return WatchValue<T>(
        key: key,
        getter: () => computed.value,
        builder: (context, value) => builder(value, context),
      );
    } else if (builder is Widget Function(T, BuildContext, Widget?)) {
      return Watch(
        key: key,
        child: child,
        builder: (context, child) => builder(computed.value, context, child),
      );
    } else {
      throw ArgumentError(
        'Invalid builder type. Expected one of:\n'
        '  Widget Function(T value)\n'
        '  Widget Function(T value, BuildContext context)\n'
        '  Widget Function(T value, BuildContext context, Widget? child)',
      );
    }
  }

  /// Creates a ComputedBuilder widget that rebuilds when this computed changes.
  ///
  /// Example:
  /// ```dart
  /// final doubled = computed((prev) => count() * 2);
  /// // In a widget:
  /// doubled.builder((context, value) => Text('$value'))
  /// ```
  Widget builder(
    Widget Function(BuildContext context, T value) builder, {
    Widget? child,
  }) {
    return ComputedBuilder<T>(
      computed: this,
      builder: (context, value, child) => builder(context, value),
      child: child,
    );
  }

  /// Creates a ComputedBuilder with a child widget for optimization.
  Widget builderWithChild({
    required Widget child,
    required Widget Function(BuildContext context, T value, Widget child)
        builder,
  }) {
    return ComputedBuilder<T>(
      computed: this,
      builder: (context, value, child) => builder(context, value, child!),
      child: child,
    );
  }

  /// Creates a ComputedSelector widget that only rebuilds when the selected
  /// value changes.
  ///
  /// Example:
  /// ```dart
  /// final users = computed((_) => fetchUsers());
  /// // Only rebuilds when the count changes:
  /// users.select(
  ///   (list) => list.length,
  ///   (context, count) => Text('$count users'),
  /// )
  /// ```
  Widget select<R>(
    R Function(T value) selector,
    Widget Function(BuildContext context, R value) builder, {
    Widget? child,
  }) {
    return ComputedSelector<T, R>(
      computed: this,
      selector: selector,
      builder: (context, value, child) => builder(context, value),
      child: child,
    );
  }

  /// Creates a ComputedSelector with a child widget for optimization.
  Widget selectWithChild<R>({
    required R Function(T value) selector,
    required Widget child,
    required Widget Function(BuildContext context, R value, Widget child)
        builder,
  }) {
    return ComputedSelector<T, R>(
      computed: this,
      selector: selector,
      builder: (context, value, child) => builder(context, value, child!),
      child: child,
    );
  }
}

/// A mixin that provides reactive state management for StatefulWidget.
///
/// This mixin automatically manages the lifecycle of signals and effects,
/// disposing them when the widget is disposed.
///
/// Example:
/// ```dart
/// class _MyWidgetState extends State<MyWidget> with SignalStateMixin {
///   late final Signal<int> count;
///
///   @override
///   void initState() {
///     super.initState();
///     count = createSignal(0);
///     createEffect(() {
///       print('Count changed: ${count()}');
///     });
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return count.builder((context, value) => Text('$value'));
///   }
/// }
/// ```
mixin SignalStateMixin<T extends StatefulWidget> on State<T> {
  EffectScope? _scope;
  final List<Effect> _effects = [];

  /// Gets or creates the effect scope for this widget.
  EffectScope get scope {
    return _scope ??= effectScope(() {});
  }

  /// Creates a new signal that will be tracked by this widget's scope.
  Signal<V> createSignal<V>(V initialValue) {
    return signal(initialValue);
  }

  /// Creates a new computed that will be tracked by this widget's scope.
  Computed<V> createComputed<V>(V Function(V? prev) getter) {
    return computed(getter);
  }

  /// Creates a new effect that will be automatically disposed when the widget is disposed.
  Effect createEffect(void Function() fn) {
    final eff = effect(fn);
    _effects.add(eff);
    return eff;
  }

  /// Creates an effect that triggers a rebuild when dependencies change.
  ///
  /// This is useful when you want to rebuild the widget when signals change
  /// without using SignalBuilder.
  ///
  /// Note: Consider using [SignalBuilder] or [ReactiveBuilder] instead for
  /// more explicit dependency tracking.
  Effect createReactiveEffect(void Function() fn) {
    final eff = effect(() {
      fn();
      if (mounted) {
        _triggerRebuild();
      }
    });
    _effects.add(eff);
    return eff;
  }

  /// Triggers a rebuild of the widget. Override this if needed.
  void _triggerRebuild() {
    (this as dynamic).setState(() {});
  }

  @override
  void dispose() {
    // Stop all effects
    for (final eff in _effects) {
      eff.stop();
    }
    _effects.clear();

    // Stop the scope
    _scope?.stop();
    _scope = null;

    super.dispose();
  }
}

/// A mixin for reactive state management without needing a StatefulWidget.
///
/// This mixin provides lifecycle-aware signal management that integrates
/// with Flutter's widget lifecycle.
mixin ReactiveStateMixin<T extends StatefulWidget> on State<T> {
  EffectScope? _reactiveScope;
  bool _isInitialized = false;

  /// Initialize reactive state. Call this in initState().
  void initReactive(void Function() setup) {
    assert(!_isInitialized, 'initReactive can only be called once');
    _isInitialized = true;
    _reactiveScope = effectScope(setup);
  }

  /// Run a function within the reactive scope.
  void runInScope(void Function() fn) {
    assert(_isInitialized, 'Call initReactive first');
    fn();
  }

  @override
  void dispose() {
    _reactiveScope?.stop();
    _reactiveScope = null;
    super.dispose();
  }
}

/// Widget that creates an effect scope for its children.
///
/// All effects created within descendant widgets can access this scope's
/// context and will be disposed when this widget is disposed.
class ReactiveScope extends StatefulWidget {
  /// The child widget.
  final Widget child;

  /// Optional callback when the scope is created.
  final void Function(EffectScope scope)? onScopeCreated;

  const ReactiveScope({
    super.key,
    required this.child,
    this.onScopeCreated,
  });

  @override
  State<ReactiveScope> createState() => _ReactiveScopeState();
}

class _ReactiveScopeState extends State<ReactiveScope> {
  late final EffectScope _scope;

  @override
  void initState() {
    super.initState();
    _scope = effectScope(() {
      widget.onScopeCreated?.call(_scope);
    });
  }

  @override
  void dispose() {
    _scope.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
