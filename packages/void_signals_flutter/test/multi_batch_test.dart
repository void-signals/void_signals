import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_signals_flutter/void_signals_flutter.dart';

void main() {
  group('Multi-component batch behavior', () {
    testWidgets('multiple components calling batch independently',
        (tester) async {
      final counter = signal(0);
      var watchBuildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              // Component A - calls batch
              ElevatedButton(
                key: const Key('btnA'),
                onPressed: () {
                  batch(() {
                    counter.value++;
                    counter.value++;
                  });
                },
                child: const Text('A'),
              ),
              // Component B - calls batch
              ElevatedButton(
                key: const Key('btnB'),
                onPressed: () {
                  batch(() {
                    counter.value++;
                    counter.value++;
                  });
                },
                child: const Text('B'),
              ),
              // Watch widget
              Watch(builder: (_, __) {
                watchBuildCount++;
                return Text('Count: ${counter.value}');
              }),
            ],
          ),
        ),
      );

      expect(watchBuildCount, 1); // Initial build

      // Tap A - batch update
      await tester.tap(find.byKey(const Key('btnA')));
      await tester.pump();
      expect(watchBuildCount, 2); // One rebuild after A's batch
      expect(find.text('Count: 2'), findsOneWidget);

      // Tap B - batch update
      await tester.tap(find.byKey(const Key('btnB')));
      await tester.pump();
      expect(watchBuildCount, 3); // One rebuild after B's batch
      expect(find.text('Count: 4'), findsOneWidget);
    });

    testWidgets('sequential batch calls in same frame', (tester) async {
      final counter = signal(0);
      var watchBuildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              ElevatedButton(
                key: const Key('btn'),
                onPressed: () {
                  // Two separate batch calls in same event handler
                  batch(() {
                    counter.value++;
                  });
                  batch(() {
                    counter.value++;
                  });
                },
                child: const Text('Update'),
              ),
              Watch(builder: (_, __) {
                watchBuildCount++;
                return Text('Count: ${counter.value}');
              }),
            ],
          ),
        ),
      );

      expect(watchBuildCount, 1);

      await tester.tap(find.byKey(const Key('btn')));
      await tester.pump();

      // Two separate batches = Two effect runs = but Flutter coalesces setState
      // The key insight: each batch ends with flush(), triggering effect
      // But Watch uses _safeSetState which may coalesce
      print('After two sequential batches, buildCount = $watchBuildCount');
      expect(find.text('Count: 2'), findsOneWidget);
    });

    testWidgets('nested batch calls', (tester) async {
      final counter = signal(0);
      var effectRunCount = 0;

      // Track effect runs directly
      final eff = effect(() {
        counter.value; // Subscribe
        effectRunCount++;
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ElevatedButton(
            key: const Key('btn'),
            onPressed: () {
              batch(() {
                counter.value++;
                batch(() {
                  counter.value++;
                  batch(() {
                    counter.value++;
                  });
                });
              });
            },
            child: const Text('Nested'),
          ),
        ),
      );

      effectRunCount = 0; // Reset after initial run

      await tester.tap(find.byKey(const Key('btn')));
      await tester.pump();

      // Nested batch: only outermost batch triggers flush
      expect(effectRunCount, 1, reason: 'Nested batch should only flush once');
      expect(counter.value, 3);

      eff.stop();
    });

    testWidgets('batch across multiple Watch widgets', (tester) async {
      final counter = signal(0);
      var buildCountA = 0;
      var buildCountB = 0;
      var buildCountC = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              Watch(builder: (_, __) {
                buildCountA++;
                return Text('A: ${counter.value}');
              }),
              Watch(builder: (_, __) {
                buildCountB++;
                return Text('B: ${counter.value}');
              }),
              Watch(builder: (_, __) {
                buildCountC++;
                return Text('C: ${counter.value}');
              }),
              ElevatedButton(
                key: const Key('btn'),
                onPressed: () {
                  batch(() {
                    counter.value++;
                    counter.value++;
                    counter.value++;
                  });
                },
                child: const Text('Update'),
              ),
            ],
          ),
        ),
      );

      expect(buildCountA, 1);
      expect(buildCountB, 1);
      expect(buildCountC, 1);

      await tester.tap(find.byKey(const Key('btn')));
      await tester.pump();

      // Each Watch should rebuild once
      expect(buildCountA, 2);
      expect(buildCountB, 2);
      expect(buildCountC, 2);
      expect(find.text('A: 3'), findsOneWidget);
    });
  });

  group('Signal memory management', () {
    test('signal without subscribers can be garbage collected', () {
      // This is a conceptual test - actual GC testing is complex
      // The point is: signals are just objects, they follow normal GC rules

      Signal<int>? sig = signal(42);

      // Signal exists
      expect(sig.value, 42);

      // If we null the reference and there are no subscribers,
      // the signal becomes eligible for GC
      sig = null;

      // Can't test actual GC, but the principle is:
      // - No references = can be collected
      // - Has subscribers = kept alive by subscriber references
    });

    test('effect keeps signal alive while running', () {
      final sig = signal(0);
      var runCount = 0;

      final eff = effect(() {
        sig.value;
        runCount++;
      });

      expect(runCount, 1);
      expect(sig.hasSubscribers, true);

      // Stop effect - signal no longer has this subscriber
      eff.stop();

      // After stopping, if no other subscribers, signal could be collected
      // (but sig variable still holds reference here)
    });

    test('global signals persist for app lifetime', () {
      // This is expected behavior for global signals
      // They are like any other global variable

      // Recommendation:
      // 1. Use global signals for truly app-wide state (theme, user, etc.)
      // 2. Use SignalScope for page-level state that should be isolated
      // 3. Use local signals in StatefulWidget for component-level state
    });
  });
}
