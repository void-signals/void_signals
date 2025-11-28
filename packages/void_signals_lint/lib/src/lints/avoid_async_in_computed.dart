import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that warns when long-running operations are in computed.
///
/// Computed values should be fast to calculate. Long-running operations
/// like network requests should use asyncComputed instead, which provides
/// proper dependency tracking and cancellation of outdated computations.
///
/// **BAD:**
/// ```dart
/// final userData = computed((_) async {
///   return await fetchUser();  // ❌ Async operation in computed
/// });
/// ```
///
/// **GOOD:**
/// ```dart
/// // ✅ Use asyncComputed for proper async dependency tracking
/// final userData = asyncComputed(() async {
///   final id = userId();  // Dependencies tracked before first await
///   return await fetchUser(id);
/// });
///
/// // ✅ Or use asyncSignal for simple futures without dependency tracking
/// final userData = asyncSignal(fetchUser());
/// ```
class AvoidAsyncInComputed extends DartLintRule {
  const AvoidAsyncInComputed() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_async_in_computed',
    problemMessage:
        'Avoid async operations in computed. Use asyncComputed() for tracked async or asyncSignal() for simple futures.',
    correctionMessage:
        'Replace computed with asyncComputed for async operations with dependency tracking, '
        'or asyncSignal for simple untracked futures. Computed should be synchronous and fast.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      if (node.methodName.name != 'computed' &&
          node.methodName.name != 'computedFrom') {
        return;
      }

      final arg = node.argumentList.arguments.firstOrNull;
      if (arg == null) return;

      // Check if the callback is async
      if (arg is FunctionExpression) {
        if (arg.body.isAsynchronous) {
          reporter.atNode(node, code);
          return;
        }

        // Check for await expressions inside
        if (_containsAwait(arg.body)) {
          reporter.atNode(node, code);
        }
      }
    });
  }

  bool _containsAwait(AstNode node) {
    var found = false;
    node.accept(_AwaitVisitor(onAwait: () => found = true));
    return found;
  }

  @override
  List<Fix> getFixes() => [_ConvertToAsyncSignalFix()];
}

class _AwaitVisitor extends RecursiveAstVisitor<void> {
  _AwaitVisitor({required this.onAwait});

  final void Function() onAwait;

  @override
  void visitAwaitExpression(AwaitExpression node) {
    onAwait();
    super.visitAwaitExpression(node);
  }
}

/// Quick fix to convert computed to asyncComputed.
class _ConvertToAsyncSignalFix extends DartFix {
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

      if (node.methodName.name != 'computed' &&
          node.methodName.name != 'computedFrom') {
        return;
      }

      final arg = node.argumentList.arguments.firstOrNull;
      if (arg == null) return;

      // Primary fix: convert to asyncComputed
      final changeBuilder = reporter.createChangeBuilder(
        message: 'Convert to asyncComputed (with dependency tracking)',
        priority: 80,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleReplacement(
          node.methodName.sourceRange,
          'asyncComputed',
        );
      });

      // Alternative fix: convert to asyncSignal (simpler, no tracking)
      final altChangeBuilder = reporter.createChangeBuilder(
        message: 'Convert to asyncSignal (simple future)',
        priority: 70,
      );

      altChangeBuilder.addDartFileEdit((builder) {
        builder.addSimpleReplacement(
          node.methodName.sourceRange,
          'asyncSignal',
        );
      });
    });
  }
}
