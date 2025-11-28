import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that warns against accessing signal value in initState.
///
/// In initState, accessing signal.value might be premature if the signal
/// depends on context-based data. Consider using didChangeDependencies
/// or effect() for setup that depends on signals.
///
/// **CAUTION:**
/// ```dart
/// @override
/// void initState() {
///   super.initState();
///   final value = count.value;  // ⚠️ May be premature
///   setup(value);
/// }
/// ```
///
/// **BETTER:**
/// ```dart
/// @override
/// void initState() {
///   super.initState();
///   // Use effect for reactive setup
///   _effect = effect(() {
///     setup(count.value);
///   });
/// }
/// ```
class CautionSignalInInitState extends DartLintRule {
  const CautionSignalInInitState() : super(code: _code);

  static const _code = LintCode(
    name: 'caution_signal_in_init_state',
    problemMessage: 'Accessing signal value in initState may be premature. '
        'Consider using effect() or didChangeDependencies.',
    correctionMessage:
        'Use effect() for reactive setup, or move to didChangeDependencies '
        'if the signal depends on inherited widgets.',
    errorSeverity: ErrorSeverity.INFO,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodDeclaration((node) {
      if (node.name.lexeme != 'initState') return;

      // Check if in State class
      final classDecl = node.thisOrAncestorOfType<ClassDeclaration>();
      if (classDecl == null) return;

      if (!_isStateClass(classDecl)) return;

      // Find signal value accesses
      node.body.accept(_SignalAccessVisitor(
        onAccess: (accessNode) {
          reporter.atNode(accessNode, code);
        },
      ));
    });
  }

  bool _isStateClass(ClassDeclaration classDecl) {
    final extendsClause = classDecl.extendsClause;
    if (extendsClause == null) return false;

    final superclass = extendsClause.superclass.toSource();
    return superclass.startsWith('State<');
  }
}

class _SignalAccessVisitor extends RecursiveAstVisitor<void> {
  _SignalAccessVisitor({required this.onAccess});

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
}
