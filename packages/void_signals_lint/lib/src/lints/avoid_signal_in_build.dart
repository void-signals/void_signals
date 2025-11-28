import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:collection/collection.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that warns when signals are created inside Flutter build methods.
///
/// Creating signals in build methods means they are recreated on every rebuild,
/// which defeats the purpose of using signals for state management.
///
/// **BAD:**
/// ```dart
/// Widget build(BuildContext context) {
///   final count = signal(0);  // ❌ Created on every build
///   return Text('$count');
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// final count = signal(0);  // ✅ Created once
///
/// Widget build(BuildContext context) {
///   return Text('$count');
/// }
/// ```
class AvoidSignalInBuild extends DartLintRule {
  const AvoidSignalInBuild() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_signal_in_build',
    problemMessage:
        'Avoid creating signals inside build methods. Signals created here '
        'will be recreated on every rebuild, losing their state.',
    correctionMessage:
        'Move the signal declaration outside of the build method, '
        'e.g., to class level or a final top-level variable.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  /// Check if the function call is a signal creation.
  static const _signalCreators = {
    'signal',
    'computed',
    'computedFrom',
  };

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodDeclaration((node) {
      // Check if this is a build method
      if (!_isBuildMethod(node)) return;

      // Find all signal creations in the build method
      node.body.accept(_SignalCreationVisitor(
        onSignalCreation: (invocation) {
          reporter.atNode(invocation, code);
        },
      ));
    });
  }

  /// Checks if a method declaration is a Flutter build method.
  bool _isBuildMethod(MethodDeclaration node) {
    if (node.name.lexeme != 'build') return false;

    // Check return type
    final returnType = node.returnType?.toSource();
    if (returnType != 'Widget' && returnType != 'Widget?') return false;

    // Check parameters
    final params = node.parameters?.parameters;
    if (params == null || params.isEmpty) return false;

    // First parameter should be BuildContext
    final firstParam = params.first;
    if (firstParam is SimpleFormalParameter) {
      final type = firstParam.type?.toSource();
      if (type == 'BuildContext') return true;
    }

    return false;
  }

  @override
  List<Fix> getFixes() => [_MoveSignalOutOfBuildFix()];
}

/// Visitor to find signal creation invocations.
class _SignalCreationVisitor extends RecursiveAstVisitor<void> {
  _SignalCreationVisitor({required this.onSignalCreation});

  final void Function(MethodInvocation) onSignalCreation;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;
    if (AvoidSignalInBuild._signalCreators.contains(methodName)) {
      onSignalCreation(node);
    }
    super.visitMethodInvocation(node);
  }
}

/// Quick fix to help move signal out of build method.
class _MoveSignalOutOfBuildFix extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    context.registry.addMethodInvocation((node) {
      // Check if this is the flagged invocation
      if (!analysisError.sourceRange.intersects(node.sourceRange)) return;

      // Find the variable declaration containing this signal
      final parent = node.parent;
      if (parent is! VariableDeclaration) return;

      final grandParent = parent.parent;
      if (grandParent is! VariableDeclarationList) return;

      final greatGrandParent = grandParent.parent;
      if (greatGrandParent is! VariableDeclarationStatement) return;

      // Find the class containing this build method
      final classDecl = node.thisOrAncestorOfType<ClassDeclaration>();
      if (classDecl == null) return;

      // Get the variable name and type
      final varName = parent.name.lexeme;
      final typeAnnotation = grandParent.type?.toSource() ?? 'final';
      final isLate = grandParent.lateKeyword != null;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Move signal to class level',
        priority: 80,
      );

      changeBuilder.addDartFileEdit((builder) {
        // Remove the variable declaration from build method
        builder.addDeletion(greatGrandParent.sourceRange);

        // Find the insertion point (after class opening brace)
        final classBody = classDecl.members.firstOrNull;
        final insertOffset =
            classBody?.offset ?? classDecl.leftBracket.offset + 1;

        // Build the field declaration
        final prefix = isLate ? 'late ' : '';
        final signalDecl = node.toSource();
        final fieldDecl =
            '\n  $prefix$typeAnnotation $varName = $signalDecl;\n';

        builder.addSimpleInsertion(insertOffset, fieldDecl);
      });
    });
  }
}
