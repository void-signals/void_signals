import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that suggests using peek() for read-only access in non-reactive contexts.
///
/// When you only need to read a signal value without establishing a dependency,
/// using peek() is more efficient and clearer in intent.
///
/// **CONSIDER:**
/// ```dart
/// void logValue() {
///   print(count.value);  // Creates dependency tracking overhead
/// }
/// ```
///
/// **BETTER:**
/// ```dart
/// void logValue() {
///   print(count.peek());  // ✅ No tracking overhead, clearer intent
/// }
/// ```
class PreferPeekInNonReactive extends DartLintRule {
  const PreferPeekInNonReactive() : super(code: _code);

  static const _code = LintCode(
    name: 'prefer_peek_in_non_reactive',
    problemMessage:
        'Consider using peek() instead of value in non-reactive contexts.',
    correctionMessage:
        'Use signal.peek() when you only need the current value without '
        'establishing a reactive dependency.',
    errorSeverity: ErrorSeverity.INFO,
  );

  /// Reactive contexts where .value makes sense
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
    context.registry.addPrefixedIdentifier((node) {
      if (node.identifier.name != 'value') return;

      // Check if we're in a reactive context
      if (_isInReactiveContext(node)) return;

      // Check if we're in a Watch builder
      if (_isInWatchBuilder(node)) return;

      // Check if we're in a StatefulWidget State class method
      if (_isInBuildMethod(node)) return;

      // Check if it's a write operation
      final parent = node.parent;
      if (parent is AssignmentExpression && parent.leftHandSide == node) {
        return;
      }

      reporter.atNode(node, code);
    });

    context.registry.addPropertyAccess((node) {
      if (node.propertyName.name != 'value') return;

      // Check if we're in a reactive context
      if (_isInReactiveContext(node)) return;

      // Check if we're in a Watch builder
      if (_isInWatchBuilder(node)) return;

      // Check if we're in a build method
      if (_isInBuildMethod(node)) return;

      // Check if it's a write operation
      final parent = node.parent;
      if (parent is AssignmentExpression && parent.leftHandSide == node) {
        return;
      }

      reporter.atNode(node, code);
    });
  }

  bool _isInReactiveContext(AstNode node) {
    var parent = node.parent;

    while (parent != null) {
      if (parent is MethodInvocation) {
        final methodName = parent.methodName.name;
        if (_reactiveContexts.contains(methodName)) {
          return true;
        }
      }

      // Stop at function boundaries
      if (parent is FunctionDeclaration || parent is MethodDeclaration) {
        break;
      }

      parent = parent.parent;
    }

    return false;
  }

  bool _isInWatchBuilder(AstNode node) {
    var parent = node.parent;

    while (parent != null) {
      if (parent is InstanceCreationExpression) {
        final typeName = parent.constructorName.type.name2.lexeme;
        if (typeName == 'Watch' ||
            typeName == 'WatchValue' ||
            typeName == 'SignalBuilder') {
          return true;
        }
      }

      parent = parent.parent;
    }

    return false;
  }

  bool _isInBuildMethod(AstNode node) {
    var parent = node.parent;

    while (parent != null) {
      if (parent is MethodDeclaration && parent.name.lexeme == 'build') {
        return true;
      }
      parent = parent.parent;
    }

    return false;
  }

  @override
  List<Fix> getFixes() => [_UsePeekFix()];
}

/// Quick fix to convert .value to .peek().
class _UsePeekFix extends DartFix {
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

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Use peek() instead',
        priority: 80,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleReplacement(
          node.sourceRange,
          '$signalName.peek()',
        );
      });
    });

    context.registry.addPropertyAccess((node) {
      if (!analysisError.sourceRange.intersects(node.sourceRange)) return;
      if (node.propertyName.name != 'value') return;

      final signalExpr = node.target?.toSource() ?? '';

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Use peek() instead',
        priority: 80,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleReplacement(
          node.sourceRange,
          '$signalExpr.peek()',
        );
      });
    });
  }
}
