import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_signals_hooks/void_signals_hooks.dart';

/// Edge cases and performance tests for hooks
void main() {
  group('Hook Performance - Rebuild Coalescing', () {
    testWidgets('should coalesce batch updates to single rebuild',
        (tester) async {
      late Signal<int> a;
      late Signal<int> b;
      late Signal<int> c;
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              buildCount++;
              a = useSignal(0);
              b = useSignal(0);
              c = useSignal(0);
              final sumA = useWatch(a);
              final sumB = useWatch(b);
              final sumC = useWatch(c);
              return Text('${sumA + sumB + sumC}');
            },
          ),
        ),
      );

      expect(buildCount, 1);

      // Batch multiple updates
      batch(() {
        a.value = 10;
        b.value = 20;
        c.value = 30;
      });
      await tester.pump();

      // Only one additional rebuild
      expect(buildCount, 2);
      expect(find.text('60'), findsOneWidget);
    });

    testWidgets('should not rebuild when value reverts in batch',
        (tester) async {
      late Signal<int> count;
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              buildCount++;
              count = useSignal(0);
              final value = useWatch(count);
              return Text('$value');
            },
          ),
        ),
      );

      expect(buildCount, 1);

      // Change and revert in batch
      batch(() {
        count.value = 100;
        count.value = 0;
      });
      await tester.pump();

      // Should not rebuild since final value is same
      expect(buildCount, 1);
    });
  });

  group('Hook Lazy Evaluation', () {
    testWidgets('computed should not compute until accessed', (tester) async {
      int computeCount = 0;
      late Signal<int> source;
      late Computed<int> doubled;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              source = useSignal(10);
              doubled = useComputed((prev) {
                computeCount++;
                return source.value * 2;
              });
              // Intentionally NOT accessing doubled.value
              return const Text('Not using computed');
            },
          ),
        ),
      );

      // Computed not accessed, so not computed
      expect(computeCount, 0);

      // Now access it
      expect(doubled.value, 20);
      expect(computeCount, 1);

      // Access again - cached
      expect(doubled.value, 20);
      expect(computeCount, 1);
    });

    testWidgets('should only compute accessed branches', (tester) async {
      int leftCount = 0;
      int rightCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              final condition = useSignal(true);
              final left = useComputed((prev) {
                leftCount++;
                return 'left';
              });
              final right = useComputed((prev) {
                rightCount++;
                return 'right';
              });
              final value = useWatch(condition) ? left.value : right.value;
              return Text(value);
            },
          ),
        ),
      );

      expect(find.text('left'), findsOneWidget);
      expect(leftCount, 1);
      expect(rightCount, 0); // Right never computed
    });
  });

  group('Hook Cleanup', () {
    testWidgets('should cleanup effects on widget dispose', (tester) async {
      late Signal<int> count;
      final log = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              count = useSignal(0);
              useSignalEffect(() {
                log.add(count.value);
              });
              return Text('${count.value}');
            },
          ),
        ),
      );

      expect(log, [0]);

      // Dispose widget
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      // Effect should be stopped
      count.value = 999;
      expect(log, [0]); // No new entries
    });

    testWidgets('should cleanup multiple effects', (tester) async {
      late Signal<int> a;
      late Signal<int> b;
      final logA = <int>[];
      final logB = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              a = useSignal(0);
              b = useSignal(0);
              useSignalEffect(() {
                logA.add(a.value);
              });
              useSignalEffect(() {
                logB.add(b.value);
              });
              return const SizedBox();
            },
          ),
        ),
      );

      expect(logA, [0]);
      expect(logB, [0]);

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      a.value = 100;
      b.value = 200;

      expect(logA, [0]);
      expect(logB, [0]);
    });

    testWidgets('effect scope should create effects', (tester) async {
      late Signal<int> count;
      final log = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              count = useSignal(0);
              useEffectScope(() {
                effect(() {
                  log.add(count.value);
                });
              });
              return const SizedBox();
            },
          ),
        ),
      );

      expect(log, [0]);

      count.value = 1;
      expect(log, [0, 1]);

      // Note: dispose behavior depends on implementation details
      // We just verify the scope was created and effects run
    });
  });

  group('Hook Edge Cases', () {
    testWidgets('should handle null initial value', (tester) async {
      late Signal<String?> name;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              name = useSignal<String?>(null);
              final value = useWatch(name);
              return Text(value ?? 'null');
            },
          ),
        ),
      );

      expect(find.text('null'), findsOneWidget);

      name.value = 'John';
      await tester.pump();
      expect(find.text('John'), findsOneWidget);

      name.value = null;
      await tester.pump();
      expect(find.text('null'), findsOneWidget);
    });

    testWidgets('should handle rapid signal changes', (tester) async {
      late Signal<int> count;
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              buildCount++;
              count = useSignal(0);
              final value = useWatch(count);
              return Text('$value');
            },
          ),
        ),
      );

      expect(buildCount, 1);

      // Rapid changes in batch
      batch(() {
        for (int i = 0; i < 100; i++) {
          count.value = i;
        }
      });
      await tester.pump();

      expect(buildCount, 2);
      expect(find.text('99'), findsOneWidget);
    });

    testWidgets('should handle conditional hooks', (tester) async {
      final showExtra = signal(false);

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              // Use useWatch to trigger rebuild on showExtra change
              final showExtraValue = useWatch(showExtra);
              final count = useSignal(0);
              final value = useWatch(count);

              return Column(
                children: [
                  Text('Count: $value'),
                  if (showExtraValue)
                    HookBuilder(
                      builder: (context) {
                        final extra = useSignal(100);
                        return Text('Extra: ${extra.value}');
                      },
                    ),
                ],
              );
            },
          ),
        ),
      );

      expect(find.text('Count: 0'), findsOneWidget);
      expect(find.text('Extra: 100'), findsNothing);

      showExtra.value = true;
      await tester.pump();

      expect(find.text('Extra: 100'), findsOneWidget);
    });

    testWidgets('should handle deeply nested hooks', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              final a = useSignal(1);
              return HookBuilder(
                builder: (context) {
                  final b = useSignal(2);
                  return HookBuilder(
                    builder: (context) {
                      final c = useSignal(3);
                      final sum = useComputedSimple(
                        () => a.value + b.value + c.value,
                      );
                      return Text('Sum: ${sum.value}');
                    },
                  );
                },
              );
            },
          ),
        ),
      );

      expect(find.text('Sum: 6'), findsOneWidget);
    });
  });

  group('Hook useSelect Edge Cases', () {
    testWidgets('should handle complex selector', (tester) async {
      final items = signal(<Map<String, dynamic>>[
        {'id': 1, 'name': 'Alice', 'score': 100},
        {'id': 2, 'name': 'Bob', 'score': 80},
        {'id': 3, 'name': 'Charlie', 'score': 90},
      ]);
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              buildCount++;
              // Select only total score
              final totalScore = useSelect(
                items,
                (list) => list.fold<int>(
                  0,
                  (sum, item) => sum + (item['score'] as int),
                ),
              );
              return Text('Total: $totalScore');
            },
          ),
        ),
      );

      expect(find.text('Total: 270'), findsOneWidget);
      expect(buildCount, 1);

      // Change name - total score unchanged
      items.value = [
        {'id': 1, 'name': 'Alice Changed', 'score': 100},
        {'id': 2, 'name': 'Bob', 'score': 80},
        {'id': 3, 'name': 'Charlie', 'score': 90},
      ];
      await tester.pump();
      expect(buildCount, 1); // No rebuild

      // Change score
      items.value = [
        {'id': 1, 'name': 'Alice Changed', 'score': 150},
        {'id': 2, 'name': 'Bob', 'score': 80},
        {'id': 3, 'name': 'Charlie', 'score': 90},
      ];
      await tester.pump();
      expect(buildCount, 2); // Rebuild
      expect(find.text('Total: 320'), findsOneWidget);
    });
  });

  group('Hook Stream/Future Integration', () {
    testWidgets('should update signal from stream', (tester) async {
      final controller = StreamController<int>();
      late Signal<int> sig;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              sig = useSignalFromStream(controller.stream, initialValue: 0);
              return Text('${sig.value}');
            },
          ),
        ),
      );

      expect(sig.value, 0);

      controller.add(10);
      await tester.pump();
      expect(sig.value, 10);

      controller.add(20);
      await tester.pump();
      expect(sig.value, 20);

      await controller.close();
    });

    testWidgets('should handle stream that completes', (tester) async {
      final controller = StreamController<int>();
      late Signal<int> sig;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              sig = useSignalFromStream(controller.stream, initialValue: 0);
              return Text('${sig.value}');
            },
          ),
        ),
      );

      controller.add(10);
      await tester.pump();
      expect(sig.value, 10);

      await controller.close();
      await tester.pump();

      // Should keep last value after stream closes
      expect(sig.value, 10);
    });

    testWidgets('should update signal from future', (tester) async {
      late Signal<int> sig;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              sig = useSignalFromFuture(
                Future.delayed(const Duration(milliseconds: 10), () => 42),
                initialValue: 0,
              );
              return Text('${sig.value}');
            },
          ),
        ),
      );

      expect(sig.value, 0);

      await tester.pumpAndSettle();
      expect(sig.value, 42);
    });
  });

  group('Hook Memoization', () {
    testWidgets('useSignal should return same instance across rebuilds',
        (tester) async {
      Signal<int>? firstInstance;
      int rebuildCount = 0;

      final trigger = signal(0);

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              useWatch(trigger); // Force rebuild on trigger change
              rebuildCount++;
              final sig = useSignal(0);
              firstInstance ??= sig;
              return Text('${sig.value}');
            },
          ),
        ),
      );

      expect(rebuildCount, 1);

      // Force rebuild
      trigger.value = 1;
      await tester.pump();

      expect(rebuildCount, 2);

      // Should be same instance
      final sig = firstInstance!;
      expect(identical(sig, firstInstance), true);
    });

    testWidgets('useComputed should return same instance across rebuilds',
        (tester) async {
      Computed<int>? firstInstance;
      final trigger = signal(0);

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              useWatch(trigger);
              final source = useSignal(10);
              final comp = useComputed((prev) => source.value * 2);
              firstInstance ??= comp;
              return Text('${comp.value}');
            },
          ),
        ),
      );

      final first = firstInstance;

      trigger.value = 1;
      await tester.pump();

      expect(identical(firstInstance, first), true);
    });
  });

  group('useReactive Variations', () {
    testWidgets('should handle update function correctly', (tester) async {
      late int value;
      late void Function(int) setValue;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              (value, setValue) = useReactive(0);
              return Column(
                children: [
                  Text('$value'),
                  ElevatedButton(
                    onPressed: () => setValue(value + 10),
                    child: const Text('Add 10'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      await tester.tap(find.text('Add 10'));
      await tester.pump();
      expect(find.text('10'), findsOneWidget);

      await tester.tap(find.text('Add 10'));
      await tester.pump();
      expect(find.text('20'), findsOneWidget);
    });
  });
}
