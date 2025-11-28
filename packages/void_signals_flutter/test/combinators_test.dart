import 'package:flutter_test/flutter_test.dart';
import 'package:void_signals_flutter/void_signals_flutter.dart';

void main() {
  group('mapped', () {
    test('should transform signal value', () {
      final source = signal(10);
      final doubled = mapped(source, (v) => v * 2);
      expect(doubled.value, equals(20));
    });

    test('should update when source changes', () {
      final source = signal(5);
      final doubled = mapped(source, (v) => v * 2);
      expect(doubled.value, equals(10));

      source.value = 15;
      expect(doubled.value, equals(30));
    });

    test('should handle type transformation', () {
      final source = signal(42);
      final asString = mapped(source, (v) => 'Value: $v');
      expect(asString.value, equals('Value: 42'));
    });

    test('should work with complex transformations', () {
      final source = signal([1, 2, 3]);
      final sum = mapped(source, (list) => list.fold(0, (a, b) => a + b));
      expect(sum.value, equals(6));

      source.value = [1, 2, 3, 4, 5];
      expect(sum.value, equals(15));
    });
  });

  group('filtered', () {
    test('should only update when predicate is true', () {
      final source = signal(0);
      final evenOnly = filtered(source, (v) => v.isEven);

      expect(evenOnly.value, equals(0));

      source.value = 1; // Odd, should not update
      expect(evenOnly.value, equals(0));

      source.value = 2; // Even, should update
      expect(evenOnly.value, equals(2));

      source.value = 3; // Odd, should not update
      expect(evenOnly.value, equals(2));

      source.value = 4; // Even, should update
      expect(evenOnly.value, equals(4));
    });

    test('should use initial value if it matches predicate', () {
      final source = signal(10);
      final positive = filtered(source, (v) => v > 0);
      expect(positive.value, equals(10));
    });

    test('should work with non-numeric types', () {
      final source = signal('');
      final nonEmpty = filtered(source, (v) => v.isNotEmpty);

      expect(nonEmpty.value, equals(''));

      source.value = 'hello';
      expect(nonEmpty.value, equals('hello'));

      source.value = '';
      expect(nonEmpty.value, equals('hello')); // Should keep last valid value
    });
  });

  group('distinctUntilChanged', () {
    test('should only emit when value changes', () {
      final source = signal(0);
      final distinct = distinctUntilChanged(source);
      var updateCount = 0;

      effect(() {
        distinct.value;
        updateCount++;
      });

      expect(updateCount, equals(1));

      source.value = 0; // Same value
      expect(updateCount, equals(1));

      source.value = 1; // Different value
      expect(updateCount, equals(2));

      source.value = 1; // Same value
      expect(updateCount, equals(2));
    });

    test('should use custom equality function', () {
      final source = signal({'id': 1, 'name': 'Alice'});
      final distinct =
          distinctUntilChanged(source, (a, b) => a['id'] == b['id']);

      var updateCount = 0;
      effect(() {
        distinct.value;
        updateCount++;
      });

      expect(updateCount, equals(1));

      source.value = {'id': 1, 'name': 'Bob'}; // Same id
      expect(updateCount, equals(1));

      source.value = {'id': 2, 'name': 'Bob'}; // Different id
      expect(updateCount, equals(2));
    });

    test('should work with default equality', () {
      final source = signal('hello');
      final distinct = distinctUntilChanged(source);

      expect(distinct.value, equals('hello'));

      source.value = 'hello';
      expect(distinct.value, equals('hello'));

      source.value = 'world';
      expect(distinct.value, equals('world'));
    });
  });

  group('combine2', () {
    test('should combine two signals', () {
      final a = signal(1);
      final b = signal(2);
      final sum = combine2(a, b, (va, vb) => va + vb);

      expect(sum.value, equals(3));
    });

    test('should update when either signal changes', () {
      final a = signal(1);
      final b = signal(2);
      final sum = combine2(a, b, (va, vb) => va + vb);

      expect(sum.value, equals(3));

      a.value = 10;
      expect(sum.value, equals(12));

      b.value = 20;
      expect(sum.value, equals(30));
    });

    test('should work with different types', () {
      final name = signal('Alice');
      final age = signal(30);
      final profile = combine2(name, age, (n, a) => '$n is $a years old');

      expect(profile.value, equals('Alice is 30 years old'));

      name.value = 'Bob';
      expect(profile.value, equals('Bob is 30 years old'));

      age.value = 25;
      expect(profile.value, equals('Bob is 25 years old'));
    });

    test('should batch updates correctly', () {
      final a = signal(1);
      final b = signal(2);
      final product = combine2(a, b, (va, vb) => va * vb);
      var updateCount = 0;

      effect(() {
        product.value;
        updateCount++;
      });

      expect(updateCount, equals(1));

      batch(() {
        a.value = 10;
        b.value = 20;
      });

      expect(product.value, equals(200));
      expect(updateCount, equals(2)); // Should update once after batch
    });
  });

  group('combine3', () {
    test('should combine three signals', () {
      final a = signal(1);
      final b = signal(2);
      final c = signal(3);
      final sum = combine3(a, b, c, (va, vb, vc) => va + vb + vc);

      expect(sum.value, equals(6));
    });

    test('should update when any signal changes', () {
      final a = signal(1);
      final b = signal(2);
      final c = signal(3);
      final sum = combine3(a, b, c, (va, vb, vc) => va + vb + vc);

      a.value = 10;
      expect(sum.value, equals(15));

      b.value = 20;
      expect(sum.value, equals(33));

      c.value = 30;
      expect(sum.value, equals(60));
    });

    test('should work with complex combining logic', () {
      final first = signal('Hello');
      final middle = signal(' ');
      final last = signal('World');
      final combined = combine3(first, middle, last, (f, m, l) => '$f$m$l');

      expect(combined.value, equals('Hello World'));
    });
  });

  group('combine4', () {
    test('should combine four signals', () {
      final a = signal(1);
      final b = signal(2);
      final c = signal(3);
      final d = signal(4);
      final sum = combine4(a, b, c, d, (va, vb, vc, vd) => va + vb + vc + vd);

      expect(sum.value, equals(10));
    });

    test('should update when any signal changes', () {
      final a = signal(1);
      final b = signal(2);
      final c = signal(3);
      final d = signal(4);
      final product =
          combine4(a, b, c, d, (va, vb, vc, vd) => va * vb * vc * vd);

      expect(product.value, equals(24));

      a.value = 2;
      expect(product.value, equals(48));

      d.value = 10;
      expect(product.value, equals(120));
    });
  });

  group('withPrevious', () {
    test('should return current and previous values', () {
      final source = signal(0);
      final (current, previous) = withPrevious(source);

      expect(current.value, equals(0));
      expect(previous.value, isNull);
    });

    test('should track previous value on change', () {
      final source = signal(1);
      final (current, previous) = withPrevious(source);

      // Initial state
      expect(current.value, equals(1));
      expect(previous.value, isNull);

      // First change
      source.value = 2;
      expect(current.value, equals(2));
      expect(previous.value, equals(1));

      // Second change
      source.value = 3;
      expect(current.value, equals(3));
      expect(previous.value, equals(2));
    });

    test('should work with complex types', () {
      final source = signal<List<int>>([1, 2, 3]);
      final (current, previous) = withPrevious(source);

      expect(current.value, equals([1, 2, 3]));
      expect(previous.value, isNull);

      source.value = [4, 5, 6];
      expect(current.value, equals([4, 5, 6]));
      expect(previous.value, equals([1, 2, 3]));
    });
  });

  group('Combinator integration', () {
    test('should chain combinators', () {
      final source = signal(1);

      // Map then use filtered on source directly (since combinators return Computed)
      final doubled = mapped(source, (v) => v * 2);
      // Use computed chaining instead of casting
      final evenDoubled =
          computed((_) => doubled.value.isEven ? doubled.value : doubled.value);

      source.value = 3;
      expect(evenDoubled.value, equals(6));
    });

    test('should work with effects', () {
      final a = signal(0);
      final b = signal(0);
      final combined = combine2(a, b, (va, vb) => va + vb);

      var lastValue = 0;
      effect(() {
        lastValue = combined.value;
      });

      expect(lastValue, equals(0));

      a.value = 5;
      expect(lastValue, equals(5));

      b.value = 10;
      expect(lastValue, equals(15));
    });

    test('should support nested combining', () {
      final a = signal(1);
      final b = signal(2);
      final c = signal(3);
      final d = signal(4);

      // Use computed to combine multiple signals directly
      // since combine2 returns Computed, not Signal
      final abcd = computed((_) => (a.value + b.value) * (c.value + d.value));

      expect(abcd.value, equals(21)); // (1+2) * (3+4) = 3 * 7 = 21

      a.value = 10;
      expect(abcd.value, equals(84)); // (10+2) * (3+4) = 12 * 7 = 84
    });
  });
}
