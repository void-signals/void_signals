import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Lint rule that suggests using Watch widget over effect() for UI updates.
///
/// Effects are designed for side effects like logging or API calls.
/// For UI updates, Watch is more appropriate as it:
/// - Handles lifecycle automatically
/// - Properly batches updates
/// - Is optimized for rebuilding widgets
///
/// **BAD:**
/// ```dart
/// class MyWidget extends StatefulWidget {
///   @override
///   State<MyWidget> createState() => _MyWidgetState();
/// }
///
/// class _MyWidgetState extends State<MyWidget> {
///   Effect? _eff;
///
///   @override
///   void initState() {
///     super.initState();
///     _eff = effect(() {
///       setState(() {});  // ❌ Using effect to trigger rebuilds
///     });
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Text('${count.value}');
///   }
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// class MyWidget extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return Watch(
///       builder: (context, _) => Text('${count.value}'),  // ✅ Watch handles updates
///     );
///   }
/// }
/// ```
class PreferWatchOverEffectForUI extends DartLintRule {
  const PreferWatchOverEffectForUI() : super(code: _code);

  static const _code = LintCode(
    name: 'prefer_watch_over_effect_for_ui',
    problemMessage: 'Avoid using setState() inside effect(). '
        'Use Watch widget for reactive UI updates instead.',
    correctionMessage:
        'Replace this pattern with Watch widget which handles reactivity automatically.',
    errorSeverity: ErrorSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      if (node.methodName.name != 'effect') return;

      // Check if this is a void_signals effect (would need type resolution)
      // For now, check the argument for setState calls

      final args = node.argumentList.arguments;
      if (args.isEmpty) return;

      final firstArg = args.first;
      if (firstArg is! FunctionExpression) return;

      // Check if the effect body contains setState
      bool hasSetState = false;
      firstArg.body.accept(_SetStateVisitor((found) {
        hasSetState = found;
      }));

      if (hasSetState) {
        reporter.atNode(node, code);
      }
    });
  }
}

class _SetStateVisitor extends RecursiveAstVisitor<void> {
  _SetStateVisitor(this.onFound);
  final void Function(bool) onFound;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'setState') {
      onFound(true);
    }
    super.visitMethodInvocation(node);
  }
}
