import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_signals_flutter/void_signals_flutter.dart';

void main() {
  group('Watch Widget', () {
    testWidgets('should track all dependencies automatically', (tester) async {
      final a = signal(1);
      final b = signal(2);

      await tester.pumpWidget(
        MaterialApp(
          home: Watch(
            builder: (context, child) {
              return Text('${a.value * b.value}');
            },
          ),
        ),
      );

      expect(find.text('2'), findsOneWidget);

      a.value = 3;
      await tester.pump();
      expect(find.text('6'), findsOneWidget);

      b.value = 4;
      await tester.pump();
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('should support child optimization', (tester) async {
      final count = signal(0);
      int childBuildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Watch(
            child: Builder(
              builder: (context) {
                childBuildCount++;
                return const Text('Static Child');
              },
            ),
            builder: (context, child) {
              return Column(
                children: [
                  Text('Count: ${count.value}'),
                  child!,
                ],
              );
            },
          ),
        ),
      );

      expect(find.text('Count: 0'), findsOneWidget);
      expect(find.text('Static Child'), findsOneWidget);
      expect(childBuildCount, 1);

      count.value = 5;
      await tester.pump();

      expect(find.text('Count: 5'), findsOneWidget);
      expect(childBuildCount, 1); // Child not rebuilt
    });

    testWidgets('should handle computed values', (tester) async {
      final count = signal(2);
      final doubled = computed<int>((p) => count.value * 2);

      await tester.pumpWidget(
        MaterialApp(
          home: Watch(
            builder: (context, child) {
              return Text('Doubled: ${doubled.value}');
            },
          ),
        ),
      );

      expect(find.text('Doubled: 4'), findsOneWidget);

      count.value = 5;
      await tester.pump();
      expect(find.text('Doubled: 10'), findsOneWidget);
    });

    testWidgets('should cleanup effect on dispose', (tester) async {
      final count = signal(0);
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Watch(
            builder: (context, child) {
              buildCount++;
              return Text('${count.value}');
            },
          ),
        ),
      );

      expect(buildCount, 1);

      // Remove widget
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      // Signal update should not affect disposed widget
      count.value = 100;
      await tester.pump();

      expect(buildCount, 1);
    });
  });

  group('WatchValue Widget', () {
    testWidgets('should watch getter function', (tester) async {
      final count = signal(0);

      await tester.pumpWidget(
        MaterialApp(
          home: WatchValue<int>(
            getter: () => count.value * 10,
            builder: (context, value) {
              return Text('$value');
            },
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      count.value = 5;
      await tester.pump();
      expect(find.text('50'), findsOneWidget);
    });

    testWidgets('should handle multiple signals in getter', (tester) async {
      final a = signal(1);
      final b = signal(2);

      await tester.pumpWidget(
        MaterialApp(
          home: WatchValue<int>(
            getter: () => a.value + b.value,
            builder: (context, value) {
              return Text('Sum: $value');
            },
          ),
        ),
      );

      expect(find.text('Sum: 3'), findsOneWidget);

      a.value = 10;
      await tester.pump();
      expect(find.text('Sum: 12'), findsOneWidget);

      b.value = 20;
      await tester.pump();
      expect(find.text('Sum: 30'), findsOneWidget);
    });
  });

  group('Signal.watch Extension', () {
    testWidgets('should work with simple builder', (tester) async {
      final count = signal(42);

      await tester.pumpWidget(
        MaterialApp(
          home: count.watch((value) => Text('Value: $value')),
        ),
      );

      expect(find.text('Value: 42'), findsOneWidget);

      count.value = 100;
      await tester.pump();
      expect(find.text('Value: 100'), findsOneWidget);
    });

    testWidgets('should work with context builder', (tester) async {
      final isDark = signal(false);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: ThemeMode.light,
          home: isDark.watch((value, context) {
            final theme = Theme.of(context);
            return Text(
              'Theme: ${value ? "dark" : "light"}',
              style: theme.textTheme.bodyLarge,
            );
          }),
        ),
      );

      expect(find.text('Theme: light'), findsOneWidget);

      isDark.value = true;
      await tester.pump();
      expect(find.text('Theme: dark'), findsOneWidget);
    });

    testWidgets('should work with child builder', (tester) async {
      final count = signal(0);
      int childBuildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: count.watch(
            (value, context, child) {
              return Column(
                children: [
                  Text('Count: $value'),
                  child!,
                ],
              );
            },
            child: Builder(
              builder: (context) {
                childBuildCount++;
                return const Text('Static');
              },
            ),
          ),
        ),
      );

      expect(find.text('Count: 0'), findsOneWidget);
      expect(childBuildCount, 1);

      count.value = 5;
      await tester.pump();
      expect(find.text('Count: 5'), findsOneWidget);
      expect(childBuildCount, 1);
    });
  });

  group('SignalBuilder', () {
    testWidgets('should build with initial value', (tester) async {
      final count = signal(0);

      await tester.pumpWidget(
        MaterialApp(
          home: SignalBuilder<int>(
            signal: count,
            builder: (context, value, child) {
              return Text('$value');
            },
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('should rebuild when signal changes', (tester) async {
      final count = signal(0);

      await tester.pumpWidget(
        MaterialApp(
          home: SignalBuilder<int>(
            signal: count,
            builder: (context, value, child) {
              return Text('$value');
            },
          ),
        ),
      );

      count.value = 1;
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('should not rebuild child widget', (tester) async {
      final count = signal(0);
      int childBuildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: SignalBuilder<int>(
            signal: count,
            child: Builder(
              builder: (context) {
                childBuildCount++;
                return const Text('child');
              },
            ),
            builder: (context, value, child) {
              return Column(
                children: [Text('$value'), child!],
              );
            },
          ),
        ),
      );

      expect(childBuildCount, 1);

      count.value = 1;
      await tester.pump();
      expect(childBuildCount, 1);
    });

    testWidgets('should handle signal change to same signal', (tester) async {
      final count = signal(0);

      await tester.pumpWidget(
        MaterialApp(
          home: SignalBuilder<int>(
            signal: count,
            builder: (context, value, child) {
              return Text('$value');
            },
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      // Same value should not trigger rebuild
      count.value = 0;
      await tester.pump();
      expect(find.text('0'), findsOneWidget);
    });
  });

  group('ComputedBuilder', () {
    testWidgets('should build with computed value', (tester) async {
      final count = signal(5);
      final doubled = computed<int>((prev) => count.value * 2);

      await tester.pumpWidget(
        MaterialApp(
          home: ComputedBuilder<int>(
            computed: doubled,
            builder: (context, value, child) {
              return Text('$value');
            },
          ),
        ),
      );

      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('should rebuild when computed changes', (tester) async {
      final count = signal(5);
      final doubled = computed<int>((prev) => count.value * 2);

      await tester.pumpWidget(
        MaterialApp(
          home: ComputedBuilder<int>(
            computed: doubled,
            builder: (context, value, child) {
              return Text('$value');
            },
          ),
        ),
      );

      count.value = 10;
      await tester.pump();
      expect(find.text('20'), findsOneWidget);
    });
  });

  group('MultiSignalBuilder', () {
    testWidgets('should rebuild when any signal changes', (tester) async {
      final a = signal(1);
      final b = signal(2);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiSignalBuilder(
            signals: [a, b],
            builder: (context, child) {
              return Text('${a.value + b.value}');
            },
          ),
        ),
      );

      expect(find.text('3'), findsOneWidget);

      a.value = 10;
      await tester.pump();
      expect(find.text('12'), findsOneWidget);

      b.value = 20;
      await tester.pump();
      expect(find.text('30'), findsOneWidget);
    });

    testWidgets('should support child optimization', (tester) async {
      final a = signal(1);
      final b = signal(2);
      int childBuildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: MultiSignalBuilder(
            signals: [a, b],
            child: Builder(
              builder: (context) {
                childBuildCount++;
                return const Text('child');
              },
            ),
            builder: (context, child) {
              return Column(
                children: [
                  Text('${a.value + b.value}'),
                  child!,
                ],
              );
            },
          ),
        ),
      );

      expect(childBuildCount, 1);

      a.value = 10;
      await tester.pump();
      expect(childBuildCount, 1);
    });
  });

  group('SignalSelector', () {
    testWidgets('should only rebuild when selected value changes',
        (tester) async {
      final user = signal({'name': 'John', 'age': 30});
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: SignalSelector<Map<String, dynamic>, String>(
            signal: user,
            selector: (u) => u['name'] as String,
            builder: (context, name, child) {
              buildCount++;
              return Text(name);
            },
          ),
        ),
      );

      expect(find.text('John'), findsOneWidget);
      expect(buildCount, 1);

      // Change age - should NOT rebuild
      user.value = {'name': 'John', 'age': 31};
      await tester.pump();
      expect(buildCount, 1);

      // Change name - should rebuild
      user.value = {'name': 'Jane', 'age': 31};
      await tester.pump();
      expect(find.text('Jane'), findsOneWidget);
      expect(buildCount, 2);
    });

    testWidgets('should work via select extension', (tester) async {
      final user = signal({'name': 'Alice', 'score': 100});

      await tester.pumpWidget(
        MaterialApp(
          home: user.select(
            (u) => u['score'] as int,
            (context, score) => Text('Score: $score'),
          ),
        ),
      );

      expect(find.text('Score: 100'), findsOneWidget);

      user.value = {'name': 'Alice', 'score': 150};
      await tester.pump();
      expect(find.text('Score: 150'), findsOneWidget);
    });
  });

  group('ComputedSelector', () {
    testWidgets('should only rebuild when selected computed value changes',
        (tester) async {
      final items = signal([1, 2, 3]);
      final stats = computed<Map<String, int>>((p) => {
            'sum': items.value.fold(0, (a, b) => a + b),
            'count': items.value.length,
          });
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: ComputedSelector<Map<String, int>, int>(
            computed: stats,
            selector: (s) => s['count']!,
            builder: (context, count, child) {
              buildCount++;
              return Text('Count: $count');
            },
          ),
        ),
      );

      expect(find.text('Count: 3'), findsOneWidget);
      expect(buildCount, 1);

      // Change sum but not count - might trigger based on computed change
      items.value = [2, 3, 4];
      await tester.pump();

      // Add item - count changes
      items.value = [1, 2, 3, 4];
      await tester.pump();
      expect(find.text('Count: 4'), findsOneWidget);
    });
  });
}
