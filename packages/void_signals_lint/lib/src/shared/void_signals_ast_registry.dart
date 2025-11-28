import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import 'void_signals_types.dart';

/// AST Registry for void_signals specific patterns.
///
/// Similar to Riverpod's RiverpodAstRegistry, this class provides
/// a centralized way to register callbacks for void_signals-specific
/// AST patterns.
class VoidSignalsAstRegistry {
  final List<void Function(SignalCreation)> _signalCreationListeners = [];
  final List<void Function(ComputedCreation)> _computedCreationListeners = [];
  final List<void Function(EffectCreation)> _effectCreationListeners = [];
  final List<void Function(SignalAccess)> _signalAccessListeners = [];
  final List<void Function(WatchWidgetDeclaration)> _watchWidgetListeners = [];
  final List<void Function(RefInvocation)> _refInvocationListeners = [];
  final List<void Function(BuildMethodDeclaration)> _buildMethodListeners = [];

  /// Register a callback for signal creations (signal(), Signal()).
  void addSignalCreation(void Function(SignalCreation) listener) {
    _signalCreationListeners.add(listener);
  }

  /// Register a callback for computed creations.
  void addComputedCreation(void Function(ComputedCreation) listener) {
    _computedCreationListeners.add(listener);
  }

  /// Register a callback for effect creations.
  void addEffectCreation(void Function(EffectCreation) listener) {
    _effectCreationListeners.add(listener);
  }

  /// Register a callback for signal accesses (.value, .peek(), call()).
  void addSignalAccess(void Function(SignalAccess) listener) {
    _signalAccessListeners.add(listener);
  }

  /// Register a callback for Watch widget declarations.
  void addWatchWidgetDeclaration(
      void Function(WatchWidgetDeclaration) listener) {
    _watchWidgetListeners.add(listener);
  }

  /// Register a callback for ref.watch/ref.read/ref.listen invocations.
  void addRefInvocation(void Function(RefInvocation) listener) {
    _refInvocationListeners.add(listener);
  }

  /// Register a callback for Flutter build methods.
  void addBuildMethodDeclaration(
      void Function(BuildMethodDeclaration) listener) {
    _buildMethodListeners.add(listener);
  }

  void _notifySignalCreation(SignalCreation creation) {
    for (final listener in _signalCreationListeners) {
      listener(creation);
    }
  }

  void _notifyComputedCreation(ComputedCreation creation) {
    for (final listener in _computedCreationListeners) {
      listener(creation);
    }
  }

  void _notifyEffectCreation(EffectCreation creation) {
    for (final listener in _effectCreationListeners) {
      listener(creation);
    }
  }

  void _notifySignalAccess(SignalAccess access) {
    for (final listener in _signalAccessListeners) {
      listener(access);
    }
  }

  void _notifyWatchWidgetDeclaration(WatchWidgetDeclaration decl) {
    for (final listener in _watchWidgetListeners) {
      listener(decl);
    }
  }

  void _notifyRefInvocation(RefInvocation invocation) {
    for (final listener in _refInvocationListeners) {
      listener(invocation);
    }
  }

  void _notifyBuildMethodDeclaration(BuildMethodDeclaration decl) {
    for (final listener in _buildMethodListeners) {
      listener(decl);
    }
  }

  /// Run the registry on a compilation unit.
  void run(CompilationUnit unit) {
    unit.accept(_VoidSignalsAstVisitor(this));
  }
}

/// Represents a signal creation (signal() call or Signal() constructor).
class SignalCreation {
  SignalCreation({
    required this.node,
    required this.valueType,
    this.initialValue,
    this.variableName,
    this.isInsideBuildMethod = false,
    this.isInsideCallback = false,
    this.enclosingClass,
    this.enclosingMethod,
  });

  /// The AST node of the creation.
  final AstNode node;

  /// The type of the signal value.
  final DartType? valueType;

  /// The initial value expression, if available.
  final Expression? initialValue;

