import 'flags.dart';
import 'nodes.dart';

/// Global state for the reactive system.
/// Using top-level variables for direct access (faster than class properties).
int _cycle = 0;
int _batchDepth = 0;
int _notifyIndex = 0;
int _queuedLength = 0;
ReactiveNode? _activeSub;

/// Queue for pending effects - uses fixed list for better performance
final List<EffectNode?> _queued =
    List<EffectNode?>.filled(1024, null, growable: true);

/// Gets the currently active subscriber.
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
ReactiveNode? getActiveSub() => _activeSub;

/// Sets the active subscriber and returns the previous one.
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
ReactiveNode? setActiveSub(ReactiveNode? sub) {
  final prevSub = _activeSub;
  _activeSub = sub;
  return prevSub;
}

/// Gets the current batch depth.
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
int getBatchDepth() => _batchDepth;

/// Starts a new batch operation.
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
void startBatch() {
  ++_batchDepth;
}

/// Ends a batch operation and flushes if this was the outermost batch.
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
void endBatch() {
  if (--_batchDepth == 0) {
    flush();
  }
}

/// Links a dependency to a subscriber.
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
@pragma('vm:align-loops')
void link(ReactiveNode dep, ReactiveNode sub, int version) {
  final prevDep = sub.depsTail;

  // Fast path: same dependency as last access
  if (prevDep != null && identical(prevDep.dep, dep)) {
    return;
  }

  // Check next dependency (common pattern in loops)
  final nextDep = prevDep != null ? prevDep.nextDep : sub.deps;
  if (nextDep != null && identical(nextDep.dep, dep)) {
    nextDep.version = version;
    sub.depsTail = nextDep;
    return;
  }

  // Check if already linked in current tracking
  final prevSub = dep.subsTail;
  if (prevSub != null &&
      prevSub.version == version &&
      identical(prevSub.sub, sub)) {
    return;
  }

  // Create new link
  final newLink = Link(
    dep: dep,
    sub: sub,
    version: version,
    prevDep: prevDep,
    nextDep: nextDep,
    prevSub: prevSub,
  );

  sub.depsTail = dep.subsTail = newLink;

  // Update pointers
  if (nextDep != null) {
    nextDep.prevDep = newLink;
  }
  if (prevDep != null) {
    prevDep.nextDep = newLink;
  } else {
    sub.deps = newLink;
  }

  if (prevSub != null) {
    prevSub.nextSub = newLink;
  } else {
    dep.subs = newLink;
  }
}

/// Unlinks a link from the graph.
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
@pragma('vm:align-loops')
Link? unlink(Link link, [ReactiveNode? sub]) {
  sub ??= link.sub;
  final dep = link.dep;
  final prevDep = link.prevDep;
  final nextDep = link.nextDep;
  final nextSub = link.nextSub;
  final prevSub = link.prevSub;

  if (nextDep != null) {
    nextDep.prevDep = prevDep;
  } else {
    sub.depsTail = prevDep;
  }
  if (prevDep != null) {
    prevDep.nextDep = nextDep;
  } else {
    sub.deps = nextDep;
  }

  if (nextSub != null) {
    nextSub.prevSub = prevSub;
  } else {
    dep.subsTail = prevSub;
  }
  if (prevSub != null) {
    prevSub.nextSub = nextSub;
  } else if ((dep.subs = nextSub) == null) {
    _unwatched(dep);
  }

  return nextDep;
}

/// Handles when a node becomes unwatched.
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
void _unwatched(ReactiveNode node) {
  if (!node.flags.isMutable) {
    // EffectScope or Effect - stop it
    _stopScope(node);
  } else if (node.depsTail != null) {
    // Computed - clear its dependencies
    node.depsTail = null;
    node.flags = ReactiveFlags.mutable | ReactiveFlags.dirty;
    _purgeDeps(node);
  }
}

/// Stops a scope or effect.
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
void _stopScope(ReactiveNode node) {
  node.depsTail = null;
  node.flags = ReactiveFlags.none;
  _purgeDeps(node);
  final sub = node.subs;
  if (sub != null) {
    unlink(sub);
  }
}

