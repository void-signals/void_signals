import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that suggests using Watch widgets instead of effects for UI updates.
///
/// When using effects inside StatefulWidget for UI updates, it's better to use
/// dedicated reactive widgets like Watch or SignalBuilder.
///
/// **NOT RECOMMENDED:**
/// ```dart
/// class MyWidget extends StatefulWidget {
///   @override
///   void initState() {
///     super.initState();
///     effect(() {
///       setState(() {});  // Updates UI in response to signal changes
///     });
///   }
/// }
/// ```
///
/// **RECOMMENDED:**
/// ```dart
/// Watch(builder: (context) => Text('${count.value}'))
/// // or
/// SignalBuilder(signal: count, builder: (context, value, child) => Text('$value'))
/// ```
class PreferWatchOverEffectInWidget extends DartLintRule {
  const PreferWatchOverEffectInWidget() : super(code: _code);

  static const _code = LintCode(
    name: 'prefer_watch_over_effect_in_widget',
    problemMessage:
        'Consider using Watch or SignalBuilder instead of effect with setState for UI updates.',
    correctionMessage:
        'Watch and SignalBuilder widgets automatically track signal dependencies '
        'and rebuild efficiently. Use them for reactive UI updates.',
    errorSeverity: ErrorSeverity.INFO,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      // Check if this is an effect() call
      if (node.methodName.name != 'effect') return;

      // Check if it's inside a StatefulWidget lifecycle method
      final method = node.thisOrAncestorOfType<MethodDeclaration>();
      if (method == null) return;

      final methodName = method.name.lexeme;
      if (!_isLifecycleMethod(methodName)) return;

      // Check if it's in a State class
      final classDecl = method.thisOrAncestorOfType<ClassDeclaration>();
      if (classDecl == null) return;

      if (!_isStateClass(classDecl)) return;

      // Check if the effect body contains setState
      final effectArg = node.argumentList.arguments.firstOrNull;
      if (effectArg == null) return;

      if (_containsSetState(effectArg)) {
        reporter.atNode(node, code);
      }
    });
  }

  bool _isLifecycleMethod(String name) {
    return const {
      'initState',
      'didChangeDependencies',
      'didUpdateWidget',
    }.contains(name);
  }

  bool _isStateClass(ClassDeclaration classDecl) {
    final extendsClause = classDecl.extendsClause;
    if (extendsClause == null) return false;

    final superclass = extendsClause.superclass.toSource();
    return superclass.startsWith('State<');
  }

  bool _containsSetState(AstNode node) {
    var found = false;
    node.accept(_SetStateVisitor(onSetState: () => found = true));
    return found;
  }
}

class _SetStateVisitor extends RecursiveAstVisitor<void> {
  _SetStateVisitor({required this.onSetState});

  final void Function() onSetState;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'setState') {
      onSetState();
    }
    super.visitMethodInvocation(node);
  }
}
