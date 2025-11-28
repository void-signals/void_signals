import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../shared/ast_utils.dart';

/// A lint rule that warns when useSignal is created but never watched.
///
/// Creating a signal with useSignal but not subscribing to it with useWatch
/// means the widget won't rebuild when the signal changes.
///
/// **BAD:**
/// ```dart
/// Widget build(BuildContext context) {
///   final count = useSignal(0);
///   return Text('Count: ${count.value}');  // ❌ Won't rebuild
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// Widget build(BuildContext context) {
///   final count = useSignal(0);
///   final value = useWatch(count);  // ✅ Subscribes to changes
///   return Text('Count: $value');
/// }
/// ```
class UseSignalWithoutWatch extends DartLintRule {
  const UseSignalWithoutWatch() : super(code: _code);

  static const _code = LintCode(
    name: 'use_signal_without_watch',
    problemMessage:
        'Signal created with useSignal is not watched. Widget won\'t rebuild on changes.',
    correctionMessage:
        'Use useWatch() to subscribe to the signal, or use useReactive() '
        'for a signal that auto-subscribes.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodDeclaration((node) {
      if (!isBuildMethod(node)) return;

      // Collect all useSignal variable names
      final signalVars = <String, MethodInvocation>{};

      // Collect all useWatch arguments
      final watchedSignals = <String>{};

      node.body.accept(_HookAnalyzer(
        onUseSignal: (invocation, varName) {
          if (varName != null) {
            signalVars[varName] = invocation;
          }
        },
        onUseWatch: (invocation) {
          final arg = invocation.argumentList.arguments.firstOrNull;
          if (arg is SimpleIdentifier) {
            watchedSignals.add(arg.name);
          }
        },
        onUseReactive: (invocation, varName) {
          // useReactive auto-subscribes, remove from check
          if (varName != null) {
            signalVars.remove(varName);
          }
        },
      ));

      // Report signals that aren't watched
      for (final entry in signalVars.entries) {
        if (!watchedSignals.contains(entry.key)) {
          reporter.atNode(entry.value, code);
        }
      }
    });
  }

  @override
  List<Fix> getFixes() => [
        _AddUseWatchFix(),
        _ConvertToUseReactiveFix(),
      ];
}

class _HookAnalyzer extends RecursiveAstVisitor<void> {
  _HookAnalyzer({
    required this.onUseSignal,
    required this.onUseWatch,
    required this.onUseReactive,
  });

  final void Function(MethodInvocation, String?) onUseSignal;
  final void Function(MethodInvocation) onUseWatch;
  final void Function(MethodInvocation, String?) onUseReactive;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;
    final varName = getAssignedVariableName(node);

    if (methodName == 'useSignal') {
      onUseSignal(node, varName);
    } else if (methodName == 'useWatch') {
      onUseWatch(node);
    } else if (methodName == 'useReactive') {
      onUseReactive(node, varName);
    }

    super.visitMethodInvocation(node);
  }
}

class _AddUseWatchFix extends DartFix {
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
      if (node.methodName.name != 'useSignal') return;

      final varName = getAssignedVariableName(node);
      if (varName == null) return;

      // Find the statement
      AstNode? statement = node.parent;
      while (statement != null && statement is! Statement) {
        statement = statement.parent;
      }
      if (statement == null) return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Add useWatch($varName)',
        priority: 85,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleInsertion(
          statement!.end,
          '\n    final ${varName}Value = useWatch($varName);',
        );
      });
    });
  }
}

class _ConvertToUseReactiveFix extends DartFix {
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
      if (node.methodName.name != 'useSignal') return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Convert to useReactive (auto-subscribes)',
        priority: 80,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleReplacement(
          node.methodName.sourceRange,
          'useReactive',
        );
      });
    });
  }
}
