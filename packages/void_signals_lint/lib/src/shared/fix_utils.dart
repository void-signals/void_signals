import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Utility functions for creating quick fixes.

/// Creates a quick fix that wraps code with a widget.
void createWrapWithWidgetFix({
  required ChangeReporter reporter,
  required AstNode node,
  required String widgetName,
  required String message,
  String? builderParam,
  String? additionalParams,
  int priority = 80,
}) {
  final changeBuilder = reporter.createChangeBuilder(
    message: message,
    priority: priority,
  );

  changeBuilder.addDartFileEdit((builder) {
    final prefix = builderParam != null
        ? '$widgetName(\n  $builderParam: (context) => '
        : '$widgetName(\n  ';
    final suffix =
        additionalParams != null ? ',\n  $additionalParams\n)' : '\n)';

    builder.addSimpleInsertion(node.offset, prefix);
    builder.addSimpleInsertion(node.end, ',$suffix');
  });
}

/// Creates a quick fix that wraps code with a function call.
void createWrapWithFunctionFix({
  required ChangeReporter reporter,
  required AstNode node,
  required String functionName,
  required String message,
  int priority = 80,
}) {
  final changeBuilder = reporter.createChangeBuilder(
    message: message,
    priority: priority,
  );

  changeBuilder.addDartFileEdit((builder) {
    builder.addSimpleInsertion(node.offset, '$functionName(() ');
    builder.addSimpleInsertion(node.end, ')');
  });
}

/// Creates a quick fix that replaces a method name.
void createReplaceMethodNameFix({
  required ChangeReporter reporter,
  required MethodInvocation node,
  required String newMethodName,
  required String message,
  int priority = 80,
}) {
  final changeBuilder = reporter.createChangeBuilder(
    message: message,
    priority: priority,
  );

  changeBuilder.addDartFileEdit((builder) {
    builder.addSimpleReplacement(
      node.methodName.sourceRange,
      newMethodName,
    );
  });
}

/// Creates a quick fix that removes a node.
void createRemoveNodeFix({
  required ChangeReporter reporter,
  required AstNode node,
  required String message,
  int priority = 80,
}) {
  final changeBuilder = reporter.createChangeBuilder(
    message: message,
    priority: priority,
  );

  changeBuilder.addDartFileEdit((builder) {
    builder.addDeletion(node.sourceRange);
  });
}

/// Creates a quick fix that adds an import.
void createAddImportFix({
  required ChangeReporter reporter,
  required CompilationUnit unit,
  required String importUri,
  required String message,
  int priority = 80,
}) {
  final changeBuilder = reporter.createChangeBuilder(
    message: message,
    priority: priority,
  );

  changeBuilder.addDartFileEdit((builder) {
    // Find the last import or library directive
    int insertOffset = 0;
    for (final directive in unit.directives) {
      if (directive is ImportDirective || directive is LibraryDirective) {
        insertOffset = directive.end;
      }
    }

    if (insertOffset == 0) {
      // No imports, add at the beginning
      builder.addSimpleInsertion(0, "import '$importUri';\n\n");
    } else {
      builder.addSimpleInsertion(insertOffset, "\nimport '$importUri';");
    }
  });
}

/// Creates a quick fix that adds a parameter to a function call.
void createAddParameterFix({
  required ChangeReporter reporter,
  required ArgumentList argumentList,
  required String parameterName,
  required String parameterValue,
  required String message,
  int priority = 80,
}) {
  final changeBuilder = reporter.createChangeBuilder(
    message: message,
    priority: priority,
  );

  changeBuilder.addDartFileEdit((builder) {
    final hasArguments = argumentList.arguments.isNotEmpty;
    final insertOffset = hasArguments
        ? argumentList.arguments.last.end
        : argumentList.leftParenthesis.end;

    final prefix = hasArguments ? ', ' : '';
    builder.addSimpleInsertion(
      insertOffset,
      '$prefix$parameterName: $parameterValue',
    );
  });
}

/// Creates a quick fix that moves code to class level.
void createMoveToClassLevelFix({
  required ChangeReporter reporter,
  required VariableDeclarationStatement statement,
  required ClassDeclaration classDecl,
  required String message,
  bool makeLateFinal = false,
  int priority = 80,
}) {
  final changeBuilder = reporter.createChangeBuilder(
    message: message,
    priority: priority,
  );

  changeBuilder.addDartFileEdit((builder) {
    // Get the variable info
    final varList = statement.variables;
    final variable = varList.variables.first;
    final varName = variable.name.lexeme;
    final typeAnnotation = varList.type?.toSource();
    final initializer = variable.initializer?.toSource() ?? '';

    // Remove from current location
    builder.addDeletion(statement.sourceRange);

    // Find insertion point in class
    final classBody = classDecl.members.isNotEmpty
        ? classDecl.members.first.offset
        : classDecl.leftBracket.offset + 1;

    // Build the field declaration
    String fieldDecl;
    if (makeLateFinal) {
      fieldDecl =
          '\n  late final ${typeAnnotation ?? ''} $varName = $initializer;\n';
    } else if (typeAnnotation != null) {
      fieldDecl = '\n  $typeAnnotation $varName = $initializer;\n';
    } else {
      fieldDecl = '\n  final $varName = $initializer;\n';
    }

    builder.addSimpleInsertion(classBody, fieldDecl);
  });
}

/// Creates a quick fix that converts to a different hook.
void createConvertHookFix({
  required ChangeReporter reporter,
  required MethodInvocation node,
  required String newHookName,
  required String message,
  String? additionalParams,
  int priority = 80,
}) {
  final changeBuilder = reporter.createChangeBuilder(
    message: message,
    priority: priority,
  );

  changeBuilder.addDartFileEdit((builder) {
    builder.addSimpleReplacement(
      node.methodName.sourceRange,
      newHookName,
    );

    if (additionalParams != null) {
      final args = node.argumentList;
      final insertOffset = args.arguments.isNotEmpty
          ? args.arguments.last.end
          : args.leftParenthesis.end;

      final prefix = args.arguments.isNotEmpty ? ', ' : '';
      builder.addSimpleInsertion(insertOffset, '$prefix$additionalParams');
    }
  });
}

/// Creates a quick fix that adds useWatch wrapper.
void createAddUseWatchFix({
  required ChangeReporter reporter,
  required AstNode signalAccess,
  required String signalName,
  required String message,
  int priority = 80,
}) {
  final changeBuilder = reporter.createChangeBuilder(
    message: message,
    priority: priority,
  );

  changeBuilder.addDartFileEdit((builder) {
    // Find the method body to add useWatch at the beginning
    MethodDeclaration? method;
    AstNode? current = signalAccess.parent;
    while (current != null) {
      if (current is MethodDeclaration) {
        method = current;
        break;
      }
      current = current.parent;
    }

    if (method != null) {
      final body = method.body;
      if (body is BlockFunctionBody) {
        final block = body.block;
        final insertOffset = block.leftBracket.end;
        builder.addSimpleInsertion(
          insertOffset,
          '\n    useWatch($signalName);',
        );
      }
    }
  });
}

/// Extension for SourceRange intersection check.
extension SourceRangeExtension on SourceRange {
  bool intersects(SourceRange other) {
    return offset < other.offset + other.length &&
        offset + length > other.offset;
  }
}
