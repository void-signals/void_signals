import 'package:test/test.dart';
import 'package:void_signals/void_signals.dart';

void main() {
  group('Computed - Basic Operations', () {
    test('should compute value from signal', () {
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

      // Access again, should use cached value
      expect(c(), 2);
      expect(computeCount, 1);
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

      a.value = 3;
      expect(c(), 3);
      expect(prev, 2);
    });

    test('should work with nested computed', () {
      final a = signal(1);
      final b = computed((prev) => a() * 2);
      final c = computed((prev) => b() + 1);

      expect(c(), 3);
      a.value = 5;
      expect(c(), 11);
    });

    test('should handle hasSubscribers', () {
      final a = signal(1);
      final c = computed((prev) => a() * 2);

      expect(c.hasSubscribers, false);

      final eff = effect(() {
        c();
      });
      expect(c.hasSubscribers, true);

      eff.stop();
      expect(c.hasSubscribers, false);
    });

    test('peek should return cached value without recomputing', () {
      final a = signal(1);
      int computeCount = 0;
      final c = computed((prev) {
        computeCount++;
        return a() * 2;
      });

      // Initial compute
      expect(c(), 2);
      expect(computeCount, 1);

      // peek should return cached value
      expect(c.peek(), 2);
      expect(computeCount, 1);
    });

    test('toString should return readable format', () {
      final c = computed((prev) => 42);
      expect(c.toString(), 'Computed(42)');
    });
  });

  group('Computed - Propagation', () {
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

  group('Computed - Diamond Dependency', () {
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

  group('Computed - Lazy Branches', () {
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

    test('should handle conditional dependency changes', () {
      final condition = signal(true);
      final a = signal(1);
      final b = signal(2);
      final result = computed((p) => condition() ? a() : b());

      expect(result(), 1);

      a.value = 10;
      expect(result(), 10);

      // Switch condition
      condition.value = false;
      expect(result(), 2);

      // a changes should not affect result now
      a.value = 100;
      expect(result(), 2);

      // b changes should affect result
      b.value = 20;
      expect(result(), 20);
    });
  });

  group('Computed - Error Handling', () {
    test('should throw error in computed', () {
      final a = signal(0);
      final c = computed((p) {
        if (a() == 1) throw Exception('fail');
        return a();
      });

      expect(c(), 0);

      a.value = 1;
      expect(() => c(), throwsException);

      a.value = 2;
      expect(c(), 2);
    });

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
  });

  group('Computed - Long Chains', () {
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
      for (final c in computeds) {
        sum += c();
      }

      expect(sum, (99 * 100) ~/ 2);

      source.value = 1;
      sum = 0;
      for (final c in computeds) {
        sum += c();
      }
      expect(sum, (99 * 100) ~/ 2 + 100);
    });
  });
}