/// Purges stale dependencies from a subscriber.
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
@pragma('vm:align-loops')
void _purgeDeps(ReactiveNode sub) {
  final depsTail = sub.depsTail;
  Link? dep = depsTail != null ? depsTail.nextDep : sub.deps;
  while (dep != null) {
    dep = unlink(dep, sub);
  }
}

/// Propagates changes through the reactive graph.
@pragma('vm:align-loops')
void propagate(Link link) {
  Link? next = link.nextSub;
  Stack<Link?>? stack;

  top:
  do {
    final sub = link.sub;
    ReactiveFlags localFlags = sub.flags;

    // Check propagation conditions using pre-computed flag combinations
    final checkFlags = ReactiveFlags.recursedCheck |
        ReactiveFlags.recursed |
        ReactiveFlags.dirty |
        ReactiveFlags.pending;

    if (!localFlags.has(checkFlags)) {
      sub.flags = localFlags | ReactiveFlags.pending;
    } else if (!localFlags
        .has(ReactiveFlags.recursedCheck | ReactiveFlags.recursed)) {
      localFlags = ReactiveFlags.none;
    } else if (!localFlags.isRecursedCheck) {
      sub.flags =
          (localFlags & ~ReactiveFlags.recursed) | ReactiveFlags.pending;
    } else if (!localFlags.has(ReactiveFlags.dirty | ReactiveFlags.pending) &&
        _isValidLink(link, sub)) {
      sub.flags = localFlags | ReactiveFlags.recursed | ReactiveFlags.pending;
      localFlags = localFlags & ReactiveFlags.mutable;
    } else {
      localFlags = ReactiveFlags.none;
    }

    // Notify watching effects
    if (localFlags.isWatching) {
      _notify(sub as EffectNode);
    }

    // Propagate to subscribers if mutable
    if (localFlags.isMutable) {
      final subSubs = sub.subs;
      if (subSubs != null) {
        link = subSubs;
        final nextSub = link.nextSub;
        if (nextSub != null) {
          stack = Stack(value: next, prev: stack);
          next = nextSub;
        }
        continue;
      }
    }

    if (next != null) {
      link = next;
      next = link.nextSub;
      continue;
    }

    while (stack != null) {
      final stackValue = stack.value;
      stack = stack.prev;
      if (stackValue != null) {
        link = stackValue;
        next = link.nextSub;
        continue top;
      }
    }

    break;
  } while (true);
}

/// Notifies an effect that it needs to run.
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
void _notify(EffectNode effect) {
  int insertIndex = _queuedLength;
  final firstInsertedIndex = insertIndex;

  EffectNode? current = effect;
  do {
    current!.flags = current.flags & ~ReactiveFlags.watching;

    // Ensure queue capacity
    if (insertIndex >= _queued.length) {
      _queued.length = _queued.length * 2;
    }
    _queued[insertIndex++] = current;

    final subs = current.subs;
    if (subs == null) break;

    final sub = subs.sub;
    // Only continue if the subscriber is an EffectNode and is watching
    if (sub is! EffectNode || !sub.flags.isWatching) {
      break;
    }
    current = sub;
  } while (true);

  _queuedLength = insertIndex;

  // Reverse the order for proper execution sequence
  int left = firstInsertedIndex;
  int right = insertIndex - 1;
  while (left < right) {
    final temp = _queued[left];
    _queued[left++] = _queued[right];
    _queued[right--] = temp;
  }
}

/// Checks if a link is valid (still in the dependency chain).
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
@pragma('vm:align-loops')
bool _isValidLink(Link checkLink, ReactiveNode sub) {
  Link? link = sub.depsTail;
  while (link != null) {
    if (identical(link, checkLink)) return true;
    link = link.prevDep;
  }
  return false;
}

