import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that warns when effects are created without being stored for cleanup.
///
/// Effects that are not stored cannot be stopped, which can lead to memory leaks
/// and unexpected behavior when the containing widget or object is disposed.
///
/// **BAD:**
/// ```dart
/// void initState() {
///   super.initState();
///   effect(() {  // ❌ Effect created but not stored
///     print(count.value);
///   });
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// Effect? _effect;
///
/// void initState() {
///   super.initState();
///   _effect = effect(() {  // ✅ Effect stored for cleanup
///     print(count.value);
///   });
/// }
///
/// void dispose() {
///   _effect?.stop();
///   super.dispose();
/// }
/// ```
class MissingEffectCleanup extends DartLintRule {
  const MissingEffectCleanup() : super(code: _code);

  static const _code = LintCode(
    name: 'missing_effect_cleanup',
    problemMessage: 'Effect created without being stored for cleanup. '
        'This may cause memory leaks.',
    correctionMessage:
        'Store the effect in a variable and call stop() in dispose().',
    errorSeverity: ErrorSeverity.WARNING,
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

      // Check if we're in a State class
      final classDecl = node.thisOrAncestorOfType<ClassDeclaration>();
      if (classDecl == null) return;

      if (!_isStateClass(classDecl)) return;

      // Check if the effect is being assigned to a variable or field
      if (_isEffectStored(node)) return;

      // Check if we're inside an effectScope - that handles cleanup
      if (_isInsideEffectScope(node)) return;

      reporter.atNode(node, code);
    });
  }

  bool _isStateClass(ClassDeclaration classDecl) {
    final extendsClause = classDecl.extendsClause;
    if (extendsClause == null) return false;

    final superclass = extendsClause.superclass.toSource();
    return superclass.startsWith('State<');
  }

  bool _isEffectStored(MethodInvocation node) {
    final parent = node.parent;

    // Check if effect is assigned to a variable
    // e.g., final effect = effect(() { ... });
    if (parent is VariableDeclaration) {
      return true;
    }

    // Check if effect is assigned to a field
    // e.g., _effect = effect(() { ... });
    if (parent is AssignmentExpression) {
      return true;
    }

    // Check if effect is returned
    // e.g., return effect(() { ... });
    if (parent is ReturnStatement) {
      return true;
    }

    // Check if effect is part of a list or collection
    // e.g., [effect(() { ... })]
    if (parent is ListLiteral) {
      return true;
    }

    return false;
  }

  bool _isInsideEffectScope(AstNode node) {
    var parent = node.parent;
    while (parent != null) {
      if (parent is MethodInvocation &&
          parent.methodName.name == 'effectScope') {
        return true;
      }

      // Stop at function/class boundaries
      if (parent is FunctionDeclaration ||
          parent is MethodDeclaration ||
          parent is ClassDeclaration) {
        break;
      }

      parent = parent.parent;
    }
    return false;
  }

  @override
  List<Fix> getFixes() => [_StoreEffectFix()];
}

/// Quick fix to store the effect in a variable.
class _StoreEffectFix extends DartFix {
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
      if (node.methodName.name != 'effect') return;

      final statement = node.thisOrAncestorOfType<ExpressionStatement>();
      if (statement == null) return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Store effect in a variable',
        priority: 80,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleReplacement(
          statement.sourceRange,
          '_effect = ${node.toSource()};',
        );
      });
    });
  }
}
