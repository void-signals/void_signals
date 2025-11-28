import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../shared/void_signals_custom_lint.dart';

/// Lint rule that warns when effects are created inside build methods.
///
/// Creating effects in build methods causes:
/// - Multiple effects to be created on each rebuild
/// - Memory leaks from orphaned effects
/// - Unpredictable behavior from effects running multiple times
///
/// **BAD:**
/// ```dart
/// Widget build(BuildContext context) {
///   effect(() {
///     print('Count: ${count.value}');  // ❌ Created on every build
///   });
///   return Text('...');
/// }
/// ```
///
/// **GOOD:**
/// ```dart
/// // Option 1: Use initState
/// @override
/// void initState() {
///   super.initState();
///   _effectCleanup = effect(() {
///     print('Count: ${count.value}');  // ✅ Created once
///   });
/// }
///
/// @override
/// void dispose() {
///   _effectCleanup?.stop();
///   super.dispose();
/// }
///
/// // Option 2: Use useEffect hook (in HookWidget)
/// useEffect(() {
///   final eff = effect(() => print(count.value));
///   return eff.stop;  // ✅ Properly cleaned up
/// }, []);
/// ```
class AvoidEffectInBuild extends VoidSignalsLintRule {
  const AvoidEffectInBuild() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_effect_in_build',
    problemMessage:
        'Avoid creating effects inside build methods. Effects created here '
        'will be recreated on every rebuild, causing multiple subscriptions '
        'and potential memory leaks.',
    correctionMessage:
        'Move the effect to initState() and clean it up in dispose(), '
        'or use useEffect() hook if using HookWidget.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    voidSignalsRegistry(context).addEffectCreation((creation) {
      if (creation.isInsideBuildMethod) {
        reporter.atNode(creation.node, code);
      }
    });
  }

  @override
  List<DartFix> getFixes() => [_MoveEffectToInitStateFix()];
}

class _MoveEffectToInitStateFix extends VoidSignalsFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    AnalysisError analysisError,
    List<AnalysisError> others,
  ) {
    voidSignalsRegistry(context).addEffectCreation((creation) {
      if (!creation.isInsideBuildMethod) return;
      if (!analysisError.sourceRange.intersects(SourceRangeFrom.from(
          start: creation.node.offset, end: creation.node.end))) {
        return;
      }

      final classDecl = creation.enclosingClass;
      if (classDecl == null) return;

      // Get the effect code
      final effectCode = creation.node.toSource();
      final variableName = creation.variableName ?? '_effectCleanup';

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Move effect to initState with cleanup',
        priority: 80,
      );

      changeBuilder.addDartFileEdit((builder) {
        // Find the statement containing this effect and remove it
        AstNode? currentNode = creation.node;
        Statement? stmt;
        while (currentNode != null) {
          if (currentNode is Statement) {
            stmt = currentNode;
            break;
          }
          currentNode = currentNode.parent;
        }
        if (stmt != null) {
          builder.addDeletion(stmt.sourceRange);
        }

        // Find existing initState or add new one
        MethodDeclaration? initStateMethod;
        MethodDeclaration? disposeMethod;

        for (final member in classDecl.members) {
          if (member is MethodDeclaration) {
            if (member.name.lexeme == 'initState') {
              initStateMethod = member;
            } else if (member.name.lexeme == 'dispose') {
              disposeMethod = member;
            }
          }
        }

        // Find insertion point for class member (after first brace)
        final classBody = classDecl.members.firstOrNull;
        final fieldInsertOffset =
            classBody?.offset ?? classDecl.leftBracket.offset + 1;

        // Add field declaration
        builder.addSimpleInsertion(
          fieldInsertOffset,
          '\n  Effect? $variableName;\n',
        );

        if (initStateMethod != null) {
          // Add to existing initState
          final body = initStateMethod.body;
          if (body is BlockFunctionBody) {
            final insertOffset = body.block.rightBracket.offset;
            builder.addSimpleInsertion(
              insertOffset,
              '    $variableName = $effectCode;\n  ',
            );
          }
        } else {
          // Create new initState
          builder.addSimpleInsertion(
            fieldInsertOffset,
            '''
  @override
  void initState() {
    super.initState();
    $variableName = $effectCode;
  }

''',
          );
        }

        if (disposeMethod != null) {
          // Add cleanup to existing dispose
          final body = disposeMethod.body;
          if (body is BlockFunctionBody) {
            // Insert before super.dispose() or at start of block
            final statements = body.block.statements;
            int insertOffset = body.block.leftBracket.end;

            // Find super.dispose() call and insert before it
            for (final stmt in statements) {
              if (stmt is ExpressionStatement) {
                final expr = stmt.expression;
                if (expr is MethodInvocation) {
                  final target = expr.target;
                  if (target is SuperExpression &&
                      expr.methodName.name == 'dispose') {
                    insertOffset = stmt.offset;
                    break;
                  }
                }
              }
            }

            builder.addSimpleInsertion(
              insertOffset,
              '\n    $variableName?.stop();',
            );
          }
        } else {
          // Create new dispose
          builder.addSimpleInsertion(
            fieldInsertOffset,
            '''
  @override
  void dispose() {
    $variableName?.stop();
    super.dispose();
  }

''',
          );
        }
      });
    });
  }
}
