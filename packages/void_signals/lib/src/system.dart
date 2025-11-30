import 'flags.dart';
import 'nodes.dart';

// ============================================================================
// GLOBAL STATE
// ============================================================================

int _cycle = 0;
int _batchDepth = 0;
ReactiveNode? _activeSub;
EffectNode? _queuedEffects;
EffectNode? _queuedEffectsTail;

// ============================================================================
// SUBSCRIBER MANAGEMENT
// ============================================================================

@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
ReactiveNode? getActiveSub() => _activeSub;

@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
ReactiveNode? setActiveSub(ReactiveNode? sub) {
  final prevSub = _activeSub;
  _activeSub = sub;
  return prevSub;
}

// ============================================================================
// BATCH MANAGEMENT
// ============================================================================

@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
int getBatchDepth() => _batchDepth;

@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
void startBatch() => ++_batchDepth;

@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
void endBatch() {
  if (--_batchDepth == 0) flush();
}

// ============================================================================
// LINK MANAGEMENT
// ============================================================================

@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
void link(ReactiveNode dep, ReactiveNode sub, int version) {
  final prevDep = sub.depsTail;
  if (prevDep != null && identical(prevDep.dep, dep)) {
    return;
  }

  final nextDep = prevDep != null ? prevDep.nextDep : sub.deps;
  if (nextDep != null && identical(nextDep.dep, dep)) {
    nextDep.version = version;
    sub.depsTail = nextDep;
    return;
  }

  final prevSub = dep.subsTail;
  if (prevSub != null &&
      prevSub.version == version &&
      identical(prevSub.sub, sub)) {
    return;
  }

  final newLink = sub.depsTail = dep.subsTail = Link(dep, sub, version)
    ..prevDep = prevDep
    ..nextDep = nextDep
    ..prevSub = prevSub;

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

@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
Link? unlink(Link link, ReactiveNode sub) {
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

@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
void _unwatched(ReactiveNode node) {
  final flags = node.flags;
  if ((flags & ReactiveFlags.mutable) == ReactiveFlags.none) {
    _stop(node);
  } else if (node.depsTail != null) {
    node.depsTail = null;
    node.flags = 17 as ReactiveFlags;
    _purgeDeps(node);
  }
}

@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
void _stop(ReactiveNode node) {
  node.depsTail = null;
  node.flags = ReactiveFlags.none;
  _purgeDeps(node);
  final sub = node.subs;
  if (sub != null) {
    unlink(sub, sub.sub);
  }
}

@pragma('vm:align-loops')
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
void _purgeDeps(ReactiveNode sub) {
  final depsTail = sub.depsTail;
  Link? dep = depsTail != null ? depsTail.nextDep : sub.deps;
  while (dep != null) {
    dep = unlink(dep, sub);
  }
}

// ============================================================================
// PROPAGATION
// ============================================================================

@pragma('vm:align-loops')
void propagate(Link link) {
  Link? next = link.nextSub;
  Stack<Link?>? stack;

  top:
  do {
    final sub = link.sub;
    ReactiveFlags flags = sub.flags;

    if ((flags & 60) == ReactiveFlags.none) {
      sub.flags = flags | ReactiveFlags.pending;
    } else if ((flags & 12) == ReactiveFlags.none) {
      flags = ReactiveFlags.none;
    } else if ((flags & ReactiveFlags.recursedCheck) == ReactiveFlags.none) {
      sub.flags = (flags & -9) | ReactiveFlags.pending;
    } else if ((flags & 48) == ReactiveFlags.none && _isValidLink(link, sub)) {
      sub.flags = flags | (40 as ReactiveFlags);
      flags &= ReactiveFlags.mutable;
    } else {
      flags = ReactiveFlags.none;
    }

    if ((flags & ReactiveFlags.watching) != ReactiveFlags.none) {
      _notify(sub as EffectNode);
    }

    if ((flags & ReactiveFlags.mutable) != ReactiveFlags.none) {
      final subSubs = sub.subs;
      if (subSubs != null) {
        final nextSub = (link = subSubs).nextSub;
        if (nextSub != null) {
          stack = Stack(next, stack);
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
      final Stack(:value, :prev) = stack;
      stack = prev;
      if (value != null) {
        link = value;
        next = link.nextSub;
        continue top;
      }
    }

    break;
  } while (true);
}

@pragma('vm:align-loops')
void _notify(EffectNode effect) {
  EffectNode? head;
  final tail = effect;

  do {
    effect.flags &= -3;
    effect.nextEffect = head;
    head = effect;

    final next = effect.subs?.sub;
    if (next == null ||
        next is! EffectNode ||
        (next.flags & ReactiveFlags.watching) == ReactiveFlags.none) {
      break;
    }
    effect = next;
  } while (true);

  if (_queuedEffectsTail == null) {
    _queuedEffects = _queuedEffectsTail = head;
  } else {
    _queuedEffectsTail!.nextEffect = head;
    _queuedEffectsTail = tail;
  }
}

@pragma('vm:align-loops')
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
void shallowPropagate(Link link) {
  Link? curr = link;
  do {
    final sub = curr!.sub;
    final flags = sub.flags;
    if ((flags & 48) == ReactiveFlags.pending) {
      sub.flags = flags | ReactiveFlags.dirty;
      if ((flags & 6) == ReactiveFlags.watching) {
        _notify(sub as EffectNode);
      }
    }
  } while ((curr = curr.nextSub) != null);
}

@pragma('vm:align-loops')
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
bool _isValidLink(Link checkLink, ReactiveNode sub) {
  Link? link = sub.depsTail;
  while (link != null) {
    if (identical(link, checkLink)) return true;
    link = link.prevDep;
  }
  return false;
}

// ============================================================================
// DIRTY CHECKING
// ============================================================================

@pragma('vm:align-loops')
bool checkDirty(Link link, ReactiveNode sub) {
  Stack<Link>? stack;
  int checkDepth = 0;
  bool dirty = false;

  top:
  do {
    final dep = link.dep;
    final flags = dep.flags;

    if ((sub.flags & ReactiveFlags.dirty) != ReactiveFlags.none) {
      dirty = true;
    } else if ((flags & 17) == 17) {
      if (_update(dep)) {
        final subs = dep.subs!;
        if (subs.nextSub != null) {
          shallowPropagate(subs);
        }
        dirty = true;
      }
    } else if ((flags & 33) == 33) {
      if (link.nextSub != null || link.prevSub != null) {
        stack = Stack(link, stack);
      }
      link = dep.deps!;
      sub = dep;
      ++checkDepth;
      continue;
    }

    if (!dirty) {
      final nextDep = link.nextDep;
      if (nextDep != null) {
        link = nextDep;
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
        sub.flags &= -33;
      }
      sub = link.sub;
      final nextDep = link.nextDep;
      if (nextDep != null) {
        link = nextDep;
        continue top;
      }
    }

    return dirty;
  } while (true);
}

// ============================================================================
// UPDATE FUNCTIONS
// ============================================================================

@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
bool _update(ReactiveNode node) {
  if (node is ComputedNode<dynamic>) {
    return _updateComputedNode(node);
  } else if (node is SignalNode<dynamic>) {
    return node.applyPending();
  }
  return false;
}

@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
bool _updateComputedNode(ComputedNode<dynamic> node) {
  ++_cycle;
  node.depsTail = null;
  node.flags = 5 as ReactiveFlags;

  final prevSub = _activeSub;
  _activeSub = node;
  try {
    return node.recompute();
  } finally {
    _activeSub = prevSub;
    node.flags &= -5;
    _purgeDeps(node);
  }
}

@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
bool _updateComputed<T>(ComputedNode<T> node) {
  ++_cycle;
  node.depsTail = null;
  node.flags = 5 as ReactiveFlags;

  final prevSub = _activeSub;
  _activeSub = node;
  try {
    return node.recompute();
  } finally {
    _activeSub = prevSub;
    node.flags &= -5;
    _purgeDeps(node);
  }
}

// ============================================================================
// EFFECT EXECUTION
// ============================================================================

@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
void _runEffect(EffectNode effect) {
  final flags = effect.flags;

  if ((flags & ReactiveFlags.dirty) != ReactiveFlags.none ||
      ((flags & ReactiveFlags.pending) != ReactiveFlags.none &&
          checkDirty(effect.deps!, effect))) {
    ++_cycle;
    effect.depsTail = null;
    effect.flags = 6 as ReactiveFlags;

    final prevSub = _activeSub;
    _activeSub = effect;
    try {
      effect.fn();
    } finally {
      _activeSub = prevSub;
      effect.flags &= -5;
      _purgeDeps(effect);
    }
  } else {
    effect.flags = ReactiveFlags.watching;
  }
}

@pragma('vm:align-loops')
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
void flush() {
  while (_queuedEffects != null) {
    final effect = _queuedEffects!;
    final next = effect.nextEffect as EffectNode?;
    if (next != null) {
      _queuedEffects = next;
      effect.nextEffect = null;
    } else {
      _queuedEffects = null;
      _queuedEffectsTail = null;
    }
    _runEffect(effect);
  }
}

// ============================================================================
// PUBLIC API
// ============================================================================

@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
T getComputed<T>(ComputedNode<T> node) {
  final flags = node.flags;

  if ((flags & ReactiveFlags.dirty) != ReactiveFlags.none ||
      ((flags & ReactiveFlags.pending) != ReactiveFlags.none &&
          (checkDirty(node.deps!, node) ||
              identical(node.flags = flags & -33, false)))) {
    if (_updateComputed(node)) {
      final subs = node.subs;
      if (subs != null) {
        shallowPropagate(subs);
      }
    }
  } else if (flags == ReactiveFlags.none) {
    node.flags = 5 as ReactiveFlags;
    final prevSub = _activeSub;
    _activeSub = node;
    try {
      node.cachedValue = node.getter(null);
    } finally {
      _activeSub = prevSub;
      node.flags &= -5;
    }
  }

  final sub = _activeSub;
  if (sub != null) {
    link(node, sub, _cycle);
  }
  return node.cachedValue as T;
}

@pragma('vm:align-loops')
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
T getSignal<T>(SignalNode<T> node) {
  if ((node.flags & ReactiveFlags.dirty) != ReactiveFlags.none) {
    if (node.applyPending()) {
      final subs = node.subs;
      if (subs != null) {
        shallowPropagate(subs);
      }
    }
  }

  ReactiveNode? sub = _activeSub;
  while (sub != null) {
    if ((sub.flags & 3) != ReactiveFlags.none) {
      link(node, sub, _cycle);
      break;
    }
    sub = sub.subs?.sub;
  }

  return node.currentValue;
}

@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
void setSignal<T>(SignalNode<T> node, T value) {
  if (node.pendingValue != (node.pendingValue = value)) {
    node.flags = 17 as ReactiveFlags;
    final subs = node.subs;
    if (subs != null) {
      propagate(subs);
      if (_batchDepth == 0) {
        flush();
      }
    }
  }
}

// ============================================================================
// EFFECT MANAGEMENT
// ============================================================================

@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
EffectNode createEffect(void Function() fn) {
  final e = EffectNode(fn);

  final prevSub = _activeSub;
  _activeSub = e;
  if (prevSub != null) {
    link(e, prevSub, 0);
  }
  try {
    e.fn();
  } finally {
    _activeSub = prevSub;
    e.flags &= -5;
  }
  return e;
}

@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
void stopEffect(EffectNode effect) {
  _stop(effect);
}

@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
ScopeNode createEffectScope(void Function() fn) {
  final e = ScopeNode();

  final prevSub = _activeSub;
  _activeSub = e;
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

@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
@pragma('wasm:prefer-inline')
void stopEffectScope(ScopeNode scope) {
  _stop(scope);
}

@pragma('vm:align-loops')
void triggerFn(void Function() fn) {
  final sub = ScopeNode();
  sub.flags = ReactiveFlags.watching;

  final prevSub = _activeSub;
  _activeSub = sub;
  try {
    fn();
  } finally {
    _activeSub = prevSub;
    Link? link = sub.deps;
    while (link != null) {
      final dep = link.dep;
      final nextLink = unlink(link, sub);
      if (dep.subs != null) {
        sub.flags = ReactiveFlags.none;
        propagate(dep.subs!);
        shallowPropagate(dep.subs!);
      }
      link = nextLink;
    }
    if (_batchDepth == 0) {
      flush();
    }
  }
}
