import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that warns when disposing an EffectScope is forgotten.
///
/// EffectScopes must be disposed to prevent memory leaks. In StatefulWidget,
/// this should happen in dispose().
///
/// **BAD:**
/// ```dart
/// class MyWidget extends State<MyStatefulWidget> {
///   late final scope = effectScope(() {
///     effect(() { ... });
///   });
///   // ❌ Missing dispose!
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// class MyWidget extends State<MyStatefulWidget> {
///   late final scope = effectScope(() {
///     effect(() { ... });
///   });
///
///   @override
///   void dispose() {
///     scope.stop();  // ✅ Properly disposed
///     super.dispose();
///   }
/// }
/// ```
class MissingScopeDispose extends DartLintRule {
  const MissingScopeDispose() : super(code: _code);

  static const _code = LintCode(
    name: 'missing_scope_dispose',
    problemMessage:
        'EffectScope should be disposed in dispose() to prevent memory leaks.',
    correctionMessage: 'Add scope.stop() in the dispose() method.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addClassDeclaration((node) {
      // Check if this is a State class
      if (!_isStateClass(node)) return;

      // Find all effectScope declarations
      final scopeFields = <String>[];
      for (final member in node.members) {
        if (member is FieldDeclaration) {
          for (final variable in member.fields.variables) {
            final initializer = variable.initializer;
            if (initializer is MethodInvocation &&
                initializer.methodName.name == 'effectScope') {
              scopeFields.add(variable.name.lexeme);
            }
          }
        }
      }

      if (scopeFields.isEmpty) return;

      // Find dispose method
      final disposeMethod = node.members.whereType<MethodDeclaration>().where(
            (m) => m.name.lexeme == 'dispose',
          );

      if (disposeMethod.isEmpty) {
        // No dispose method - report on the scope declaration
        for (final member in node.members) {
          if (member is FieldDeclaration) {
            for (final variable in member.fields.variables) {
              if (scopeFields.contains(variable.name.lexeme)) {
                reporter.atNode(variable, code);
              }
            }
          }
        }
        return;
      }

      // Check if dispose calls stop() on all scopes
      final dispose = disposeMethod.first;
      final stoppedScopes = <String>{};

      dispose.body.accept(_StopCallVisitor(
        onStopCall: (name) => stoppedScopes.add(name),
      ));

      // Report scopes that aren't stopped
      for (final scopeName in scopeFields) {
        if (!stoppedScopes.contains(scopeName)) {
          for (final member in node.members) {
            if (member is FieldDeclaration) {
              for (final variable in member.fields.variables) {
                if (variable.name.lexeme == scopeName) {
                  reporter.atNode(variable, code);
                }
              }
            }
          }
        }
      }
    });
  }

  bool _isStateClass(ClassDeclaration classDecl) {
    final extendsClause = classDecl.extendsClause;
    if (extendsClause == null) return false;

    final superclass = extendsClause.superclass.toSource();
    return superclass.startsWith('State<');
  }

  @override
  List<Fix> getFixes() => [_AddScopeDisposeFix()];
}

class _StopCallVisitor extends RecursiveAstVisitor<void> {
  _StopCallVisitor({required this.onStopCall});

  final void Function(String name) onStopCall;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'stop') {
      final target = node.target;
      if (target is SimpleIdentifier) {
        onStopCall(target.name);
      }
    }
    super.visitMethodInvocation(node);
  }
}

/// Quick fix to add scope disposal.
class _AddScopeDisposeFix extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    context.registry.addVariableDeclaration((node) {
      if (!analysisError.sourceRange.intersects(node.sourceRange)) return;

      final scopeName = node.name.lexeme;
      final classDecl = node.thisOrAncestorOfType<ClassDeclaration>();
      if (classDecl == null) return;

      // Find dispose method
      final disposeMethod =
          classDecl.members.whereType<MethodDeclaration>().where(
                (m) => m.name.lexeme == 'dispose',
              );

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Add $scopeName.stop() in dispose()',
        priority: 80,
      );

      changeBuilder.addDartFileEdit((builder) {
        if (disposeMethod.isEmpty) {
          // Add dispose method
          final insertOffset = classDecl.rightBracket.offset;
          builder.addSimpleInsertion(
            insertOffset,
            '\n  @override\n  void dispose() {\n    $scopeName.stop();\n    super.dispose();\n  }\n',
          );
        } else {
          // Add stop call to existing dispose
          final dispose = disposeMethod.first;
          final body = dispose.body;
          if (body is BlockFunctionBody) {
            final firstStatement = body.block.statements.firstOrNull;
            if (firstStatement != null) {
              builder.addSimpleInsertion(
                firstStatement.offset,
                '$scopeName.stop();\n    ',
              );
            }
          }
        }
      });
    });
  }
}
