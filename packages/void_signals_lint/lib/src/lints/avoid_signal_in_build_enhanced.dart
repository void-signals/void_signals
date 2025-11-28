import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../shared/void_signals_custom_lint.dart';

/// Enhanced lint rule that warns when signals are created inside Flutter build methods.
///
/// Creating signals in build methods means they are recreated on every rebuild,
/// which defeats the purpose of using signals for state management and can cause:
/// - Memory leaks from orphaned signals
/// - Loss of state on every rebuild
/// - Performance issues from repeated allocations
///
/// This enhanced version uses type resolution instead of simple name matching.
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
/// // Option 1: Class field
/// final count = signal(0);  // ✅ Created once
///
/// // Option 2: useSignal hook (in HookWidget)
/// final count = useSignal(0);  // ✅ Managed by hooks
/// ```
class AvoidSignalInBuildEnhanced extends VoidSignalsLintRule {
  const AvoidSignalInBuildEnhanced() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_signal_in_build',
    problemMessage:
        'Avoid creating signals inside build methods. Signals created here '
        'will be recreated on every rebuild, losing their state.',
    correctionMessage:
        'Move the signal declaration to a class field, use a late final field, '
        'or use useSignal() hook if using HookWidget.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    voidSignalsRegistry(context).addSignalCreation((creation) {
      if (creation.isInsideBuildMethod) {
        reporter.atNode(creation.node, code);
      }
    });
  }

  @override
  List<DartFix> getFixes() => [_MoveSignalToClassFieldFix()];
}

class _MoveSignalToClassFieldFix extends VoidSignalsFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    voidSignalsRegistry(context).addSignalCreation((creation) {
      if (!analysisError.sourceRange.intersects(SourceRangeFrom.from(
          start: creation.node.offset, end: creation.node.end))) {
        return;
      }

      final classDecl = creation.enclosingClass;
      if (classDecl == null) return;

      final variableName = creation.variableName;
      if (variableName == null) return;

      // Get the full variable declaration statement
      AstNode? currentNode = creation.node;
      VariableDeclarationStatement? varStmt;
      while (currentNode != null) {
        if (currentNode is VariableDeclarationStatement) {
          varStmt = currentNode;
          break;
        }
        currentNode = currentNode.parent;
      }
      if (varStmt == null) return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Move signal to class field',
        priority: 80,
      );

      changeBuilder.addDartFileEdit((builder) {
        // Remove the variable declaration from build method
        builder.addDeletion(varStmt!.sourceRange);

        // Find the insertion point (after class opening brace)
        final classBody = classDecl.members.firstOrNull;
        final insertOffset =
            classBody?.offset ?? classDecl.leftBracket.offset + 1;

        // Build the field declaration
        final signalDecl = creation.node.toSource();
        final fieldDecl = '\n  late final $variableName = $signalDecl;\n';

        builder.addSimpleInsertion(insertOffset, fieldDecl);
      });
    });
  }
}
