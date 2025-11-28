import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that warns against using zero duration for useDebounced.
///
/// A duration of zero defeats the purpose of debouncing.
///
/// **BAD:**
/// ```dart
/// final debounced = useDebounced(signal, Duration.zero);  // ❌
/// final debounced = useDebounced(signal, Duration(milliseconds: 0));  // ❌
/// ```
///
/// **GOOD:**
/// ```dart
/// final debounced = useDebounced(signal, Duration(milliseconds: 300));  // ✅
/// ```
class UseDebouncedZeroDuration extends DartLintRule {
  const UseDebouncedZeroDuration() : super(code: _code);

  static const _code = LintCode(
    name: 'use_debounced_zero_duration',
    problemMessage:
        'Using Duration.zero with useDebounced defeats the purpose of debouncing.',
    correctionMessage:
        'Use a meaningful duration like Duration(milliseconds: 300).',
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      final methodName = node.methodName.name;
      if (methodName != 'useDebounced' && methodName != 'useThrottled') return;

      final args = node.argumentList.arguments;
      if (args.length < 2) return;

      final durationArg = args[1];

      // Check for Duration.zero
      if (durationArg is PrefixedIdentifier) {
        if (durationArg.prefix.name == 'Duration' &&
            durationArg.identifier.name == 'zero') {
          reporter.atNode(durationArg, code);
          return;
        }
      }

      // Check for Duration(milliseconds: 0) or similar
      if (durationArg is InstanceCreationExpression) {
        final typeName = durationArg.constructorName.type.name2.lexeme;
        if (typeName == 'Duration') {
          final durationArgs = durationArg.argumentList.arguments;
          if (durationArgs.length == 1) {
            final arg = durationArgs.first;
            if (arg is NamedExpression) {
              final value = arg.expression;
              if (value is IntegerLiteral && value.value == 0) {
                reporter.atNode(durationArg, code);
              }
            }
          }
        }
      }
    });
  }

  @override
  List<Fix> getFixes() => [_FixDebounceDurationFix()];
}

class _FixDebounceDurationFix extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    context.registry.addMethodInvocation((node) {
      final methodName = node.methodName.name;
      if (methodName != 'useDebounced' && methodName != 'useThrottled') return;

      final args = node.argumentList.arguments;
      if (args.length < 2) return;

      final durationArg = args[1];
      if (!analysisError.sourceRange.intersects(durationArg.sourceRange)) {
        return;
      }

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Change to 300ms',
        priority: 80,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleReplacement(
          durationArg.sourceRange,
          'Duration(milliseconds: 300)',
        );
      });
    });
  }
}
