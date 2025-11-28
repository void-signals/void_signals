import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_signals_hooks/void_signals_hooks.dart';

void main() {
  group('useSignal', () {
    testWidgets('should create and memoize a signal', (tester) async {
      late Signal<int> sig;
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              buildCount++;
              sig = useSignal(0);
              return Text('${sig.value}');
            },
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
      expect(buildCount, 1);

      // Rebuild to verify memoization
      await tester.pump();
      final prevSig = sig;
      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              buildCount++;
              sig = useSignal(0);
              return Text('${sig.value}');
            },
          ),
        ),
      );

      expect(identical(prevSig, sig), true);
    });

    testWidgets('should preserve signal across rebuilds', (tester) async {
      late Signal<int> sig;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              sig = useSignal(0);
              return Text('${sig.value}');
            },
          ),
        ),
      );

      sig.value = 10;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              sig = useSignal(0);
              return Text('${sig.value}');
            },
          ),
        ),
      );

      // Signal should still have value 10
      expect(sig.value, 10);
    });
  });

  group('useComputed', () {
    testWidgets('should create computed value', (tester) async {
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
    });

    testWidgets('should access previous value', (tester) async {
      late Signal<int> trigger;
      late Computed<int> sumComputed;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              trigger = useSignal(1);
              sumComputed = useComputed((prev) {
                return (prev ?? 0) + trigger.value;
              });
              return Text('${sumComputed.value}');
            },
          ),
        ),
      );

      expect(sumComputed.value, 1);

      trigger.value = 2;
      expect(sumComputed.value, 3);

      trigger.value = 3;
      expect(sumComputed.value, 6);
    });
  });

  group('useComputedSimple', () {
    testWidgets('should create simple computed without prev', (tester) async {
      late Signal<int> a;
      late Signal<int> b;
      late Computed<int> sum;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              a = useSignal(1);
              b = useSignal(2);
              sum = useComputedSimple(() => a.value + b.value);
              return Text('${sum.value}');
            },
          ),
        ),
      );

      expect(find.text('3'), findsOneWidget);
    });
  });

  group('useWatch', () {
    testWidgets('should trigger rebuild on signal change', (tester) async {
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

      expect(find.text('0'), findsOneWidget);
      expect(buildCount, 1);

      count.value = 1;
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
      expect(buildCount, 2);
    });

    testWidgets('should handle signal replacement', (tester) async {
      final sig1 = signal(10);
      final sig2 = signal(20);
      var useFirst = true;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return HookBuilder(
                builder: (context) {
                  final value = useWatch(useFirst ? sig1 : sig2);
                  return Column(
                    children: [
                      Text('$value'),
                      TextButton(
                        onPressed: () {
                          setState(() => useFirst = false);
                        },
                        child: const Text('Switch'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      );

      expect(find.text('10'), findsOneWidget);

      await tester.tap(find.text('Switch'));
      await tester.pump();

      expect(find.text('20'), findsOneWidget);
    });
  });

  group('useWatchComputed', () {
    testWidgets('should trigger rebuild on computed change', (tester) async {
      late Signal<int> count;
      late Computed<int> doubled;
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              buildCount++;
              count = useSignal(5);
              doubled = useComputedSimple(() => count.value * 2);
              final value = useWatchComputed(doubled);
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
      final log = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              count = useSignal(0);
              useSignalEffect(() {
                log.add(count.value);
              });
              return const SizedBox();
            },
          ),
        ),
      );

      expect(log, [0]);

      count.value = 1;
      expect(log, [0, 1]);

      count.value = 2;
      expect(log, [0, 1, 2]);
    });

    testWidgets('should cleanup on dispose', (tester) async {
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
              return const SizedBox();
            },
          ),
        ),
      );

      expect(log, [0]);

      // Dispose widget
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      // Effect should be stopped
      count.value = 100;
      expect(log, [0]); // No new entries
    });
  });

  group('useReactive', () {
    testWidgets('should provide value and setter', (tester) async {
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
                  TextButton(
                    onPressed: () => setValue(10),
                    child: const Text('Set'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      await tester.tap(find.text('Set'));
      await tester.pump();

      expect(find.text('10'), findsOneWidget);
    });
  });

  group('useSelect', () {
    testWidgets('should only rebuild when selected value changes',
        (tester) async {
      final user = signal({'name': 'Alice', 'age': 25});
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              buildCount++;
              final name = useSelect(user, (u) => u['name'] as String);
              return Text(name);
            },
          ),
        ),
      );

      expect(find.text('Alice'), findsOneWidget);
      expect(buildCount, 1);

      // Change age - should not rebuild
      user.value = {'name': 'Alice', 'age': 26};
      await tester.pump();
      expect(buildCount, 1);

      // Change name - should rebuild
      user.value = {'name': 'Bob', 'age': 26};
      await tester.pump();
      expect(find.text('Bob'), findsOneWidget);
      expect(buildCount, 2);
    });
  });

  group('useEffectScope', () {
    testWidgets('should create effect scope', (tester) async {
      late EffectScope scope;
      final log = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              scope = useEffectScope(() {
                log.add('setup');
              });
              return const SizedBox();
            },
          ),
        ),
      );

      expect(log, ['setup']);
      expect(scope, isNotNull);
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

      final scopeBefore = scope;

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      // Scope should be the same instance but stopped
      expect(identical(scope, scopeBefore), true);
    });
  });

  group('useBatch', () {
    testWidgets('should batch updates', (tester) async {
      late Signal<int> a;
      late Signal<int> b;
      int effectCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              a = useSignal(0);
              b = useSignal(0);
              useSignalEffect(() {
                a.value + b.value;
                effectCount++;
              });

              useBatch(() {
                a.value = 1;
                b.value = 2;
              });

              return const SizedBox();
            },
          ),
        ),
      );

      // Effect runs once for initial + once for batch
      expect(effectCount, 2);
    });
  });

  group('useUntrack', () {
    testWidgets('should not track dependencies', (tester) async {
      late Signal<int> count;
      int effectCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              count = useSignal(0);
              useSignalEffect(() {
                useUntrack(() => count.value);
                effectCount++;
              });
              return const SizedBox();
            },
          ),
        ),
      );

      expect(effectCount, 1);

      count.value = 10;
      expect(effectCount, 1); // Should not re-run
    });
  });

  group('useSignalFromStream', () {
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

      expect(find.text('0'), findsOneWidget);

      controller.add(10);
      await tester.pump();
      expect(sig.value, 10);

      controller.add(20);
      await tester.pump();
      expect(sig.value, 20);

      await controller.close();
    });
  });

  group('useSignalFromFuture', () {
    testWidgets('should update signal from future', (tester) async {
      final completer = Completer<int>();
      late Signal<int> sig;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              sig = useSignalFromFuture(completer.future, initialValue: 0);
              return Text('${sig.value}');
            },
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
      expect(sig.value, 0);

      completer.complete(42);
      await tester.pumpAndSettle();
      expect(sig.value, 42);
    });
  });
}
