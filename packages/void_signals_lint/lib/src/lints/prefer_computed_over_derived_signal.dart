import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that suggests using computed() instead of manually derived signals.
///
/// When you have a signal that's updated based on other signals using an effect,
/// it's better to use computed() which is more declarative and efficient.
///
/// **NOT RECOMMENDED:**
/// ```dart
/// final firstName = signal('John');
/// final lastName = signal('Doe');
/// final fullName = signal('');
///
/// effect(() {
///   fullName.value = '${firstName.value} ${lastName.value}';  // ❌ Manual derivation
/// });
/// ```
///
/// **RECOMMENDED:**
/// ```dart
/// final firstName = signal('John');
/// final lastName = signal('Doe');
/// final fullName = computed((_) => '${firstName.value} ${lastName.value}');  // ✅ Automatic
/// ```
class PreferComputedOverDerivedSignal extends DartLintRule {
  const PreferComputedOverDerivedSignal() : super(code: _code);

  static const _code = LintCode(
    name: 'prefer_computed_over_derived_signal',
    problemMessage: 'Signal is being updated based on other signals. '
        'Consider using computed() instead.',
    correctionMessage: 'Use computed() for derived values: '
        'final derived = computed((_) => source1.value + source2.value);',
    errorSeverity: ErrorSeverity.INFO,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      // Check if this is an effect() call
      if (node.methodName.name != 'effect') return;

      // Get the effect body
      final effectArg = node.argumentList.arguments.firstOrNull;
      if (effectArg == null) return;

      // Find signal updates inside the effect
      final signalUpdates = <AssignmentExpression>[];
      final signalReads = <String>[];

      effectArg.accept(_SignalAccessVisitor(
        onSignalWrite: signalUpdates.add,
        onSignalRead: signalReads.add,
      ));

      // Check if we have exactly one signal update that reads from other signals
      if (signalUpdates.length == 1 && signalReads.isNotEmpty) {
        final update = signalUpdates.first;

        // Check if the write is to a different signal than the reads
        final writeTarget = _getSignalName(update.leftHandSide);
        if (writeTarget != null && !signalReads.contains(writeTarget)) {
          reporter.atNode(node, code);
        }
      }
    });
  }

  String? _getSignalName(Expression expr) {
    if (expr is PrefixedIdentifier) {
      return expr.prefix.name;
    }
    if (expr is PropertyAccess) {
      final target = expr.target;
      if (target is SimpleIdentifier) {
        return target.name;
      }
    }
    return null;
  }
}

/// Visitor to find signal read and write operations.
class _SignalAccessVisitor extends RecursiveAstVisitor<void> {
  _SignalAccessVisitor({
    required this.onSignalWrite,
    required this.onSignalRead,
  });

  final void Function(AssignmentExpression) onSignalWrite;
  final void Function(String) onSignalRead;

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final left = node.leftHandSide;

    // Check for signal.value = x
    if (left is PrefixedIdentifier && left.identifier.name == 'value') {
      onSignalWrite(node);
    } else if (left is PropertyAccess && left.propertyName.name == 'value') {
      onSignalWrite(node);
    }

    // Continue visiting right side for reads
    node.rightHandSide.accept(this);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    // Check for signal.value read
    if (node.identifier.name == 'value') {
      onSignalRead(node.prefix.name);
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    // Check for signal.value read
    if (node.propertyName.name == 'value') {
      final target = node.target;
      if (target is SimpleIdentifier) {
        onSignalRead(target.name);
      }
    }
    super.visitPropertyAccess(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // Check for signal() call (which also reads the value)
    final target = node.target;
    if (target == null && node.argumentList.arguments.isEmpty) {
      // Could be a signal() call
      onSignalRead(node.methodName.name);
    }
    super.visitMethodInvocation(node);
  }
}
