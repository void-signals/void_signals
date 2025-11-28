import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that suggests using SignalScope for dependency injection.
///
/// When you have signals that should be overridable in tests or different
/// parts of the widget tree, consider using SignalScope for proper DI.
///
/// **GLOBAL (less flexible):**
/// ```dart
/// // Hard to test and override
/// final globalCounter = signal(0);
/// ```
///
/// **WITH SignalScope (more flexible):**
/// ```dart
/// final counter = signal(0);
///
/// // In widget tree:
/// SignalScope(
///   overrides: [counter.overrideWith(signal(10))],
///   child: MyWidget(),
/// )
/// ```
class PreferSignalScopeForDI extends DartLintRule {
  const PreferSignalScopeForDI() : super(code: _code);

  static const _code = LintCode(
    name: 'prefer_signal_scope_for_di',
    problemMessage:
        'Consider using SignalScope for dependency injection to make this '
        'signal overridable in tests and different parts of the widget tree.',
    correctionMessage:
        'Wrap your widget tree with SignalScope and use signal.scoped(context) '
        'to access overridable signals.',
    errorSeverity: ErrorSeverity.INFO,
  );

  /// Signal creators that might benefit from DI
  static const _signalCreators = {
    'signal',
    'asyncSignal',
  };

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addTopLevelVariableDeclaration((node) {
      // Check for top-level signal declarations
      for (final variable in node.variables.variables) {
        final initializer = variable.initializer;
        if (initializer is! MethodInvocation) continue;

        if (!_signalCreators.contains(initializer.methodName.name)) continue;

        // Check if it's used in a way that might benefit from DI
        // For now, just suggest on any top-level signal
        reporter.atNode(variable, code);
      }
    });
  }
}
