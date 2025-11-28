import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that suggests adding a debug label to useSignal for easier debugging.
///
/// Debug labels help identify signals in DevTools and error messages.
///
/// **GOOD (with label):**
/// ```dart
/// final count = useSignal(0, debugLabel: 'counter');
/// ```
class PreferUseSignalWithLabel extends DartLintRule {
  const PreferUseSignalWithLabel() : super(code: _code);

  static const _code = LintCode(
    name: 'prefer_use_signal_with_label',
    problemMessage:
        'Consider adding a debugLabel to useSignal for easier debugging.',
    correctionMessage:
        'Add debugLabel parameter: useSignal(value, debugLabel: "name")',
    errorSeverity: ErrorSeverity.INFO,
  );

  static const _hooksWithLabels = {
    'useSignal',
    'useComputed',
    'useReactive',
  };

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      final methodName = node.methodName.name;
      if (!_hooksWithLabels.contains(methodName)) return;

      // Check if debugLabel is already provided
      final hasDebugLabel = node.argumentList.arguments.any((arg) {
        if (arg is NamedExpression) {
          return arg.name.label.name == 'debugLabel';
        }
        return false;
      });

      if (!hasDebugLabel) {
        reporter.atNode(node, code);
      }
    });
  }

  @override
  List<Fix> getFixes() => [_AddDebugLabelFix()];
}

class _AddDebugLabelFix extends DartFix {
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

      // Try to get variable name for the label
      String? labelName;
      final parent = node.parent;
      if (parent is VariableDeclaration) {
        labelName = parent.name.lexeme;
      }

      labelName ??= 'TODO';

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Add debugLabel',
        priority: 70,
      );

      changeBuilder.addDartFileEdit((builder) {
        final args = node.argumentList;
        final insertOffset = args.arguments.isNotEmpty
            ? args.arguments.last.end
            : args.leftParenthesis.end;

        final prefix = args.arguments.isNotEmpty ? ', ' : '';
        builder.addSimpleInsertion(
          insertOffset,
          "${prefix}debugLabel: '$labelName'",
        );
      });
    });
  }
}
