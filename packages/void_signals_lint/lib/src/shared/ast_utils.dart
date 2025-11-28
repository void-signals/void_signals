import 'package:analyzer/dart/ast/ast.dart';

/// Utility functions for AST analysis.

/// Known HookWidget base classes from flutter_hooks and related packages.
const _hookWidgetBaseClasses = {
  // flutter_hooks
  'HookWidget',
  'HookStatefulWidget',
  'StatefulHookWidget',
  // hooks_riverpod
  'HookConsumerWidget',
  'StatefulHookConsumerWidget',
  // Common patterns - classes ending with HookWidget
};

/// Checks if a method declaration is a Flutter build method.
bool isBuildMethod(MethodDeclaration node) {
  if (node.name.lexeme != 'build') return false;

  // Check return type
  final returnType = node.returnType?.toSource();
  if (returnType != 'Widget' && returnType != 'Widget?') return false;

  // Check parameters
  final params = node.parameters?.parameters;
  if (params == null || params.isEmpty) return false;

  // First parameter should be BuildContext
  final firstParam = params.first;
  if (firstParam is SimpleFormalParameter) {
    final type = firstParam.type?.toSource();
    if (type == 'BuildContext') return true;
  }

  return false;
}

/// Checks if a class extends or is a HookWidget.
///
/// This uses multiple strategies:
/// 1. Direct match against known HookWidget classes
/// 2. Naming convention check (ends with 'HookWidget')
/// 3. Check for 'Hook' in the inheritance chain (best effort without type resolution)
bool isHookWidgetClass(ClassDeclaration classDecl) {
  final extendsClause = classDecl.extendsClause;
  if (extendsClause == null) return false;

  final superclassName = extendsClause.superclass.name2.lexeme;

  // Strategy 1: Direct match against known base classes
  if (_hookWidgetBaseClasses.contains(superclassName)) {
    return true;
  }

  // Strategy 2: Naming convention - class ends with HookWidget
  if (superclassName.endsWith('HookWidget')) {
    return true;
  }

  // Strategy 3: Naming convention - class contains 'Hook' and extends Widget
  if (superclassName.contains('Hook') &&
      (superclassName.contains('Widget') ||
          superclassName.contains('Consumer'))) {
    return true;
  }

  return false;
}

/// Checks if a function is a hook function (starts with 'use').
bool isHookFunction(FunctionDeclaration node) {
  return node.name.lexeme.startsWith('use');
}

/// Checks if a method is a hook method (starts with 'use').
bool isHookMethod(MethodDeclaration node) {
  return node.name.lexeme.startsWith('use');
}

/// Gets the enclosing class declaration.
ClassDeclaration? getEnclosingClass(AstNode node) {
  return node.thisOrAncestorOfType<ClassDeclaration>();
}

/// Gets the enclosing function declaration.
FunctionDeclaration? getEnclosingFunction(AstNode node) {
  return node.thisOrAncestorOfType<FunctionDeclaration>();
}

/// Gets the enclosing method declaration.
MethodDeclaration? getEnclosingMethod(AstNode node) {
  return node.thisOrAncestorOfType<MethodDeclaration>();
}

/// Gets the enclosing function body.
FunctionBody? getEnclosingFunctionBody(AstNode node) {
  return node.thisOrAncestorOfType<FunctionBody>();
}

/// Checks if the node is inside a conditional statement.
bool isInsideConditional(AstNode node) {
  AstNode? current = node.parent;
  while (current != null) {
    if (current is IfStatement ||
        current is SwitchStatement ||
        current is ConditionalExpression ||
        current is ForStatement ||
        current is WhileStatement ||
        current is DoStatement ||
        current is ForElement ||
        current is IfElement) {
      return true;
    }
    // Stop at method/function boundary
    if (current is MethodDeclaration || current is FunctionDeclaration) {
      return false;
    }
    current = current.parent;
  }
  return false;
}

/// Checks if the node is inside a loop.
bool isInsideLoop(AstNode node) {
  AstNode? current = node.parent;
  while (current != null) {
    if (current is ForStatement ||
        current is WhileStatement ||
        current is DoStatement ||
        current is ForElement) {
      return true;
    }
    // Stop at method/function boundary
    if (current is MethodDeclaration || current is FunctionDeclaration) {
      return false;
    }
    current = current.parent;
  }
  return false;
}

/// Gets the condition type if inside a conditional.
String? getConditionalType(AstNode node) {
  AstNode? current = node.parent;
  while (current != null) {
    if (current is IfStatement) return 'if';
    if (current is SwitchStatement) return 'switch';
    if (current is ConditionalExpression) return 'ternary';
    if (current is ForStatement) return 'for';
    if (current is WhileStatement) return 'while';
    if (current is DoStatement) return 'do-while';
    if (current is ForElement) return 'for-element';
    if (current is IfElement) return 'if-element';
    // Stop at method/function boundary
    if (current is MethodDeclaration || current is FunctionDeclaration) {
      return null;
    }
    current = current.parent;
  }
  return null;
}

/// Checks if node is inside a callback/closure.
bool isInsideCallback(AstNode node) {
  AstNode? current = node.parent;
  while (current != null) {
    if (current is FunctionExpression) {
      // Check if this is a callback (not the main build method body)
      final parent = current.parent;
      if (parent is ArgumentList || parent is NamedExpression) {
        return true;
      }
    }
    // Stop at method/function declaration boundary
    if (current is MethodDeclaration || current is FunctionDeclaration) {
      return false;
    }
    current = current.parent;
  }
  return false;
}

/// Gets the callback argument name if inside a callback.
String? getCallbackName(AstNode node) {
  AstNode? current = node.parent;
  while (current != null) {
    if (current is FunctionExpression) {
      final parent = current.parent;
      if (parent is NamedExpression) {
        return parent.name.label.name;
      }
    }
    if (current is MethodDeclaration || current is FunctionDeclaration) {
      return null;
    }
    current = current.parent;
  }
  return null;
}

/// Extracts the variable name from a method invocation if assigned to a variable.
String? getAssignedVariableName(MethodInvocation node) {
  final parent = node.parent;
  if (parent is VariableDeclaration) {
    return parent.name.lexeme;
  }
  if (parent is AssignmentExpression) {
    final leftHandSide = parent.leftHandSide;
    if (leftHandSide is SimpleIdentifier) {
      return leftHandSide.name;
    }
  }
  return null;
}

/// Checks if a method invocation result is used (not just called for side effects).
bool isResultUsed(MethodInvocation node) {
  final parent = node.parent;
  return parent is VariableDeclaration ||
      parent is AssignmentExpression ||
      parent is ReturnStatement ||
      parent is ArgumentList ||
      parent is NamedExpression ||
      parent is ConditionalExpression ||
      parent is BinaryExpression ||
      parent is PropertyAccess ||
      parent is IndexExpression;
}

/// Gets the type annotation source if available.
String? getTypeAnnotation(VariableDeclaration node) {
  final parent = node.parent;
  if (parent is VariableDeclarationList) {
    return parent.type?.toSource();
  }
  return null;
}

/// Checks if a node is in a try block.
bool isInsideTryBlock(AstNode node) {
  AstNode? current = node.parent;
  while (current != null) {
    if (current is TryStatement) {
      return true;
    }
    if (current is MethodDeclaration || current is FunctionDeclaration) {
      return false;
    }
    current = current.parent;
  }
  return false;
}
