import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that warns when SignalBuilder is used with a function call
/// instead of a signal reference.
///
/// SignalBuilder expects a Signal instance, not a signal creation call.
///
/// **BAD:**
/// ```dart
/// SignalBuilder(
///   signal: signal(0),  // ❌ Creates new signal on each build!
///   builder: (context, value, child) => Text('$value'),
/// )
/// ```
///
/// **GOOD:**
/// ```dart
/// final count = signal(0);
///
/// SignalBuilder(
///   signal: count,  // ✅ Reference to existing signal
///   builder: (context, value, child) => Text('$value'),
/// )
/// ```
class AvoidSignalCreationInBuilder extends DartLintRule {
  const AvoidSignalCreationInBuilder() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_signal_creation_in_builder',
    problemMessage:
        'Creating a signal inside a builder creates a new signal on each build.',
    correctionMessage:
        'Move the signal creation outside of the widget and pass a reference.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  /// Signal creation functions
  static const _signalCreators = {
    'signal',
    'computed',
    'computedFrom',
    'asyncSignal',
    'debounced',
    'throttled',
    'delayed',
  };

  /// Widget constructors that take signals
  static const _signalWidgets = {
    'SignalBuilder',
    'ComputedBuilder',
    'WatchValue',
    'MultiSignalBuilder',
    'AsyncSignalBuilder',
    'SignalFieldBuilder',
  };

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      final typeName = node.constructorName.type.name2.lexeme;

      if (!_signalWidgets.contains(typeName)) return;

      // Check the signal argument
      for (final arg in node.argumentList.arguments) {
        Expression? argExpr;
        String? argName;

        if (arg is NamedExpression) {
          argName = arg.name.label.name;
          argExpr = arg.expression;
        } else {
          argExpr = arg;
        }

        // Check if it's a 'signal' or 'signals' argument
        if (argName != null &&
            argName != 'signal' &&
            argName != 'signals' &&
            argName != 'computed') {
          continue;
        }

        // Check for signal creation in the argument
        if (argExpr is MethodInvocation) {
          if (_signalCreators.contains(argExpr.methodName.name)) {
            reporter.atNode(argExpr, code);
          }
        } else if (argExpr is ListLiteral) {
          // Check list items for MultiSignalBuilder
          for (final item in argExpr.elements) {
            if (item is MethodInvocation) {
              if (_signalCreators.contains(item.methodName.name)) {
                reporter.atNode(item, code);
              }
            }
          }
        }
      }
    });
  }
}
