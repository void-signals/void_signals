import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that warns when useBatch is used for a single signal update.
///
/// useBatch is meant to group multiple signal updates to prevent intermediate
/// rebuilds. Using it for a single update is unnecessary.
///
/// **UNNECESSARY:**
/// ```dart
/// useBatch(() {
///   count.value++;  // ❌ Only one update
/// });
/// ```
///
/// **GOOD:**
/// ```dart
/// useBatch(() {
///   count.value++;
///   total.value = count.value * price.value;  // ✅ Multiple updates
/// });
/// ```
class UnnecessaryUseBatch extends DartLintRule {
  const UnnecessaryUseBatch() : super(code: _code);

  static const _code = LintCode(
    name: 'unnecessary_use_batch',
    problemMessage: 'useBatch is unnecessary for a single signal update.',
    correctionMessage: 'Remove useBatch wrapper when updating only one signal.',
    errorSeverity: ErrorSeverity.INFO,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      if (node.methodName.name != 'useBatch') return;

      final args = node.argumentList.arguments;
      if (args.isEmpty) return;

      final callback = args.first;
      if (callback is! FunctionExpression) return;

      // Count signal updates in the callback
      final updateCount = _countSignalUpdates(callback.body);
      if (updateCount <= 1) {
        reporter.atNode(node, code);
      }
    });
  }

  int _countSignalUpdates(AstNode node) {
    var count = 0;
    node.accept(_SignalUpdateCounter(onUpdate: () => count++));
    return count;
  }

  @override
  List<Fix> getFixes() => [_RemoveUseBatchFix()];
}

class _SignalUpdateCounter extends RecursiveAstVisitor<void> {
  _SignalUpdateCounter({required this.onUpdate});

  final void Function() onUpdate;

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final left = node.leftHandSide;
    if (left is PrefixedIdentifier && left.identifier.name == 'value') {
      onUpdate();
    }
    if (left is PropertyAccess && left.propertyName.name == 'value') {
      onUpdate();
    }
    super.visitAssignmentExpression(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    final operand = node.operand;
    if (operand is PrefixedIdentifier && operand.identifier.name == 'value') {
      onUpdate();
    }
    if (operand is PropertyAccess && operand.propertyName.name == 'value') {
      onUpdate();
    }
    super.visitPostfixExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    final operand = node.operand;
    if (operand is PrefixedIdentifier && operand.identifier.name == 'value') {
      onUpdate();
    }
    if (operand is PropertyAccess && operand.propertyName.name == 'value') {
      onUpdate();
    }
    super.visitPrefixExpression(node);
  }
}

class _RemoveUseBatchFix extends DartFix {
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
      if (node.methodName.name != 'useBatch') return;

      final args = node.argumentList.arguments;
      if (args.isEmpty) return;

      final callback = args.first;
      if (callback is! FunctionExpression) return;

      final body = callback.body;
      String innerCode;

      if (body is BlockFunctionBody) {
        // Extract statements from block
        final statements = body.block.statements;
        innerCode = statements.map((s) => s.toSource()).join('\n');
      } else if (body is ExpressionFunctionBody) {
        innerCode = '${body.expression.toSource()};';
      } else {
        return;
      }

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Remove useBatch wrapper',
        priority: 75,
      );

      changeBuilder.addDartFileEdit((builder) {
        // Find the statement containing this call
        AstNode? statement = node.parent;
        while (statement != null && statement is! Statement) {
          statement = statement.parent;
        }

        if (statement != null) {
          builder.addSimpleReplacement(statement.sourceRange, innerCode);
        }
      });
    });
  }
}
