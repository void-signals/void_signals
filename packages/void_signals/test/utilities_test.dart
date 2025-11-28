import 'package:test/test.dart';
import 'package:void_signals/void_signals.dart';

void main() {
  group('batch', () {
    test('should batch multiple updates', () {
      final a = signal(1);
      final b = signal(2);
      int runCount = 0;

      effect(() {
        a();
        b();
        runCount++;
      });

      expect(runCount, 1);

      batch(() {
        a.value = 10;
        b.value = 20;
      });

      expect(runCount, 2);
    });

    test('should return value from batch', () {
      final result = batch(() => 42);
      expect(result, 42);
    });

    test('should support nested batches', () {
      final a = signal(1);
      final b = signal(2);
      final c = signal(3);
      int runCount = 0;

      effect(() {
        a();
        b();
        c();
        runCount++;
      });

      expect(runCount, 1);

      batch(() {
        a.value = 10;
        batch(() {
          b.value = 20;
          c.value = 30;
        });
      });

      expect(runCount, 2);
    });

    test(
        'should still trigger after batch even with same value set then changed',
        () {
      final s = signal(0);
      int runCount = 0;

      effect(() {
        s();
        runCount++;
      });

      expect(runCount, 1);

      batch(() {
        s.value = 1;
        s.value = 0;
        s.value = 2;
      });

      expect(runCount, 2);
    });

    test('should not trigger if value returns to original', () {
      final s = signal(0);
      int runCount = 0;

      effect(() {
        s();
        runCount++;
      });

      expect(runCount, 1);

      batch(() {
        s.value = 1;
        s.value = 0;
      });

      expect(runCount, 1);
    });
  });

  group('untrack', () {
    test('should not track dependencies in untrack', () {
      final a = signal(1);
      final b = signal(2);
      int runCount = 0;

      effect(() {
        a();
        untrack(() => b());
        runCount++;
      });

      expect(runCount, 1);

      a.value = 10;
      expect(runCount, 2);

      b.value = 20;
      expect(runCount, 2);
    });

    test('should return value from untrack', () {
      final s = signal(42);
      final result = untrack(() => s());
      expect(result, 42);
    });

    test('should pause tracking in computed', () {
      final src = signal(0);

      int computedTriggerTimes = 0;
      final c = computed((p) {
        computedTriggerTimes++;
        final currentSub = setActiveSub(null);
        final value = src();
        setActiveSub(currentSub);
        return value;
      });

      expect(c(), 0);
      expect(computedTriggerTimes, 1);

      src.value = 1;
      src.value = 2;
      src.value = 3;
      expect(c(), 0);
      expect(computedTriggerTimes, 1);
    });

    test('should pause tracking in effect', () {
      final src = signal(0);
      final is_ = signal(0);

      int effectTriggerTimes = 0;
      effect(() {
        effectTriggerTimes++;
        if (is_() != 0) {
          final currentSub = setActiveSub(null);
          src();
          setActiveSub(currentSub);
        }
      });

      expect(effectTriggerTimes, 1);

      is_.value = 1;
      expect(effectTriggerTimes, 2);

      src.value = 1;
      src.value = 2;
      src.value = 3;
      expect(effectTriggerTimes, 2);

      is_.value = 2;
      expect(effectTriggerTimes, 3);

      src.value = 4;
      src.value = 5;
      src.value = 6;
      expect(effectTriggerTimes, 3);

      is_.value = 0;
      expect(effectTriggerTimes, 4);

      src.value = 7;
      src.value = 8;
      src.value = 9;
      expect(effectTriggerTimes, 4);
    });
  });

  group('trigger', () {
    test('should trigger subscribers', () {
      final s = signal(0);
      int runCount = 0;

      effect(() {
        s();
        runCount++;
      });

      expect(runCount, 1);

      trigger(() {
        s();
      });

      expect(runCount, 2);
    });

    test('should not throw when triggering with no dependencies', () {
      expect(() => trigger(() {}), returnsNormally);
    });

    test('should trigger updates for dependent computed signals', () {
      final arr = signal<List<int>>([]);
      final length = computed((p) => arr().length);

      expect(length(), 0);
      arr().add(1);
      trigger(() => arr());
      expect(length(), 1);
    });

    test('should trigger updates for the second source signal', () {
      final src1 = signal<List<int>>([]);
      final src2 = signal<List<int>>([]);
      final length = computed((p) => src2().length);

      expect(length(), 0);
      src2().add(1);
      trigger(() {
        src1();
        src2();
      });
      expect(length(), 1);
    });

    test('should trigger effect once', () {
      final src1 = signal<List<int>>([]);
      final src2 = signal<List<int>>([]);

      int triggers = 0;

      effect(() {
        triggers++;
        src1();
        src2();
      });

      expect(triggers, 1);
      trigger(() {
        src1();
        src2();
      });
      expect(triggers, 2);
    });
  });

  group('startBatch and endBatch', () {
    test('should batch updates between startBatch and endBatch', () {
      final a = signal(1);
      final b = signal(2);
      int runCount = 0;

      effect(() {
        a();
        b();
        runCount++;
      });

      expect(runCount, 1);

      startBatch();
      a.value = 10;
      b.value = 20;
      expect(runCount, 1); // Not yet triggered
      endBatch();

      expect(runCount, 2);
    });

    test('should handle nested startBatch/endBatch', () {
      final s = signal(0);
      int runCount = 0;

      effect(() {
        s();
        runCount++;
      });

      expect(runCount, 1);

      startBatch();
      s.value = 1;
      startBatch();
      s.value = 2;
      endBatch();
      expect(runCount, 1); // Still batching
      endBatch();

      expect(runCount, 2);
    });
  });

  group('Type Checks', () {
    test('isSignal should work', () {
      final s = signal(1);
      expect(isSignal(s), true);
      expect(isSignal(computed((p) => 1)), false);
      expect(isSignal(effect(() {})), false);
      expect(isSignal(effectScope(() {})), false);
      expect(isSignal(42), false);
      expect(isSignal(null), false);
      expect(isSignal('string'), false);
    });

    test('isComputed should work', () {
      final c = computed((p) => 1);
      expect(isComputed(c), true);
      expect(isComputed(signal(1)), false);
      expect(isComputed(effect(() {})), false);
      expect(isComputed(42), false);
    });

    test('isEffect should work', () {
      final e = effect(() {});
      expect(isEffect(e), true);
      expect(isEffect(signal(1)), false);
      expect(isEffect(computed((p) => 1)), false);
      expect(isEffect(42), false);
    });

    test('isEffectScope should work', () {
      final scope = effectScope(() {});
      expect(isEffectScope(scope), true);
      expect(isEffectScope(signal(1)), false);
      expect(isEffectScope(effect(() {})), false);
      expect(isEffectScope(42), false);
    });
  });
}
