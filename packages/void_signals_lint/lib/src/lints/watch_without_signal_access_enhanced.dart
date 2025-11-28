import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../shared/void_signals_custom_lint.dart';

/// Lint rule that warns when a Watch widget doesn't access any signals.
///
/// A Watch widget that doesn't access any signals in its builder won't
/// rebuild when signals change, making it equivalent to a regular Builder.
/// This is likely a mistake or unnecessary overhead.
///
/// **BAD:**
/// ```dart
/// Watch(
///   builder: (context, child) {
///     return Text('Static text');  // ❌ No signal access
///   },
/// )
/// ```
///
/// **GOOD:**
/// ```dart
/// Watch(
///   builder: (context, child) {
///     return Text('Count: ${count.value}');  // ✅ Accesses signal
///   },
/// )
/// ```
class WatchWithoutSignalAccess extends VoidSignalsLintRule {
  const WatchWithoutSignalAccess() : super(code: _code);

  static const _code = LintCode(
    name: 'watch_without_signal_access',
    problemMessage:
        'This Watch widget does not appear to access any signals in its builder. '
        'It will never rebuild and may be unnecessary.',
    correctionMessage: 'Either access signals in the builder using .value, '
        'or replace Watch with a regular widget.',
    errorSeverity: ErrorSeverity.INFO,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    voidSignalsRegistry(context).addWatchWidgetDeclaration((watchDecl) {
      if (watchDecl.accessedSignals.isEmpty) {
        reporter.atNode(watchDecl.node, code);
      }
    });
  }

  @override
  List<DartFix> getFixes() => [_RemoveWatchWrapperFix()];
}

class _RemoveWatchWrapperFix extends VoidSignalsFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    voidSignalsRegistry(context).addWatchWidgetDeclaration((watchDecl) {
      if (!analysisError.sourceRange.intersects(SourceRangeFrom.from(
          start: watchDecl.node.offset, end: watchDecl.node.end))) {
        return;
      }

      // Try to extract the builder's return value as a replacement
      final builder = watchDecl.builder;
      if (builder is! FunctionExpression) return;

      final body = builder.body;
      Expression? returnExpr;

      if (body is ExpressionFunctionBody) {
        returnExpr = body.expression;
      } else if (body is BlockFunctionBody) {
        final statements = body.block.statements;
        if (statements.length == 1 && statements.first is ReturnStatement) {
          returnExpr = (statements.first as ReturnStatement).expression;
        }
      }

      if (returnExpr == null) return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Replace Watch with its content',
        priority: 60,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleReplacement(
          watchDecl.node.sourceRange,
          returnExpr!.toSource(),
        );
      });
    });
  }
}
