import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that warns when using setState with signals.
///
/// When using void_signals, you typically don't need setState because
/// signals handle reactivity automatically through Watch widgets.
///
/// **AVOID:**
/// ```dart
/// void _increment() {
///   setState(() {
///     count.value++;
///   });
/// }
/// ```
///
/// **BETTER:**
/// ```dart
/// void _increment() {
///   count.value++;  // Widget rebuilds automatically if using Watch
/// }
/// ```
class AvoidSetStateWithSignals extends DartLintRule {
  const AvoidSetStateWithSignals() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_set_state_with_signals',
    problemMessage:
        'Using setState with signals is unnecessary. Signals automatically '
        'trigger rebuilds through Watch widgets.',
    correctionMessage:
        'Remove the setState wrapper. Just update the signal value directly '
        'and use Watch widget for reactivity.',
    errorSeverity: ErrorSeverity.INFO,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      if (node.methodName.name != 'setState') return;

      // Check if setState body contains signal updates
      final argument = node.argumentList.arguments.firstOrNull;
      if (argument == null) return;

      if (_containsSignalUpdate(argument)) {
        reporter.atNode(node, code);
      }
    });
  }

  bool _containsSignalUpdate(AstNode node) {
    var found = false;
    node.accept(_SignalUpdateVisitor(onUpdate: () => found = true));
    return found;
  }

  @override
  List<Fix> getFixes() => [_RemoveSetStateFix()];
}

class _SignalUpdateVisitor extends RecursiveAstVisitor<void> {
  _SignalUpdateVisitor({required this.onUpdate});

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

/// Quick fix to remove setState wrapper.
class _RemoveSetStateFix extends DartFix {
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
      if (node.methodName.name != 'setState') return;

      final argument = node.argumentList.arguments.firstOrNull;
      if (argument == null) return;

      final statement = node.thisOrAncestorOfType<ExpressionStatement>();
      if (statement == null) return;

      // Extract the body of setState
      if (argument is FunctionExpression) {
        final body = argument.body;
        String replacement;

        if (body is BlockFunctionBody) {
          final statements = body.block.statements;
          replacement = statements.map((s) => s.toSource()).join('\n');
        } else if (body is ExpressionFunctionBody) {
          replacement = '${body.expression.toSource()};';
        } else {
          return;
        }

        final changeBuilder = reporter.createChangeBuilder(
          message: 'Remove setState wrapper',
          priority: 80,
        );

        changeBuilder.addDartFileEdit((builder) {
          builder.addSimpleReplacement(statement.sourceRange, replacement);
        });
      }
    });
  }
}
