import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../shared/void_signals_custom_lint.dart';
import '../shared/void_signals_ast_registry.dart';

/// Lint rule that warns when .value is accessed after an await statement.
///
/// Signal values accessed after await may be stale, as the signal could have
/// changed while awaiting. This is a common source of bugs in async code.
///
/// **BAD:**
/// ```dart
/// void handleClick() async {
///   final before = count.value;
///   await fetchData();
///   count.value = count.value + 1;  // ❌ count.value might have changed!
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// void handleClick() async {
///   final before = count.value;
///   await fetchData();
///   // Re-read the signal after await
///   final current = count.value;
///   count.value = current + 1;  // ✅ Clear that we're reading fresh value
/// }
///
/// // Or use peek() to show intent of reading current value
/// void handleClick() async {
///   await fetchData();
///   count.value = count.peek() + 1;  // ✅ Explicit current value access
/// }
/// ```
class AvoidSignalAccessAfterAwait extends VoidSignalsLintRule {
  const AvoidSignalAccessAfterAwait() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_signal_access_after_await',
    problemMessage:
        'Accessing signal.value after await may return a stale value. '
        'The signal may have changed while awaiting.',
    correctionMessage:
        'Consider using signal.peek() to explicitly acknowledge reading '
        'the current value, or re-read the signal into a local variable.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    voidSignalsRegistry(context).addSignalAccess((access) {
      // Only warn about .value access (not .peek())
      if (access.kind != SignalAccessKind.value) return;

      // Only warn in async context
      if (!access.isInsideAsyncContext) return;

      // Check if this access is after an await in the same method
      final method = access.enclosingMethod;
      if (method == null) return;
      if (!method.body.isAsynchronous) return;

      // Check if there's an await before this access
      if (_hasAwaitBefore(method.body, access.node)) {
        reporter.atNode(access.node, code);
      }
    });
  }

  bool _hasAwaitBefore(FunctionBody body, AstNode targetNode) {
    // Simple heuristic: check if there's any await in the method before this node
    final awaitPositions = <int>[];
    body.accept(_AwaitFinder(awaitPositions));

    final targetOffset = targetNode.offset;
    return awaitPositions.any((pos) => pos < targetOffset);
  }

  @override
  List<DartFix> getFixes() => [_UsePeekInsteadFix()];
}

class _AwaitFinder extends RecursiveAstVisitor<void> {
  _AwaitFinder(this.positions);
  final List<int> positions;

  @override
  void visitAwaitExpression(AwaitExpression node) {
    positions.add(node.offset);
    super.visitAwaitExpression(node);
  }
}

class _UsePeekInsteadFix extends VoidSignalsFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    voidSignalsRegistry(context).addSignalAccess((access) {
      if (access.kind != SignalAccessKind.value) return;
      if (!analysisError.sourceRange.intersects(SourceRangeFrom.from(
          start: access.node.offset, end: access.node.end))) {
        return;
      }

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Use .peek() instead of .value',
        priority: 70,
      );

      changeBuilder.addDartFileEdit((builder) {
        // Find .value and replace with .peek()
        final node = access.node;
        if (node is PrefixedIdentifier) {
          builder.addSimpleReplacement(
            node.identifier.sourceRange,
            'peek()',
          );
        } else if (node is PropertyAccess) {
          builder.addSimpleReplacement(
            node.propertyName.sourceRange,
            'peek()',
          );
        }
      });
    });
  }
}
