import 'package:test/test.dart';
import 'package:void_signals/void_signals.dart';

void main() {
  group('Signal', () {
    test('should create signal with initial value', () {
      final s = signal(1);
      expect(s(), 1);
      expect(s.value, 1);
    });

    test('should update signal value', () {
      final s = signal(1);
      s.value = 2;
      expect(s(), 2);
    });

    test('should update signal value with value setter', () {
      final s = signal(1);
      s.value = 2;
      expect(s.value, 2);
    });

    test('should update signal value with update method', () {
      final s = signal(1);
      s.update(3);
      expect(s.value, 3);
    });

    test('should peek value without tracking', () {
      final s = signal(1);
      expect(s.peek(), 1);
    });

    test('should track hasSubscribers', () {
      final s = signal(1);
      expect(s.hasSubscribers, false);

      final eff = effect(() {
        s();
      });
      expect(s.hasSubscribers, true);

      eff.stop();
      expect(s.hasSubscribers, false);
    });
  });

  group('Computed', () {
    test('should compute value', () {
      final a = signal(1);
      final b = signal(2);
      final sum = computed((prev) => a() + b());

      expect(sum(), 3);
    });

    test('should recompute when dependency changes', () {
      final a = signal(1);
      final b = signal(2);
      final sum = computed((prev) => a() + b());

      expect(sum(), 3);
      a.value = 10;
      expect(sum(), 12);
    });

    test('should cache value when dependencies unchanged', () {
      int computeCount = 0;
      final a = signal(1);
      final c = computed((prev) {
        computeCount++;
        return a() * 2;
      });

      expect(c(), 2);
      expect(computeCount, 1);
      expect(c(), 2);
    });

    test('should receive previous value', () {
      final a = signal(1);
      int? prev;
      final c = computed<int>((int? previous) {
        prev = previous;
        return a();
      });

      expect(c(), 1);
      expect(prev, null);

      a.value = 2;
      expect(c(), 2);
      expect(prev, 1);
    });

    test('should work with nested computed', () {
      final a = signal(1);
      final b = computed((prev) => a() * 2);
      final c = computed((prev) => b() + 1);

      expect(c(), 3);
      a.value = 5;
      expect(c(), 11);
    });

    // From computed.spec.ts
    test('should correctly propagate changes through computed signals', () {
      final src = signal(0);
      final c1 = computed((p) => src() % 2);
      final c2 = computed((p) => c1());
      final c3 = computed((p) => c2());

      c3();
      src.value = 1;
      c2();
      src.value = 3;

      expect(c3(), 1);
    });

    test('should propagate updated source value through chained computations',
        () {
      final src = signal(0);
      final a = computed((p) => src());
      final b = computed((p) => a() % 2);
      final c = computed((p) => src());
      final d = computed((p) => b() + c());

      expect(d(), 0);
      src.value = 2;
      expect(d(), 2);
    });

    test('should handle flags are indirectly updated during checkDirty', () {
      final a = signal(false);
      final b = computed((p) => a());
      final c = computed((p) {
        b();
        return 0;
      });
      final d = computed((p) {
        c();
        return b();
      });

      expect(d(), false);
      a.value = true;
      expect(d(), true);
    });

    test('should not update if the signal value is reverted', () {
      int times = 0;

      final src = signal(0);
      final c1 = computed((p) {
        times++;
        return src();
      });
      c1();
      expect(times, 1);
      src.value = 1;
      src.value = 0;
      c1();
      expect(times, 1);
    });
  });

  group('Effect', () {
    test('should run immediately', () {
      bool ran = false;
      effect(() {
        ran = true;
      });
      expect(ran, true);
    });

    test('should run when dependency changes', () {
      final s = signal(0);
      int runCount = 0;

      effect(() {
        s();
        runCount++;
      });

      expect(runCount, 1);
      s.value = 1;
      expect(runCount, 2);
    });

    test('should stop running when stopped', () {
      final s = signal(0);
      int runCount = 0;

      final eff = effect(() {
        s();
        runCount++;
      });

      expect(runCount, 1);
      eff.stop();
      s.value = 1;
      expect(runCount, 1);
    });

    test('should track computed dependencies', () {
      final a = signal(1);
      final b = computed((prev) => a() * 2);
      int runCount = 0;
      int? lastValue;

      effect(() {
        lastValue = b();
        runCount++;
      });

      expect(runCount, 1);
      expect(lastValue, 2);

      a.value = 5;
      expect(runCount, 2);
      expect(lastValue, 10);
    });

    test('should handle diamond dependencies', () {
      final a = signal(1);
      final b = computed((prev) => a() * 2);
      final c = computed((prev) => a() * 3);
      final d = computed((prev) => b() + c());

      int runCount = 0;
      int? lastValue;

      effect(() {
        lastValue = d();
        runCount++;
      });

      expect(runCount, 1);
      expect(lastValue, 5);

      a.value = 2;
      expect(runCount, 2);
      expect(lastValue, 10);
    });

    // From effect.spec.ts
    test('should clear subscriptions when untracked by all subscribers', () {
      int bRunTimes = 0;

      final a = signal(1);
      final b = computed((p) {
        bRunTimes++;
        return a() * 2;
      });
      final stopEffect = effect(() {
        b();
      });

      expect(bRunTimes, 1);
      a.value = 2;
      expect(bRunTimes, 2);
      stopEffect.stop();
      a.value = 3;
      expect(bRunTimes, 2);
    });

    test('should not run untracked inner effect', () {
      final a = signal(3);
      final b = computed((p) => a() > 0);

      effect(() {
        if (b()) {
          effect(() {
            if (a() == 0) {
              throw Exception("bad");
            }
          });
        }
      });

      a.value = 2;
      a.value = 1;
      a.value = 0;
    });

    test('should run outer effect first', () {
      final a = signal(1);
      final b = signal(1);

      effect(() {
        if (a() != 0) {
          effect(() {
            b();
            if (a() == 0) {
              throw Exception("bad");
            }
          });
        }
      });

      startBatch();
      b.value = 0;
      a.value = 0;
      endBatch();
    });

    test('should not trigger inner effect when resolve maybe dirty', () {
      final a = signal(0);
      final b = computed((p) => a() % 2);

      int innerTriggerTimes = 0;

      effect(() {
        effect(() {
          b();
          innerTriggerTimes++;
          if (innerTriggerTimes >= 2) {
            throw Exception("bad");
          }
        });
      });

      a.value = 2;
    });

    test('should handle flags are indirectly updated during checkDirty', () {
      final a = signal(false);
      final b = computed((p) => a());
      final c = computed((p) {
        b();
        return 0;
      });
      final d = computed((p) {
        c();
        return b();
      });

      int triggers = 0;

      effect(() {
        d();
        triggers++;
      });
      expect(triggers, 1);
      a.value = true;
      expect(triggers, 2);
    });
  });

  group('EffectScope', () {
    test('should stop all effects when stopped', () {
      final s = signal(0);
      int runCount1 = 0;
      int runCount2 = 0;

      final scope = effectScope(() {
        effect(() {
          s();
          runCount1++;
        });
        effect(() {
          s();
          runCount2++;
        });
      });

      expect(runCount1, 1);
      expect(runCount2, 1);

      s.value = 1;
      expect(runCount1, 2);
      expect(runCount2, 2);

      scope.stop();
      s.value = 2;
      expect(runCount1, 2);
      expect(runCount2, 2);
    });

    test('should support nested scopes', () {
      final s = signal(0);
      int runCount = 0;

      final outerScope = effectScope(() {
        effectScope(() {
          effect(() {
            s();
            runCount++;
          });
        });
      });

      expect(runCount, 1);
      s.value = 1;
      expect(runCount, 2);

      outerScope.stop();
      s.value = 2;
      expect(runCount, 2);
    });

    // From effectScope.spec.ts
    test('should dispose inner effects if created in an effect', () {
      final source = signal(1);

      int triggers = 0;

      effect(() {
        final dispose = effectScope(() {
          effect(() {
            source();
            triggers++;
          });
        });
        expect(triggers, 1);

        source.value = 2;
        expect(triggers, 2);
        dispose.stop();
        source.value = 3;
        expect(triggers, 2);
      });
    });

    test(
        'should track signal updates in inner scope when accessed by outer effect',
        () {
      final source = signal(1);

      int triggers = 0;

      effect(() {
        effectScope(() {
          source();
        });
        triggers++;
      });

      expect(triggers, 1);
      source.value = 2;
      expect(triggers, 2);
    });
  });

  group('Batch', () {
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
  });

  group('Untrack', () {
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

    // From untrack.spec.ts
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

  group('Trigger', () {
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

    // From trigger.spec.ts
    test('should not throw when triggering with no dependencies', () {
      trigger(() {});
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

  group('Type checks', () {
    test('isSignal should work', () {
      final s = signal(1);
      expect(isSignal(s), true);
      expect(isSignal(computed((p) => 1)), false);
      expect(isSignal(effect(() {})), false);
    });

    test('isComputed should work', () {
      final c = computed((p) => 1);
      expect(isComputed(c), true);
      expect(isComputed(signal(1)), false);
    });

    test('isEffect should work', () {
      final e = effect(() {});
      expect(isEffect(e), true);
      expect(isEffect(signal(1)), false);
    });

    test('isEffectScope should work', () {
      final scope = effectScope(() {});
      expect(isEffectScope(scope), true);
      expect(isEffectScope(signal(1)), false);
    });
  });

  group('Graph updates (from topology.spec.ts)', () {
    test('should drop A->B->A updates', () {
      final a = signal(2);
      final b = computed((p) => a() - 1);
      final c = computed((p) => a() + b());

      int computeCount = 0;
      final d = computed((p) {
        computeCount++;
        return 'd: ${c()}';
      });

      expect(d(), 'd: 3');
      expect(computeCount, 1);
      computeCount = 0;

      a.value = 4;
      d();
      expect(computeCount, 1);
    });

    test('should only update every signal once (diamond graph)', () {
      final a = signal('a');
      final b = computed((p) => a());
      final c = computed((p) => a());

      int spyCount = 0;
      final d = computed((p) {
        spyCount++;
        return '${b()} ${c()}';
      });

      expect(d(), 'a a');
      expect(spyCount, 1);

      a.value = 'aa';
      expect(d(), 'aa aa');
      expect(spyCount, 2);
    });

    test('should only update every signal once (diamond graph + tail)', () {
      final a = signal('a');
      final b = computed((p) => a());
      final c = computed((p) => a());

      final d = computed((p) => '${b()} ${c()}');

      int spyCount = 0;
      final e = computed((p) {
        spyCount++;
        return d();
      });

      expect(e(), 'a a');
      expect(spyCount, 1);

      a.value = 'aa';
      expect(e(), 'aa aa');
      expect(spyCount, 2);
    });

    test('should bail out if result is the same', () {
      final a = signal('a');
      final b = computed((p) {
        a();
        return 'foo';
      });

      int spyCount = 0;
      final c = computed((p) {
        spyCount++;
        return b();
      });

      expect(c(), 'foo');
      expect(spyCount, 1);

      a.value = 'aa';
      expect(c(), 'foo');
      expect(spyCount, 1);
    });

    test('should support lazy branches', () {
      final a = signal(0);
      final b = computed((p) => a());
      final c = computed((p) => a() > 0 ? a() : b());

      expect(c(), 0);
      a.value = 1;
      expect(c(), 1);

      a.value = 0;
      expect(c(), 0);
    });

    test('should not update a sub if all deps unmark it', () {
      final a = signal('a');
      final b = computed((p) {
        a();
        return 'b';
      });
      final c = computed((p) {
        a();
        return 'c';
      });

      int spyCount = 0;
      final d = computed((p) {
        spyCount++;
        return '${b()} ${c()}';
      });

      expect(d(), 'b c');
      spyCount = 0;

      a.value = 'aa';
      expect(spyCount, 0);
    });
  });

  group('Error handling', () {
    test('should keep graph consistent on errors during activation', () {
      final a = signal(0);
      final b = computed((p) {
        throw Exception('fail');
      });
      final c = computed((p) => a());

      expect(() => b(), throwsException);

      a.value = 1;
      expect(c(), 1);
    });

    test('should keep graph consistent on errors in computeds', () {
      final a = signal(0);
      final b = computed((p) {
        if (a() == 1) throw Exception('fail');
        return a();
      });
      final c = computed((p) => b());

      expect(c(), 0);

      a.value = 1;
      expect(() => b(), throwsException);

      a.value = 2;
      expect(c(), 2);
    });
  });

  group('Edge cases', () {
    test('should handle self-referential computed', () {
      final count = signal(0);
      int? lastValue;

      final c = computed<int>((int? prev) {
        lastValue = prev;
        return count();
      });

      expect(c(), 0);
      expect(lastValue, null);

      count.value = 1;
      expect(c(), 1);
      expect(lastValue, 0);
    });

    test('should handle long dependency chains', () {
      final source = signal(0);
      Computed<int> current = computed<int>((int? p) => source());

      for (int i = 0; i < 100; i++) {
        final prev = current;
        current = computed<int>((int? p) => prev() + 1);
      }

      expect(current(), 100);
      source.value = 1;
      expect(current(), 101);
    });

    test('should handle wide dependency trees', () {
      final source = signal(0);
      final computeds = List.generate(
        100,
        (i) => computed<int>((int? p) => source() + i),
      );

      int sum = 0;
      effect(() {
        sum = 0;
        for (final c in computeds) {
          sum += c();
        }
      });

      expect(sum, (99 * 100) ~/ 2);

      source.value = 1;
      expect(sum, (99 * 100) ~/ 2 + 100);
    });

    test('should handle nullable signal values', () {
      final s = signal<String?>(null);
      expect(s(), null);

      s.update('hello');
      expect(s(), 'hello');

      s.update(null);
      expect(s(), null);
    });
  });
}
