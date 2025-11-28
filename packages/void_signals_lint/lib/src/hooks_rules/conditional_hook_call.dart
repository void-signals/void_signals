import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../shared/ast_utils.dart';
import '../shared/constants.dart';

/// A lint rule that prevents calling hooks inside conditional statements or loops.
///
/// Hooks must be called in the same order on every render. Calling hooks
/// inside conditions or loops breaks this rule and leads to unpredictable behavior.
///
/// **BAD:**
/// ```dart
/// Widget build(BuildContext context) {
///   if (showCounter) {
///     final count = useSignal(0);  // ❌ Conditional hook call
///   }
///   for (var i = 0; i < 3; i++) {
///     useSignalEffect(() => print(i));  // ❌ Hook in loop
///   }
///   return Container();
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// Widget build(BuildContext context) {
///   final count = useSignal(0);  // ✅ Always called
///
///   return showCounter
///     ? Text('${count.value}')
///     : Container();
/// }
/// ```
class ConditionalHookCall extends DartLintRule {
  const ConditionalHookCall() : super(code: _code);

  static const _code = LintCode(
    name: 'conditional_hook_call',
    problemMessage:
        'Hooks must not be called inside conditional statements or loops.',
    correctionMessage:
        'Move this hook call to the top level of the build method. '
        'Hooks must always be called in the same order on every render.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      final methodName = node.methodName.name;

      // Check if this is a hook call
      if (!allHooks.contains(methodName)) return;

      // Check if inside a conditional or loop
      final conditionalType = getConditionalType(node);
      if (conditionalType != null) {
        reporter.atNode(node, code);
      }
    });
  }

  @override
  List<Fix> getFixes() => [_MoveHookOutOfConditionalFix()];
}

class _MoveHookOutOfConditionalFix extends DartFix {
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

      // Find the enclosing build method
      final method = getEnclosingMethod(node);
      if (method == null || !isBuildMethod(method)) return;

      final body = method.body;
      if (body is! BlockFunctionBody) return;

      // Get variable name if this is a variable declaration
      final varName = getAssignedVariableName(node);
      if (varName == null) return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Move hook to top of build method',
        priority: 85,
      );

      changeBuilder.addDartFileEdit((builder) {
        // Find the statement containing this hook
        AstNode? statement = node.parent;
        while (statement != null && statement is! Statement) {
          statement = statement.parent;
        }

        if (statement == null) return;

        // Get the full statement source
        final statementSource = statement.toSource();

        // Remove from current location
        builder.addDeletion(statement.sourceRange);

        // Add at the beginning of the build method body
        final insertOffset = body.block.leftBracket.end;
        builder.addSimpleInsertion(insertOffset, '\n    $statementSource');
      });
    });
  }
}
