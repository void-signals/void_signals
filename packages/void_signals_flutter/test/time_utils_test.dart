import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_signals_flutter/void_signals_flutter.dart';

void main() {
  group('debounced', () {
    test('should have initial value from source', () {
      final source = signal('initial');
      final debounced_ = debounced(source, const Duration(milliseconds: 100));

      expect(debounced_.value, equals('initial'));

      debounced_.dispose();
    });

    test('should not update immediately when source changes', () async {
      final source = signal(0);
      final debounced_ = debounced(source, const Duration(milliseconds: 100));

      expect(debounced_.value, equals(0));

      source.value = 1;
      expect(debounced_.value, equals(0)); // Should still be 0

      debounced_.dispose();
    });

    test('should update after delay', () async {
      final source = signal(0);
      final debounced_ = debounced(source, const Duration(milliseconds: 50));

      source.value = 1;
      expect(debounced_.value, equals(0));

      // Wait for debounce delay
      await Future.delayed(const Duration(milliseconds: 100));

      expect(debounced_.value, equals(1));

      debounced_.dispose();
    });

    test('should reset timer on rapid changes', () async {
      final source = signal(0);
      final debounced_ = debounced(source, const Duration(milliseconds: 100));

      source.value = 1;
      await Future.delayed(const Duration(milliseconds: 50));
      expect(debounced_.value, equals(0));

      source.value = 2; // Reset timer
      await Future.delayed(const Duration(milliseconds: 50));
      expect(debounced_.value, equals(0)); // Timer reset, still waiting

      source.value = 3; // Reset timer again
      await Future.delayed(const Duration(milliseconds: 150));
      expect(debounced_.value, equals(3)); // Now it should have updated

      debounced_.dispose();
    });

    test('should track debounced signal in effects', () async {
      final source = signal('');
      final debounced_ = debounced(source, const Duration(milliseconds: 50));
      final values = <String>[];

      final eff = effect(() {
        values.add(debounced_.value);
      });

      expect(values, equals(['']));

      source.value = 'hello';
      await Future.delayed(const Duration(milliseconds: 100));

      expect(values.last, equals('hello'));

      eff.stop();
      debounced_.dispose();
    });

    test('should cleanup on dispose', () async {
      final source = signal(0);
      final debounced_ = debounced(source, const Duration(milliseconds: 50));

      source.value = 1;
      debounced_.dispose();

      // Wait for what would have been the timer
      await Future.delayed(const Duration(milliseconds: 100));

      // Value should still be 0 since we disposed before timer fired
      expect(debounced_.value, equals(0));
    });
  });

  group('throttled', () {
    test('should have initial value from source', () {
      final source = signal('initial');
      final throttled_ = throttled(source, const Duration(milliseconds: 100));

      expect(throttled_.value, equals('initial'));

      throttled_.dispose();
    });

    test('should update immediately on first change', () {
      final source = signal(0);
      final throttled_ = throttled(source, const Duration(milliseconds: 100));

      source.value = 1;
      expect(throttled_.value, equals(1)); // Should update immediately

      throttled_.dispose();
    });

    test('should throttle rapid changes', () async {
      final source = signal(0);
      final throttled_ = throttled(source, const Duration(milliseconds: 100));

      source.value = 1; // First update - immediate
      expect(throttled_.value, equals(1));

      source.value = 2; // Within throttle window
      expect(throttled_.value, equals(1)); // Should still be 1

      source.value = 3; // Still within window
      expect(throttled_.value, equals(1)); // Should still be 1

      // Wait for throttle window to pass
      await Future.delayed(const Duration(milliseconds: 150));

      // Last value should be applied as trailing update
      expect(throttled_.value, equals(3));

      throttled_.dispose();
    });

    test('should allow update after throttle window', () async {
      final source = signal(0);
      final throttled_ = throttled(source, const Duration(milliseconds: 50));

      source.value = 1;
      expect(throttled_.value, equals(1));

      // Wait for throttle window
      await Future.delayed(const Duration(milliseconds: 100));

      source.value = 2;
      expect(throttled_.value, equals(2)); // Should update immediately

      throttled_.dispose();
    });

    test('should track throttled signal in effects', () async {
      final source = signal(0);
      final throttled_ = throttled(source, const Duration(milliseconds: 50));
      final values = <int>[];

      final eff = effect(() {
        values.add(throttled_.value);
      });

      expect(values, equals([0]));

      source.value = 1;
      expect(values.last, equals(1));

      source.value = 2;
      source.value = 3;
      // Should not have updated yet due to throttle
      expect(values.last, equals(1));

      await Future.delayed(const Duration(milliseconds: 100));
      expect(values.last, equals(3)); // Trailing update

      eff.stop();
      throttled_.dispose();
    });

    test('should cleanup on dispose', () async {
      final source = signal(0);
      final throttled_ = throttled(source, const Duration(milliseconds: 50));

      source.value = 1; // Immediate update
      source.value = 2; // Pending trailing update

      throttled_.dispose();

      // Wait for what would have been the trailing update
      await Future.delayed(const Duration(milliseconds: 100));

      // Value should be 1 (immediate update) since trailing was cancelled
      expect(throttled_.value, equals(1));
    });
  });

  group('delayed', () {
    test('should have initial value from source', () {
      final source = signal('initial');
      final delayed_ = delayed(source, const Duration(milliseconds: 100));

      expect(delayed_.value, equals('initial'));

      delayed_.dispose();
    });

    test('should delay all updates', () async {
      final source = signal(0);
      final delayed_ = delayed(source, const Duration(milliseconds: 50));

      source.value = 1;
      expect(delayed_.value, equals(0)); // Not updated yet

      await Future.delayed(const Duration(milliseconds: 100));
      expect(delayed_.value, equals(1));

      delayed_.dispose();
    });

    test('should delay each update independently', () async {
      final source = signal(0);
      final delayed_ = delayed(source, const Duration(milliseconds: 50));

      source.value = 1;
      expect(delayed_.value, equals(0));

      await Future.delayed(const Duration(milliseconds: 30));
      source.value = 2; // This resets the timer for the latest value
      expect(delayed_.value, equals(0)); // Still waiting

      await Future.delayed(const Duration(milliseconds: 30));
      // First update should have passed but was overwritten
      expect(delayed_.value, equals(0));

      await Future.delayed(const Duration(milliseconds: 30));
      expect(delayed_.value, equals(2)); // Now updated to latest

      delayed_.dispose();
    });

    test('should cleanup on dispose', () async {
      final source = signal(0);
      final delayed_ = delayed(source, const Duration(milliseconds: 50));

      source.value = 1;
      delayed_.dispose();

      await Future.delayed(const Duration(milliseconds: 100));
      expect(delayed_.value, equals(0)); // Should not have updated
    });
  });

  group('TimedSignal', () {
    test('should expose underlying signal', () {
      final source = signal(42);
      final debounced_ = debounced(source, const Duration(milliseconds: 100));

      expect(debounced_.signal, isA<Signal<int>>());
      expect(debounced_.signal.value, equals(42));

      debounced_.dispose();
    });

    test('should support callable syntax', () {
      final source = signal('test');
      final debounced_ = debounced(source, const Duration(milliseconds: 100));

      expect(debounced_(), equals('test'));

      debounced_.dispose();
    });
  });

  group('Integration with Watch widget', () {
    testWidgets('debounced should work with Watch', (tester) async {
      final source = signal('');
      final debounced_ = debounced(source, const Duration(milliseconds: 50));

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              Watch(
                  builder: (ctx, _) => Text('Debounced: ${debounced_.value}')),
            ],
          ),
        ),
      );

      expect(find.text('Debounced: '), findsOneWidget);

      source.value = 'hello';
      await tester.pump();
      expect(find.text('Debounced: '), findsOneWidget); // Not updated yet

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Debounced: hello'), findsOneWidget);

      debounced_.dispose();
    });

    testWidgets('throttled should work with Watch', (tester) async {
      final source = signal(0);
      final throttled_ = throttled(source, const Duration(milliseconds: 100));

      await tester.pumpWidget(
        MaterialApp(
          home: Watch(builder: (ctx, _) => Text('Value: ${throttled_.value}')),
        ),
      );

      expect(find.text('Value: 0'), findsOneWidget);

      source.value = 1;
      await tester.pump();
      expect(find.text('Value: 1'), findsOneWidget); // Immediate update

      source.value = 2;
      source.value = 3;
      await tester.pump();
      expect(find.text('Value: 1'), findsOneWidget); // Throttled

      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('Value: 3'), findsOneWidget); // Trailing update

      throttled_.dispose();
    });
  });
}