  /// The variable name if assigned to a variable.
  final String? variableName;

  /// Whether this creation is inside a Flutter build method.
  final bool isInsideBuildMethod;

  /// Whether this creation is inside a callback.
  final bool isInsideCallback;

  /// The enclosing class, if any.
  final ClassDeclaration? enclosingClass;

  /// The enclosing method, if any.
  final MethodDeclaration? enclosingMethod;
}

/// Represents a computed creation (computed() call).
class ComputedCreation {
  ComputedCreation({
    required this.node,
    required this.getter,
    this.valueType,
    this.variableName,
    this.isInsideBuildMethod = false,
    this.enclosingClass,
    this.enclosingMethod,
    this.dependencies = const [],
  });

  final AstNode node;
  final Expression getter;
  final DartType? valueType;
  final String? variableName;
  final bool isInsideBuildMethod;
  final ClassDeclaration? enclosingClass;
  final MethodDeclaration? enclosingMethod;

  /// Identified signal/computed dependencies accessed in the getter.
  final List<String> dependencies;
}

/// Represents an effect creation (effect() call).
class EffectCreation {
  EffectCreation({
    required this.node,
    required this.effectFn,
    this.variableName,
    this.isInsideBuildMethod = false,
    this.isInsideInitState = false,
    this.enclosingClass,
    this.enclosingMethod,
    this.dependencies = const [],
  });

  final AstNode node;
  final Expression effectFn;
  final String? variableName;
  final bool isInsideBuildMethod;
  final bool isInsideInitState;
  final ClassDeclaration? enclosingClass;
  final MethodDeclaration? enclosingMethod;

  /// Identified signal/computed dependencies accessed in the effect.
  final List<String> dependencies;
}

/// Represents a signal access (.value, .peek(), signal()).
enum SignalAccessKind {
  /// .value getter
  value,

  /// .peek() method
  peek,

  /// signal() call (legacy style)
  call,
}

class SignalAccess {
  SignalAccess({
    required this.node,
    required this.kind,
    required this.signalExpression,
    this.signalType,
    this.isInsideReactiveContext = false,
    this.isInsideAsyncContext = false,
    this.enclosingMethod,
  });

  final AstNode node;
  final SignalAccessKind kind;
  final Expression signalExpression;
  final DartType? signalType;
  final bool isInsideReactiveContext;
  final bool isInsideAsyncContext;
  final MethodDeclaration? enclosingMethod;
}

/// Represents a Watch widget declaration.
class WatchWidgetDeclaration {
  WatchWidgetDeclaration({
    required this.node,
    required this.builder,
    this.child,
    this.accessedSignals = const [],
  });

  final InstanceCreationExpression node;
  final Expression builder;
  final Expression? child;

  /// Signal accesses found inside the builder.
  final List<SignalAccess> accessedSignals;
}

/// Represents a ref.watch/read/listen invocation.
enum RefInvocationKind {
  watch,
  read,
  listen,
}

class RefInvocation {
  RefInvocation({
    required this.node,
    required this.kind,
    required this.signalExpression,
    this.signalType,
    this.isInsideBuildMethod = false,
    this.enclosingClass,
  });

  final MethodInvocation node;
  final RefInvocationKind kind;
  final Expression signalExpression;
  final DartType? signalType;
  final bool isInsideBuildMethod;
  final ClassDeclaration? enclosingClass;
}

/// Represents a Flutter build method declaration.
class BuildMethodDeclaration {
  BuildMethodDeclaration({
    required this.node,
    required this.enclosingClass,
    this.signalCreations = const [],
    this.signalAccesses = const [],
    this.effectCreations = const [],
  });

  final MethodDeclaration node;
  final ClassDeclaration enclosingClass;

  /// Signals created inside this build method.
  final List<SignalCreation> signalCreations;

  /// Signal accesses inside this build method.
  final List<SignalAccess> signalAccesses;

  /// Effects created inside this build method.
  final List<EffectCreation> effectCreations;
}

