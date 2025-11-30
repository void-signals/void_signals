import 'package:flutter_test/flutter_test.dart';
import 'package:void_signals_flutter/void_signals_flutter.dart';

void main() {
  group('UndoableSignal', () {
    test('should create with initial value', () {
      final undoable = UndoableSignal<int>(0);
      expect(undoable.value, equals(0));
      expect(undoable.historyLength, equals(1));
    });

    test('should track value changes', () {
      final undoable = UndoableSignal<int>(0);
      undoable.value = 1;
      undoable.value = 2;
      undoable.value = 3;

      expect(undoable.value, equals(3));
      expect(undoable.historyLength, equals(4));
    });

    test('should undo changes', () {
      final undoable = UndoableSignal<int>(0);
      undoable.value = 1;
      undoable.value = 2;

      undoable.undo();
      expect(undoable.value, equals(1));

      undoable.undo();
      expect(undoable.value, equals(0));
    });

    test('should redo changes', () {
      final undoable = UndoableSignal<int>(0);
      undoable.value = 1;
      undoable.value = 2;

      undoable.undo();
      undoable.undo();
      expect(undoable.value, equals(0));

      undoable.redo();
      expect(undoable.value, equals(1));

      undoable.redo();
      expect(undoable.value, equals(2));
    });

    test('should report canUndo correctly', () {
      final undoable = UndoableSignal<int>(0);
      expect(undoable.canUndo.value, isFalse);

      undoable.value = 1;
      expect(undoable.canUndo.value, isTrue);

      undoable.undo();
      expect(undoable.canUndo.value, isFalse);
    });

    test('should report canRedo correctly', () {
      final undoable = UndoableSignal<int>(0);
      expect(undoable.canRedo.value, isFalse);

      undoable.value = 1;
      expect(undoable.canRedo.value, isFalse);

      undoable.undo();
      expect(undoable.canRedo.value, isTrue);

      undoable.redo();
      expect(undoable.canRedo.value, isFalse);
    });

    test('should report undoCount correctly', () {
      final undoable = UndoableSignal<int>(0);
      expect(undoable.undoCount.value, equals(0));

      undoable.value = 1;
      expect(undoable.undoCount.value, equals(1));

      undoable.value = 2;
      expect(undoable.undoCount.value, equals(2));

      undoable.undo();
      expect(undoable.undoCount.value, equals(1));
    });

    test('should report redoCount correctly', () {
      final undoable = UndoableSignal<int>(0);
      expect(undoable.redoCount.value, equals(0));

      undoable.value = 1;
      undoable.value = 2;
      expect(undoable.redoCount.value, equals(0));

      undoable.undo();
      expect(undoable.redoCount.value, equals(1));

      undoable.undo();
      expect(undoable.redoCount.value, equals(2));
    });

    test('should truncate forward history on new value', () {
      final undoable = UndoableSignal<int>(0);
      undoable.value = 1;
      undoable.value = 2;
      undoable.value = 3;

      undoable.undo();
      undoable.undo();
      expect(undoable.value, equals(1));

      // New value should truncate forward history
      undoable.value = 10;
      expect(undoable.historyLength, equals(3)); // [0, 1, 10]
      expect(undoable.canRedo.value, isFalse);
    });

    test('should respect maxHistory limit', () {
      final undoable = UndoableSignal<int>(0, maxHistory: 3);

      undoable.value = 1;
      undoable.value = 2;
      undoable.value = 3;
      undoable.value = 4;

      expect(undoable.historyLength, equals(3));
      expect(undoable.history, equals([2, 3, 4]));
    });

    test('should handle unlimited history with maxHistory -1', () {
      final undoable = UndoableSignal<int>(0, maxHistory: -1);

      for (int i = 1; i <= 200; i++) {
        undoable.value = i;
      }

      expect(undoable.historyLength, equals(201));
    });

    test('should clear history', () {
      final undoable = UndoableSignal<int>(0);
      undoable.value = 1;
      undoable.value = 2;

      undoable.clearHistory();
      expect(undoable.historyLength, equals(1));
      expect(undoable.value, equals(2));
      expect(undoable.canUndo.value, isFalse);
    });

    test('should reset to new value', () {
      final undoable = UndoableSignal<int>(0);
      undoable.value = 1;
      undoable.value = 2;

      undoable.reset(100);
      expect(undoable.value, equals(100));
      expect(undoable.historyLength, equals(1));
      expect(undoable.canUndo.value, isFalse);
    });

    test('should return history snapshot', () {
      final undoable = UndoableSignal<int>(0);
      undoable.value = 1;
      undoable.value = 2;

      final history = undoable.history;
      expect(history, equals([0, 1, 2]));

      // History should be unmodifiable snapshot
      expect(() => history.add(3), throwsUnsupportedError);
    });

    test('should report currentIndex', () {
      final undoable = UndoableSignal<int>(0);
      expect(undoable.currentIndex, equals(0));

      undoable.value = 1;
      expect(undoable.currentIndex, equals(1));

      undoable.undo();
      expect(undoable.currentIndex, equals(0));
    });

    test('should jumpTo specific index', () {
      final undoable = UndoableSignal<int>(0);
      undoable.value = 1;
      undoable.value = 2;
      undoable.value = 3;

      undoable.jumpTo(1);
      expect(undoable.value, equals(1));
      expect(undoable.currentIndex, equals(1));
    });

    test('should ignore invalid jumpTo index', () {
      final undoable = UndoableSignal<int>(0);
      undoable.value = 1;

      undoable.jumpTo(-1);
      expect(undoable.currentIndex, equals(1));

      undoable.jumpTo(100);
      expect(undoable.currentIndex, equals(1));
    });

    test('should create and restore checkpoint', () {
      final undoable = UndoableSignal<int>(0);
      undoable.value = 1;
      undoable.value = 2;

      final checkpoint = undoable.checkpoint();
      expect(checkpoint.value, equals(2));
      expect(checkpoint.index, equals(2));

      undoable.value = 3;
      undoable.value = 4;

      undoable.restore(checkpoint);
      expect(undoable.value, equals(2));
      expect(undoable.historyLength, equals(3));
    });

    test('should expose underlying signal', () {
      final undoable = UndoableSignal<int>(0);
      expect(undoable.signal, isA<Signal<int>>());
      expect(undoable.signal.value, equals(0));
    });

    test('should not add to history when undo/redo', () {
      final undoable = UndoableSignal<int>(0);
      undoable.value = 1;
      undoable.value = 2;

      final historyBefore = undoable.historyLength;
      undoable.undo();
      undoable.redo();

      expect(undoable.historyLength, equals(historyBefore));
    });

    test('should handle string values', () {
      final undoable = UndoableSignal<String>('');
      undoable.value = 'Hello';
      undoable.value = 'Hello World';

      expect(undoable.value, equals('Hello World'));
      undoable.undo();
      expect(undoable.value, equals('Hello'));
    });

    test('should handle complex object values', () {
      final undoable = UndoableSignal<Map<String, int>>({'a': 1});
      undoable.value = {'a': 1, 'b': 2};
      undoable.value = {'a': 1, 'b': 2, 'c': 3};

      undoable.undo();
      expect(undoable.value, equals({'a': 1, 'b': 2}));
    });
  });

  group('HistoryCheckpoint', () {
    test('should store value', () {
      final undoable = UndoableSignal<int>(42);
      final checkpoint = undoable.checkpoint();
      expect(checkpoint.value, equals(42));
    });

    test('should store history length', () {
      final undoable = UndoableSignal<int>(0);
      undoable.value = 1;
      undoable.value = 2;

      final checkpoint = undoable.checkpoint();
      expect(checkpoint.historyLength, equals(3));
    });

    test('should store index', () {
      final undoable = UndoableSignal<int>(0);
      undoable.value = 1;
      undoable.undo();

      final checkpoint = undoable.checkpoint();
      expect(checkpoint.index, equals(0));
    });
  });

  group('undoable function', () {
    test('should create UndoableSignal from value', () {
      final source = signal(10);
      final undoable = source.toUndoable();

      expect(undoable, isA<UndoableSignal<int>>());
      expect(undoable.value, equals(10));
    });

    test('should respect maxHistory parameter', () {
      final source = signal(0);
      final undoable = source.toUndoable(maxHistory: 5);

      for (int i = 1; i <= 10; i++) {
        undoable.value = i;
      }

      expect(undoable.historyLength, equals(5));
    });
  });

  group('UndoableSignalExtension', () {
    test('should convert signal to undoable', () {
      final source = signal('test');
      final undoable = source.toUndoable();

      expect(undoable.value, equals('test'));
    });
  });

  group('UndoGroup', () {
    test('should create with multiple signals', () {
      final a = UndoableSignal<int>(0);
      final b = UndoableSignal<String>('');

      final group = UndoGroup([a, b]);
      expect(group.canUndo, isFalse);
      expect(group.canRedo, isFalse);
    });

    test('should report canUndo if any signal can undo', () {
      final a = UndoableSignal<int>(0);
      final b = UndoableSignal<String>('');

      final group = UndoGroup([a, b]);
      expect(group.canUndo, isFalse);

      a.value = 1;
      expect(group.canUndo, isTrue);
    });

    test('should report canRedo if any signal can redo', () {
      final a = UndoableSignal<int>(0);
      final b = UndoableSignal<String>('');

      final group = UndoGroup([a, b]);
      a.value = 1;
      a.undo();

      expect(group.canRedo, isTrue);
    });

    test('should undoAll', () {
      final a = UndoableSignal<int>(0);
      final b = UndoableSignal<String>('');

      a.value = 1;
      b.value = 'test';

      final group = UndoGroup([a, b]);
      group.undoAll();

      expect(a.value, equals(0));
      expect(b.value, equals(''));
    });

    test('should redoAll', () {
      final a = UndoableSignal<int>(0);
      final b = UndoableSignal<String>('');

      a.value = 1;
      b.value = 'test';

      final group = UndoGroup([a, b]);
      group.undoAll();
      group.redoAll();

      expect(a.value, equals(1));
      expect(b.value, equals('test'));
    });

    test('should clearAllHistory', () {
      final a = UndoableSignal<int>(0);
      final b = UndoableSignal<String>('');

      a.value = 1;
      a.value = 2;
      b.value = 'test';

      final group = UndoGroup([a, b]);
      group.clearAllHistory();

      expect(a.historyLength, equals(1));
      expect(b.historyLength, equals(1));
    });

    test('should checkpoint and restore all', () {
      final a = UndoableSignal<int>(0);
      final b = UndoableSignal<String>('');

      a.value = 1;
      b.value = 'test';

      final group = UndoGroup([a, b]);
      final checkpoints = group.checkpointAll();

      a.value = 2;
      b.value = 'modified';

      group.restoreAll(checkpoints);

      expect(a.value, equals(1));
      expect(b.value, equals('test'));
    });

    test('should throw on checkpoint/restore count mismatch', () {
      final a = UndoableSignal<int>(0);
      final b = UndoableSignal<String>('');

      final group = UndoGroup([a, b]);
      final checkpoints = group.checkpointAll();

      // Create group with different count
      final smallerGroup = UndoGroup([a]);

      expect(
        () => smallerGroup.restoreAll(checkpoints),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('SaveableSignal', () {
    test('should track unsaved changes', () {
      final saveable = SaveableSignal<String>('initial');
      expect(saveable.hasUnsavedChanges.value, isFalse);

      saveable.value = 'modified';
      expect(saveable.hasUnsavedChanges.value, isTrue);
    });

    test('should mark as saved', () {
      final saveable = SaveableSignal<String>('initial');
      saveable.value = 'modified';
      expect(saveable.hasUnsavedChanges.value, isTrue);

      saveable.markSaved();
      expect(saveable.hasUnsavedChanges.value, isFalse);
    });

    test('should revert to saved', () {
      final saveable = SaveableSignal<String>('initial');
      saveable.value = 'modified1';
      saveable.markSaved();
      saveable.value = 'modified2';
      saveable.value = 'modified3';

      expect(saveable.value, equals('modified3'));

      saveable.revertToSaved();
      expect(saveable.value, equals('modified1'));
    });

    test('should return savedValue', () {
      final saveable = SaveableSignal<String>('initial');
      expect(saveable.savedValue, equals('initial'));

      saveable.value = 'modified';
      saveable.markSaved();
      expect(saveable.savedValue, equals('modified'));
    });

    test('should work with undo after save', () {
      final saveable = SaveableSignal<String>('initial');
      saveable.value = 'step1';
      saveable.value = 'step2';
      saveable.markSaved();
      saveable.value = 'step3';

      expect(saveable.hasUnsavedChanges.value, isTrue);

      saveable.undo();
      expect(saveable.value, equals('step2'));
      expect(saveable.hasUnsavedChanges.value, isFalse);
    });
  });

  group('UndoTransactionExtension', () {
    test('should group changes into single undo step', () {
      final undoable = UndoableSignal<String>('Hello');

      undoable.transaction(() {
        undoable.value = 'Hello World';
        undoable.value = 'Hello World!';
      });

      expect(undoable.value, equals('Hello World!'));

      // Single undo should go back to original
      undoable.undo();
      expect(undoable.value, equals('Hello'));
    });

    test('should handle no changes in transaction', () {
      final undoable = UndoableSignal<int>(10);
      final historyBefore = undoable.historyLength;

      undoable.transaction(() {
        // No changes
      });

      expect(undoable.historyLength, equals(historyBefore));
    });
  });

  group('Edge cases', () {
    test('should handle undo when at start', () {
      final undoable = UndoableSignal<int>(0);
      undoable.undo(); // Should not throw
      expect(undoable.value, equals(0));
    });

    test('should handle redo when at end', () {
      final undoable = UndoableSignal<int>(0);
      undoable.value = 1;
      undoable.redo(); // Should not throw
      expect(undoable.value, equals(1));
    });

    test('should handle same value updates', () {
      final undoable = UndoableSignal<int>(0);
      undoable.value = 1;
      undoable.value = 1; // Same value
      undoable.value = 1; // Same value again

      // All values are tracked even if same
      expect(undoable.historyLength, equals(4));
    });

    test('should handle null values', () {
      final undoable = UndoableSignal<String?>('initial');
      undoable.value = null;
      undoable.value = 'restored';

      undoable.undo();
      expect(undoable.value, isNull);

      undoable.undo();
      expect(undoable.value, equals('initial'));
    });

    test('should trigger effects on undo/redo', () {
      final undoable = UndoableSignal<int>(0);
      undoable.value = 1;
      undoable.value = 2;

      var effectCount = 0;
      final eff = effect(() {
        undoable.signal.value;
        effectCount++;
      });

      effectCount = 0;
      undoable.undo();
      expect(effectCount, equals(1));

      undoable.redo();
      expect(effectCount, equals(2));

      eff.stop();
    });

    test('should handle rapid undo/redo', () {
      final undoable = UndoableSignal<int>(0);
      for (int i = 1; i <= 10; i++) {
        undoable.value = i;
      }

      for (int i = 0; i < 10; i++) {
        undoable.undo();
      }
      expect(undoable.value, equals(0));

      for (int i = 0; i < 10; i++) {
        undoable.redo();
      }
      expect(undoable.value, equals(10));
    });

    test('should handle maxHistory of 1', () {
      final undoable = UndoableSignal<int>(0, maxHistory: 1);
      undoable.value = 1;
      undoable.value = 2;

      expect(undoable.historyLength, equals(1));
      expect(undoable.value, equals(2));
      expect(undoable.canUndo.value, isFalse);
    });
  });

  group('Reactivity', () {
    test('value changes should trigger effects', () {
      final undoable = UndoableSignal<int>(0);
      var effectCount = 0;

      final eff = effect(() {
        undoable.signal.value;
        effectCount++;
      });

      undoable.value = 1;
      expect(effectCount, equals(2));

      undoable.value = 2;
      expect(effectCount, equals(3));

      eff.stop();
    });

    test('canUndo computed should update reactively', () {
      final undoable = UndoableSignal<int>(0);
      var canUndoValues = <bool>[];

      final eff = effect(() {
        canUndoValues.add(undoable.canUndo.value);
      });

      undoable.value = 1;
      undoable.undo();
      undoable.value = 2;

      expect(canUndoValues, equals([false, true, false, true]));

      eff.stop();
    });
  });
}
