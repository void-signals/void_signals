import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that suggests using batch() for multiple signal updates.
///
/// When multiple signals are updated in sequence, each update triggers
/// a separate notification cycle. Using batch() groups them together
/// for better performance.
///
/// **LESS EFFICIENT:**
/// ```dart
/// void updateUser(String first, String last) {
///   firstName.value = first;  // Triggers update
///   lastName.value = last;    // Triggers another update
///   age.value = 30;           // Triggers yet another update
/// }
/// ```
///
/// **MORE EFFICIENT:**
/// ```dart
/// void updateUser(String first, String last) {
///   batch(() {
///     firstName.value = first;
///     lastName.value = last;
///     age.value = 30;
///   });  // Single update at the end
/// }
/// ```
class PreferBatchForMultipleUpdates extends DartLintRule {
  const PreferBatchForMultipleUpdates() : super(code: _code);

  static const _code = LintCode(
    name: 'prefer_batch_for_multiple_updates',
    problemMessage:
        'Multiple signal updates detected. Consider using batch() to group '
        'them for better performance.',
    correctionMessage:
        'Wrap consecutive signal updates in batch(() { ... }) to reduce '
        'the number of notification cycles.',
    errorSeverity: ErrorSeverity.INFO,
  );

  /// Minimum number of consecutive signal updates to trigger the lint.
  static const _minUpdates = 2;

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addBlock((node) {
      _checkBlockForMultipleUpdates(node, reporter);
    });

    context.registry.addFunctionBody((node) {
      if (node is BlockFunctionBody) {
        _checkBlockForMultipleUpdates(node.block, reporter);
      }
    });
  }

  void _checkBlockForMultipleUpdates(Block block, ErrorReporter reporter) {
    // Skip if already inside a batch
    if (_isInsideBatch(block)) return;

    final statements = block.statements;
    if (statements.length < _minUpdates) return;

    int consecutiveUpdates = 0;
    int? firstUpdateIndex;

    for (int i = 0; i < statements.length; i++) {
      final statement = statements[i];

      if (_isSignalUpdate(statement)) {
        if (firstUpdateIndex == null) {
          firstUpdateIndex = i;
        }
        consecutiveUpdates++;
      } else {
        // Reset counter if we encounter a non-update statement
        if (consecutiveUpdates >= _minUpdates && firstUpdateIndex != null) {
          _reportMultipleUpdates(
            statements.sublist(firstUpdateIndex, i),
            reporter,
          );
        }
        consecutiveUpdates = 0;
        firstUpdateIndex = null;
      }
    }

    // Check at the end of the block
    if (consecutiveUpdates >= _minUpdates && firstUpdateIndex != null) {
      _reportMultipleUpdates(
        statements.sublist(firstUpdateIndex),
        reporter,
      );
    }
  }

  bool _isInsideBatch(AstNode node) {
    var parent = node.parent;
    while (parent != null) {
      if (parent is MethodInvocation && parent.methodName.name == 'batch') {
        return true;
      }
      parent = parent.parent;
    }
    return false;
  }

  bool _isSignalUpdate(Statement statement) {
    if (statement is! ExpressionStatement) return false;

    final expr = statement.expression;

    // Check for signal.value = x
    if (expr is AssignmentExpression) {
      final left = expr.leftHandSide;
      if (left is PrefixedIdentifier && left.identifier.name == 'value') {
        return true;
      }
      if (left is PropertyAccess && left.propertyName.name == 'value') {
        return true;
      }
    }

    // Check for signal.update(x)
    if (expr is MethodInvocation) {
      final methodName = expr.methodName.name;
      if (methodName == 'update') {
        return true;
      }
    }

    return false;
  }

  void _reportMultipleUpdates(
    List<Statement> statements,
    ErrorReporter reporter,
  ) {
    if (statements.isEmpty) return;

    // Report on the first statement
    reporter.atNode(statements.first, code);
  }

  @override
  List<Fix> getFixes() => [_WrapInBatchFix()];
}

/// Quick fix to wrap multiple updates in batch().
class _WrapInBatchFix extends DartFix {
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
      final block = node.thisOrAncestorOfType<Block>();
      if (block == null) return;

      // Find all consecutive signal updates starting from this statement
      final statements = block.statements;
      final startIndex = statements.indexOf(node);
      if (startIndex == -1) return;

      int endIndex = startIndex;
      for (int i = startIndex; i < statements.length; i++) {
        if (_isSignalUpdate(statements[i])) {
          endIndex = i;
        } else {
          break;
        }
      }

      if (endIndex == startIndex) return;

      final updateStatements = statements.sublist(startIndex, endIndex + 1);
      final updatesCode =
          updateStatements.map((s) => s.toSource()).join('\n  ');

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Wrap updates in batch()',
        priority: 80,
      );

      changeBuilder.addDartFileEdit((builder) {
        final firstOffset = updateStatements.first.offset;
        final lastEnd = updateStatements.last.end;

        builder.addSimpleReplacement(
          SourceRange(firstOffset, lastEnd - firstOffset),
          'batch(() {\n  $updatesCode\n});',
        );
      });
    });
  }

  bool _isSignalUpdate(Statement statement) {
    if (statement is! ExpressionStatement) return false;

    final expr = statement.expression;

    if (expr is AssignmentExpression) {
      final left = expr.leftHandSide;
      if (left is PrefixedIdentifier && left.identifier.name == 'value') {
        return true;
      }
      if (left is PropertyAccess && left.propertyName.name == 'value') {
        return true;
      }
    }

    if (expr is MethodInvocation && expr.methodName.name == 'update') {
      return true;
    }

    return false;
  }
}