/// Visitor that identifies void_signals patterns in the AST.
class _VoidSignalsAstVisitor extends RecursiveAstVisitor<void> {
  _VoidSignalsAstVisitor(this.registry);

  final VoidSignalsAstRegistry registry;

  bool _isInsideBuildMethod = false;
  bool _isInsideAsyncContext = false;
  bool _isInsideCallback = false;
  MethodDeclaration? _currentMethod;
  ClassDeclaration? _currentClass;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final prevClass = _currentClass;
    _currentClass = node;
    super.visitClassDeclaration(node);
    _currentClass = prevClass;
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final prevMethod = _currentMethod;
    final prevIsInBuild = _isInsideBuildMethod;
    final prevIsAsync = _isInsideAsyncContext;

    _currentMethod = node;
    _isInsideAsyncContext = node.body.isAsynchronous;

    // Check if this is a build method
    if (_isBuildMethod(node)) {
      _isInsideBuildMethod = true;

      // Collect information about this build method
      final signalCreations = <SignalCreation>[];
      final signalAccesses = <SignalAccess>[];
      final effectCreations = <EffectCreation>[];

      // This will be populated by child visits
      registry._notifyBuildMethodDeclaration(BuildMethodDeclaration(
        node: node,
        enclosingClass: _currentClass!,
        signalCreations: signalCreations,
        signalAccesses: signalAccesses,
        effectCreations: effectCreations,
      ));
    }

    super.visitMethodDeclaration(node);

    _currentMethod = prevMethod;
    _isInsideBuildMethod = prevIsInBuild;
    _isInsideAsyncContext = prevIsAsync;
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    final prevIsCallback = _isInsideCallback;
    final prevIsAsync = _isInsideAsyncContext;

    // Check if this is a callback (passed as argument)
    final parent = node.parent;
    if (parent is ArgumentList || parent is NamedExpression) {
      _isInsideCallback = true;
    }

    if (node.body.isAsynchronous) {
      _isInsideAsyncContext = true;
    }

    super.visitFunctionExpression(node);

    _isInsideCallback = prevIsCallback;
    _isInsideAsyncContext = prevIsAsync;
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    final prevIsAsync = _isInsideAsyncContext;
    _isInsideAsyncContext = true;
    super.visitAwaitExpression(node);
    _isInsideAsyncContext = prevIsAsync;
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;

    // Check for signal creation: signal()
    if (methodName == 'signal') {
      _handleSignalCreation(node);
    }

    // Check for computed creation: computed(), computedFrom()
    if (methodName == 'computed' || methodName == 'computedFrom') {
      _handleComputedCreation(node);
    }

    // Check for effect creation: effect()
    if (methodName == 'effect') {
      _handleEffectCreation(node);
    }

    // Check for signal access: .value, .peek()
    final target = node.target;
    if (target != null) {
      final targetType = target.staticType;
      if (targetType != null &&
          (targetType.isSignal || targetType.isComputed)) {
        if (methodName == 'peek') {
          registry._notifySignalAccess(SignalAccess(
            node: node,
            kind: SignalAccessKind.peek,
            signalExpression: target,
            signalType: targetType,
            isInsideReactiveContext: _isInsideBuildMethod || _isInsideCallback,
            isInsideAsyncContext: _isInsideAsyncContext,
            enclosingMethod: _currentMethod,
          ));
        }
      }

      // Check for ref.watch/read/listen
      if (targetType != null && signalRefType.isExactlyType(targetType)) {
        _handleRefInvocation(node, methodName);
      }
    }

    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    // Check for signal.value access
    if (node.identifier.name == 'value') {
      final prefixType = node.prefix.staticType;
      if (prefixType != null &&
          (prefixType.isSignal || prefixType.isComputed)) {
        registry._notifySignalAccess(SignalAccess(
          node: node,
          kind: SignalAccessKind.value,
          signalExpression: node.prefix,
          signalType: prefixType,
          isInsideReactiveContext: _isInsideBuildMethod || _isInsideCallback,
          isInsideAsyncContext: _isInsideAsyncContext,
          enclosingMethod: _currentMethod,
        ));
      }
    }

    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    // Check for signal.value access via property
    if (node.propertyName.name == 'value') {
      final targetType = node.target?.staticType;
      if (targetType != null &&
          (targetType.isSignal || targetType.isComputed)) {
        registry._notifySignalAccess(SignalAccess(
          node: node,
          kind: SignalAccessKind.value,
          signalExpression: node.target!,
          signalType: targetType,
          isInsideReactiveContext: _isInsideBuildMethod || _isInsideCallback,
          isInsideAsyncContext: _isInsideAsyncContext,
          enclosingMethod: _currentMethod,
        ));
      }
    }

