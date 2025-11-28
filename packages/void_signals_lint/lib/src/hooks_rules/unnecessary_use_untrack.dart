import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that warns when useUntrack is used around code that doesn't
/// access signals.
///
/// useUntrack is meant to prevent signal access from creating dependencies.
/// Using it when no signals are accessed is unnecessary.
///
/// **UNNECESSARY:**
/// ```dart
/// useUntrack(() {
///   print('hello');  // ❌ No signal access
/// });
/// ```
///
/// **GOOD:**
/// ```dart
/// useUntrack(() {
///   // Read signal without creating dependency
///   final current = count.value;  // ✅ Untracked read
///   print('Current: $current');
/// });
/// ```
class UnnecessaryUseUntrack extends DartLintRule {
  const UnnecessaryUseUntrack() : super(code: _code);

  static const _code = LintCode(
    name: 'unnecessary_use_untrack',
    problemMessage: 'useUntrack is unnecessary when no signals are accessed.',
    correctionMessage:
        'Remove useUntrack wrapper or add signal accesses that need to be untracked.',
    errorSeverity: ErrorSeverity.INFO,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      if (node.methodName.name != 'useUntrack') return;

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
    node.accept(_SignalAccessFinder((n) => found = true));
    return found;
  }
}

class _SignalAccessFinder extends RecursiveAstVisitor<void> {
  _SignalAccessFinder(this.onAccess);

  final void Function(AstNode) onAccess;

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.identifier.name == 'value') {
      onAccess(node);
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.propertyName.name == 'value') {
      onAccess(node);
    }
    super.visitPropertyAccess(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'peek') {
      onAccess(node);
    }
    super.visitMethodInvocation(node);
  }
}
