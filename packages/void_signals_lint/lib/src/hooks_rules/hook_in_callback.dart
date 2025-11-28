import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../shared/ast_utils.dart';
import '../shared/constants.dart';

/// A lint rule that prevents calling hooks inside callbacks.
///
/// Hooks must be called at the top level of a HookWidget.build() method
/// or custom hook function, not inside callbacks like onPressed or builder.
///
/// **BAD:**
/// ```dart
/// Widget build(BuildContext context) {
///   return ElevatedButton(
///     onPressed: () {
///       final count = useSignal(0);  // ❌ Hook in callback
///     },
///     child: Text('Click'),
///   );
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// Widget build(BuildContext context) {
///   final count = useSignal(0);  // ✅ Top level
///
///   return ElevatedButton(
///     onPressed: () {
///       count.value++;  // Just use the signal
///     },
///     child: Text('Click'),
///   );
/// }
/// ```
class HookInCallback extends DartLintRule {
  const HookInCallback() : super(code: _code);

  static const _code = LintCode(
    name: 'hook_in_callback',
    problemMessage: 'Hooks must not be called inside callbacks.',
    correctionMessage:
        'Move this hook call to the top level of the build method, '
        'then use the returned value inside the callback.',
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

      // Check if inside a callback
      if (isInsideCallback(node)) {
        reporter.atNode(node, code);
      }
    });
  }

  @override
  List<Fix> getFixes() => [_ExtractHookFromCallbackFix()];
}

class _ExtractHookFromCallbackFix extends DartFix {
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

      // Get variable name and type info
      final varName = getAssignedVariableName(node);
      if (varName == null) return;

      // Find the containing statement
      AstNode? statement = node.parent;
      while (statement != null && statement is! Statement) {
        statement = statement.parent;
      }
      if (statement == null) return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Extract hook to build method top level',
        priority: 85,
      );

      changeBuilder.addDartFileEdit((builder) {
        // Get the hook call source
        final hookSource = node.toSource();
        final typeHint = _inferTypeFromHook(node.methodName.name);

        // Remove from current location
        builder.addDeletion(statement!.sourceRange);

        // Add at the beginning of build method
        final insertOffset = body.block.leftBracket.end;
        builder.addSimpleInsertion(
          insertOffset,
          '\n    $typeHint $varName = $hookSource;',
        );
      });
    });
  }

  String _inferTypeFromHook(String hookName) {
    switch (hookName) {
      case 'useSignal':
        return 'final';
      case 'useComputed':
        return 'final';
      case 'useSignalList':
        return 'final';
      case 'useSignalMap':
        return 'final';
      case 'useSignalSet':
        return 'final';
      default:
        return 'final';
    }
  }
}