/// Checks if a subscriber is dirty and needs update.
@pragma('vm:align-loops')
bool checkDirty(Link checkLink, ReactiveNode sub) {
  Stack<Link>? stack;
  int checkDepth = 0;
  Link? link = checkLink;
  bool dirty = false;

  top:
  do {
    final dep = link!.dep;
    final flags = dep.flags;

    if (sub.flags.isDirty) {
      dirty = true;
    } else if (flags.hasAll(ReactiveFlags.mutable | ReactiveFlags.dirty)) {
      if (_update(dep)) {
        final depSubs = dep.subs!;
        if (depSubs.nextSub != null) {
          shallowPropagate(depSubs);
        }
        dirty = true;
      }
    } else if (flags.hasAll(ReactiveFlags.mutable | ReactiveFlags.pending)) {
      final depDeps = dep.deps;
      if (depDeps == null) {
        dep.flags = dep.flags & ~ReactiveFlags.pending;
      } else {
        if (link.nextSub != null || link.prevSub != null) {
          stack = Stack(value: link, prev: stack);
        }
        link = depDeps;
        sub = dep;
        ++checkDepth;
        continue;
      }
    }

    if (!dirty) {
      final nextLink = link.nextDep;
      if (nextLink != null) {
        link = nextLink;
        continue;
      }
    }

    while (checkDepth-- > 0) {
      final firstSub = sub.subs!;
      final hasMultipleSubs = firstSub.nextSub != null;
      if (hasMultipleSubs) {
        link = stack!.value;
        stack = stack.prev;
      } else {
        link = firstSub;
      }
      if (dirty) {
        if (_update(sub)) {
          if (hasMultipleSubs) {
            shallowPropagate(firstSub);
          }
          sub = link.sub;
          continue;
        }
        dirty = false;
      } else {
        sub.flags = sub.flags & ~ReactiveFlags.pending;
      }
      sub = link.sub;
      final nextLink = link.nextDep;
      if (nextLink != null) {
        link = nextLink;
        continue top;
      }
    }

    return dirty;
  } while (true);
}

/// Performs shallow propagation to mark nodes as dirty.
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
@pragma('vm:align-loops')
void shallowPropagate(Link link) {
  Link? current = link;
  do {
    final sub = current!.sub;
    final flags = sub.flags;
    if ((flags & (ReactiveFlags.pending | ReactiveFlags.dirty)) ==
        ReactiveFlags.pending) {
      sub.flags = flags | ReactiveFlags.dirty;
      final checkFlags = ReactiveFlags.watching | ReactiveFlags.recursedCheck;
      if ((flags & checkFlags) == ReactiveFlags.watching) {
        _notify(sub as EffectNode);
      }
    }
    current = current.nextSub;
  } while (current != null);
}

/// Updates a node and returns whether the value changed.
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
bool _update(ReactiveNode node) {
  return switch (node) {
    SignalNode() => _updateSignal(node),
    ComputedNode() => _updateComputed(node),
    _ => false,
  };
}

/// Updates a signal node.
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
bool _updateSignal(SignalNode node) {
  node.flags = ReactiveFlags.mutable;
  return node.currentValue != (node.currentValue = node.pendingValue);
}

/// Updates a computed node.
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
bool _updateComputed(ComputedNode node) {
  ++_cycle;
  node.depsTail = null;
  node.flags = ReactiveFlags.mutable | ReactiveFlags.recursedCheck;
  final prevSub = setActiveSub(node);
  try {
    final oldValue = node.value;
    return oldValue != (node.value = node.compute(oldValue));
  } finally {
    _activeSub = prevSub;
    node.flags = node.flags & ~ReactiveFlags.recursedCheck;
    _purgeDeps(node);
  }
}

/// Runs an effect.
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
void _runEffect(EffectNode effect) {
  final flags = effect.flags;
  if (flags.isDirty || (flags.isPending && checkDirty(effect.deps!, effect))) {
    ++_cycle;
    effect.depsTail = null;
    effect.flags = ReactiveFlags.watching | ReactiveFlags.recursedCheck;
    final prevSub = setActiveSub(effect);
    try {
      effect.fn();
    } finally {
      _activeSub = prevSub;
      effect.flags = effect.flags & ~ReactiveFlags.recursedCheck;
      _purgeDeps(effect);
    }
  } else {
    effect.flags = ReactiveFlags.watching;
  }
}

