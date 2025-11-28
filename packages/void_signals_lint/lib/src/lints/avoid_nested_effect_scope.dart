import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that warns against creating nested effect scopes.
///
/// Nested effect scopes can lead to unexpected behavior and memory leaks.
/// It's better to use a flat structure for effect scopes.
///
/// **BAD:**
/// ```dart
/// effectScope(() {
///   effectScope(() {  // ❌ Nested scope
///     effect(() { ... });
///   });
/// });
/// ```
///
/// **GOOD:**
/// ```dart
/// final parentScope = effectScope(() {
///   effect(() { ... });
/// });
/// final childScope = effectScope(() {
///   effect(() { ... });
/// });
/// ```
class AvoidNestedEffectScope extends DartLintRule {
  const AvoidNestedEffectScope() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_nested_effect_scope',
    problemMessage:
        'Avoid creating nested effect scopes. This can lead to memory leaks '
        'and unexpected behavior.',
    correctionMessage:
        'Consider restructuring your code to use separate, non-nested scopes.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((outerNode) {
      // Check if this is an effectScope() call
      if (outerNode.methodName.name != 'effectScope') return;

      // Find nested effectScope calls inside this one
      final callback = outerNode.argumentList.arguments.firstOrNull;
      if (callback == null) return;

      // Visit the callback to find nested effectScope calls
      callback.accept(_NestedEffectScopeVisitor(reporter, code));
    });
  }
}

class _NestedEffectScopeVisitor extends RecursiveAstVisitor<void> {
  _NestedEffectScopeVisitor(this.reporter, this.code);

  final ErrorReporter reporter;
  final LintCode code;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'effectScope') {
      // Found a nested effectScope
      reporter.atNode(node, code);
    }
    // Continue visiting to find deeply nested ones
    super.visitMethodInvocation(node);
  }
}