    super.visitPropertyAccess(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final type = node.staticType;

    // Check for Watch widget
    if (type != null && watchWidgetType.isExactlyType(type)) {
      _handleWatchWidget(node);
    }

    super.visitInstanceCreationExpression(node);
  }

  void _handleSignalCreation(MethodInvocation node) {
    final parent = node.parent;
    String? variableName;
    if (parent is VariableDeclaration) {
      variableName = parent.name.lexeme;
    }

    final args = node.argumentList.arguments;
    Expression? initialValue;
    if (args.isNotEmpty) {
      final firstArg = args.first;
      if (firstArg is! NamedExpression) {
        initialValue = firstArg;
      }
    }

    registry._notifySignalCreation(SignalCreation(
      node: node,
      valueType: node.staticType,
      initialValue: initialValue,
      variableName: variableName,
      isInsideBuildMethod: _isInsideBuildMethod,
      isInsideCallback: _isInsideCallback,
      enclosingClass: _currentClass,
      enclosingMethod: _currentMethod,
    ));
  }

  void _handleComputedCreation(MethodInvocation node) {
    final parent = node.parent;
    String? variableName;
    if (parent is VariableDeclaration) {
      variableName = parent.name.lexeme;
    }

    final args = node.argumentList.arguments;
    Expression? getter;
    if (args.isNotEmpty) {
      final firstArg = args.first;
      if (firstArg is! NamedExpression) {
        getter = firstArg;
      }
    }

    if (getter == null) return;

    // Collect dependencies from the getter
    final dependencies = <String>[];
    getter.accept(_DependencyCollector(dependencies));

    registry._notifyComputedCreation(ComputedCreation(
      node: node,
      getter: getter,
      valueType: node.staticType,
      variableName: variableName,
      isInsideBuildMethod: _isInsideBuildMethod,
      enclosingClass: _currentClass,
      enclosingMethod: _currentMethod,
      dependencies: dependencies,
    ));
  }

  void _handleEffectCreation(MethodInvocation node) {
    final parent = node.parent;
    String? variableName;
    if (parent is VariableDeclaration) {
      variableName = parent.name.lexeme;
    }

    final args = node.argumentList.arguments;
    Expression? effectFn;
    if (args.isNotEmpty) {
      final firstArg = args.first;
      if (firstArg is! NamedExpression) {
        effectFn = firstArg;
      }
    }

    if (effectFn == null) return;

    // Collect dependencies
    final dependencies = <String>[];
    effectFn.accept(_DependencyCollector(dependencies));

    // Check if inside initState
    final isInsideInitState = _currentMethod?.name.lexeme == 'initState';

    registry._notifyEffectCreation(EffectCreation(
      node: node,
      effectFn: effectFn,
      variableName: variableName,
      isInsideBuildMethod: _isInsideBuildMethod,
      isInsideInitState: isInsideInitState,
      enclosingClass: _currentClass,
      enclosingMethod: _currentMethod,
      dependencies: dependencies,
    ));
  }

