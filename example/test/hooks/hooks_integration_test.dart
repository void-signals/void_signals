import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_signals_flutter/void_signals_flutter.dart';
import 'package:void_signals_hooks/void_signals_hooks.dart';

/// Tests for void_signals_hooks integration
void main() {
  group('useSignal', () {
    testWidgets('should create and manage signal', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: _UseSignalDemo()));

      expect(find.text('Count: 0'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(find.text('Count: 1'), findsOneWidget);
    });

    testWidgets('should preserve signal across rebuilds', (tester) async {
      var buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              buildCount++;
              final counter = useSignal(0);
              final value = useWatch(
                counter,
              ); // Must use useWatch to trigger rebuilds
              return Scaffold(
                body: Text('Count: $value'),
                floatingActionButton: FloatingActionButton(
                  onPressed: () => counter.value++,
                  child: const Icon(Icons.add),
                ),
              );
            },
          ),
        ),
      );

      expect(buildCount, 1);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(buildCount, 2);
      expect(find.text('Count: 1'), findsOneWidget);
    });
  });

  group('useComputed', () {
    testWidgets('should create computed from signals', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: _UseComputedDemo()));

      expect(find.text('Doubled: 0'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(find.text('Doubled: 2'), findsOneWidget);
    });

    testWidgets('should update when dependencies change', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              final a = useSignal(1);
              final b = useSignal(2);
              final sum = useComputed((_) => a.value + b.value);
              final sumValue = useWatchComputed(
                sum,
              ); // Must watch to get updates

              return Scaffold(
                body: Column(
                  children: [
                    Text('Sum: $sumValue'),
                    ElevatedButton(
                      onPressed: () => a.value++,
                      child: const Text('Inc A'),
                    ),
                    ElevatedButton(
                      onPressed: () => b.value++,
                      child: const Text('Inc B'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Sum: 3'), findsOneWidget);

      await tester.tap(find.text('Inc A'));
      await tester.pump();
      expect(find.text('Sum: 4'), findsOneWidget);

      await tester.tap(find.text('Inc B'));
      await tester.pump();
      expect(find.text('Sum: 5'), findsOneWidget);
    });
  });

  group('useWatch', () {
    testWidgets('should trigger rebuild on signal change', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: _UseWatchDemo()));

      expect(find.text('Value: 0'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(find.text('Value: 1'), findsOneWidget);
    });
  });

  group('useWatchComputed', () {
    testWidgets('should watch computed values', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              final source = useSignal(5);
              final doubled = useComputed((_) => source.value * 2);
              final watchedValue = useWatchComputed(doubled);

              return Scaffold(
                body: Column(
                  children: [
                    Text('Doubled: $watchedValue'),
                    ElevatedButton(
                      onPressed: () => source.value++,
                      child: const Text('Increment'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Doubled: 10'), findsOneWidget);

      await tester.tap(find.text('Increment'));
      await tester.pump();

      expect(find.text('Doubled: 12'), findsOneWidget);
    });
  });

  group('useSignalEffect', () {
    testWidgets('should run effect on signal change', (tester) async {
      final logs = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              final counter = useSignal(0);

              useSignalEffect(() {
                logs.add(counter.value);
              });

              return Scaffold(
                body: Text('Count: ${counter.value}'),
                floatingActionButton: FloatingActionButton(
                  onPressed: () => counter.value++,
                  child: const Icon(Icons.add),
                ),
              );
            },
          ),
        ),
      );

      expect(logs, [0]);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(logs, [0, 1]);
    });

    testWidgets('should cleanup effect on unmount', (tester) async {
      final globalCounter = signal(0);
      var effectRuns = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              useSignalEffect(() {
                globalCounter.value;
                effectRuns++;
              });

              return const Text('Widget');
            },
          ),
        ),
      );

      expect(effectRuns, 1);

      globalCounter.value = 1;
      await tester.pump();
      expect(effectRuns, 2);

      // Unmount widget
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      // Effect should not run after unmount
      globalCounter.value = 2;
      await tester.pump();
      expect(effectRuns, 2);
    });
  });

  group('Combined Hooks Pattern', () {
    testWidgets('should work together correctly', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: _CombinedHooksDemo()));

      // Initial render shows correct values
      expect(find.text('Count: 0'), findsOneWidget);
      expect(find.text('Doubled: 0'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      // After increment, all computed values update
      expect(find.text('Count: 1'), findsOneWidget);
      expect(find.text('Doubled: 2'), findsOneWidget);
    });
  });

  group('Hooks Rules', () {
    testWidgets('should maintain hook order', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              // Hooks must be called in same order
              final a = useSignal(1);
              final b = useSignal(2);
              final sum = useComputed((_) => a.value + b.value);

              return Column(
                children: [
                  Text('a: ${a.value}'),
                  Text('b: ${b.value}'),
                  Text('sum: ${sum.value}'),
                ],
              );
            },
          ),
        ),
      );

      expect(find.text('a: 1'), findsOneWidget);
      expect(find.text('b: 2'), findsOneWidget);
      expect(find.text('sum: 3'), findsOneWidget);
    });
  });
}

// Demo Widgets

class _UseSignalDemo extends HookWidget {
  const _UseSignalDemo();

  @override
  Widget build(BuildContext context) {
    final counter = useSignal(0);
    final value = useWatch(counter); // Must use useWatch to trigger rebuilds

    return Scaffold(
      body: Center(child: Text('Count: $value')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => counter.value++,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _UseComputedDemo extends HookWidget {
  const _UseComputedDemo();

  @override
  Widget build(BuildContext context) {
    final counter = useSignal(0);
    final doubled = useComputed((_) => counter.value * 2);
    final watchedDoubled = useWatchComputed(doubled);

    return Scaffold(
      body: Center(child: Text('Doubled: $watchedDoubled')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => counter.value++,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _UseWatchDemo extends HookWidget {
  const _UseWatchDemo();

  @override
  Widget build(BuildContext context) {
    final counter = useSignal(0);
    final value = useWatch(counter);

    return Scaffold(
      body: Center(child: Text('Value: $value')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => counter.value++,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CombinedHooksDemo extends HookWidget {
  const _CombinedHooksDemo();

  @override
  Widget build(BuildContext context) {
    final counter = useSignal(0);
    final doubled = useComputed((_) => counter.value * 2);

    // Watch values for display
    final counterValue = useWatch(counter);
    final doubledValue = useWatchComputed(doubled);

    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Count: $counterValue'),
          Text('Doubled: $doubledValue'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => counter.value++,
        child: const Icon(Icons.add),
      ),
    );
  }
}
