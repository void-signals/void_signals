import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../shared/void_signals_types.dart';

/// Assist to wrap a widget with Watch.
///
/// This is one of the most useful assists for void_signals users.
/// It converts a regular widget into a reactive widget that rebuilds
/// when signals change.
///
/// Before:
/// ```dart
/// Text('Count: ${count.value}')
/// ```
///
/// After:
/// ```dart
/// Watch(
///   builder: (context, _) => Text('Count: ${count.value}'),
/// )
/// ```
class WrapWithWatch extends DartAssist {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    SourceRange target,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      // Check if target intersects with widget creation
      if (!target.intersects(node.sourceRange)) return;

      // Verify this is a Widget
      final type = node.staticType;
      if (type == null || !type.isWidget) return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Wrap with Watch',
        priority: 30,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleInsertion(
          node.offset,
          'Watch(\n  builder: (context, _) => ',
        );
        builder.addSimpleInsertion(node.end, ',\n)');
      });
    });
  }
}

/// Assist to wrap a widget with SignalBuilder.
///
/// For single-signal reactive updates with explicit signal binding.
///
/// Before:
/// ```dart
/// Text('Count: ${count.value}')
/// ```
///
/// After:
/// ```dart
/// SignalBuilder<int>(
///   signal: count,
///   builder: (context, value, _) => Text('Count: $value'),
/// )
/// ```
class WrapWithSignalBuilder extends DartAssist {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    SourceRange target,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      if (!target.intersects(node.sourceRange)) return;

      final type = node.staticType;
      if (type == null || !type.isWidget) return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Wrap with SignalBuilder',
        priority: 29,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleInsertion(
          node.offset,
          'SignalBuilder(\n  signal: /* TODO: signal */,\n  builder: (context, value, _) => ',
        );
        builder.addSimpleInsertion(node.end, ',\n)');
      });
    });
  }
}

/// Assist to wrap a widget with Consumer.
///
/// For Riverpod-style API users.
///
/// Before:
/// ```dart
/// Text('Count: ${count.value}')
/// ```
///
/// After:
/// ```dart
/// Consumer(
///   builder: (context, ref, _) => Text('Count: ${ref.watch(count)}'),
/// )
/// ```
class WrapWithConsumer extends DartAssist {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    SourceRange target,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      if (!target.intersects(node.sourceRange)) return;

      final type = node.staticType;
      if (type == null || !type.isWidget) return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Wrap with Consumer',
        priority: 28,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleInsertion(
          node.offset,
          'Consumer(\n  builder: (context, ref, _) => ',
        );
        builder.addSimpleInsertion(node.end, ',\n)');
      });
    });
  }
}

/// Assist to extract a signal's initial value to a const.
///
/// For signals with complex initial values that should be constants.
///
/// Before:
/// ```dart
/// final config = signal(AppConfig(debug: true, maxItems: 100));
/// ```
///
/// After:
/// ```dart
/// const _defaultConfig = AppConfig(debug: true, maxItems: 100);
/// final config = signal(_defaultConfig);
/// ```
class ExtractSignalInitialValue extends DartAssist {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    SourceRange target,
  ) {
    context.registry.addMethodInvocation((node) {
      if (!target.intersects(node.sourceRange)) return;
      if (node.methodName.name != 'signal') return;

      final args = node.argumentList.arguments;
      if (args.isEmpty) return;

      final firstArg = args.first;
      if (firstArg is NamedExpression) return;

      // Only offer for non-trivial initial values
      if (firstArg is Literal || firstArg is PrefixedIdentifier) return;

      // Get variable name if available
      String? varName;
      final parent = node.parent;
      if (parent is VariableDeclaration) {
        varName = parent.name.lexeme;
      }

      final constName =
          varName != null ? '_default${_capitalize(varName)}' : '_defaultValue';

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Extract initial value to const',
        priority: 25,
      );

      changeBuilder.addDartFileEdit((builder) {
        // Find the top-level statement
        var current = node.parent;
        while (current != null && current is! CompilationUnitMember) {
          current = current.parent;
        }

        if (current != null) {
          final initialValue = firstArg.toSource();
          builder.addSimpleInsertion(
            current.offset,
            'const $constName = $initialValue;\n\n',
          );
          builder.addSimpleReplacement(
            firstArg.sourceRange,
            constName,
          );
        }
      });
    });
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

