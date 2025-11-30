import 'package:void_signals/void_signals.dart' as signals;
import 'package:void_signals/void_signals.dart' show Signal, Computed, batch;

// =============================================================================
// Undo/Redo History Support
//
// Provides history tracking for signals with undo/redo capabilities.
// =============================================================================

/// A signal that maintains a history of values for undo/redo support.
///
/// Tracks all value changes and allows navigating through history.
///
/// Example:
/// ```dart
/// final text = UndoableSignal<String>('');
///
/// text.value = 'Hello';
/// text.value = 'Hello World';
/// text.value = 'Hello World!';
///
/// print(text.value);  // 'Hello World!'
/// text.undo();
/// print(text.value);  // 'Hello World'
/// text.undo();
/// print(text.value);  // 'Hello'
/// text.redo();
/// print(text.value);  // 'Hello World'
///
/// // In your widget
/// Watch(builder: (context, _) {
///   return Row(children: [
///     IconButton(
///       onPressed: text.canUndo.value ? text.undo : null,
///       icon: Icon(Icons.undo),
///     ),
///     IconButton(
///       onPressed: text.canRedo.value ? text.redo : null,
///       icon: Icon(Icons.redo),
///     ),
///   ]);
/// });
/// ```
class UndoableSignal<T> {
  final Signal<T> _current;
  final Signal<List<T>> _history;
  final Signal<int> _index;
  final int _maxHistory;
  bool _isUndoRedoAction = false;

  /// Creates an [UndoableSignal] with the given initial value.
  ///
  /// [maxHistory] limits the number of history entries (default: 100).
  /// Set to -1 for unlimited history.
  UndoableSignal(
    T initialValue, {
    int maxHistory = 100,
  })  : _current = signals.signal(initialValue),
        _history = signals.signal([initialValue]),
        _index = signals.signal(0),
        _maxHistory = maxHistory;

  /// The current value.
  T get value => _current.value;

  /// Sets a new value and adds it to history.
  set value(T newValue) {
    if (_isUndoRedoAction) {
      _current.value = newValue;
      return;
    }

    // If we're not at the end of history, truncate the forward history
    final currentIndex = _index.value;
    var history = _history.value;

    if (currentIndex < history.length - 1) {
      history = history.sublist(0, currentIndex + 1);
    }

    // Add new value
    history = [...history, newValue];

    // Trim history if needed
    if (_maxHistory > 0 && history.length > _maxHistory) {
      history = history.sublist(history.length - _maxHistory);
    }

    batch(() {
      _history.value = history;
      _index.value = history.length - 1;
      _current.value = newValue;
    });
  }

  /// The underlying signal (for passing to widgets).
  Signal<T> get signal => _current;

  /// Whether undo is available.
  Computed<bool> get canUndo => signals.computed((_) => _index.value > 0);

  /// Whether redo is available.
  Computed<bool> get canRedo =>
      signals.computed((_) => _index.value < _history.value.length - 1);

  /// The number of undo steps available.
  Computed<int> get undoCount => signals.computed((_) => _index.value);

  /// The number of redo steps available.
  Computed<int> get redoCount =>
      signals.computed((_) => _history.value.length - 1 - _index.value);

  /// The total history length.
  int get historyLength => _history.value.length;

  /// Undoes the last change.
  void undo() {
    if (_index.value > 0) {
      _isUndoRedoAction = true;
      batch(() {
        _index.value--;
        _current.value = _history.value[_index.value];
      });
      _isUndoRedoAction = false;
    }
  }

  /// Redoes the last undone change.
  void redo() {
    if (_index.value < _history.value.length - 1) {
      _isUndoRedoAction = true;
      batch(() {
        _index.value++;
        _current.value = _history.value[_index.value];
      });
      _isUndoRedoAction = false;
    }
  }

  /// Clears the history and resets to the current value.
  void clearHistory() {
    final current = _current.value;
    batch(() {
      _history.value = [current];
      _index.value = 0;
    });
  }

  /// Resets to a new value and clears history.
  void reset(T newValue) {
    batch(() {
      _history.value = [newValue];
      _index.value = 0;
      _current.value = newValue;
    });
  }

  /// Gets a snapshot of the current history.
  List<T> get history => List.unmodifiable(_history.value);

  /// Gets the current position in history.
  int get currentIndex => _index.value;

  /// Jumps to a specific position in history.
  void jumpTo(int index) {
    if (index >= 0 && index < _history.value.length) {
      _isUndoRedoAction = true;
      batch(() {
        _index.value = index;
        _current.value = _history.value[index];
      });
      _isUndoRedoAction = false;
    }
  }

  /// Creates a checkpoint that can be restored later.
  HistoryCheckpoint<T> checkpoint() {
    return HistoryCheckpoint._(
      value: _current.value,
      history: List.from(_history.value),
      index: _index.value,
    );
  }

  /// Restores from a checkpoint.
  void restore(HistoryCheckpoint<T> checkpoint) {
    _isUndoRedoAction = true;
    batch(() {
      _history.value = List.from(checkpoint._history);
      _index.value = checkpoint._index;
      _current.value = checkpoint._value;
    });
    _isUndoRedoAction = false;
  }
}

/// A checkpoint of history state that can be restored later.
class HistoryCheckpoint<T> {
  final T _value;
  final List<T> _history;
  final int _index;

  const HistoryCheckpoint._({
    required T value,
    required List<T> history,
    required int index,
  })  : _value = value,
        _history = history,
        _index = index;

  /// The value at this checkpoint.
  T get value => _value;

  /// The history length at this checkpoint.
  int get historyLength => _history.length;

