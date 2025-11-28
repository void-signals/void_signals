import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'void_signals_ast_registry.dart';

/// Base class for void_signals lint rules.
///
/// Similar to Riverpod's RiverpodLintRule, this class provides automatic
/// setup of the VoidSignalsAstRegistry and convenient access to it.
abstract class VoidSignalsLintRule extends DartLintRule with _ParseVoidSignals {
  const VoidSignalsLintRule({required super.code});

  @override
  Future<void> startUp(
    CustomLintResolver resolver,
    CustomLintContext context,
  ) async {
    await _setupRegistry(resolver, context);
    await super.startUp(resolver, context);
  }

  @override
  List<DartFix> getFixes() => [];
}

/// Base class for void_signals assists.
abstract class VoidSignalsAssist extends DartAssist with _ParseVoidSignals {
  @override
  Future<void> startUp(
    CustomLintResolver resolver,
    CustomLintContext context,
    SourceRange target,
  ) async {
    await _setupRegistry(resolver, context);
    await super.startUp(resolver, context, target);
  }
}

/// Base class for void_signals fixes.
abstract class VoidSignalsFix extends DartFix with _ParseVoidSignals {
  @override
  Future<void> startUp(
    CustomLintResolver resolver,
    CustomLintContext context,
  ) async {
    await _setupRegistry(resolver, context);
    await super.startUp(resolver, context);
  }
}

mixin _ParseVoidSignals {
  static final _contextKey = Object();

  Future<void> _setupRegistry(
    CustomLintResolver resolver,
    CustomLintContext context,
  ) async {
    if (context.sharedState.containsKey(_contextKey)) return;
    // Only run the parsing logic once
    final registry =
        context.sharedState[_contextKey] = VoidSignalsAstRegistry();
    final unit = await resolver.getResolvedUnitResult();

    context.addPostRunCallback(() => registry.run(unit.unit));
  }

  /// Get the VoidSignalsAstRegistry for the current context.
  VoidSignalsAstRegistry voidSignalsRegistry(CustomLintContext context) {
    final registry = context.sharedState[_ParseVoidSignals._contextKey]
        as VoidSignalsAstRegistry?;
    if (registry == null) {
      throw StateError('VoidSignalsAstRegistry not initialized');
    }
    return registry;
  }
}

/// Extension for source range operations.
extension SourceRangeFrom on Object {
  static SourceRange from({required int start, required int end}) {
    return SourceRange(start, end - start);
  }
}
