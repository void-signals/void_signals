import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import 'constants.dart';

/// Visitor that finds signal creation invocations.
class SignalCreationVisitor extends RecursiveAstVisitor<void> {
  SignalCreationVisitor({required this.onSignalCreation});

  final void Function(MethodInvocation) onSignalCreation;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;
    if (signalCreators.contains(methodName)) {
      onSignalCreation(node);
    }
    super.visitMethodInvocation(node);
  }
}

/// Visitor that finds hook invocations.
class HookInvocationVisitor extends RecursiveAstVisitor<void> {
  HookInvocationVisitor({
    this.onHookCall,
    this.onSignalHookCall,
    this.onEffectHookCall,
    this.onCollectionHookCall,
    this.onScopeHookCall,
    this.onUtilityHookCall,
  });

  final void Function(MethodInvocation, String hookName)? onHookCall;
  final void Function(MethodInvocation, String hookName)? onSignalHookCall;
  final void Function(MethodInvocation, String hookName)? onEffectHookCall;
  final void Function(MethodInvocation, String hookName)? onCollectionHookCall;
  final void Function(MethodInvocation, String hookName)? onScopeHookCall;
  final void Function(MethodInvocation, String hookName)? onUtilityHookCall;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;

    if (allHooks.contains(methodName)) {
      onHookCall?.call(node, methodName);

      if (hookSignalCreators.contains(methodName)) {
        onSignalHookCall?.call(node, methodName);
      } else if (hookEffectCreators.contains(methodName)) {
        onEffectHookCall?.call(node, methodName);
      } else if (hookCollectionCreators.contains(methodName)) {
        onCollectionHookCall?.call(node, methodName);
      } else if (hookScopeCreators.contains(methodName)) {
        onScopeHookCall?.call(node, methodName);
      } else if (hookUtilityCreators.contains(methodName)) {
        onUtilityHookCall?.call(node, methodName);
      }
    }

    super.visitMethodInvocation(node);
  }
}

/// Visitor that checks for signal value access.
class SignalAccessVisitor extends RecursiveAstVisitor<void> {
  SignalAccessVisitor({required this.onAccess});

  final void Function(AstNode node, String accessType) onAccess;

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    final identifier = node.identifier.name;
    if (signalAccessors.contains(identifier)) {
      onAccess(node, identifier);
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    final propertyName = node.propertyName.name;
    if (signalAccessors.contains(propertyName)) {
      onAccess(node, propertyName);
    }
    super.visitPropertyAccess(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'peek') {
      onAccess(node, 'peek');
    }
    super.visitMethodInvocation(node);
  }
}

/// Visitor that finds conditional statements.
class ConditionalVisitor extends RecursiveAstVisitor<void> {
  ConditionalVisitor({required this.onConditional});

  final void Function(AstNode node, String type) onConditional;

  @override
  void visitIfStatement(IfStatement node) {
    onConditional(node, 'if');
    super.visitIfStatement(node);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    onConditional(node, 'switch');
    super.visitSwitchStatement(node);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    onConditional(node, 'ternary');
    super.visitConditionalExpression(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    onConditional(node, 'for');
    super.visitForStatement(node);
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    onConditional(node, 'while');
    super.visitWhileStatement(node);
  }

  @override
  void visitDoStatement(DoStatement node) {
    onConditional(node, 'do-while');
    super.visitDoStatement(node);
  }

  @override
  void visitForElement(ForElement node) {
    onConditional(node, 'for-element');
    super.visitForElement(node);
  }

  @override
  void visitIfElement(IfElement node) {
    onConditional(node, 'if-element');
    super.visitIfElement(node);
  }
}

/// Visitor that finds async operations.
class AsyncOperationVisitor extends RecursiveAstVisitor<void> {
  AsyncOperationVisitor({required this.onAsync});

  final void Function(AstNode node, String type) onAsync;

  @override
  void visitAwaitExpression(AwaitExpression node) {
    onAsync(node, 'await');
    super.visitAwaitExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;
    if (methodName == 'then' || methodName == 'whenComplete') {
      onAsync(node, methodName);
    }
    super.visitMethodInvocation(node);
  }
}

/// Visitor that collects all identifiers used.
class IdentifierCollector extends RecursiveAstVisitor<void> {
  final Set<String> identifiers = {};

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    identifiers.add(node.name);
    super.visitSimpleIdentifier(node);
  }
}

/// Visitor that finds variable declarations.
class VariableDeclarationVisitor extends RecursiveAstVisitor<void> {
  VariableDeclarationVisitor({required this.onDeclaration});

  final void Function(VariableDeclaration node, String name) onDeclaration;

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    onDeclaration(node, node.name.lexeme);
    super.visitVariableDeclaration(node);
  }
}
