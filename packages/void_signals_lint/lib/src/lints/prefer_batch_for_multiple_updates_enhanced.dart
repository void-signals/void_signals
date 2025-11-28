import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../shared/void_signals_types.dart';

/// Lint rule that suggests using batch() for multiple signal updates.
///
/// When updating multiple signals at once, use batch() to:
/// - Prevent intermediate states from triggering effects
/// - Improve performance by combining updates
/// - Ensure atomic state transitions
///
/// **BAD:**
/// ```dart
/// void updateUserProfile(String name, int age) {
///   userName.value = name;   // ❌ Triggers effects
///   userAge.value = age;     // ❌ Triggers effects again
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// void updateUserProfile(String name, int age) {
///   batch(() {
///     userName.value = name;   // ✅ Combined
///     userAge.value = age;     // ✅ Single notification
///   });
/// }
/// ```
class PreferBatchForMultipleUpdates extends DartLintRule {
  const PreferBatchForMultipleUpdates() : super(code: _code);

  static const _code = LintCode(
    name: 'prefer_batch_for_multiple_updates',
    problemMessage:
        'Multiple signal updates in sequence should be wrapped in batch() '
        'to avoid triggering effects multiple times.',
    correctionMessage:
        'Wrap these updates in batch(() { ... }) for better performance.',
    errorSeverity: ErrorSeverity.INFO,
  );

  static const _minUpdatesForWarning = 2;

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addBlock((node) {
      // Find consecutive signal assignments not in a batch
      if (_isInsideBatch(node)) return;

      final signalAssignments = <ExpressionStatement>[];

      for (final stmt in node.statements) {
        if (stmt is! ExpressionStatement) continue;
        final expr = stmt.expression;

        // Check for signal.value = x patterns
        if (_isSignalValueAssignment(expr)) {
          signalAssignments.add(stmt);
        } else {
          // Non-signal statement breaks the sequence
          if (signalAssignments.length >= _minUpdatesForWarning) {
            _reportConsecutiveUpdates(reporter, signalAssignments);
          }
          signalAssignments.clear();
        }
      }

      // Check remaining assignments at end of block
      if (signalAssignments.length >= _minUpdatesForWarning) {
        _reportConsecutiveUpdates(reporter, signalAssignments);
      }
    });
  }

  bool _isInsideBatch(AstNode node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is MethodInvocation && current.methodName.name == 'batch') {
        return true;
      }
      current = current.parent;
    }
    return false;
  }

  bool _isSignalValueAssignment(Expression expr) {
    if (expr is! AssignmentExpression) return false;

    final lhs = expr.leftHandSide;
    if (lhs is PrefixedIdentifier && lhs.identifier.name == 'value') {
      final prefixType = lhs.prefix.staticType;
      if (prefixType != null && prefixType.isSignal) {
        return true;
      }
    }
    if (lhs is PropertyAccess && lhs.propertyName.name == 'value') {
      final targetType = lhs.target?.staticType;
      if (targetType != null && targetType.isSignal) {
        return true;
      }
    }
    return false;
  }

  void _reportConsecutiveUpdates(
    ErrorReporter reporter,
    List<ExpressionStatement> statements,
  ) {
    // Report on the first statement
    reporter.atNode(statements.first.expression, code);
  }

  @override
  List<DartFix> getFixes() => [_WrapWithBatchFix()];
}

class _WrapWithBatchFix extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    context.registry.addExpressionStatement((node) {
      if (!analysisError.sourceRange.intersects(node.sourceRange)) return;

      // Find the block containing this statement
      final block = node.parent;
      if (block is! Block) return;

      // Find all consecutive signal assignments starting from this one
      final startIndex = block.statements.indexOf(node);
      if (startIndex < 0) return;

      int endIndex = startIndex;
      for (int i = startIndex; i < block.statements.length; i++) {
        final stmt = block.statements[i];
        if (stmt is! ExpressionStatement) break;
        if (!_isSignalValueAssignment(stmt.expression)) break;
        endIndex = i;
      }

      if (endIndex <= startIndex) return;

      final firstStmt = block.statements[startIndex];
      final lastStmt = block.statements[endIndex];

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Wrap with batch()',
        priority: 70,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleInsertion(firstStmt.offset, 'batch(() {\n    ');
        builder.addSimpleInsertion(lastStmt.end, '\n  });');
      });
    });
  }

  bool _isSignalValueAssignment(Expression expr) {
    if (expr is! AssignmentExpression) return false;

    final lhs = expr.leftHandSide;
    if (lhs is PrefixedIdentifier && lhs.identifier.name == 'value') {
      return true; // Simplified check
    }
    if (lhs is PropertyAccess && lhs.propertyName.name == 'value') {
      return true;
    }
    return false;
  }
}
