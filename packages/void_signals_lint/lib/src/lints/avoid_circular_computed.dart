import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that detects circular dependencies between computed signals.
///
/// Circular dependencies cause infinite loops or stack overflows.
///
/// **BAD:**
/// ```dart
/// final a = computed((_) => b.value + 1);
/// final b = computed((_) => a.value + 1);  // ❌ Circular!
/// ```
class AvoidCircularComputed extends DartLintRule {
  const AvoidCircularComputed() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_circular_computed',
    problemMessage:
        'This computed may have a circular dependency, which will cause '
        'infinite loops or stack overflows.',
    correctionMessage:
        'Review the computed dependencies and ensure there are no cycles.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    // Collect all computed definitions in the compilation unit
    final computedDefs = <String, Set<String>>{};

    context.registry.addCompilationUnit((unit) {
      // First pass: collect computed definitions and their dependencies
      unit.accept(_ComputedCollector(computedDefs));

      // Second pass: check for cycles
      for (final name in computedDefs.keys) {
        if (_hasCycle(name, computedDefs, <String>{})) {
          // Find and report the computed node
          unit.accept(_ComputedReporter(name, reporter, code));
        }
      }
    });
  }

  bool _hasCycle(
    String name,
    Map<String, Set<String>> deps,
    Set<String> visited,
  ) {
    if (visited.contains(name)) return true;
    if (!deps.containsKey(name)) return false;

    visited.add(name);
    for (final dep in deps[name]!) {
      if (_hasCycle(dep, deps, visited)) {
        return true;
      }
    }
    visited.remove(name);
    return false;
  }
}

class _ComputedCollector extends RecursiveAstVisitor<void> {
  _ComputedCollector(this.computedDefs);

  final Map<String, Set<String>> computedDefs;

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    final initializer = node.initializer;
    if (initializer is! MethodInvocation) {
      super.visitVariableDeclaration(node);
      return;
    }

    if (initializer.methodName.name != 'computed' &&
        initializer.methodName.name != 'computedFrom') {
      super.visitVariableDeclaration(node);
      return;
    }

    final name = node.name.lexeme;
    final deps = <String>{};

    // Collect dependencies from the computed body
    final arg = initializer.argumentList.arguments.firstOrNull;
    if (arg != null) {
      arg.accept(_DependencyCollector(deps));
    }

    computedDefs[name] = deps;
    super.visitVariableDeclaration(node);
  }
}

class _DependencyCollector extends RecursiveAstVisitor<void> {
  _DependencyCollector(this.deps);

  final Set<String> deps;

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.identifier.name == 'value') {
      deps.add(node.prefix.name);
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    // Could be a computed being accessed
    deps.add(node.name);
    super.visitSimpleIdentifier(node);
  }
}

class _ComputedReporter extends RecursiveAstVisitor<void> {
  _ComputedReporter(this.targetName, this.reporter, this.code);

  final String targetName;
  final ErrorReporter reporter;
  final LintCode code;

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (node.name.lexeme == targetName) {
      reporter.atNode(node, code);
    }
    super.visitVariableDeclaration(node);
  }
}
