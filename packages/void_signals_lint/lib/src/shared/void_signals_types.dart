import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Type matchers for void_signals package.
///
/// These TypeCheckers provide reliable type matching for void_signals types,
/// similar to Riverpod's riverpod_analyzer_utils approach.

// ============================================================================
// Core void_signals types
// ============================================================================

/// Matches the Signal type from void_signals.
const signalType = TypeChecker.fromName(
  'Signal',
  packageName: 'void_signals',
);

/// Matches the Computed type from void_signals.
const computedType = TypeChecker.fromName(
  'Computed',
  packageName: 'void_signals',
);

/// Matches the Effect type from void_signals.
const effectType = TypeChecker.fromName(
  'Effect',
  packageName: 'void_signals',
);

/// Matches the EffectScope type from void_signals.
const effectScopeType = TypeChecker.fromName(
  'EffectScope',
  packageName: 'void_signals',
);

/// Matches any reactive type (Signal, Computed, Effect, EffectScope).
bool isReactiveType(DartType type) {
  return signalType.isExactlyType(type) ||
      computedType.isExactlyType(type) ||
      effectType.isExactlyType(type) ||
      effectScopeType.isExactlyType(type);
}

/// Matches Signal or Computed (readable reactive values).
bool isReadableReactiveType(DartType type) {
  return signalType.isExactlyType(type) || computedType.isExactlyType(type);
}

// ============================================================================
// void_signals_flutter types
// ============================================================================

/// Matches the Watch widget type.
const watchWidgetType = TypeChecker.fromName(
  'Watch',
  packageName: 'void_signals_flutter',
);

/// Matches the WatchValue widget type.
const watchValueWidgetType = TypeChecker.fromName(
  'WatchValue',
  packageName: 'void_signals_flutter',
);

/// Matches the SignalBuilder widget type.
const signalBuilderType = TypeChecker.fromName(
  'SignalBuilder',
  packageName: 'void_signals_flutter',
);

/// Matches the ComputedBuilder widget type.
const computedBuilderType = TypeChecker.fromName(
  'ComputedBuilder',
  packageName: 'void_signals_flutter',
);

/// Matches the Consumer widget type.
const consumerWidgetType = TypeChecker.fromName(
  'Consumer',
  packageName: 'void_signals_flutter',
);

/// Matches the ConsumerWidget type.
const consumerWidgetBaseType = TypeChecker.fromName(
  'ConsumerWidget',
  packageName: 'void_signals_flutter',
);

/// Matches the ConsumerStatefulWidget type.
const consumerStatefulWidgetType = TypeChecker.fromName(
  'ConsumerStatefulWidget',
  packageName: 'void_signals_flutter',
);

/// Matches the ConsumerState type.
const consumerStateType = TypeChecker.fromName(
  'ConsumerState',
  packageName: 'void_signals_flutter',
);

/// Matches the SignalRef type.
const signalRefType = TypeChecker.fromName(
  'SignalRef',
  packageName: 'void_signals_flutter',
);

/// Matches the SignalScope widget type.
const signalScopeType = TypeChecker.fromName(
  'SignalScope',
  packageName: 'void_signals_flutter',
);

/// Matches the EffectScopeProvider widget type.
const effectScopeProviderType = TypeChecker.fromName(
  'EffectScopeProvider',
  packageName: 'void_signals_flutter',
);

// ============================================================================
// void_signals_hooks types
// ============================================================================

/// Matches the HookWidget type from flutter_hooks.
const hookWidgetType = TypeChecker.fromName(
  'HookWidget',
  packageName: 'flutter_hooks',
);

/// Matches the StatefulHookWidget type from flutter_hooks.
const statefulHookWidgetType = TypeChecker.fromName(
  'StatefulHookWidget',
  packageName: 'flutter_hooks',
);

// ============================================================================
// Flutter types
// ============================================================================

