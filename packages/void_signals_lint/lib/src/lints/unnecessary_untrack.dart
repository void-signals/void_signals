import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that flags unnecessary uses of untrack().
///
/// untrack() is only needed inside reactive contexts (effect, computed, Watch).
/// Using it elsewhere has no effect and can be confusing.
///
/// **UNNECESSARY:**
/// ```dart
/// void main() {
///   untrack(() {  // ❌ Not inside reactive context
///     print(count.value);
///   });
/// }
/// ```
///
/// **NECESSARY:**
/// ```dart
/// effect(() {
///   untrack(() {  // ✅ Inside reactive context
///     print(otherSignal.value);  // Won't track this
///   });
/// });
/// ```
class UnnecessaryUntrack extends DartLintRule {
  const UnnecessaryUntrack() : super(code: _code);

  static const _code = LintCode(
    name: 'unnecessary_untrack',
    problemMessage: 'untrack() has no effect outside of a reactive context '
        '(effect, computed, Watch).',
    correctionMessage:
        'Remove the untrack() wrapper or move this code inside a reactive context.',
    errorSeverity: ErrorSeverity.INFO,
  );

  /// Reactive contexts where untrack is meaningful.
  static const _reactiveContexts = {
    'effect',
    'computed',
    'computedFrom',
  };

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      // Check if this is an untrack() call
      if (node.methodName.name != 'untrack') return;

      // Check if we're inside a reactive context
      if (_isInsideReactiveContext(node)) return;

      reporter.atNode(node, code);
    });
  }

  bool _isInsideReactiveContext(AstNode node) {
    var parent = node.parent;

    while (parent != null) {
      if (parent is MethodInvocation) {
        final methodName = parent.methodName.name;
        if (_reactiveContexts.contains(methodName)) {
          return true;
        }
      }

      // Check for Watch or SignalBuilder widgets
      if (parent is InstanceCreationExpression) {
        final typeName = parent.constructorName.type.name2.lexeme;
        if (typeName == 'Watch' ||
            typeName == 'WatchValue' ||
            typeName == 'SignalBuilder' ||
            typeName == 'ComputedBuilder') {
          // Check if we're in the builder argument
          final arguments = parent.argumentList.arguments;
          if (arguments.isEmpty) {
            parent = parent.parent;
            continue;
          }

          Expression? builderArg;
          for (final arg in arguments) {
            if (arg is NamedExpression && arg.name.label.name == 'builder') {
              builderArg = arg.expression;
              break;
            }
          }
          builderArg ??= arguments.first;

          if (_isDescendantOf(node, builderArg)) {
            return true;
          }
        }
      }

      // Stop at function/class boundaries (unless it's the reactive callback)
      if (parent is FunctionDeclaration || parent is ClassDeclaration) {
        break;
      }

      parent = parent.parent;
    }

    return false;
  }

  bool _isDescendantOf(AstNode node, AstNode potentialAncestor) {
    var current = node.parent;
    while (current != null) {
      if (current == potentialAncestor) return true;
      current = current.parent;
    }
    return false;
  }

  @override
  List<Fix> getFixes() => [_RemoveUntrackFix()];
}

/// Quick fix to remove unnecessary untrack.
class _RemoveUntrackFix extends DartFix {
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
      if (node.methodName.name != 'untrack') return;

      final argument = node.argumentList.arguments.firstOrNull;
      if (argument == null) return;

      // If the argument is a function expression, extract its body
      if (argument is FunctionExpression) {
        final body = argument.body;
        String replacement;

        if (body is BlockFunctionBody) {
          // For block body, we need to extract statements
          // This is more complex - just unwrap the whole call
          final statements = body.block.statements;
          if (statements.length == 1) {
            replacement = statements.first.toSource();
          } else {
            // Multiple statements - replace with just the body block
            replacement = body.block
                .toSource()
                .substring(1, body.block.toSource().length - 1)
                .trim();
          }
        } else if (body is ExpressionFunctionBody) {
          replacement = '${body.expression.toSource()};';
        } else {
          return;
        }

        final changeBuilder = reporter.createChangeBuilder(
          message: 'Remove unnecessary untrack()',
          priority: 80,
        );

        final statement = node.thisOrAncestorOfType<ExpressionStatement>();
        if (statement != null) {
          changeBuilder.addDartFileEdit((builder) {
            builder.addSimpleReplacement(
              statement.sourceRange,
              replacement,
            );
          });
        }
      }
    });
  }
}