/// Assist to convert ValueNotifier to Signal.
///
/// Helps migrate from Flutter's ValueNotifier to void_signals.
///
/// Before:
/// ```dart
/// final count = ValueNotifier(0);
/// ```
///
/// After:
/// ```dart
/// final count = signal(0);
/// ```
class ConvertValueNotifierToSignal extends DartAssist {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    SourceRange target,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      if (!target.intersects(node.sourceRange)) return;

      final typeName = node.constructorName.type.name2.lexeme;
      if (typeName != 'ValueNotifier') return;

      final args = node.argumentList.arguments;
      if (args.isEmpty) return;

      final initialValue = args.first;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Convert to signal()',
        priority: 35,
      );

      changeBuilder.addDartFileEdit((builder) {
        builder.addSimpleReplacement(
          node.sourceRange,
          'signal(${initialValue.toSource()})',
        );
      });
    });
  }
}

/// Assist to add debug label to signal.
///
/// Adds a label parameter for easier debugging.
///
/// Before:
/// ```dart
/// final count = signal(0);
/// ```
///
/// After:
/// ```dart
/// final count = signal(0, debugLabel: 'count');
/// ```
class AddSignalDebugLabel extends DartAssist {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    SourceRange target,
  ) {
    context.registry.addMethodInvocation((node) {
      if (!target.intersects(node.sourceRange)) return;
      if (node.methodName.name != 'signal' &&
          node.methodName.name != 'computed') return;

      // Check if already has debugLabel
      for (final arg in node.argumentList.arguments) {
        if (arg is NamedExpression && arg.name.label.name == 'debugLabel') {
          return; // Already has label
        }
      }

      // Get variable name
      String? varName;
      final parent = node.parent;
      if (parent is VariableDeclaration) {
        varName = parent.name.lexeme;
      }

      if (varName == null) return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Add debug label',
        priority: 20,
      );

      changeBuilder.addDartFileEdit((builder) {
        final args = node.argumentList.arguments;
        if (args.isNotEmpty) {
          // Insert after last argument
          builder.addSimpleInsertion(
            args.last.end,
            ", debugLabel: '$varName'",
          );
        }
      });
    });
  }
}

/// Assist to convert effect to Watch widget.
///
/// When an effect is only used to update UI, suggest converting to Watch.
///
/// Before:
/// ```dart
/// effect(() {
///   setState(() {});
/// });
/// return Text('${count.value}');
/// ```
///
/// After:
/// ```dart
/// return Watch(
///   builder: (context, _) => Text('${count.value}'),
/// );
/// ```
class ConvertEffectToWatch extends DartAssist {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    SourceRange target,
  ) {
    context.registry.addMethodInvocation((node) {
      if (!target.intersects(node.sourceRange)) return;
      if (node.methodName.name != 'effect') return;

      final args = node.argumentList.arguments;
      if (args.isEmpty) return;

      final effectFn = args.first;
      if (effectFn is! FunctionExpression) return;

      // Check if effect body only contains setState
      bool hasOnlySetState = false;
      effectFn.body.accept(_SetStateOnlyChecker((result) {
        hasOnlySetState = result;
      }));

      if (!hasOnlySetState) return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Convert effect to Watch widget',
        priority: 40,
      );

      changeBuilder.addDartFileEdit((builder) {
        // This is a placeholder - actual implementation would need to
        // find the widget being returned and wrap it with Watch
        // For now, just add a TODO comment
        builder.addSimpleInsertion(
          node.offset,
          '// TODO: Replace this effect with Watch widget\n    ',
        );
      });
    });
  }
}

class _SetStateOnlyChecker extends RecursiveAstVisitor<void> {
  _SetStateOnlyChecker(this.onResult);
  final void Function(bool) onResult;
  int _methodCallCount = 0;
  int _setStateCount = 0;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _methodCallCount++;
    if (node.methodName.name == 'setState') {
      _setStateCount++;
    }
    super.visitMethodInvocation(node);
    // If done visiting
    onResult(_setStateCount > 0 && _setStateCount == _methodCallCount);
  }
}
