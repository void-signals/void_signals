/// Custom lint rules for void_signals and void_signals_hooks.
///
/// This package provides comprehensive static analysis tools for the void_signals
/// library, helping developers catch common mistakes, follow best practices,
/// and write more maintainable reactive code.
///
/// ## Usage
///
/// Add to your `pubspec.yaml`:
/// ```yaml
/// dev_dependencies:
///   void_signals_lint: ^1.0.0
///   custom_lint: ^0.8.0
/// ```
///
/// Enable in `analysis_options.yaml`:
/// ```yaml
/// analyzer:
///   plugins:
///     - custom_lint
/// ```
///
/// ## Available Rules
///
/// ### Signal Creation & Management
///
/// - `avoid_signal_in_build` - Prevents creating signals in build methods
/// - `avoid_signal_creation_in_builder` - Prevents signal creation in SignalBuilder
/// - `prefer_final_signal` - Enforces final declarations for signals
/// - `prefer_signal_with_label` - Suggests adding debug labels
/// - `prefer_signal_over_value_notifier` - Suggests Signal over ValueNotifier
/// - `prefer_signal_scope_for_di` - Suggests SignalScope for DI patterns
///
/// ### Reactive Patterns
///
/// - `prefer_watch_over_effect_in_widget` - Suggests Watch widget over effects
/// - `watch_without_signal_access` - Warns when Watch doesn't access signals
/// - `prefer_computed_over_derived_signal` - Suggests computed for derived state
/// - `prefer_batch_for_multiple_updates` - Suggests batch for multiple updates
/// - `prefer_peek_in_non_reactive` - Suggests peek() in non-reactive contexts
///
/// ### Effect & Scope Management
///
/// - `avoid_nested_effect_scope` - Prevents nested effect scopes
/// - `missing_effect_cleanup` - Ensures effects are properly cleaned up
/// - `missing_scope_dispose` - Ensures EffectScopes are disposed
/// - `avoid_effect_for_ui` - Warns against using effects for UI updates
///
/// ### Async & State
///
/// - `avoid_signal_access_in_async` - Warns about stale values after await
/// - `avoid_async_in_computed` - Prevents async operations in computed
/// - `avoid_mutating_signal_collection` - Prevents direct collection mutation
/// - `avoid_circular_computed` - Detects circular dependencies
/// - `prefer_async_computed_for_tracked` - Suggests asyncComputed when signals are read
/// - `async_computed_dependency_tracking` - Warns about signal reads after await in asyncComputed
///
/// ### Flutter Integration
///
/// - `caution_signal_in_init_state` - Cautions about signal access in initState
/// - `avoid_set_state_with_signals` - Warns against unnecessary setState
/// - `unnecessary_untrack` - Flags unnecessary untrack calls
///
/// ### Hooks Rules (void_signals_hooks)
///
/// - `hooks_outside_hook_widget` - Ensures hooks are called in HookWidget.build()
/// - `conditional_hook_call` - Prevents hooks in conditionals/loops
/// - `hook_in_callback` - Prevents hooks inside callbacks
/// - `use_signal_without_watch` - Warns when useSignal is not watched
/// - `use_effect_without_dependency` - Warns when useSignalEffect has no deps
/// - `prefer_use_computed_over_effect` - Suggests useComputed for derived values
/// - `use_debounced_zero_duration` - Warns against zero duration debounce
/// - `prefer_use_signal_with_label` - Suggests debug labels for hooks
/// - `use_select_pure_selector` - Ensures useSelect selector is pure
/// - `unnecessary_use_batch` - Flags unnecessary useBatch
/// - `unnecessary_use_untrack` - Flags unnecessary useUntrack
///
/// ## Quick Fixes
///
/// Most rules come with automatic quick fixes accessible via the IDE's
/// quick action menu (Ctrl/Cmd + .).
library void_signals_lint;

import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

// Signal Creation & Management
import 'src/lints/avoid_signal_in_build.dart';
import 'src/lints/avoid_signal_creation_in_builder.dart';
import 'src/lints/prefer_final_signal.dart';
import 'src/lints/prefer_signal_with_label.dart';
import 'src/lints/prefer_signal_over_value_notifier.dart';
import 'src/lints/prefer_signal_scope_for_di.dart';

// Reactive Patterns
import 'src/lints/prefer_watch_over_effect_in_widget.dart';
import 'src/lints/watch_without_signal_access.dart';
import 'src/lints/prefer_computed_over_derived_signal.dart';
import 'src/lints/prefer_batch_for_multiple_updates.dart';
import 'src/lints/prefer_peek_in_non_reactive.dart';
import 'src/lints/prefer_watch_over_effect_for_ui.dart';

// Effect & Scope Management
import 'src/lints/avoid_nested_effect_scope.dart';
import 'src/lints/missing_effect_cleanup.dart';
import 'src/lints/missing_scope_dispose.dart';
import 'src/lints/avoid_effect_for_ui.dart';
import 'src/lints/avoid_effect_in_build.dart';

// Async & State
import 'src/lints/avoid_signal_access_in_async.dart';
import 'src/lints/avoid_signal_access_after_await.dart';
import 'src/lints/avoid_async_in_computed.dart';
import 'src/lints/avoid_mutating_signal_collection.dart';
import 'src/lints/avoid_circular_computed.dart';
import 'src/lints/prefer_async_computed_for_tracked.dart';
import 'src/lints/async_computed_dependency_tracking.dart';

// Flutter Integration
import 'src/lints/caution_signal_in_init_state.dart';
import 'src/lints/avoid_set_state_with_signals.dart';
import 'src/lints/unnecessary_untrack.dart';

