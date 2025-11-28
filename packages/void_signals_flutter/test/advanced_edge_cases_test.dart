import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_signals_flutter/void_signals_flutter.dart';

/// Advanced edge cases tests for void_signals_flutter
void main() {
  group('Watch - Advanced Edge Cases', () {
    testWidgets('should handle widget rebuild during signal update',
        (tester) async {
      final counter = signal(0);
      var buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  ElevatedButton(
                    key: const Key('rebuild'),
                    onPressed: () => setState(() {}),
                    child: const Text('Rebuild'),
                  ),
                  Watch(builder: (_, __) {
                    buildCount++;
                    return Text('${counter.value}');
                  }),
                ],
              );
            },
          ),
        ),
      );

      expect(buildCount, 1);

      // Trigger parent rebuild
      await tester.tap(find.byKey(const Key('rebuild')));
      await tester.pump();
      expect(buildCount, 2);

      // Signal update
      counter.value = 1;
      await tester.pump();
      expect(buildCount, 3);
    });

    testWidgets('should handle rapid parent rebuilds with signal updates',
        (tester) async {
      final counter = signal(0);
      var buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  ElevatedButton(
                    key: const Key('action'),
                    onPressed: () {
                      // Both rebuild parent and update signal
                      counter.value++;
                      setState(() {});
                    },
                    child: const Text('Action'),
                  ),
                  Watch(builder: (_, __) {
                    buildCount++;
                    return Text('${counter.value}');
                  }),
                ],
              );
            },
          ),
        ),
      );

      expect(buildCount, 1);

      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byKey(const Key('action')));
      }
      await tester.pump();

      expect(counter.value, 5);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('should handle Watch with null child', (tester) async {
      final counter = signal(0);

      await tester.pumpWidget(
        MaterialApp(
          home: Watch(
            child: null,
            builder: (context, child) {
              expect(child, isNull);
              return Text('${counter.value}');
            },
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('should handle Watch inside ListView.builder', (tester) async {
      final items = signal(List.generate(100, (i) => i));
      var buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: 100,
              itemBuilder: (context, index) {
                return Watch(builder: (_, __) {
                  buildCount++;
                  return Text('Item ${items.value[index]}');
                });
              },
            ),
          ),
        ),
      );

      // Only visible items should build
      expect(buildCount, lessThan(100));

      // Scroll
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pump();

      // Update signal - should only rebuild visible items
      items.value = List.generate(100, (i) => i * 10);
      await tester.pump();
    });

    testWidgets('should handle Watch with async builder operations',
        (tester) async {
      final loading = signal(true);
      final data = signal<String?>(null);

      await tester.pumpWidget(
        MaterialApp(
          home: Watch(builder: (_, __) {
            if (loading.value) {
              return const CircularProgressIndicator();
            }
            return Text(data.value ?? 'No data');
          }),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      batch(() {
        loading.value = false;
        data.value = 'Hello World';
      });
      await tester.pump();

      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('should handle Watch disposal during build', (tester) async {
      final show = signal(true);
      final counter = signal(0);

      await tester.pumpWidget(
        MaterialApp(
          home: Watch(builder: (_, __) {
            if (!show.value) {
              return const Text('Hidden');
            }
            return Watch(builder: (_, __) {
              return Text('Count: ${counter.value}');
            });
          }),
        ),
      );

      expect(find.text('Count: 0'), findsOneWidget);

      // Hide the inner Watch
      show.value = false;
      await tester.pump();
      expect(find.text('Hidden'), findsOneWidget);

      // Counter update should not affect disposed Watch
      counter.value = 100;
      await tester.pump();
      expect(find.text('Hidden'), findsOneWidget);

      // Show again
      show.value = true;
      await tester.pump();
      expect(find.text('Count: 100'), findsOneWidget);
    });
  });

  group('SignalBuilder - Edge Cases', () {
    testWidgets('should handle signal change to same reference',
        (tester) async {
      final list = [1, 2, 3];
      final s = signal(list);
      var buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: SignalBuilder<List<int>>(
            signal: s,
            builder: (context, value, child) {
              buildCount++;
              return Text('${value.length}');
            },
          ),
        ),
      );

      expect(buildCount, 1);

      // Same reference - no rebuild
      s.value = list;
      await tester.pump();
      expect(buildCount, 1);

      // New reference - rebuild
      s.value = [1, 2, 3, 4];
      await tester.pump();
      expect(buildCount, 2);
    });

    testWidgets('should handle widget key change', (tester) async {
      final counter = signal(0);
      var buildCount = 0;

      Widget buildWidget(Key key) {
        return MaterialApp(
          home: SignalBuilder<int>(
            key: key,
            signal: counter,
            builder: (context, value, child) {
              buildCount++;
              return Text('$value');
            },
          ),
        );
      }

      await tester.pumpWidget(buildWidget(const Key('a')));
      expect(buildCount, 1);

      await tester.pumpWidget(buildWidget(const Key('b')));
      expect(buildCount, 2); // New widget instance

      counter.value = 1;
      await tester.pump();
      expect(buildCount, 3);
    });

    testWidgets('should handle signal replacement', (tester) async {
      final signal1 = signal(1);
      final signal2 = signal(100);
      final current = ValueNotifier(signal1);

      await tester.pumpWidget(
        MaterialApp(
          home: ValueListenableBuilder<Signal<int>>(
            valueListenable: current,
            builder: (context, sig, _) {
              return SignalBuilder<int>(
                signal: sig,
                builder: (context, value, child) {
                  return Text('$value');
                },
              );
            },
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);

      // Switch to different signal
      current.value = signal2;
      await tester.pump();
      expect(find.text('100'), findsOneWidget);

      // Update original signal - should not affect
      signal1.value = 999;
      await tester.pump();
      expect(find.text('100'), findsOneWidget);

      // Update current signal
      signal2.value = 200;
      await tester.pump();
      expect(find.text('200'), findsOneWidget);
    });
  });

  group('Consumer - Edge Cases', () {
    testWidgets('should handle ref.watch after unmount attempt',
        (tester) async {
      final counter = signal(0);
      late SignalRef capturedRef;

      await tester.pumpWidget(
        MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              capturedRef = ref;
              return Text('${ref.watch(counter)}');
            },
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      // Remove widget
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      // Trying to use ref after unmount should throw
      expect(() => capturedRef.watch(counter), throwsStateError);
    });

    testWidgets('should handle ref.select with complex selector',
        (tester) async {
      final user = signal<Map<String, Map<String, dynamic>>>({
        'profile': {
          'name': 'John',
          'settings': {
            'theme': 'dark',
            'notifications': true,
          },
        },
      });
      var buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              buildCount++;
              final theme = ref.select(
                user,
                (u) => (u['profile']!['settings']
                    as Map<String, dynamic>)['theme'] as String,
              );
              return Text('Theme: $theme');
            },
          ),
        ),
      );

      expect(buildCount, 1);
      expect(find.text('Theme: dark'), findsOneWidget);

      // Change unrelated field
      user.value = {
        'profile': {
          'name': 'Jane', // Changed
          'settings': {
            'theme': 'dark', // Same
            'notifications': false, // Changed
          },
        },
      };
      await tester.pump();
      expect(buildCount, 1); // No rebuild - selected value same

      // Change selected field
      user.value = {
        'profile': {
          'name': 'Jane',
          'settings': {
            'theme': 'light', // Changed
            'notifications': false,
          },
        },
      };
      await tester.pump();
      expect(buildCount, 2);
      expect(find.text('Theme: light'), findsOneWidget);
    });
  });

  group('AsyncValue - Edge Cases', () {
    testWidgets('should handle rapid async state transitions', (tester) async {
      final state = signal<AsyncValue<int>>(const AsyncLoading());

      await tester.pumpWidget(
        MaterialApp(
          home: Watch(builder: (_, __) {
            return state.value.when(
              loading: () => const Text('Loading'),
              data: (v) => Text('Data: $v'),
              error: (e, _) => Text('Error: $e'),
            );
          }),
        ),
      );

      expect(find.text('Loading'), findsOneWidget);

      // Rapid transitions
      state.value = const AsyncData(1);
      state.value = const AsyncLoading();
      state.value = const AsyncData(2);
      state.value = AsyncError('fail', StackTrace.current);
      state.value = const AsyncData(3);

      await tester.pump();
      expect(find.text('Data: 3'), findsOneWidget);
    });

    testWidgets('should handle asyncSignal completion', (tester) async {
      final completer = Completer<String>();
      late Signal<AsyncValue<String>> asyncSig;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (context) {
            asyncSig = asyncSignal(completer.future);
            return Watch(builder: (_, __) {
              return asyncSig.value.when(
                loading: () => const Text('Loading'),
                data: (v) => Text('Data: $v'),
                error: (e, _) => const Text('Error'),
              );
            });
          }),
        ),
      );

      expect(find.text('Loading'), findsOneWidget);

      completer.complete('Hello');
      await tester.pump();
      await tester.pump(); // Extra pump for async completion

      expect(find.text('Data: Hello'), findsOneWidget);
    });

    testWidgets('should handle asyncSignal error', (tester) async {
      final completer = Completer<String>();
      late Signal<AsyncValue<String>> asyncSig;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (context) {
            asyncSig = asyncSignal(completer.future);
            return Watch(builder: (_, __) {
              return asyncSig.value.when(
                loading: () => const Text('Loading'),
                data: (v) => Text('Data: $v'),
                error: (e, _) => Text('Error: $e'),
              );
            });
          }),
        ),
      );

      expect(find.text('Loading'), findsOneWidget);

      completer.completeError('Network error');
      await tester.pump();
      await tester.pump();

      expect(find.text('Error: Network error'), findsOneWidget);
    });
  });

  group('SignalScope - Edge Cases', () {
    testWidgets('should handle nested SignalScope overrides', (tester) async {
      final counter = signal(0);

      await tester.pumpWidget(
        MaterialApp(
          home: SignalScope(
            overrides: [counter.override(10)],
            child: Builder(builder: (context) {
              final outer = counter.scoped(context);
              return SignalScope(
                overrides: [counter.override(100)],
                child: Builder(builder: (context) {
                  final inner = counter.scoped(context);
                  return Column(
                    children: [
                      Text('Outer: ${outer.value}'),
                      Text('Inner: ${inner.value}'),
                      Text('Global: ${counter.value}'),
                    ],
                  );
                }),
              );
            }),
          ),
        ),
      );

      expect(find.text('Outer: 10'), findsOneWidget);
      expect(find.text('Inner: 100'), findsOneWidget);
      expect(find.text('Global: 0'), findsOneWidget);
    });

    testWidgets('should handle SignalScope with Watch', (tester) async {
      final counter = signal(0);

      await tester.pumpWidget(
        MaterialApp(
          home: SignalScope(
            overrides: [counter.override(50)],
            child: Builder(builder: (context) {
              final scoped = counter.scoped(context);
              return Column(
                children: [
                  Watch(builder: (_, __) {
                    return Text('Scoped: ${scoped.value}');
                  }),
                  ElevatedButton(
                    key: const Key('increment'),
                    onPressed: () => scoped.value++,
                    child: const Text('Increment'),
                  ),
                ],
              );
            }),
          ),
        ),
      );

      expect(find.text('Scoped: 50'), findsOneWidget);

      await tester.tap(find.byKey(const Key('increment')));
      await tester.pump();

      expect(find.text('Scoped: 51'), findsOneWidget);
      expect(counter.value, 0); // Global unchanged
    });
  });

  group('batchLater - Edge Cases', () {
    test('should handle exception in batchLater', () async {
      final counter = signal(0);
      var effectCount = 0;

      final eff = effect(() {
        counter.value;
        effectCount++;
      });
      effectCount = 0;

      batchLater(() => counter.value = 1);
      expect(
        () => batchLater(() => throw Exception('Test')),
        throwsException,
      );
      batchLater(() => counter.value = 2);

      await Future.microtask(() {});

      expect(counter.value, 2);
      expect(effectCount, 1);

      eff.stop();
    });

    test('should handle nested batchLater with return values', () async {
      final counter = signal(0);

      final result1 = batchLater(() {
        counter.value++;
        return batchLater(() {
          counter.value++;
          return batchLater(() {
            counter.value++;
            return 'done';
          });
        });
      });

      expect(result1, 'done');
      expect(counter.value, 3);

      await Future.microtask(() {});
    });

    test('should handle batchLater with async/await', () async {
      final counter = signal(0);
      var effectCount = 0;

      final eff = effect(() {
        counter.value;
        effectCount++;
      });
      effectCount = 0;

      Future<void> asyncUpdate() async {
        batchLater(() => counter.value++);
        await Future.delayed(Duration.zero);
        batchLater(() => counter.value++);
      }

      await asyncUpdate();
      await Future.microtask(() {});

      expect(counter.value, 2);
      // Two separate microtasks = two effect runs
      expect(effectCount, 2);

      eff.stop();
    });
  });

  group('Time Utils - Edge Cases', () {
    testWidgets('debounced should handle rapid changes', (tester) async {
      final source = signal('');
      final debounce = debounced(source, const Duration(milliseconds: 100));
      final values = <String>[];

      final eff = effect(() {
        values.add(debounce.value);
      });

      // Rapid changes
      source.value = 'a';
      source.value = 'ab';
      source.value = 'abc';
      source.value = 'abcd';

      await tester.pump(const Duration(milliseconds: 50));
      expect(debounce.value, ''); // Still initial

      await tester.pump(const Duration(milliseconds: 100));
      expect(debounce.value, 'abcd'); // Final value

      eff.stop();
      debounce.dispose();
    });

    testWidgets('throttled should limit update frequency', (tester) async {
      final source = signal(0);
      final throttle = throttled(source, const Duration(milliseconds: 100));

      expect(throttle.value, 0);

      // Updates within throttle window
      source.value = 1;
      await tester.pump(); // Let the throttle update
      expect(throttle.value, 1); // First value immediately

      source.value = 2;
      source.value = 3;
      await tester.pump();
      expect(throttle.value, 1); // Still throttled

      await tester.pump(const Duration(milliseconds: 110));
      expect(throttle.value, 3); // After throttle window

      throttle.dispose();
    });
  });

  group('Signal Extensions - Edge Cases', () {
    test('IntSignalX increment/decrement edge cases', () {
      final counter = signal(0);

      counter.increment(0); // No-op
      expect(counter.value, 0);

      counter.increment(-5); // Negative increment
      expect(counter.value, -5);

      counter.decrement(-10); // Negative decrement (actually adds)
      expect(counter.value, 5);
    });

    test('ListSignalX operations on empty list', () {
      final list = signal<List<int>>([]);

      list.add(1);
      expect(list.value, [1]);

      list.remove(1);
      expect(list.value, isEmpty);

      list.remove(999); // Remove non-existent
      expect(list.value, isEmpty);

      list.clear();
      expect(list.value, isEmpty);
    });

    test('MapSignalX operations', () {
      final map = signal<Map<String, int>>({});

      map.set('a', 1);
      expect(map.value, {'a': 1});

      map.set('a', 2); // Override
      expect(map.value, {'a': 2});

      map.remove('b'); // Remove non-existent
      expect(map.value, {'a': 2});

      map.remove('a');
      expect(map.value, isEmpty);
    });

    test('NullableSignalX operations', () {
      final nullable = signal<String?>(null);

      expect(nullable.orDefault('fallback'), 'fallback');

      nullable.value = 'actual';
      expect(nullable.orDefault('fallback'), 'actual');

      nullable.clear();
      expect(nullable.value, isNull);
    });
  });

  group('Combinators - Edge Cases', () {
    test('mapped with null values', () {
      final source = signal<int?>(null);
      final mapped_ = mapped(source, (v) => v?.toString() ?? 'null');

      expect(mapped_.value, 'null');

      source.value = 42;
      expect(mapped_.value, '42');

      source.value = null;
      expect(mapped_.value, 'null');
    });

    test('filtered with always-false predicate', () {
      final source = signal(0);
      final filtered_ = filtered(source, (v) => false);

      expect(filtered_.value, 0); // Initial value passes

      source.value = 1;
      expect(filtered_.value, 0); // Filtered out

      source.value = 100;
      expect(filtered_.value, 0); // Still filtered
    });

    test('combine4 with rapid updates', () {
      final a = signal(1);
      final b = signal(2);
      final c = signal(3);
      final d = signal(4);

      final combined = combine4(a, b, c, d, (a, b, c, d) => a + b + c + d);

      expect(combined.value, 10);

      batch(() {
        a.value = 10;
        b.value = 20;
        c.value = 30;
        d.value = 40;
      });

      expect(combined.value, 100);
    });

    test('withPrevious tracking', () {
      final source = signal(0);
      final (current, previous) = withPrevious(source);

      expect(current.value, 0);
      expect(previous.value, isNull);

      source.value = 1;
      expect(current.value, 1);
      expect(previous.value, 0);

      source.value = 2;
      expect(current.value, 2);
      expect(previous.value, 1);
    });
  });

  group('Performance - Stress Tests', () {
    testWidgets('should handle 100 Watch widgets', (tester) async {
      final counter = signal(0);

      await tester.pumpWidget(
        MaterialApp(
          home: SingleChildScrollView(
            child: Column(
              children: List.generate(
                100,
                (i) => Watch(
                  key: ValueKey(i),
                  builder: (_, __) => Text('$i: ${counter.value}'),
                ),
              ),
            ),
          ),
        ),
      );

      counter.value = 1;
      await tester.pump();

      expect(find.text('0: 1'), findsOneWidget);
      expect(find.text('99: 1'), findsOneWidget);
    });

    testWidgets('should handle rapid signal updates in list', (tester) async {
      final items = signal(List.generate(50, (i) => 'Item $i'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Watch(builder: (_, __) {
              return ListView.builder(
                itemCount: items.value.length,
                itemBuilder: (context, index) {
                  return Text(items.value[index]);
                },
              );
            }),
          ),
        ),
      );

      expect(find.text('Item 0'), findsOneWidget);

      // Update
      for (int i = 0; i < 5; i++) {
        items.value = List.generate(50, (j) => 'Item $j (update $i)');
        await tester.pump();
      }

      expect(find.textContaining('update 4'), findsWidgets);
    });
  });
}
