import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that warns when signals are declared as non-final.
///
/// Signals should be declared as final because reassigning a signal variable
/// would break the reactive connection.
///
/// **BAD:**
/// ```dart
/// var count = signal(0);  // ❌ Can be reassigned
/// count = signal(1);  // Breaks reactivity!
/// ```
///
/// **GOOD:**
/// ```dart
/// final count = signal(0);  // ✅ Cannot be reassigned
/// count.value = 1;  // Proper way to update
/// ```
class PreferFinalSignal extends DartLintRule {
  const PreferFinalSignal() : super(code: _code);

  static const _code = LintCode(
    name: 'prefer_final_signal',
    problemMessage:
        'Signal should be declared as final. Reassigning the signal variable '
        'will break reactive connections.',
    correctionMessage: 'Add "final" keyword to the signal declaration.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  /// Signal creation functions to check.
  static const _signalCreators = {
    'signal',
    'computed',
    'computedFrom',
    'asyncSignal',
    'asyncSignalFromStream',
    'debounced',
    'throttled',
    'delayed',
  };

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addVariableDeclaration((node) {
      // Check if initialization is a signal creation
      final initializer = node.initializer;
      if (initializer is! MethodInvocation) return;

      if (!_signalCreators.contains(initializer.methodName.name)) return;

      // Check if the variable is final or const
      final parent = node.parent;
      if (parent is! VariableDeclarationList) return;

      if (parent.isFinal || parent.isConst) return;

      // Check for late keyword
      if (parent.lateKeyword != null) return;

      reporter.atNode(node, code);
    });
  }

  @override
  List<Fix> getFixes() => [_MakeSignalFinalFix()];
}

/// Quick fix to make signal declaration final.
class _MakeSignalFinalFix extends DartFix {
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

      final parent = node.parent;
      if (parent is! VariableDeclarationList) return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Make signal final',
        priority: 90,
      );

      changeBuilder.addDartFileEdit((builder) {
        // Find the keyword to replace or add final
        if (parent.keyword != null) {
          // Replace 'var' with 'final'
          builder.addSimpleReplacement(
            parent.keyword!.sourceRange,
            'final',
          );
        } else if (parent.type != null) {
          // Add 'final' before the type
          builder.addSimpleInsertion(parent.type!.offset, 'final ');
        }
      });
    });
  }
}