// Hooks Rules
import 'src/hooks_rules/hooks_outside_hook_widget.dart';
import 'src/hooks_rules/conditional_hook_call.dart';
import 'src/hooks_rules/hook_in_callback.dart';
import 'src/hooks_rules/use_signal_without_watch.dart';
import 'src/hooks_rules/use_effect_without_dependency.dart';
import 'src/hooks_rules/prefer_use_computed_over_effect.dart';
import 'src/hooks_rules/use_debounced_zero_duration.dart';
import 'src/hooks_rules/prefer_use_signal_with_label.dart';
import 'src/hooks_rules/use_select_pure_selector.dart';
import 'src/hooks_rules/unnecessary_use_batch.dart';
import 'src/hooks_rules/unnecessary_use_untrack.dart';

// Enhanced Assists
import 'src/assists/widget_assists.dart';
import 'src/assists/conversion_assists.dart';

/// The entrypoint for the custom linter plugin.
///
/// This is called by custom_lint to get all the lint rules defined
/// in this package.
PluginBase createPlugin() => _VoidSignalsLinter();

/// The main plugin class that provides all void_signals lint rules.
///
/// This linter provides comprehensive coverage for common mistakes and
/// best practices when working with void_signals. All rules are designed
/// to provide helpful error messages and quick fixes.
class _VoidSignalsLinter extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        // Signal Creation & Management (Errors/Warnings)
        const AvoidSignalInBuild(),
        const AvoidSignalCreationInBuilder(),
        const PreferFinalSignal(),

        // Reactive Patterns
        const PreferWatchOverEffectInWidget(),
        const WatchWithoutSignalAccess(),
        const PreferComputedOverDerivedSignal(),
        const PreferBatchForMultipleUpdates(),

        // Effect & Scope Management
        const AvoidNestedEffectScope(),
        const MissingEffectCleanup(),
        const MissingScopeDispose(),
        const AvoidEffectForUI(),
        const AvoidEffectInBuild(),

        // Async & State (Critical)
        const AvoidSignalAccessInAsync(),
        const AvoidAsyncInComputed(),
        const AvoidMutatingSignalCollection(),
        const AvoidCircularComputed(),
        const AvoidSignalAccessAfterAwait(),
        const PreferAsyncComputedForTracked(),
        const AsyncComputedDependencyTracking(),

        // Flutter Integration
        const CautionSignalInInitState(),
        const AvoidSetStateWithSignals(),
        const UnnecessaryUntrack(),
        const PreferWatchOverEffectForUI(),

        // Info/Suggestions (less critical)
        const PreferSignalWithLabel(),
        const PreferSignalOverValueNotifier(),
        const PreferSignalScopeForDI(),
        const PreferPeekInNonReactive(),

        // Hooks Rules (Critical)
        const HooksOutsideHookWidget(),
        const ConditionalHookCall(),
        const HookInCallback(),

        // Hooks Rules (Warnings)
        const UseSignalWithoutWatch(),
        const UseSelectPureSelector(),
        const UseDebouncedZeroDuration(),

        // Hooks Rules (Info)
        const UseEffectWithoutDependency(),
        const PreferUseComputedOverEffect(),
        const PreferUseSignalWithLabel(),
        const UnnecessaryUseBatch(),
        const UnnecessaryUseUntrack(),
      ];

  @override
  List<Assist> getAssists() => [
        // Widget wrapping assists
        WrapWithWatch(),
        WrapWithSignalBuilder(),
        WrapWithConsumer(),
        _WrapWithEffectScope(),

        // Conversion assists
        ConvertToConsumerWidget(),
        ConvertToConsumerStatefulWidget(),
        ConvertHookWidgetToStateless(),
        AddSignalStateMixin(),
        ConvertValueNotifierToSignal(),

        // Signal utilities
        AddSignalDebugLabel(),
        ExtractSignalInitialValue(),
        _ConvertToComputed(),
        _WrapWithBatch(),
        ConvertEffectToWatch(),
      ];
}

/// Assist to wrap code with effectScope.
class _WrapWithEffectScope extends DartAssist {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    SourceRange target,
  ) {
    context.registry.addBlock((node) {
      if (!target.intersects(node.sourceRange)) return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Wrap with effectScope',
        priority: 28,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleInsertion(
            node.offset, 'final scope = effectScope(() ');
        builder.addSimpleInsertion(
            node.end, ');\n// Remember to call scope.stop() when done');
      });
    });
  }
}

/// Assist to convert effect with signal update to computed.
class _ConvertToComputed extends DartAssist {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    SourceRange target,
  ) {
    context.registry.addMethodInvocation((node) {
      if (!target.intersects(node.sourceRange)) return;
      if (node.methodName.name != 'effect') return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Convert to computed',
        priority: 27,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleReplacement(
          node.methodName.sourceRange,
          'computed',
        );
      });
    });
  }
}

/// Assist to wrap multiple statements with batch.
class _WrapWithBatch extends DartAssist {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    SourceRange target,
  ) {
    context.registry.addBlock((node) {
      if (!target.intersects(node.sourceRange)) return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Wrap with batch()',
        priority: 26,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleInsertion(node.offset, 'batch(() ');
        builder.addSimpleInsertion(node.end, ')');
      });
    });
  }
}

/// Extension for source range operations.
extension SourceRangeIntersects on SourceRange {
  bool intersects(SourceRange other) {
    return offset < other.offset + other.length &&
        offset + length > other.offset;
  }
}
