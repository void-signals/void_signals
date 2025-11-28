import 'package:test/test.dart';
import 'package:void_signals/void_signals.dart';

void main() {
  group('Effect - Basic Operations', () {
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

    test('toString should return readable format', () {
      final eff = effect(() {});
      expect(eff.toString(), 'Effect');
    });
  });

  group('Effect - Cleanup', () {
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

    test('should handle multiple effects on same signal', () {
      final s = signal(0);
      int runCount1 = 0;
      int runCount2 = 0;

      final eff1 = effect(() {
        s();
        runCount1++;
      });

      final eff2 = effect(() {
        s();
        runCount2++;
      });

      expect(runCount1, 1);
      expect(runCount2, 1);

      s.value = 1;
      expect(runCount1, 2);
      expect(runCount2, 2);

      eff1.stop();
      s.value = 2;
      expect(runCount1, 2);
      expect(runCount2, 3);

      eff2.stop();
    });
  });

  group('Effect - Nested Effects', () {
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

  group('Effect - Conditional Dependencies', () {
    test('should handle conditional dependencies', () {
      final condition = signal(true);
      final a = signal(1);
      final b = signal(2);
      int runCount = 0;
      int? lastValue;

      effect(() {
        runCount++;
        lastValue = condition() ? a() : b();
      });

      expect(runCount, 1);
      expect(lastValue, 1);

      // a changes should trigger when condition is true
      a.value = 10;
      expect(runCount, 2);
      expect(lastValue, 10);

      // b changes should NOT trigger when condition is true
      b.value = 20;
      expect(runCount, 2);

      // Switch condition
      condition.value = false;
      expect(runCount, 3);
      expect(lastValue, 20);

      // Now a changes should NOT trigger
      a.value = 100;
      expect(runCount, 3);

      // But b changes should trigger
      b.value = 30;
      expect(runCount, 4);
      expect(lastValue, 30);
    });
  });

  group('Effect - Multiple Dependencies', () {
    test('should track multiple dependencies', () {
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

      a.value = 10;
      expect(runCount, 2);

      b.value = 20;
      expect(runCount, 3);

      c.value = 30;
      expect(runCount, 4);
    });

    test('should only run once per batch even with multiple deps', () {
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
  });
}
