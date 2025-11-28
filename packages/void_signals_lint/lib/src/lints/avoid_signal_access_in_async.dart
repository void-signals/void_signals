import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that warns against accessing signal values in async gaps.
///
/// Accessing signal values after an async gap (await) may result in stale
/// values because the signal might have changed during the async operation.
///
/// **BAD:**
/// ```dart
/// Future<void> save() async {
///   await saveToServer(user.value);  // OK
///   await Future.delayed(Duration(seconds: 1));
///   print(user.value);  // ❌ May be stale after await
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// Future<void> save() async {
///   final currentUser = user.value;  // Capture before async gap
///   await saveToServer(currentUser);
///   await Future.delayed(Duration(seconds: 1));
///   print(currentUser);  // ✅ Using captured value
/// }
/// ```
class AvoidSignalAccessInAsync extends DartLintRule {
  const AvoidSignalAccessInAsync() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_signal_access_in_async',
    problemMessage:
        'Accessing signal value after an async gap may return stale data.',
    correctionMessage:
        'Consider capturing the signal value in a local variable before the '
        'async operation, or ensure this access is intentional.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addFunctionBody((node) {
      if (node is! BlockFunctionBody) return;

      // Only check async functions
      final function = node.parent;
      final isAsync = switch (function) {
        FunctionExpression() => function.body.isAsynchronous,
        MethodDeclaration() => function.body.isAsynchronous,
        FunctionDeclaration() =>
          function.functionExpression.body.isAsynchronous,
        _ => false,
      };

      if (!isAsync) return;

      // Find all await expressions and signal accesses
      final awaitLocations = <int>[];
      final signalAccesses = <_SignalAccess>[];

      node.block.accept(_AsyncAnalysisVisitor(
        onAwait: (offset) => awaitLocations.add(offset),
        onSignalAccess: (access) => signalAccesses.add(access),
      ));

      // Check for signal accesses after await
      for (final access in signalAccesses) {
        final hasAwaitBefore =
            awaitLocations.any((await_) => await_ < access.offset);
        if (hasAwaitBefore) {
          reporter.atNode(access.node, code);
        }
      }
    });
  }

  @override
  List<Fix> getFixes() => [_CaptureSignalValueFix()];
}

class _SignalAccess {
  final AstNode node;
  final int offset;

  _SignalAccess(this.node, this.offset);
}

class _AsyncAnalysisVisitor extends RecursiveAstVisitor<void> {
  _AsyncAnalysisVisitor({
    required this.onAwait,
    required this.onSignalAccess,
  });

  final void Function(int offset) onAwait;
  final void Function(_SignalAccess) onSignalAccess;

  @override
  void visitAwaitExpression(AwaitExpression node) {
    onAwait(node.offset);
    super.visitAwaitExpression(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.identifier.name == 'value') {
      onSignalAccess(_SignalAccess(node, node.offset));
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.propertyName.name == 'value') {
      onSignalAccess(_SignalAccess(node, node.offset));
    }
    super.visitPropertyAccess(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // Check for signal() call syntax
    if (node.target == null && node.argumentList.arguments.isEmpty) {
      // Could be a signal() call - this is a getter access pattern
      onSignalAccess(_SignalAccess(node, node.offset));
    }
    super.visitMethodInvocation(node);
  }
}

/// Quick fix to capture signal value before async gap.
class _CaptureSignalValueFix extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    context.registry.addPrefixedIdentifier((node) {
      if (!analysisError.sourceRange.intersects(node.sourceRange)) return;
      if (node.identifier.name != 'value') return;

      final signalName = node.prefix.name;
      final varName =
          '_captured${signalName[0].toUpperCase()}${signalName.substring(1)}';

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Capture signal value before async gap',
        priority: 80,
      );

      changeBuilder.addDartFileEdit((builder) {
        // Find the function body to add the capture at the beginning
        final body = node.thisOrAncestorOfType<BlockFunctionBody>();
        if (body == null) return;

        final block = body.block;
        final firstStatement = block.statements.firstOrNull;
        if (firstStatement == null) return;

        // Add capture statement at the start
        builder.addSimpleInsertion(
          firstStatement.offset,
          'final $varName = $signalName.value;\n  ',
        );

        // Replace the signal access with the captured variable
        builder.addSimpleReplacement(node.sourceRange, varName);
      });
    });
  }
}
