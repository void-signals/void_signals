import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../shared/ast_utils.dart';
import '../shared/constants.dart';

/// A lint rule that ensures hooks are only called inside HookWidget.build()
/// or custom hook functions (functions starting with 'use').
///
/// This rule supports:
/// - Direct HookWidget subclasses
/// - Transitive inheritance (e.g., MyBaseHookWidget extends HookWidget)
/// - Common naming conventions (classes ending with 'HookWidget')
/// - Third-party hook packages (hooks_riverpod, etc.)
///
/// **BAD:**
/// ```dart
/// class MyWidget extends StatelessWidget {
///   Widget build(BuildContext context) {
///     final count = useSignal(0);  // ❌ Not a HookWidget
///     return Text('$count');
///   }
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// class MyWidget extends HookWidget {
///   Widget build(BuildContext context) {
///     final count = useSignal(0);  // ✅ Inside HookWidget.build()
///     return Text('$count');
///   }
/// }
///
/// // Custom base class is also supported
/// class MyWidget extends MyBaseHookWidget {
///   Widget build(BuildContext context) {
///     final count = useSignal(0);  // ✅ Inherits from HookWidget
///     return Text('$count');
///   }
/// }
///
/// Signal<int> useCounter() {
///   return useSignal(0);  // ✅ Inside a custom hook function
/// }
/// ```
class HooksOutsideHookWidget extends DartLintRule {
  const HooksOutsideHookWidget() : super(code: _code);

  static const _code = LintCode(
    name: 'hooks_outside_hook_widget',
    problemMessage:
        'Hooks can only be called inside HookWidget.build() or custom hook functions.',
    correctionMessage:
        'Move this hook call to a HookWidget.build() method, or create a custom hook function (starting with "use").',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      final methodName = node.methodName.name;

      // Check if this is a hook call
      if (!allHooks.contains(methodName)) return;

      // Check if we're inside a valid context
      if (_isValidHookContext(node, resolver)) return;

      reporter.atNode(node, code);
    });
  }

  bool _isValidHookContext(MethodInvocation node, CustomLintResolver resolver) {
    // Check if inside a custom hook function (starts with 'use')
    final enclosingFunction = getEnclosingFunction(node);
    if (enclosingFunction != null && isHookFunction(enclosingFunction)) {
      return true;
    }

    // Check if inside a custom hook method (starts with 'use')
    final enclosingMethod = getEnclosingMethod(node);
    if (enclosingMethod != null && isHookMethod(enclosingMethod)) {
      return true;
    }

    // Check if inside a HookWidget.build() method
    if (enclosingMethod != null && isBuildMethod(enclosingMethod)) {
      final enclosingClass = getEnclosingClass(node);
      if (enclosingClass != null) {
        // Use the sync heuristic-based check
        if (isHookWidgetClass(enclosingClass)) {
          return true;
        }
      }
    }

    return false;
  }

  @override
  List<Fix> getFixes() => [_ConvertToHookWidgetFix()];
}

class _ConvertToHookWidgetFix extends DartFix {
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

      final classDecl = getEnclosingClass(node);
      if (classDecl == null) return;

      final extendsClause = classDecl.extendsClause;
      if (extendsClause == null) return;

      final superclassName = extendsClause.superclass.name2.lexeme;

      // Only offer fix for StatelessWidget
      if (superclassName != 'StatelessWidget') return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Convert to HookWidget',
        priority: 90,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleReplacement(
          extendsClause.superclass.sourceRange,
          'HookWidget',
        );
      });
    });
  }
}
