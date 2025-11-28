import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that suggests adding debug labels to signals.
///
/// Debug labels make it easier to identify signals in DevTools and debugging.
///
/// **WITHOUT LABEL:**
/// ```dart
/// final count = signal(0);  // Hard to identify in DevTools
/// ```
///
/// **WITH LABEL:**
/// ```dart
/// final count = signal(0).tracked(label: 'count');  // ✅ Easy to identify
/// ```
class PreferSignalWithLabel extends DartLintRule {
  const PreferSignalWithLabel() : super(code: _code);

  static const _code = LintCode(
    name: 'prefer_signal_with_label',
    problemMessage:
        'Consider adding a debug label to this signal for easier debugging.',
    correctionMessage:
        'Use .tracked(label: "name") to add a label visible in DevTools.',
    errorSeverity: ErrorSeverity.INFO,
  );

  /// Signal creators that should have labels
  static const _signalCreators = {
    'signal',
    'computed',
    'computedFrom',
    'asyncSignal',
  };

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addVariableDeclaration((node) {
      final initializer = node.initializer;
      if (initializer == null) return;

      // Check if it's a signal creation
      if (initializer is MethodInvocation) {
        if (!_signalCreators.contains(initializer.methodName.name)) return;

        // Check if .tracked() is called
        final parent = node.parent?.parent;
        if (parent is VariableDeclarationStatement) {
          // Simple signal without tracked
          reporter.atNode(initializer, code);
        }
      }

      // Check for chained call like signal(0).tracked()
      if (initializer is MethodInvocation &&
          initializer.methodName.name == 'tracked') {
        // Already has tracked
        return;
      }
    });
  }

  @override
  List<Fix> getFixes() => [_AddTrackedLabelFix()];
}

/// Quick fix to add tracked label.
class _AddTrackedLabelFix extends DartFix {
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

      final varDecl = node.thisOrAncestorOfType<VariableDeclaration>();
      if (varDecl == null) return;

      final varName = varDecl.name.lexeme;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Add .tracked(label: "$varName")',
        priority: 70,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleInsertion(
          node.end,
          '.tracked(label: \'$varName\')',
        );
      });
    });
  }
}