/// Flushes the effect queue.
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
@pragma('vm:align-loops')
void flush() {
  while (_notifyIndex < _queuedLength) {
    final effect = _queued[_notifyIndex]!;
    _queued[_notifyIndex++] = null;
    _runEffect(effect);
  }
  _notifyIndex = 0;
  _queuedLength = 0;
}

/// Gets a computed value with dependency tracking.
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
T getComputed<T>(ComputedNode<T> node) {
  final flags = node.flags;
  bool needsUpdate = false;
  if (flags.isDirty) {
    needsUpdate = true;
  } else if (flags.isPending) {
    if (checkDirty(node.deps!, node)) {
      needsUpdate = true;
    } else {
      node.flags = flags & ~ReactiveFlags.pending;
    }
  }

  if (needsUpdate) {
    if (_updateComputed(node)) {
      final subs = node.subs;
      if (subs != null) {
        shallowPropagate(subs);
      }
    }
  } else if (flags.isNone) {
    node.flags = ReactiveFlags.mutable | ReactiveFlags.recursedCheck;
    final prevSub = setActiveSub(node);
    try {
      node.value = node.compute(null);
    } finally {
      _activeSub = prevSub;
      node.flags = node.flags & ~ReactiveFlags.recursedCheck;
    }
  }

  final sub = _activeSub;
  if (sub != null) {
    link(node, sub, _cycle);
  }
  return node.value as T;
}

/// Gets a signal value with dependency tracking.
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
@pragma('vm:align-loops')
T getSignal<T>(SignalNode<T> node) {
  if (node.flags.isDirty) {
    if (_updateSignal(node)) {
      final subs = node.subs;
      if (subs != null) {
        shallowPropagate(subs);
      }
    }
  }

  ReactiveNode? sub = _activeSub;
  while (sub != null) {
    if (sub.flags.has(ReactiveFlags.mutable | ReactiveFlags.watching)) {
      link(node, sub, _cycle);
      break;
    }
    sub = sub.subs?.sub;
  }
  return node.currentValue;
}

/// Sets a signal value.
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
void setSignal<T>(SignalNode<T> node, T value) {
  if (node.pendingValue != (node.pendingValue = value)) {
    node.flags = ReactiveFlags.mutable | ReactiveFlags.dirty;
    final subs = node.subs;
    if (subs != null) {
      propagate(subs);
      if (_batchDepth == 0) {
        flush();
      }
    }
  }
}

/// Creates and runs an effect.
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
EffectNode createEffect(void Function() fn) {
  final e = EffectNode(fn: fn);
  final prevSub = setActiveSub(e);
  if (prevSub != null) {
    link(e, prevSub, 0);
  }
  try {
    e.fn();
  } finally {
    _activeSub = prevSub;
    e.flags = e.flags & ~ReactiveFlags.recursedCheck;
  }
  return e;
}

/// Stops an effect.
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
void stopEffect(EffectNode effect) {
  _stopScope(effect);
}

/// Creates an effect scope.
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
ScopeNode createEffectScope(void Function() fn) {
  final e = ScopeNode();
  final prevSub = setActiveSub(e);
  if (prevSub != null) {
    link(e, prevSub, 0);
  }
  try {
    fn();
  } finally {
    _activeSub = prevSub;
  }
  return e;
}

/// Stops an effect scope.
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
void stopEffectScope(ScopeNode scope) {
  _stopScope(scope);
}

/// Triggers all subscribers of the tracked dependencies.
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
void triggerFn(void Function() fn) {
  final sub = ScopeNode();
  sub.flags = ReactiveFlags.watching;
  final prevSub = setActiveSub(sub);
  try {
    fn();
  } finally {
    _activeSub = prevSub;
    while (sub.deps != null) {
      final link = sub.deps!;
      final dep = link.dep;
      unlink(link, sub);
      if (dep.subs != null) {
        propagate(dep.subs!);
        shallowPropagate(dep.subs!);
      }
    }
    if (_batchDepth == 0) {
      flush();
    }
  }
}
