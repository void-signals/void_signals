import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that warns when signals are read after await in asyncComputed.
///
/// In asyncComputed, signal dependencies are only tracked during the synchronous
/// phase (before the first await). Reading signals after await won't create
/// dependencies and may lead to unexpected behavior.
///
/// **BAD:**
/// ```dart
/// final data = asyncComputed(() async {
///   await Future.delayed(Duration(seconds: 1));
///   final id = userId();  // ❌ Not tracked - after await!
///   return await fetchData(id);
/// });
/// ```
///
/// **GOOD:**
/// ```dart
/// final data = asyncComputed(() async {
///   final id = userId();  // ✅ Tracked - before await
///   await Future.delayed(Duration(seconds: 1));
///   return await fetchData(id);
/// });
/// ```
class AsyncComputedDependencyTracking extends DartLintRule {
  const AsyncComputedDependencyTracking() : super(code: _code);

  static const _code = LintCode(
    name: 'async_computed_dependency_tracking',
    problemMessage:
        'Signal read after await will not be tracked as a dependency in asyncComputed.',
    correctionMessage:
        'Move signal reads before the first await to ensure they are tracked. '
        'Dependencies are only tracked during the synchronous phase.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      if (node.methodName.name != 'asyncComputed') return;

      final arg = node.argumentList.arguments.firstOrNull;
      if (arg is! FunctionExpression) return;

      final body = arg.body;
      if (body is! BlockFunctionBody) return;
      if (!body.isAsynchronous) return;

      // Find all await expressions and signal accesses
      final awaitLocations = <int>[];
      final signalAccesses = <_SignalAccessInfo>[];

      body.block.accept(_AsyncComputedAnalysisVisitor(
        onAwait: (offset) => awaitLocations.add(offset),
        onSignalAccess: (info) => signalAccesses.add(info),
      ));

      if (awaitLocations.isEmpty) return;

      final firstAwaitOffset = awaitLocations.reduce((a, b) => a < b ? a : b);

      // Report signal accesses after the first await
      for (final access in signalAccesses) {
        if (access.offset > firstAwaitOffset) {
          reporter.atNode(access.node, code);
        }
      }
    });
  }

  @override
  List<Fix> getFixes() => [_MoveBeforeAwaitFix()];
}

class _SignalAccessInfo {
  final AstNode node;
  final int offset;
  final String signalName;

  _SignalAccessInfo(this.node, this.offset, this.signalName);
}

class _AsyncComputedAnalysisVisitor extends RecursiveAstVisitor<void> {
  _AsyncComputedAnalysisVisitor({
    required this.onAwait,
    required this.onSignalAccess,
  });

  final void Function(int offset) onAwait;
  final void Function(_SignalAccessInfo) onSignalAccess;

  @override
  void visitAwaitExpression(AwaitExpression node) {
    onAwait(node.offset);
    super.visitAwaitExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // Check for signal() call syntax - a call with no arguments
    if (node.target != null && node.argumentList.arguments.isEmpty) {
      final name = node.methodName.name;
      // Likely a signal getter call like userId()
      onSignalAccess(_SignalAccessInfo(node, node.offset, name));
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.identifier.name == 'value') {
      onSignalAccess(_SignalAccessInfo(node, node.offset, node.prefix.name));
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.propertyName.name == 'value') {
      final targetName = switch (node.target) {
        Identifier(:final name) => name,
        _ => 'signal',
      };
      onSignalAccess(_SignalAccessInfo(node, node.offset, targetName));
    }
    super.visitPropertyAccess(node);
  }
}

/// Quick fix to move signal read before await.
class _MoveBeforeAwaitFix extends DartFix {
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

      // Check if this is a signal call pattern
      if (node.target == null || node.argumentList.arguments.isNotEmpty) return;

      final signalName = node.methodName.name;
      final varName = '_${signalName}Value';

      final asyncComputed = node.thisOrAncestorMatching(
          (n) => n is MethodInvocation && n.methodName.name == 'asyncComputed');
      if (asyncComputed is! MethodInvocation) return;

      final funcArg = asyncComputed.argumentList.arguments.firstOrNull;
      if (funcArg is! FunctionExpression) return;

      final body = funcArg.body;
      if (body is! BlockFunctionBody) return;

      final firstStatement = body.block.statements.firstOrNull;
      if (firstStatement == null) return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Move signal read before await',
        priority: 80,
      );

      changeBuilder.addDartFileEdit((builder) {
        // Add variable declaration at the start
        builder.addSimpleInsertion(
          firstStatement.offset,
          'final $varName = $signalName();\n    ',
        );

        // Replace the signal access with the captured variable
        builder.addSimpleReplacement(node.sourceRange, varName);
      });
    });
  }
}
