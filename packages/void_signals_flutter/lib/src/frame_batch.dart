import 'package:flutter/scheduler.dart';
import 'package:void_signals/void_signals.dart';

// =============================================================================
// Frame-Level Batching
//
// Provides automatic batching of signal updates within a single frame.
// Multiple components calling batchLater() in the same frame will share
// a single batch, resulting in only one effect flush.
//
// This is an optimization over the core batch() function which flushes
// immediately when each batch ends.
// =============================================================================

/// Global frame batch state
bool _frameBatchActive = false;
bool _flushScheduled = false;

/// Queues a signal update to be batched with other updates in the same frame.
///
/// Unlike [batch], which flushes immediately when the batch ends,
/// [batchLater] defers the flush until the end of the current microtask.
/// Multiple [batchLater] calls in the same microtask share a single flush.
///
/// ## Example
///
/// ```dart
/// // Component A
/// onPressed: () => batchLater(() => counterA.value++),
///
/// // Component B (same frame)
/// onPressed: () => batchLater(() => counterB.value++),
///
/// // Both updates execute in a single batch, effects run once
/// ```
///
/// ## Comparison with batch()
///
/// | Feature | batch() | batchLater() |
/// |---------|---------|--------------|
/// | Flush timing | Immediately | End of microtask |
/// | Multiple calls | Each flushes independently | Shared single flush |
/// | Return value | Supported | Supported |
/// | Use case | Synchronous atomic updates | Cross-component updates |
///
/// ## When to use
///
/// - Multiple independent components updating signals
/// - Want to minimize effect executions
/// - Don't need synchronous flush
///
/// ## When NOT to use
///
/// - Need immediate synchronous effect execution
/// - Single atomic update (use [batch] instead)
T batchLater<T>(T Function() fn) {
  // Start a batch if not already in one
  if (!_frameBatchActive) {
    _frameBatchActive = true;
    startBatch();
    _scheduleFlush();
  }

  try {
    return fn();
  } catch (e) {
    rethrow;
  }
}

void _scheduleFlush() {
  if (_flushScheduled) return;
  _flushScheduled = true;

  // Schedule flush at end of microtask
  Future.microtask(() {
    _flushScheduled = false;
    _frameBatchActive = false;
    endBatch(); // This triggers flush
  });
}

// =============================================================================
// FrameBatchScope - Queue-based approach for more control
// =============================================================================

/// Provides a queue-based batching mechanism.
///
/// All updates queued via [update] in the same microtask will be
/// executed together in a single batch.
///
/// ## Example
///
/// ```dart
/// FrameBatchScope.update(() => counter.value++);
/// FrameBatchScope.update(() => name.value = 'John');
/// // Both run in a single batch
/// ```
class FrameBatchScope {
  FrameBatchScope._();

  static bool _scheduled = false;
  static final List<void Function()> _queue = [];

  /// Queues an update to be executed in the next batch.
  ///
  /// All updates queued before the next microtask will be batched together.
  static void update(void Function() fn) {
    _queue.add(fn);
    _scheduleFlush();
  }

  static void _scheduleFlush() {
    if (_scheduled) return;
    _scheduled = true;

    // Schedule for end of current event loop
    Future.microtask(() {
      _scheduled = false;
      _flushQueue();
    });
  }

  static void _flushQueue() {
    if (_queue.isEmpty) return;

    final updates = List<void Function()>.from(_queue);
    _queue.clear();

    batch(() {
      for (final update in updates) {
        try {
          update();
        } catch (e, stack) {
          // Report error but continue with other updates
          SignalErrorHandler.instance?.handleError(e, stack);
        }
      }
    });
  }

  /// Immediately flushes any pending updates.
  ///
  /// Normally updates are flushed automatically via microtask.
  /// Use this if you need synchronous flushing.
  static void flush() {
    _scheduled = false;
    _flushQueue();
  }
}

/// Queues a signal update using [FrameBatchScope].
///
/// This is an alias for [FrameBatchScope.update].
void queueUpdate(void Function() update) {
  FrameBatchScope.update(update);
}
