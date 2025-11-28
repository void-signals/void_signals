import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that warns when useSelect selector function is not pure.
///
/// useSelect's selector should be a pure function that only reads signal values.
/// Side effects in the selector can lead to unpredictable behavior.
///
/// **BAD:**
/// ```dart
/// final selected = useSelect(signal, (value) {
///   print(value);  // ❌ Side effect
///   return value.name;
/// });
/// ```
///
/// **GOOD:**
/// ```dart
/// final selected = useSelect(signal, (value) => value.name);  // ✅ Pure
/// ```
class UseSelectPureSelector extends DartLintRule {
  const UseSelectPureSelector() : super(code: _code);

  static const _code = LintCode(
    name: 'use_select_pure_selector',
    problemMessage:
        'useSelect selector should be a pure function without side effects.',
    correctionMessage:
        'Remove side effects (print, setState, signal mutations) from the selector.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      if (node.methodName.name != 'useSelect') return;

      final args = node.argumentList.arguments;
      if (args.length < 2) return;

      final selector = args[1];
      if (selector is! FunctionExpression) return;

      // Check for side effects
      if (_hasSideEffects(selector.body)) {
        reporter.atNode(selector, code);
      }
    });
  }

  bool _hasSideEffects(AstNode node) {
    var found = false;
    node.accept(_SideEffectChecker(onSideEffect: () => found = true));
    return found;
  }
}

class _SideEffectChecker extends RecursiveAstVisitor<void> {
  _SideEffectChecker({required this.onSideEffect});

  final void Function() onSideEffect;

  static const _sideEffectFunctions = {
    'print',
    'debugPrint',
    'setState',
    'notifyListeners',
  };

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;

    // Check for known side effect functions
    if (_sideEffectFunctions.contains(methodName)) {
      onSideEffect();
    }

    // Check for signal mutations
    if (methodName == 'add' ||
        methodName == 'remove' ||
        methodName == 'clear' ||
        methodName == 'update') {
      onSideEffect();
    }

    super.visitMethodInvocation(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    // Check for signal.value = ...
    final left = node.leftHandSide;
    if (left is PrefixedIdentifier && left.identifier.name == 'value') {
      onSideEffect();
    }
    if (left is PropertyAccess && left.propertyName.name == 'value') {
      onSideEffect();
    }

    super.visitAssignmentExpression(node);
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    // Async operations are side effects
    onSideEffect();
    super.visitAwaitExpression(node);
  }
}
