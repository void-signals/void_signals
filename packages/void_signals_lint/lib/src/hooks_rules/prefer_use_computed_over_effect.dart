import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that suggests using useComputed instead of useSignalEffect
/// when the effect only updates a derived signal.
///
/// **BAD:**
/// ```dart
/// Widget build(BuildContext context) {
///   final firstName = useSignal('John');
///   final lastName = useSignal('Doe');
///   final fullName = useSignal('');
///
///   useSignalEffect(() {
///     fullName.value = '${firstName.value} ${lastName.value}';  // ❌
///   });
///
///   return Text(useWatch(fullName));
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// Widget build(BuildContext context) {
///   final firstName = useSignal('John');
///   final lastName = useSignal('Doe');
///   final fullName = useComputed(() =>
///     '${firstName.value} ${lastName.value}'  // ✅
///   );
///
///   return Text(useWatch(fullName));
/// }
/// ```
class PreferUseComputedOverEffect extends DartLintRule {
  const PreferUseComputedOverEffect() : super(code: _code);

  static const _code = LintCode(
    name: 'prefer_use_computed_over_effect',
    problemMessage:
        'Consider using useComputed instead of useSignalEffect for derived values.',
    correctionMessage:
        'When an effect only assigns a derived value to a signal, '
        'useComputed is more efficient and cleaner.',
    errorSeverity: ErrorSeverity.INFO,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      if (node.methodName.name != 'useSignalEffect') return;

      // Get the callback
      final args = node.argumentList.arguments;
      if (args.isEmpty) return;

      final callback = args.first;
      if (callback is! FunctionExpression) return;

      final body = callback.body;
      if (body is! BlockFunctionBody) return;

      final block = body.block;

      // Check if the block only contains a single assignment to a signal
      if (_isOnlySignalAssignment(block)) {
        reporter.atNode(node, code);
      }
    });
  }

  bool _isOnlySignalAssignment(Block block) {
    final statements = block.statements;

    // Should have exactly one statement
    if (statements.length != 1) return false;

    final statement = statements.first;
    if (statement is! ExpressionStatement) return false;

    final expr = statement.expression;
    if (expr is! AssignmentExpression) return false;

    // Left side should be signal.value
    final left = expr.leftHandSide;
    if (left is! PrefixedIdentifier) return false;
    if (left.identifier.name != 'value') return false;

    return true;
  }

  @override
  List<Fix> getFixes() => [_ConvertToUseComputedFix()];
}

class _ConvertToUseComputedFix extends DartFix {
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
      if (node.methodName.name != 'useSignalEffect') return;

      final args = node.argumentList.arguments;
      if (args.isEmpty) return;

      final callback = args.first;
      if (callback is! FunctionExpression) return;

      final body = callback.body;
      if (body is! BlockFunctionBody) return;

      final block = body.block;
      final statements = block.statements;
      if (statements.length != 1) return;

      final statement = statements.first;
      if (statement is! ExpressionStatement) return;

      final expr = statement.expression;
      if (expr is! AssignmentExpression) return;

      final left = expr.leftHandSide;
      if (left is! PrefixedIdentifier) return;

      final signalName = left.prefix.name;
      final rightSide = expr.rightHandSide.toSource();

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Convert to useComputed',
        priority: 80,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleReplacement(
          node.sourceRange,
          'final $signalName = useComputed((_) => $rightSide)',
        );
      });
    });
  }
}
