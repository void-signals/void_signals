import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Assist to convert StatelessWidget to ConsumerWidget.
///
/// For users who want to use the Riverpod-style Consumer API.
///
/// Before:
/// ```dart
/// class MyWidget extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return Text('Hello');
///   }
/// }
/// ```
///
/// After:
/// ```dart
/// class MyWidget extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, SignalRef ref) {
///     return Text('Hello');
///   }
/// }
/// ```
class ConvertToConsumerWidget extends DartAssist {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    SourceRange target,
  ) {
    context.registry.addClassDeclaration((node) {
      if (!target.intersects(node.sourceRange)) return;

      final extendsClause = node.extendsClause;
      if (extendsClause == null) return;

      final superclass = extendsClause.superclass;
      final superclassName = superclass.name2.lexeme;

      // Only convert StatelessWidget
      if (superclassName != 'StatelessWidget') return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Convert to ConsumerWidget',
        priority: 50,
      );

      changeBuilder.addDartFileEdit((builder) {
        // Change extends clause
        builder.addSimpleReplacement(
          superclass.sourceRange,
          'ConsumerWidget',
        );

        // Find build method and add SignalRef parameter
        for (final member in node.members) {
          if (member is MethodDeclaration && member.name.lexeme == 'build') {
            final params = member.parameters;
            if (params != null && params.parameters.isNotEmpty) {
              // Add ref parameter after context
              final firstParam = params.parameters.first;
              builder.addSimpleInsertion(
                firstParam.end,
                ', SignalRef ref',
              );
            }
            break;
          }
        }
      });
    });
  }
}

/// Assist to convert StatefulWidget to ConsumerStatefulWidget.
///
/// Before:
/// ```dart
/// class MyWidget extends StatefulWidget {
///   @override
///   State<MyWidget> createState() => _MyWidgetState();
/// }
///
/// class _MyWidgetState extends State<MyWidget> {
///   @override
///   Widget build(BuildContext context) {
///     return Text('Hello');
///   }
/// }
/// ```
///
/// After:
/// ```dart
/// class MyWidget extends ConsumerStatefulWidget {
///   @override
///   ConsumerState<MyWidget> createState() => _MyWidgetState();
/// }
///
/// class _MyWidgetState extends ConsumerState<MyWidget> {
///   @override
///   Widget build(BuildContext context) {
///     // Use ref.watch(signal) in build
///     return Text('Hello');
///   }
/// }
/// ```
class ConvertToConsumerStatefulWidget extends DartAssist {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    SourceRange target,
  ) {
    context.registry.addClassDeclaration((node) {
      if (!target.intersects(node.sourceRange)) return;

      final extendsClause = node.extendsClause;
      if (extendsClause == null) return;

      final superclass = extendsClause.superclass;
      final superclassName = superclass.name2.lexeme;

      // Only convert StatefulWidget
      if (superclassName != 'StatefulWidget') return;

      final className = node.name.lexeme;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Convert to ConsumerStatefulWidget',
        priority: 49,
      );

      changeBuilder.addDartFileEdit((builder) {
        // Change extends clause
        builder.addSimpleReplacement(
          superclass.sourceRange,
          'ConsumerStatefulWidget',
        );

        // Find createState and change return type
        for (final member in node.members) {
          if (member is MethodDeclaration &&
              member.name.lexeme == 'createState') {
            final returnType = member.returnType;
            if (returnType != null) {
              builder.addSimpleReplacement(
                returnType.sourceRange,
                'ConsumerState<$className>',
              );
            }
            break;
          }
        }
      });
    });

    // Also handle the State class
    context.registry.addClassDeclaration((node) {
      final extendsClause = node.extendsClause;
      if (extendsClause == null) return;

      final superclass = extendsClause.superclass;

      // Check if it's State<SomeWidget>
      if (!superclass.toSource().startsWith('State<')) return;
      if (!target.intersects(node.sourceRange)) return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Convert State to ConsumerState',
        priority: 48,
      );

      changeBuilder.addDartFileEdit((builder) {
        // Replace State<X> with ConsumerState<X>
        final source = superclass.toSource();
        final newSource = source.replaceFirst('State<', 'ConsumerState<');
        builder.addSimpleReplacement(
          superclass.sourceRange,
          newSource,
        );
      });
    });
  }
}

/// Assist to convert HookWidget to StatelessWidget with Watch.
///
/// For users migrating away from hooks to the simpler Watch pattern.
///
/// Before:
/// ```dart
/// class MyWidget extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final count = useSignal(0);
///     return Text('${count.value}');
///   }
/// }
/// ```
///
/// After:
/// ```dart
/// final _count = signal(0);
///
/// class MyWidget extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return Watch(
///       builder: (context, _) => Text('${_count.value}'),
///     );
///   }
/// }
/// ```
class ConvertHookWidgetToStateless extends DartAssist {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    SourceRange target,
  ) {
    context.registry.addClassDeclaration((node) {
      if (!target.intersects(node.sourceRange)) return;

      final extendsClause = node.extendsClause;
      if (extendsClause == null) return;

      final superclass = extendsClause.superclass;
      final superclassName = superclass.name2.lexeme;

      // Only convert HookWidget
      if (superclassName != 'HookWidget') return;

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Convert HookWidget to StatelessWidget with Watch',
        priority: 45,
      );

      changeBuilder.addDartFileEdit((builder) {
        // Change extends clause
        builder.addSimpleReplacement(
          superclass.sourceRange,
          'StatelessWidget',
        );

        // Add TODO comment about extracting hooks
        builder.addSimpleInsertion(
          node.offset,
          '// TODO: Extract useSignal calls to top-level signals\n',
        );
      });
    });
  }
}

/// Assist to add SignalStateMixin to StatefulWidget.
///
/// For users who want to use signals with automatic cleanup in StatefulWidget.
///
/// Before:
/// ```dart
/// class _MyWidgetState extends State<MyWidget> {
///   @override
///   Widget build(BuildContext context) {
///     return Text('Hello');
///   }
/// }
/// ```
///
/// After:
/// ```dart
/// class _MyWidgetState extends State<MyWidget> with SignalStateMixin {
///   @override
///   Widget build(BuildContext context) {
///     return Text('Hello');
///   }
/// }
/// ```
class AddSignalStateMixin extends DartAssist {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    SourceRange target,
  ) {
    context.registry.addClassDeclaration((node) {
      if (!target.intersects(node.sourceRange)) return;

      final extendsClause = node.extendsClause;
      if (extendsClause == null) return;

      // Check if it's a State class
      final superclass = extendsClause.superclass;
      if (!superclass.toSource().contains('State<')) return;

      // Check if already has SignalStateMixin
      final withClause = node.withClause;
      if (withClause != null) {
        for (final mixin in withClause.mixinTypes) {
          if (mixin.toSource().contains('SignalStateMixin')) {
            return; // Already has mixin
          }
        }
      }

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Add SignalStateMixin',
        priority: 40,
      );

      changeBuilder.addDartFileEdit((builder) {
        if (withClause != null) {
          // Add to existing with clause
          final lastMixin = withClause.mixinTypes.last;
          builder.addSimpleInsertion(
            lastMixin.end,
            ', SignalStateMixin',
          );
        } else {
          // Add new with clause after extends
          builder.addSimpleInsertion(
            superclass.end,
            ' with SignalStateMixin',
          );
        }
      });
    });
  }
}
