import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that warns when Watch widget has no signal access in builder.
///
/// Watch widget is meant to rebuild when signals change. If no signals are
/// accessed in the builder, the Watch is unnecessary.
///
/// **UNNECESSARY:**
/// ```dart
/// Watch(
///   builder: (context) => Text('Static text'),  // ❌ No signal access
/// )
/// ```
///
/// **CORRECT:**
/// ```dart
/// Watch(
///   builder: (context) => Text('Count: ${count.value}'),  // ✅ Accesses signal
/// )
/// ```
class WatchWithoutSignalAccess extends DartLintRule {
  const WatchWithoutSignalAccess() : super(code: _code);

  static const _code = LintCode(
    name: 'watch_without_signal_access',
    problemMessage: 'Watch widget builder does not access any signals. '
        'This Watch is unnecessary.',
    correctionMessage: 'Either access a signal in the builder using .value, '
        'or remove the Watch wrapper if no reactivity is needed.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      final typeName = node.constructorName.type.name2.lexeme;

      if (typeName != 'Watch') return;

      // Find the builder argument
      final arguments = node.argumentList.arguments;
      if (arguments.isEmpty) return;

      Expression? builderExpr;
      for (final arg in arguments) {
        if (arg is NamedExpression && arg.name.label.name == 'builder') {
          builderExpr = arg.expression;
          break;
        }
      }

      // If no named builder, use first positional argument
      builderExpr ??= arguments.first;

      // Check if builder accesses any signals
      if (!_accessesSignal(builderExpr)) {
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
    // Check for signal() call syntax
    if (node.target == null && node.argumentList.arguments.isEmpty) {
      // Could be a signal getter call
      onAccess();
    }
    // Check for .peek() which also reads signal
    if (node.methodName.name == 'peek') {
      onAccess();
    }
    super.visitMethodInvocation(node);
  }
}