  void _handleWatchWidget(InstanceCreationExpression node) {
    final args = node.argumentList.arguments;
    Expression? builder;
    Expression? child;

    for (final arg in args) {
      if (arg is NamedExpression) {
        if (arg.name.label.name == 'builder') {
          builder = arg.expression;
        } else if (arg.name.label.name == 'child') {
          child = arg.expression;
        }
      }
    }

    if (builder == null) return;

    // Collect signal accesses in the builder
    final accesses = <SignalAccess>[];
    builder.accept(_SignalAccessCollector(accesses));

    registry._notifyWatchWidgetDeclaration(WatchWidgetDeclaration(
      node: node,
      builder: builder,
      child: child,
      accessedSignals: accesses,
    ));
  }

  void _handleRefInvocation(MethodInvocation node, String methodName) {
    RefInvocationKind? kind;
    if (methodName == 'watch') {
      kind = RefInvocationKind.watch;
    } else if (methodName == 'read') {
      kind = RefInvocationKind.read;
    } else if (methodName == 'listen') {
      kind = RefInvocationKind.listen;
    }

    if (kind == null) return;

    final args = node.argumentList.arguments;
    if (args.isEmpty) return;

    final signalArg = args.first;

    registry._notifyRefInvocation(RefInvocation(
      node: node,
      kind: kind,
      signalExpression:
          signalArg is NamedExpression ? signalArg.expression : signalArg,
      signalType: signalArg.staticType,
      isInsideBuildMethod: _isInsideBuildMethod,
      enclosingClass: _currentClass,
    ));
  }

  bool _isBuildMethod(MethodDeclaration node) {
    if (node.name.lexeme != 'build') return false;

    final returnType = node.returnType?.toSource();
    if (returnType != 'Widget' && returnType != 'Widget?') return false;

    final params = node.parameters?.parameters;
    if (params == null || params.isEmpty) return false;

    final firstParam = params.first;
    if (firstParam is SimpleFormalParameter) {
      final type = firstParam.type?.toSource();
      if (type == 'BuildContext') return true;
    }

    return false;
  }
}

/// Collects signal/computed dependency names from an expression.
class _DependencyCollector extends RecursiveAstVisitor<void> {
  _DependencyCollector(this.dependencies);

  final List<String> dependencies;

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.identifier.name == 'value') {
      final prefixType = node.prefix.staticType;
      if (prefixType != null &&
          (prefixType.isSignal || prefixType.isComputed)) {
        dependencies.add(node.prefix.name);
      }
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.propertyName.name == 'value') {
      final target = node.target;
      if (target is SimpleIdentifier) {
        final targetType = target.staticType;
        if (targetType != null &&
            (targetType.isSignal || targetType.isComputed)) {
          dependencies.add(target.name);
        }
      }
    }
    super.visitPropertyAccess(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // Check for peek() calls
    if (node.methodName.name == 'peek') {
      final target = node.target;
      if (target is SimpleIdentifier) {
        final targetType = target.staticType;
        if (targetType != null &&
            (targetType.isSignal || targetType.isComputed)) {
          dependencies.add(target.name);
        }
      }
    }
    super.visitMethodInvocation(node);
  }
}

/// Collects SignalAccess instances from an expression.
class _SignalAccessCollector extends RecursiveAstVisitor<void> {
  _SignalAccessCollector(this.accesses);

  final List<SignalAccess> accesses;

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.identifier.name == 'value') {
      final prefixType = node.prefix.staticType;
      if (prefixType != null &&
          (prefixType.isSignal || prefixType.isComputed)) {
        accesses.add(SignalAccess(
          node: node,
          kind: SignalAccessKind.value,
          signalExpression: node.prefix,
          signalType: prefixType,
          isInsideReactiveContext: true,
        ));
      }
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.propertyName.name == 'value') {
      final targetType = node.target?.staticType;
      if (targetType != null &&
          (targetType.isSignal || targetType.isComputed)) {
        accesses.add(SignalAccess(
          node: node,
          kind: SignalAccessKind.value,
          signalExpression: node.target!,
          signalType: targetType,
          isInsideReactiveContext: true,
        ));
      }
    }
    super.visitPropertyAccess(node);
  }
}
