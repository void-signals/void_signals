import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_signals_hooks/void_signals_hooks.dart';

void main() {
  group('useDebounced', () {
    testWidgets('should debounce signal updates', (tester) async {
      final sig = signal(0);
      int? debouncedValue;

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            final debounced =
                useDebounced(sig, const Duration(milliseconds: 100));
            debouncedValue = useWatchComputed(debounced);
            return Text('$debouncedValue', textDirection: TextDirection.ltr);
          },
        ),
      );

      // Initial value should be 0
      expect(debouncedValue, equals(0));

      // Update signal multiple times quickly
      sig.value = 1;
      sig.value = 2;
      sig.value = 3;

      // Value should not have changed yet (debouncing)
      await tester.pump();
      expect(debouncedValue, equals(0));

      // Wait for debounce duration
      await tester.pump(const Duration(milliseconds: 150));
      expect(debouncedValue, equals(3));
    });

    testWidgets('should update immediately on first value', (tester) async {
      final sig = signal(42);
      int? debouncedValue;

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            final debounced =
                useDebounced(sig, const Duration(milliseconds: 100));
            debouncedValue = useWatchComputed(debounced);
            return Text('$debouncedValue', textDirection: TextDirection.ltr);
          },
        ),
      );

      expect(debouncedValue, equals(42));
    });

    testWidgets('should dispose correctly', (tester) async {
      final sig = signal(0);

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            useDebounced(sig, const Duration(milliseconds: 100));
            return const SizedBox();
          },
        ),
      );

      // Unmount widget
      await tester.pumpWidget(const SizedBox());

      // No exception should be thrown
      sig.value = 1;
      await tester.pump(const Duration(milliseconds: 150));
    });
  });

  group('useThrottled', () {
    testWidgets('should return initial value', (tester) async {
      final sig = signal(42);
      int? throttledValue;

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            final throttled =
                useThrottled(sig, const Duration(milliseconds: 100));
            throttledValue = useWatchComputed(throttled);
            return Text('$throttledValue', textDirection: TextDirection.ltr);
          },
        ),
      );

      expect(throttledValue, equals(42));
    });

    testWidgets('should dispose correctly', (tester) async {
      final sig = signal(0);

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            useThrottled(sig, const Duration(milliseconds: 100));
            return const SizedBox();
          },
        ),
      );

      // Unmount widget
      await tester.pumpWidget(const SizedBox());

      // No exception should be thrown
      sig.value = 1;
      await tester.pump(const Duration(milliseconds: 150));
    });

    testWidgets('should update hook when source changes', (tester) async {
      final sig1 = signal(1);
      final sig2 = signal(100);
      var sourceSignal = sig1;
      int? throttledValue;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return HookBuilder(
              builder: (context) {
                final throttled = useThrottled(
                    sourceSignal, const Duration(milliseconds: 100));
                throttledValue = useWatchComputed(throttled);
                return GestureDetector(
                  onTap: () => setState(() => sourceSignal = sig2),
                  child:
                      Text('$throttledValue', textDirection: TextDirection.ltr),
                );
              },
            );
          },
        ),
      );

      expect(throttledValue, equals(1));

      // Tap to switch signal source
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();
      expect(throttledValue, equals(100));
    });
  });

  group('useCombine2', () {
    testWidgets('should combine two signals', (tester) async {
      final signal1 = signal(1);
      final signal2 = signal(2);
      int? combinedValue;

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            final combined = useCombine2(signal1, signal2, (a, b) => a + b);
            combinedValue = useWatchComputed(combined);
            return Text('$combinedValue', textDirection: TextDirection.ltr);
          },
        ),
      );

      expect(combinedValue, equals(3));

      signal1.value = 10;
      await tester.pump();
      expect(combinedValue, equals(12));

      signal2.value = 20;
      await tester.pump();
      expect(combinedValue, equals(30));
    });
  });

  group('useCombine3', () {
    testWidgets('should combine three signals', (tester) async {
      final signal1 = signal(1);
      final signal2 = signal(2);
      final signal3 = signal(3);
      int? combinedValue;

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            final combined =
                useCombine3(signal1, signal2, signal3, (a, b, c) => a + b + c);
            combinedValue = useWatchComputed(combined);
            return Text('$combinedValue', textDirection: TextDirection.ltr);
          },
        ),
      );

      expect(combinedValue, equals(6));

      signal1.value = 10;
      await tester.pump();
      expect(combinedValue, equals(15));

      signal2.value = 20;
      await tester.pump();
      expect(combinedValue, equals(33));

      signal3.value = 30;
      await tester.pump();
      expect(combinedValue, equals(60));
    });
  });

  group('usePrevious', () {
    testWidgets('should track previous value', (tester) async {
      final sig = signal(0);
      int? currentValue;
      int? previousValue;

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            final (current, previous) = usePrevious(sig);
            currentValue = useWatchComputed(current);
            previousValue = useWatchComputed(previous);
            return Text('$currentValue', textDirection: TextDirection.ltr);
          },
        ),
      );

      // Initially, previous value should be null
      expect(currentValue, equals(0));
      expect(previousValue, isNull);

      sig.value = 1;
      await tester.pump();
      expect(currentValue, equals(1));
      expect(previousValue, equals(0));

      sig.value = 2;
      await tester.pump();
      expect(currentValue, equals(2));
      expect(previousValue, equals(1));
    });

    testWidgets('should handle multiple updates', (tester) async {
      final sig = signal(10);
      int? currentValue;
      int? previousValue;

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            final (current, previous) = usePrevious(sig);
            currentValue = useWatchComputed(current);
            previousValue = useWatchComputed(previous);
            return Text('$currentValue', textDirection: TextDirection.ltr);
          },
        ),
      );

      expect(currentValue, equals(10));
      expect(previousValue, isNull);

      sig.value = 20;
      await tester.pump();
      expect(currentValue, equals(20));
      expect(previousValue, equals(10));

      sig.value = 30;
      await tester.pump();
      expect(currentValue, equals(30));
      expect(previousValue, equals(20));

      sig.value = 40;
      await tester.pump();
      expect(currentValue, equals(40));
      expect(previousValue, equals(30));
    });
  });
}