  /// The index at this checkpoint.
  int get index => _index;
}

/// Creates an undoable signal from an existing signal.
///
/// This wraps an existing signal with undo/redo capabilities.
/// Note: Changes made directly to the original signal won't be tracked.
///
/// Example:
/// ```dart
/// final name = signal('');
/// final undoableName = undoable(name);
///
/// undoableName.value = 'John';
/// undoableName.value = 'Jane';
/// undoableName.undo();  // Back to 'John'
/// ```
UndoableSignal<T> undoable<T>(Signal<T> source, {int maxHistory = 100}) {
  return UndoableSignal<T>(source.value, maxHistory: maxHistory);
}

/// Extension methods for creating undoable versions of signals.
extension UndoableSignalExtension<T> on Signal<T> {
  /// Creates an undoable wrapper for this signal.
  UndoableSignal<T> toUndoable({int maxHistory = 100}) {
    return UndoableSignal<T>(value, maxHistory: maxHistory);
  }
}

/// A group of undoable operations that can be undone/redone together.
///
/// Useful for coordinating undo/redo across multiple signals.
///
/// Example:
/// ```dart
/// final firstName = UndoableSignal('');
/// final lastName = UndoableSignal('');
/// final group = UndoGroup([firstName, lastName]);
///
/// // Make changes to both
/// firstName.value = 'John';
/// lastName.value = 'Doe';
///
/// // Undo all
/// group.undoAll();  // Both go back
/// ```
class UndoGroup {
  final List<UndoableSignal<dynamic>> _signals;

  /// Creates an undo group with the given signals.
  UndoGroup(this._signals);

  /// Whether any signal can be undone.
  bool get canUndo => _signals.any((s) => s.canUndo.value);

  /// Whether any signal can be redone.
  bool get canRedo => _signals.any((s) => s.canRedo.value);

  /// Undoes all signals that can be undone.
  void undoAll() {
    for (final signal in _signals) {
      if (signal.canUndo.value) {
        signal.undo();
      }
    }
  }

  /// Redoes all signals that can be redone.
  void redoAll() {
    for (final signal in _signals) {
      if (signal.canRedo.value) {
        signal.redo();
      }
    }
  }

  /// Clears history for all signals.
  void clearAllHistory() {
    for (final signal in _signals) {
      signal.clearHistory();
    }
  }

  /// Creates a checkpoint for all signals.
  List<HistoryCheckpoint<dynamic>> checkpointAll() {
    return _signals.map((s) => s.checkpoint()).toList();
  }

  /// Restores all signals from checkpoints.
  void restoreAll(List<HistoryCheckpoint<dynamic>> checkpoints) {
    if (checkpoints.length != _signals.length) {
      throw ArgumentError('Checkpoint count must match signal count');
    }
    for (var i = 0; i < _signals.length; i++) {
      _signals[i].restore(checkpoints[i]);
    }
  }
}

/// A transaction that groups multiple changes into a single undo step.
///
/// All changes made within the transaction are treated as a single
/// undo/redo operation.
///
/// Example:
/// ```dart
/// final text = UndoableSignal<String>('Hello');
///
/// // Without transaction: each change is separate
/// text.value = 'Hello World';
/// text.value = 'Hello World!';
/// text.undo();  // Goes to 'Hello World'
/// text.undo();  // Goes to 'Hello'
///
/// // With transaction: all changes are one step
/// text.transaction(() {
///   text.value = 'Hello World';
///   text.value = 'Hello World!';
/// });
/// text.undo();  // Goes directly to 'Hello'
/// ```
extension UndoTransactionExtension<T> on UndoableSignal<T> {
  /// Executes a transaction where all changes are grouped.
  void transaction(void Function() action) {
    // Store current state
    final startValue = value;
    final startHistory = List<T>.from(history);
    final startIndex = currentIndex;

    // Execute action without tracking
    action();

    // Get final value
    final endValue = value;

    // Restore to start and add single change
    reset(startValue);
    for (var i = 0; i < startHistory.length && i <= startIndex; i++) {
      if (i < startIndex) {
        // Skip to index
      }
    }

    // Add the final value as a single change
    if (startValue != endValue) {
      value = endValue;
    }
  }
}

/// A signal that automatically saves its value and can be persisted.
///
/// Combines undoable history with the ability to mark "saved" points.
///
/// Example:
/// ```dart
/// final document = SaveableSignal<String>('');
///
/// document.value = 'Hello';
/// document.value = 'Hello World';
/// print(document.hasUnsavedChanges.value);  // true
///
/// document.markSaved();
/// print(document.hasUnsavedChanges.value);  // false
///
/// document.value = 'Hello World!';
/// print(document.hasUnsavedChanges.value);  // true
///
/// document.revertToSaved();  // Goes back to 'Hello World'
/// ```
class SaveableSignal<T> extends UndoableSignal<T> {
  final Signal<int> _savedIndex;

  /// Creates a [SaveableSignal] with the given initial value.
  SaveableSignal(super.initialValue, {super.maxHistory})
      : _savedIndex = signals.signal(0);

  /// Whether there are unsaved changes.
  Computed<bool> get hasUnsavedChanges =>
      signals.computed((_) => currentIndex != _savedIndex.value);

  /// Marks the current state as saved.
  void markSaved() {
    _savedIndex.value = currentIndex;
  }

  /// Reverts to the last saved state.
  void revertToSaved() {
    jumpTo(_savedIndex.value);
  }

  /// Gets the saved value (or null if no save point).
  T get savedValue => history[_savedIndex.value];
}
