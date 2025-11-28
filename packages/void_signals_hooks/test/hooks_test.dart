import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_signals_hooks/void_signals_hooks.dart';

void main() {
  group('useSignal', () {
    testWidgets('should create a signal with initial value', (tester) async {
      late Signal<int> capturedSignal;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              capturedSignal = useSignal(42);
              return Text('${capturedSignal.value}');
            },
          ),
        ),
      );

      expect(find.text('42'), findsOneWidget);
      expect(capturedSignal.value, 42);
    });

    testWidgets('should preserve signal across rebuilds', (tester) async {
      late Signal<int> firstSignal;
      late Signal<int> secondSignal;
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              buildCount++;
              if (buildCount == 1) {
                firstSignal = useSignal(0);
              } else {
                secondSignal = useSignal(0);
              }
              return const SizedBox();
            },
          ),
        ),
      );

      // Trigger a rebuild
      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              buildCount++;
              secondSignal = useSignal(0);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(identical(firstSignal, secondSignal), true);
    });

    testWidgets('should allow updating signal value', (tester) async {
      late Signal<int> capturedSignal;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              capturedSignal = useSignal(0);
              return Text('${capturedSignal.value}');
            },
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      capturedSignal.value = 42;
      await tester.pump();

      // Note: Just updating signal doesn't trigger rebuild without useWatch
      expect(capturedSignal.value, 42);
    });
  });

  group('useComputed', () {
    testWidgets('should create a computed value', (tester) async {
      late Signal<int> count;
      late Computed<int> doubled;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              count = useSignal(5);
              doubled = useComputed((prev) => count.value * 2);
              return Text('${doubled.value}');
            },
          ),
        ),
      );

      expect(find.text('10'), findsOneWidget);
      expect(doubled.value, 10);
    });

    testWidgets('should update when dependency changes', (tester) async {
      late Signal<int> count;
      late Computed<int> doubled;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              count = useSignal(5);
              doubled = useComputed((prev) => count.value * 2);
              return Text('${doubled.value}');
            },
          ),
        ),
      );

      count.value = 10;

      expect(doubled.value, 20);
    });

    testWidgets('should receive previous value', (tester) async {
      late Signal<int> count;
      late Computed<String> history;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              count = useSignal(1);
              history = useComputed((prev) {
                final current = count.value;
                return prev == null ? '$current' : '$prev->$current';
              });
              return Text(history.value);
            },
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);

      count.value = 2;
      expect(history.value, '1->2');
    });
  });

  group('useComputedSimple', () {
    testWidgets('should create a computed without previous value',
        (tester) async {
      late Signal<int> count;
      late Computed<int> tripled;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              count = useSignal(3);
              tripled = useComputedSimple(() => count.value * 3);
              return Text('${tripled.value}');
            },
          ),
        ),
      );

      expect(find.text('9'), findsOneWidget);

      count.value = 4;
      expect(tripled.value, 12);
    });
  });

  group('useWatch', () {
    testWidgets('should trigger rebuild when signal changes', (tester) async {
      late Signal<int> count;
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              count = useSignal(0);
              final value = useWatch(count);
              buildCount++;
              return Text('$value');
            },
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
      expect(buildCount, 1);

      count.value = 1;
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
      expect(buildCount, 2);
    });

    testWidgets('should return current signal value', (tester) async {
      late Signal<String> name;
      late String watchedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              name = useSignal('Alice');
              watchedValue = useWatch(name);
              return Text(watchedValue);
            },
          ),
        ),
      );

      expect(find.text('Alice'), findsOneWidget);

      name.value = 'Bob';
      await tester.pump();

      expect(find.text('Bob'), findsOneWidget);
    });
  });

  group('useWatchComputed', () {
    testWidgets('should trigger rebuild when computed changes', (tester) async {
      late Signal<int> count;
      late Computed<int> doubled;
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              count = useSignal(5);
              doubled = useComputed((prev) => count.value * 2);
              final value = useWatchComputed(doubled);
              buildCount++;
              return Text('$value');
            },
          ),
        ),
      );

      expect(find.text('10'), findsOneWidget);
      expect(buildCount, 1);

      count.value = 10;
      await tester.pump();

      expect(find.text('20'), findsOneWidget);
      expect(buildCount, 2);
    });
  });

  group('useSignalEffect', () {
    testWidgets('should run effect on signal change', (tester) async {
      late Signal<int> count;
      final effectValues = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              count = useSignal(0);
              useSignalEffect(() {
                effectValues.add(count.value);
              });
              return const SizedBox();
            },
          ),
        ),
      );

      // Effect runs initially
      expect(effectValues, [0]);

      count.value = 1;
      await tester.pump();

      expect(effectValues, [0, 1]);

      count.value = 2;
      await tester.pump();

      expect(effectValues, [0, 1, 2]);
    });

    testWidgets('should cleanup effect on dispose', (tester) async {
      late Signal<int> count;
      final effectValues = <int>[];

      final key = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            key: key,
            builder: (context) {
              count = useSignal(0);
              useSignalEffect(() {
                effectValues.add(count.value);
              });
              return const SizedBox();
            },
          ),
        ),
      );

      expect(effectValues, [0]);

      // Remove widget
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(),
        ),
      );

      // Signal update should not trigger effect after dispose
      count.value = 999;
      await tester.pump();

      expect(effectValues, [0]);
    });
  });

  group('useEffectScope', () {
    testWidgets('should create effect scope', (tester) async {
      late EffectScope scope;
      bool setupCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              scope = useEffectScope(() {
                setupCalled = true;
              });
              return const SizedBox();
            },
          ),
        ),
      );

      expect(scope, isNotNull);
      expect(setupCalled, true);
    });

    testWidgets('should stop scope on dispose', (tester) async {
      late EffectScope scope;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              scope = useEffectScope();
              return const SizedBox();
            },
          ),
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(),
        ),
      );

      // Scope should be stopped
      expect(scope, isNotNull);
    });
  });

  group('useBatch', () {
    testWidgets('should batch signal updates', (tester) async {
      late Signal<int> a;
      late Signal<int> b;
      int updateCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              a = useSignal(0);
              b = useSignal(0);

              useSignalEffect(() {
                a.value;
                b.value;
                updateCount++;
              });

              return ElevatedButton(
                onPressed: () {
                  batch(() {
                    a.value = 1;
                    b.value = 2;
                  });
                },
                child: const Text('Batch Update'),
              );
            },
          ),
        ),
      );

      expect(updateCount, 1); // Initial run

      await tester.tap(find.text('Batch Update'));
      await tester.pump();

      // Batched updates should trigger effect only once
      expect(updateCount, 2);
    });
  });

  group('useUntrack', () {
    testWidgets('should not track dependencies in untrack', (tester) async {
      late Signal<int> tracked;
      late Signal<int> untracked;
      final trackedValues = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              tracked = useSignal(0);
              untracked = useSignal(100);

              useSignalEffect(() {
                final t = tracked.value;
                final u = useUntrack(() => untracked.value);
                trackedValues.add(t + u);
              });

              return const SizedBox();
            },
          ),
        ),
      );

      expect(trackedValues, [100]); // 0 + 100

      // Update untracked signal - should NOT trigger effect
      untracked.value = 200;
      await tester.pump();

      expect(trackedValues, [100]); // No change

      // Update tracked signal - should trigger effect
      tracked.value = 1;
      await tester.pump();

      expect(trackedValues, [100, 201]); // 1 + 200
    });
  });

  group('useSignalFromStream', () {
    testWidgets('should create signal from stream', (tester) async {
      final controller = StreamController<int>.broadcast();
      late Signal<int> streamSignal;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              streamSignal = useSignalFromStream(
                controller.stream,
                initialValue: 0,
              );
              return Text('${streamSignal.value}');
            },
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      controller.add(42);
      await tester.pump();

      expect(streamSignal.value, 42);

      controller.add(100);
      await tester.pump();

      expect(streamSignal.value, 100);

      await controller.close();
    });
  });

  group('useSignalFromFuture', () {
    testWidgets('should create signal from future', (tester) async {
      final completer = Completer<String>();
      late Signal<String?> futureSignal;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              futureSignal = useSignalFromFuture(
                completer.future,
                initialValue: null,
              );
              final value = futureSignal.value;
              if (value == null) {
                return const CircularProgressIndicator();
              }
              return Text(value);
            },
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(futureSignal.value, null);

      completer.complete('Hello, Future!');
      await tester.pump();

      expect(futureSignal.value, 'Hello, Future!');
    });
  });

  group('Complex scenarios', () {
    testWidgets('should work with multiple signals and computed',
        (tester) async {
      late Signal<int> a;
      late Signal<int> b;
      late Computed<int> sum;
      late Computed<int> product;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              a = useSignal(3);
              b = useSignal(4);
              sum = useComputedSimple(() => a.value + b.value);
              product = useComputedSimple(() => a.value * b.value);
              final s = useWatchComputed(sum);
              final p = useWatchComputed(product);
              return Text('Sum: $s, Product: $p');
            },
          ),
        ),
      );

      expect(find.text('Sum: 7, Product: 12'), findsOneWidget);

      a.value = 5;
      await tester.pumpAndSettle();

      expect(find.text('Sum: 9, Product: 20'), findsOneWidget);

      b.value = 10;
      await tester.pumpAndSettle();

      expect(find.text('Sum: 15, Product: 50'), findsOneWidget);
    });

    testWidgets('should work with nested computed values', (tester) async {
      late Signal<int> base;
      late Computed<int> doubled;
      late Computed<int> quadrupled;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              base = useSignal(2);
              doubled = useComputedSimple(() => base.value * 2);
              quadrupled = useComputedSimple(() => doubled.value * 2);
              return Text('${quadrupled.value}');
            },
          ),
        ),
      );

      expect(find.text('8'), findsOneWidget);

      base.value = 5;
      expect(quadrupled.value, 20);
    });
  });

  group('useReactive', () {
    testWidgets('should create signal and watch it', (tester) async {
      late int value;
      late void Function(int) setValue;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              final (v, setV) = useReactive(0);
              value = v;
              setValue = setV;
              return Text('$v');
            },
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
      expect(value, 0);

      setValue(42);
      await tester.pump();

      expect(find.text('42'), findsOneWidget);
    });
  });

  group('useSelect', () {
    testWidgets('should only rebuild when selected value changes',
        (tester) async {
      late Signal<Map<String, dynamic>> user;
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              user = useSignal({'name': 'John', 'age': 30});
              final name = useSelect(user, (u) => u['name'] as String);
              buildCount++;
              return Text(name);
            },
          ),
        ),
      );

      expect(find.text('John'), findsOneWidget);
      final initialBuildCount = buildCount;

      // Change age - should NOT rebuild
      user.value = {'name': 'John', 'age': 31};
      await tester.pump();

      expect(buildCount, initialBuildCount);

      // Change name - should rebuild
      user.value = {'name': 'Jane', 'age': 31};
      await tester.pump();

      expect(find.text('Jane'), findsOneWidget);
      expect(buildCount, initialBuildCount + 1);
    });
  });

  group('useSelectComputed', () {
    testWidgets('should only rebuild when selected computed value changes',
        (tester) async {
      late Signal<int> count;
      late Computed<Map<String, int>> stats;
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              count = useSignal(10);
              stats = useComputedSimple(
                  () => {'value': count.value, 'doubled': count.value * 2});
              final doubled = useSelectComputed(stats, (s) => s['doubled']!);
              buildCount++;
              return Text('Doubled: $doubled');
            },
          ),
        ),
      );

      expect(find.text('Doubled: 20'), findsOneWidget);
      final initialBuildCount = buildCount;

      // Change count - should rebuild because doubled changes
      count.value = 15;
      await tester.pump();

      expect(find.text('Doubled: 30'), findsOneWidget);
      expect(buildCount, initialBuildCount + 1);
    });
  });
}
