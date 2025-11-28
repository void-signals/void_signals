import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that suggests using asyncComputed when signal dependencies are detected.
///
/// When an asyncSignal's callback reads signals, it should use asyncComputed
/// instead to properly track dependencies and re-run when they change.
///
/// **BAD:**
/// ```dart
/// final userData = asyncSignal(() async {
///   final id = userId.value;  // ❌ Signal read won't trigger re-fetch
///   return await fetchUser(id);
/// });
/// ```
///
/// **GOOD:**
/// ```dart
/// final userData = asyncComputed(() async {
///   final id = userId();  // ✅ Dependency tracked, will re-fetch when userId changes
///   return await fetchUser(id);
/// });
/// ```
class PreferAsyncComputedForTracked extends DartLintRule {
  const PreferAsyncComputedForTracked() : super(code: _code);

  static const _code = LintCode(
    name: 'prefer_async_computed_for_tracked',
    problemMessage:
        'Signal dependency detected in asyncSignal. Consider using asyncComputed() for automatic dependency tracking.',
    correctionMessage:
        'asyncComputed() will automatically re-run when the signal changes. '
        'asyncSignal() does not track dependencies.',
    errorSeverity: ErrorSeverity.INFO,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      if (node.methodName.name != 'asyncSignal') return;

      final arg = node.argumentList.arguments.firstOrNull;
      if (arg is! FunctionExpression) return;

      // Check if the callback reads any signals
      var hasSignalAccess = false;
      arg.body.accept(_SignalAccessVisitor(
        onSignalAccess: () => hasSignalAccess = true,
      ));

      if (hasSignalAccess) {
        reporter.atNode(node, code);
      }
    });
  }

  @override
  List<Fix> getFixes() => [_ConvertToAsyncComputedFix()];
}

class _SignalAccessVisitor extends RecursiveAstVisitor<void> {
  _SignalAccessVisitor({required this.onSignalAccess});

  final void Function() onSignalAccess;

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.identifier.name == 'value') {
      onSignalAccess();
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.propertyName.name == 'value') {
      onSignalAccess();
    }
    super.visitPropertyAccess(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // Check for signal() call syntax - a call with no arguments on something
    if (node.target != null && node.argumentList.arguments.isEmpty) {
      onSignalAccess();
    }
    super.visitMethodInvocation(node);
  }
}

/// Quick fix to convert asyncSignal to asyncComputed.
class _ConvertToAsyncComputedFix extends DartFix {
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
      if (node.methodName.name != 'asyncSignal') return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Convert to asyncComputed',
        priority: 80,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleReplacement(
          node.methodName.sourceRange,
          'asyncComputed',
        );
      });
    });
  }
}
