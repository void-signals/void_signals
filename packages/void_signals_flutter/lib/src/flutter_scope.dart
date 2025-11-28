import 'package:flutter/widgets.dart';
import 'package:void_signals/void_signals.dart';

/// Provides an [EffectScope] to descendant widgets.
///
/// Use this widget to create a scope that manages the lifecycle of effects
/// created by descendant widgets. When this widget is disposed, all effects
/// in the scope will be stopped.
///
/// Example:
/// ```dart
/// EffectScopeProvider(
///   builder: (context, scope, child) {
///     // Access scope here if needed
///     return child!;
///   },
///   child: MyWidget(),
/// )
/// ```
class EffectScopeProvider extends StatefulWidget {
  /// The child widget.
  final Widget child;

  /// Builder function that provides access to the scope.
  final Widget Function(BuildContext context, EffectScope scope, Widget? child)
      builder;

  const EffectScopeProvider({
    super.key,
    required this.child,
    required this.builder,
  });

  @override
  State<EffectScopeProvider> createState() => _EffectScopeProviderState();
}

class _EffectScopeProviderState extends State<EffectScopeProvider> {
  late final EffectScope _scope;

  @override
  void initState() {
    super.initState();
    _scope = effectScope(() {});
  }

  @override
  void dispose() {
    _scope.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _EffectScopeInherited(
      scope: _scope,
      child: widget.builder(context, _scope, widget.child),
    );
  }
}

/// InheritedWidget that provides access to the current EffectScope.
class _EffectScopeInherited extends InheritedWidget {
  final EffectScope scope;

  const _EffectScopeInherited({
    required this.scope,
    required super.child,
  });

  static EffectScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_EffectScopeInherited>()
        ?.scope;
  }

  static EffectScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'No EffectScopeProvider found in widget tree');
    return scope!;
  }

  @override
  bool updateShouldNotify(_EffectScopeInherited oldWidget) {
    return scope != oldWidget.scope;
  }
}

/// Gets the [EffectScope] from the widget tree.
///
/// Returns null if no [EffectScopeProvider] is found.
EffectScope? getEffectScope(BuildContext context) {
  return _EffectScopeInherited.maybeOf(context);
}

/// Gets the [EffectScope] from the widget tree.
///
/// Throws an assertion error if no [EffectScopeProvider] is found.
EffectScope requireEffectScope(BuildContext context) {
  return _EffectScopeInherited.of(context);
}

/// A widget that creates an [EffectScope] and provides it to descendants.
///
/// This is a simpler version of [EffectScopeProvider] that doesn't require
/// a builder function.
///
/// Example:
/// ```dart
/// EffectScopeWidget(
///   onScopeCreated: (scope) {
///     // Setup effects here
///   },
///   child: MyWidget(),
/// )
/// ```
class EffectScopeWidget extends StatefulWidget {
  /// The child widget.
  final Widget child;

  /// Optional callback when the scope is created.
  final void Function(EffectScope scope)? onScopeCreated;

  const EffectScopeWidget({
    super.key,
    required this.child,
    this.onScopeCreated,
  });

  @override
  State<EffectScopeWidget> createState() => _EffectScopeWidgetState();
}

class _EffectScopeWidgetState extends State<EffectScopeWidget> {
  late final EffectScope _scope;

  @override
  void initState() {
    super.initState();
    _scope = effectScope(() {});
    widget.onScopeCreated?.call(_scope);
  }

  @override
  void dispose() {
    _scope.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _EffectScopeInherited(
      scope: _scope,
      child: widget.child,
    );
  }
}

/// Extension methods for [BuildContext] to access reactive features.
extension ReactiveContextExtension on BuildContext {
  /// Gets the [EffectScope] from the widget tree.
  ///
  /// Returns null if no [EffectScopeProvider] is found.
  EffectScope? get maybeEffectScope => getEffectScope(this);

  /// Gets the [EffectScope] from the widget tree.
  ///
  /// Throws an assertion error if no [EffectScopeProvider] is found.
  EffectScope get effectScope => requireEffectScope(this);
}
