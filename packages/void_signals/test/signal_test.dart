import 'package:test/test.dart';
import 'package:void_signals/void_signals.dart';

void main() {
  group('Signal - Basic Operations', () {
    test('should create signal with initial value', () {
      final s = signal(1);
      expect(s(), 1);
      expect(s.value, 1);
    });

    test('should update signal value with setter', () {
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

      // Peek returns currentValue (not pendingValue)
      expect(s.peek(), 1);

      // Verify peek inside effect doesn't track
      int effectCount = 0;
      final eff = effect(() {
        effectCount++;
        s.peek(); // Use peek, not value - shouldn't track
      });

      expect(effectCount, 1);

      // After effect runs once, currentValue is synced
      expect(s.peek(), 1);

      // Change value - effect should NOT re-run because peek doesn't track
      s.value = 3;
      expect(effectCount, 1); // Effect should not have re-run

      // Use value getter which tracks and triggers flush
      final trackingEffect = effect(() {
        s.value; // This tracks
      });

      // Now peek returns updated value after flush
      expect(s.peek(), 3);

      eff.stop();
      trackingEffect.stop();
    });

    test('should track hasSubscribers correctly', () {
      final s = signal(1);
      expect(s.hasSubscribers, false);

      final eff = effect(() {
        s();
      });
      expect(s.hasSubscribers, true);

      eff.stop();
      expect(s.hasSubscribers, false);
    });

    test('should not notify if value is the same', () {
      final s = signal(1);
      int runCount = 0;

      effect(() {
        s();
        runCount++;
      });

      expect(runCount, 1);

      // Set same value
      s.value = 1;
      expect(runCount, 1); // Should not trigger
    });

    test('should work with nullable values', () {
      final s = signal<String?>(null);
      expect(s(), null);

      s.update('hello');
      expect(s(), 'hello');

      s.update(null);
      expect(s(), null);
    });

    test('should work with complex objects', () {
      final s = signal({'name': 'John', 'age': 30});
      expect(s()['name'], 'John');

      s.value = {'name': 'Jane', 'age': 25};
      expect(s()['name'], 'Jane');
    });

    test('toString should return readable format', () {
      final s = signal(42);
      expect(s.toString(), 'Signal(42)');
    });
  });

  group('Signal - Edge Cases', () {
    test('should handle empty string', () {
      final s = signal('');
      expect(s(), '');

      s.value = 'hello';
      expect(s(), 'hello');
    });

    test('should handle negative numbers', () {
      final s = signal(-1);
      expect(s(), -1);

      s.value = -100;
      expect(s(), -100);
    });

    test('should handle boolean values', () {
      final s = signal(false);
      expect(s(), false);

      s.value = true;
      expect(s(), true);
    });

    test('should handle list values', () {
      final s = signal([1, 2, 3]);
      expect(s(), [1, 2, 3]);

      s.value = [4, 5];
      expect(s(), [4, 5]);
    });

    test('should handle empty list', () {
      final s = signal<List<int>>([]);
      expect(s(), isEmpty);

      s.value = [1];
      expect(s(), [1]);
    });

    test('should handle double/float values', () {
      final s = signal(3.14);
      expect(s(), 3.14);

      s.value = 2.718;
      expect(s(), 2.718);
    });
  });
}