/// Matches Flutter's Widget type.
const flutterWidgetType = TypeChecker.fromName(
  'Widget',
  packageName: 'flutter',
);

/// Matches Flutter's StatelessWidget type.
const statelessWidgetType = TypeChecker.fromName(
  'StatelessWidget',
  packageName: 'flutter',
);

/// Matches Flutter's StatefulWidget type.
const statefulWidgetType = TypeChecker.fromName(
  'StatefulWidget',
  packageName: 'flutter',
);

/// Matches Flutter's State type.
const stateType = TypeChecker.fromName(
  'State',
  packageName: 'flutter',
);

/// Matches Flutter's BuildContext type.
const buildContextType = TypeChecker.fromName(
  'BuildContext',
  packageName: 'flutter',
);

/// Matches Flutter's ValueNotifier type.
const valueNotifierType = TypeChecker.fromName(
  'ValueNotifier',
  packageName: 'flutter',
);

/// Matches Flutter's ChangeNotifier type.
const changeNotifierType = TypeChecker.fromName(
  'ChangeNotifier',
  packageName: 'flutter',
);

// ============================================================================
// Utility extensions
// ============================================================================

/// Extension to check if an element is from void_signals packages.
extension VoidSignalsElementExtension on Element {
  /// Returns true if this element is from the void_signals package.
  bool get isFromVoidSignals {
    final lib = library;
    if (lib == null) return false;
    return lib.identifier.contains('void_signals');
  }

  /// Returns true if this element is from the void_signals_flutter package.
  bool get isFromVoidSignalsFlutter {
    final lib = library;
    if (lib == null) return false;
    return lib.identifier.contains('void_signals_flutter');
  }

  /// Returns true if this element is from the void_signals_hooks package.
  bool get isFromVoidSignalsHooks {
    final lib = library;
    if (lib == null) return false;
    return lib.identifier.contains('void_signals_hooks');
  }
}

/// Extension to check if a type is a Signal or Computed.
extension VoidSignalsTypeExtension on DartType {
  /// Returns true if this is a Signal type.
  bool get isSignal => signalType.isAssignableFromType(this);

  /// Returns true if this is a Computed type.
  bool get isComputed => computedType.isAssignableFromType(this);

  /// Returns true if this is an Effect type.
  bool get isEffect => effectType.isAssignableFromType(this);

  /// Returns true if this is an EffectScope type.
  bool get isEffectScope => effectScopeType.isAssignableFromType(this);

  /// Returns true if this is any reactive type (Signal, Computed, Effect).
  bool get isReactive => isSignal || isComputed || isEffect || isEffectScope;

  /// Returns true if this is a readable reactive type (Signal or Computed).
  bool get isReadableReactive => isSignal || isComputed;

  /// Returns true if this is a Flutter Widget type.
  bool get isWidget => flutterWidgetType.isAssignableFromType(this);

  /// Returns true if this is a StatelessWidget type.
  bool get isStatelessWidget => statelessWidgetType.isAssignableFromType(this);

  /// Returns true if this is a StatefulWidget type.
  bool get isStatefulWidget => statefulWidgetType.isAssignableFromType(this);

  /// Returns true if this is a State type.
  bool get isState => stateType.isAssignableFromType(this);

  /// Returns true if this is a HookWidget type.
  bool get isHookWidget =>
      hookWidgetType.isAssignableFromType(this) ||
      statefulHookWidgetType.isAssignableFromType(this);

  /// Returns true if this is a ConsumerWidget or ConsumerStatefulWidget.
  bool get isConsumerWidget =>
      consumerWidgetBaseType.isAssignableFromType(this) ||
      consumerStatefulWidgetType.isAssignableFromType(this);

  /// Returns true if this is a ValueNotifier type.
  bool get isValueNotifier => valueNotifierType.isAssignableFromType(this);

  /// Returns true if this is a ChangeNotifier type.
  bool get isChangeNotifier => changeNotifierType.isAssignableFromType(this);
}
