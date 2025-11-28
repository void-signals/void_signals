import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that warns when using effect() for UI updates in Flutter.
///
/// In Flutter, reactive UI updates are better handled by reactive widgets
/// like Watch, WatchValue, or SignalBuilder instead of effects with setState.
///
/// **AVOID:**
/// ```dart
/// effect(() {
///   // Using effect for UI side effects
///   myWidget.rebuild();
/// });
/// ```
///
/// **PREFER:**
/// ```dart
/// // Use Watch for automatic UI updates
/// Watch(builder: (context) => Text('${signal.value}'))
/// ```
class AvoidEffectForUI extends DartLintRule {
  const AvoidEffectForUI() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_effect_for_ui',
    problemMessage:
        'Avoid using effect() for UI updates. Use Watch or SignalBuilder instead.',
    correctionMessage:
        'Replace this effect with a Watch widget or SignalBuilder '
        'for automatic reactive UI updates.',
    errorSeverity: ErrorSeverity.INFO,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      if (node.methodName.name != 'effect') return;

      // Check if it's inside a Flutter State class
      final classDecl = node.thisOrAncestorOfType<ClassDeclaration>();
      if (classDecl == null) return;

      if (!_isFlutterClass(classDecl)) return;

      // Check if the effect body contains UI-related calls
      final effectArg = node.argumentList.arguments.firstOrNull;
      if (effectArg == null) return;

      if (_containsUIOperation(effectArg)) {
        reporter.atNode(node, code);
      }
    });
  }

  bool _isFlutterClass(ClassDeclaration classDecl) {
    final extendsClause = classDecl.extendsClause;
    if (extendsClause == null) return false;

    final superclass = extendsClause.superclass.toSource();
    return superclass.startsWith('State<') ||
        superclass.endsWith('Widget') ||
        superclass == 'StatelessWidget' ||
        superclass == 'StatefulWidget';
  }

  bool _containsUIOperation(AstNode node) {
    var found = false;
    node.accept(_UIOperationVisitor(onUIOperation: () => found = true));
    return found;
  }
}

class _UIOperationVisitor extends RecursiveAstVisitor<void> {
  _UIOperationVisitor({required this.onUIOperation});

  final void Function() onUIOperation;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;
    if (methodName == 'setState' ||
        methodName == 'markNeedsBuild' ||
        methodName == 'rebuild') {
      onUIOperation();
    }
    super.visitMethodInvocation(node);
  }
}
