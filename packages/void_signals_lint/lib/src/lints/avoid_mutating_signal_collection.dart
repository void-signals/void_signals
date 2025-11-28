import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that warns against directly mutating signal collection values.
///
/// When a signal holds a List, Map, or Set, directly mutating the collection
/// won't trigger updates. You should use SignalList, SignalMap, SignalSet,
/// or create a new collection.
///
/// **BAD:**
/// ```dart
/// final items = signal<List<String>>([]);
/// items.value.add('item');  // ❌ Won't trigger update!
/// ```
///
/// **GOOD:**
/// ```dart
/// // Option 1: Use SignalList
/// final items = SignalList<String>([]);
/// items.add('item');  // ✅ Triggers update
///
/// // Option 2: Replace the list
/// final items = signal<List<String>>([]);
/// items.value = [...items.value, 'item'];  // ✅ Triggers update
///
/// // Option 3: Use update method
/// items.update((list) => [...list, 'item']);  // ✅ Triggers update
/// ```
class AvoidMutatingSignalCollection extends DartLintRule {
  const AvoidMutatingSignalCollection() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_mutating_signal_collection',
    problemMessage:
        'Directly mutating a signal collection will not trigger updates.',
    correctionMessage:
        'Use SignalList/SignalMap/SignalSet for mutable collections, '
        'or replace the collection with a new one.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  /// Mutating methods for List
  static const _listMutatingMethods = {
    'add',
    'addAll',
    'insert',
    'insertAll',
    'remove',
    'removeAt',
    'removeLast',
    'removeRange',
    'removeWhere',
    'retainWhere',
    'clear',
    'fillRange',
    'setRange',
    'replaceRange',
    'setAll',
    'sort',
    'shuffle',
  };

  /// Mutating methods for Map
  static const _mapMutatingMethods = {
    'addAll',
    'addEntries',
    'remove',
    'removeWhere',
    'clear',
    'update',
    'updateAll',
    'putIfAbsent',
  };

  /// Mutating methods for Set
  static const _setMutatingMethods = {
    'add',
    'addAll',
    'remove',
    'removeAll',
    'removeWhere',
    'retainAll',
    'retainWhere',
    'clear',
  };

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      final methodName = node.methodName.name;

      // Check if it's a mutating method
      final isMutating = _listMutatingMethods.contains(methodName) ||
          _mapMutatingMethods.contains(methodName) ||
          _setMutatingMethods.contains(methodName);

      if (!isMutating) return;

      // Check if it's called on .value of a signal
      final target = node.target;
      if (target is! PropertyAccess && target is! PrefixedIdentifier) return;

      final propertyName = switch (target) {
        PropertyAccess() => target.propertyName.name,
        PrefixedIdentifier() => target.identifier.name,
        _ => null,
      };

      if (propertyName != 'value') return;

      reporter.atNode(node, code);
    });

    // Also check for index assignment: items.value[0] = 'new'
    context.registry.addAssignmentExpression((node) {
      final left = node.leftHandSide;
      if (left is! IndexExpression) return;

      final target = left.target;
      if (target is! PropertyAccess && target is! PrefixedIdentifier) return;

      final propertyName = switch (target) {
        PropertyAccess() => target.propertyName.name,
        PrefixedIdentifier() => target.identifier.name,
        _ => null,
      };

      if (propertyName != 'value') return;

      reporter.atNode(node, code);
    });
  }

  @override
  List<Fix> getFixes() => [_UseSignalCollectionFix(), _ReplaceCollectionFix()];
}

/// Quick fix to suggest using SignalList/SignalMap/SignalSet.
class _UseSignalCollectionFix extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    // This is a documentation-only fix since we can't easily transform the code
    // The fix suggestion is shown in the message but no automatic changes are made
    reporter.createChangeBuilder(
      message: 'Consider using SignalList, SignalMap, or SignalSet',
      priority: 70,
    );
  }
}

/// Quick fix to replace the collection.
class _ReplaceCollectionFix extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    context.registry.addMethodInvocation((node) {
      if (!analysisError.sourceRange.intersects(node.sourceRange)) return;

      final methodName = node.methodName.name;
      final target = node.target;

      // Only handle simple 'add' case for now
      if (methodName != 'add') return;
      if (target is! PrefixedIdentifier) return;

      final signalExpr = target.prefix.name;
      final argument = node.argumentList.arguments.firstOrNull;
      if (argument == null) return;

      final statement = node.thisOrAncestorOfType<ExpressionStatement>();
      if (statement == null) return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Replace with new list',
        priority: 80,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleReplacement(
          statement.sourceRange,
          '$signalExpr.value = [...$signalExpr.value, ${argument.toSource()}];',
        );
      });
    });
  }
}
