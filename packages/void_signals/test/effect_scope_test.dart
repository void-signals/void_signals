import 'package:test/test.dart';
import 'package:void_signals/void_signals.dart';

void main() {
  group('EffectScope - Basic Operations', () {
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

    test('toString should return readable format', () {
      final scope = effectScope(() {});
      expect(scope.toString(), 'EffectScope');
    });
  });

  group('EffectScope - Dispose Behavior', () {
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

  group('EffectScope - Multiple Scopes', () {
    test('should handle multiple independent scopes', () {
      final s = signal(0);
      int runCount1 = 0;
      int runCount2 = 0;

      final scope1 = effectScope(() {
        effect(() {
          s();
          runCount1++;
        });
      });

      final scope2 = effectScope(() {
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

      // Stop only scope1
      scope1.stop();
      s.value = 2;
      expect(runCount1, 2);
      expect(runCount2, 3);

      scope2.stop();
      s.value = 3;
      expect(runCount1, 2);
      expect(runCount2, 3);
    });

    test('should handle scope with computed', () {
      final a = signal(1);
      final b = computed((p) => a() * 2);
      int runCount = 0;

      final scope = effectScope(() {
        effect(() {
          b();
          runCount++;
        });
      });

      expect(runCount, 1);

      a.value = 2;
      expect(runCount, 2);

      scope.stop();
      a.value = 3;
      expect(runCount, 2);
    });
  });

  group('EffectScope - Edge Cases', () {
    test('should handle empty scope', () {
      final scope = effectScope(() {});
      expect(() => scope.stop(), returnsNormally);
    });

    test('should handle scope with multiple computeds', () {
      final a = signal(1);
      final b = signal(2);
      final sum = computed((p) => a() + b());
      final product = computed((p) => a() * b());
      int runCount = 0;

      final scope = effectScope(() {
        effect(() {
          sum();
          product();
          runCount++;
        });
      });

      expect(runCount, 1);

      a.value = 3;
      expect(runCount, 2);

      scope.stop();
      a.value = 4;
      expect(runCount, 2);
    });

    test('should not affect effects outside scope', () {
      final s = signal(0);
      int outsideCount = 0;
      int insideCount = 0;

      final outsideEffect = effect(() {
        s();
        outsideCount++;
      });

      final scope = effectScope(() {
        effect(() {
          s();
          insideCount++;
        });
      });

      expect(outsideCount, 1);
      expect(insideCount, 1);

      s.value = 1;
      expect(outsideCount, 2);
      expect(insideCount, 2);

      scope.stop();
      s.value = 2;
      expect(outsideCount, 3);
      expect(insideCount, 2);

      outsideEffect.stop();
    });
  });
}
