import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that suggests using Signal directly instead of ValueNotifier.
///
/// If you're using void_signals, Signals provide better performance and
/// more features than ValueNotifier.
///
/// **BEFORE:**
/// ```dart
/// final count = ValueNotifier(0);
/// count.value = 1;
/// ```
///
/// **AFTER:**
/// ```dart
/// final count = signal(0);
/// count.value = 1;  // Same API, better performance
/// ```
class PreferSignalOverValueNotifier extends DartLintRule {
  const PreferSignalOverValueNotifier() : super(code: _code);

  static const _code = LintCode(
    name: 'prefer_signal_over_value_notifier',
    problemMessage: 'Consider using Signal instead of ValueNotifier for better '
        'performance and reactive features.',
    correctionMessage:
        'Replace ValueNotifier with signal(). The value access API is similar.',
    errorSeverity: ErrorSeverity.INFO,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      final typeName = node.constructorName.type.name2.lexeme;

      if (typeName == 'ValueNotifier') {
        reporter.atNode(node, code);
      }
    });

    // Also check type annotations
    context.registry.addVariableDeclaration((node) {
      final parent = node.parent;
      if (parent is! VariableDeclarationList) return;

      final type = parent.type;
      if (type == null) return;

      final typeSource = type.toSource();
      if (typeSource.startsWith('ValueNotifier<')) {
        reporter.atNode(type, code);
      }
    });
  }

  @override
  List<Fix> getFixes() => [_ConvertToSignalFix()];
}

/// Quick fix to convert ValueNotifier to signal.
class _ConvertToSignalFix extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      if (!analysisError.sourceRange.intersects(node.sourceRange)) return;

      final typeName = node.constructorName.type.name2.lexeme;
      if (typeName != 'ValueNotifier') return;

      final argument = node.argumentList.arguments.firstOrNull;
      if (argument == null) return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Convert to signal()',
        priority: 80,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleReplacement(
          node.sourceRange,
          'signal(${argument.toSource()})',
        );
      });
    });
  }
}
