import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that warns when useSignalEffect doesn't access any signals.
///
/// useSignalEffect should react to signal changes. If no signals are accessed
/// in the effect, it will only run once on mount, which might not be intended.
///
/// **BAD:**
/// ```dart
/// useSignalEffect(() {
///   print('Hello');  // ❌ No signal dependency
/// });
/// ```
///
/// **GOOD:**
/// ```dart
/// useSignalEffect(() {
///   print('Count: ${count.value}');  // ✅ Reacts to count changes
/// });
/// ```
class UseEffectWithoutDependency extends DartLintRule {
  const UseEffectWithoutDependency() : super(code: _code);

  static const _code = LintCode(
    name: 'use_effect_without_dependency',
    problemMessage:
        'useSignalEffect does not access any signals and will only run once.',
    correctionMessage:
        'Access signal values inside the effect callback, or consider using '
        'useEffect from flutter_hooks if you only need mount/unmount behavior.',
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

      // Get the callback argument
      final args = node.argumentList.arguments;
      if (args.isEmpty) return;

      final callback = args.first;
      if (callback is! FunctionExpression) return;

      // Check if the callback accesses any signals
      if (!_accessesSignal(callback.body)) {
        reporter.atNode(node, code);
      }
    });
  }

  bool _accessesSignal(AstNode node) {
    var found = false;
    node.accept(_SignalAccessChecker(onAccess: () => found = true));
    return found;
  }
}

class _SignalAccessChecker extends RecursiveAstVisitor<void> {
  _SignalAccessChecker({required this.onAccess});

  final void Function() onAccess;

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.identifier.name == 'value') {
      onAccess();
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.propertyName.name == 'value') {
      onAccess();
    }
    super.visitPropertyAccess(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'peek') {
      onAccess();
    }
    super.visitMethodInvocation(node);
  }
}
