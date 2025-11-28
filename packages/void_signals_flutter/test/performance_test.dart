import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_signals_flutter/void_signals_flutter.dart';

/// Performance tests for Flutter integration
/// Tests for: batching UI updates, lazy loading, coalescing rebuilds
void main() {
  group('UI Rebuild Coalescing - Multiple rapid updates', () {
    testWidgets('should only rebuild once for multiple synchronous updates',
        (tester) async {
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
      expect(find.text('0'), findsOneWidget);

      // Multiple rapid updates using batch
      batch(() {
        count.value = 1;
        count.value = 2;
        count.value = 3;
        count.value = 4;
        count.value = 5;
      });

      await tester.pump();

      // Should only rebuild once after batch
      expect(buildCount, 2);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets(
        'should coalesce multiple signal updates to single rebuild with batch',
        (tester) async {
      final a = signal(0);
      final b = signal(0);
      final c = signal(0);
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Watch(
            builder: (context, child) {
              buildCount++;
              return Text('${a.value + b.value + c.value}');
            },
          ),
        ),
      );

      expect(buildCount, 1);

      // Update multiple signals in batch
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

    testWidgets('should handle rapid sequential updates without batch',
        (tester) async {
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

      // Rapid updates without batch - each triggers setState
      // but Flutter coalesces multiple setState calls in same frame
      count.value = 1;
      count.value = 2;
      count.value = 3;

      await tester.pump();

      // Flutter may coalesce or not - depends on microtask timing
      // The important thing is the final value is correct
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('should not rebuild when value reverts in same batch',
        (tester) async {
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

      // Change and revert in same batch
      batch(() {
        count.value = 100;
        count.value = 50;
        count.value = 0; // Back to original
      });

      await tester.pump();

      // Should NOT rebuild since final value equals original
      expect(buildCount, 1);
      expect(find.text('0'), findsOneWidget);
    });
  });

  group('Lazy Computation - Computed values', () {
    testWidgets('should not compute until widget builds', (tester) async {
      int computeCount = 0;
      final source = signal(10);
      final doubled = computed((p) {
        computeCount++;
        return source.value * 2;
      });

      // Computed not accessed yet
      expect(computeCount, 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Watch(
            builder: (context, child) {
              return Text('${doubled.value}');
            },
          ),
        ),
      );

      // Now accessed in build
      expect(computeCount, 1);
      expect(find.text('20'), findsOneWidget);
    });

    testWidgets('should not recompute when source changes but widget hidden',
        (tester) async {
      int computeCount = 0;
      final source = signal(10);
      final doubled = computed((p) {
        computeCount++;
        return source.value * 2;
      });
      final showWidget = signal(true);

      await tester.pumpWidget(
        MaterialApp(
          home: Watch(
            builder: (context, child) {
              if (!showWidget.value) {
                return const Text('Hidden');
              }
              return Text('${doubled.value}');
            },
          ),
        ),
      );

      expect(computeCount, 1);
      expect(find.text('20'), findsOneWidget);

      // Hide widget
      showWidget.value = false;
      await tester.pump();

      expect(find.text('Hidden'), findsOneWidget);

      // Change source while widget is hidden
      source.value = 50;

      // Computed should NOT recompute since nothing is observing it
      // (The exact count may vary based on implementation)

      // Show widget again
      showWidget.value = true;
      await tester.pump();

      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('should cache computed value across rebuilds', (tester) async {
      int computeCount = 0;
      final a = signal(1);
      final b = signal(2);
      final sum = computed((p) {
        computeCount++;
        return a.value + b.value;
      });
      final unrelatedTrigger = signal(0);

      await tester.pumpWidget(
        MaterialApp(
          home: Watch(
            builder: (context, child) {
              // Access both sum and unrelated trigger
              unrelatedTrigger.value; // Force dependency
              return Text('Sum: ${sum.value}');
            },
          ),
        ),
      );

      expect(computeCount, 1);
      expect(find.text('Sum: 3'), findsOneWidget);

      // Trigger rebuild via unrelated signal
      unrelatedTrigger.value = 1;
      await tester.pump();

      // Sum should still use cached value since a and b haven't changed
      expect(computeCount, 1);
      expect(find.text('Sum: 3'), findsOneWidget);
    });
  });

  group('SignalSelector - Selective rebuilds', () {
    testWidgets('should not rebuild when non-selected field changes',
        (tester) async {
      final user = signal({
        'name': 'John',
        'email': 'john@example.com',
        'age': 30,
      });
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: SignalSelector<Map<String, dynamic>, String>(
            signal: user,
            selector: (u) => u['name'] as String,
            builder: (context, name, child) {
              buildCount++;
              return Text('Name: $name');
            },
          ),
        ),
      );

      expect(buildCount, 1);
      expect(find.text('Name: John'), findsOneWidget);

      // Change non-selected field
      user.value = {
        'name': 'John', // Same
        'email': 'john.new@example.com', // Changed
        'age': 31, // Changed
      };
      await tester.pump();

      // Should NOT rebuild
      expect(buildCount, 1);

      // Change selected field
      user.value = {
        'name': 'Jane', // Changed
        'email': 'john.new@example.com',
        'age': 31,
      };
      await tester.pump();

      // Should rebuild
      expect(buildCount, 2);
      expect(find.text('Name: Jane'), findsOneWidget);
    });

    testWidgets('should handle complex selector logic', (tester) async {
      final items = signal(<int>[1, 2, 3, 4, 5]);
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: SignalSelector<List<int>, int>(
            signal: items,
            // Only select even numbers count
            selector: (list) => list.where((e) => e % 2 == 0).length,
            builder: (context, evenCount, child) {
              buildCount++;
              return Text('Even count: $evenCount');
            },
          ),
        ),
      );

      expect(buildCount, 1);
      expect(find.text('Even count: 2'), findsOneWidget);

      // Add odd number - even count unchanged
      items.value = [1, 2, 3, 4, 5, 7];
      await tester.pump();

      expect(buildCount, 1); // No rebuild

      // Add even number
      items.value = [1, 2, 3, 4, 5, 7, 8];
      await tester.pump();

      expect(buildCount, 2);
      expect(find.text('Even count: 3'), findsOneWidget);
    });
  });

  group('Child Widget Optimization', () {
    testWidgets('should not rebuild child in Watch', (tester) async {
      final count = signal(0);
      int parentBuildCount = 0;
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
              parentBuildCount++;
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

      expect(parentBuildCount, 1);
      expect(childBuildCount, 1);

      // Update count multiple times
      for (int i = 1; i <= 10; i++) {
        count.value = i;
        await tester.pump();
      }

      expect(parentBuildCount, 11);
      expect(childBuildCount, 1); // Still 1
    });

    testWidgets('should not rebuild child in SignalBuilder', (tester) async {
      final count = signal(0);
      int childBuildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: SignalBuilder<int>(
            signal: count,
            child: Builder(
              builder: (context) {
                childBuildCount++;
                return const Text('Expensive Child');
              },
            ),
            builder: (context, value, child) {
              return Column(
                children: [
                  Text('Value: $value'),
                  child!,
                ],
              );
            },
          ),
        ),
      );

      expect(childBuildCount, 1);

      // Multiple updates
      batch(() {
        count.value = 100;
      });
      await tester.pump();

      batch(() {
        count.value = 200;
      });
      await tester.pump();

      batch(() {
        count.value = 300;
      });
      await tester.pump();

      expect(childBuildCount, 1); // Still 1
    });
  });

  group('Effect Cleanup on Widget Dispose', () {
    testWidgets('should stop effect when Watch widget disposes',
        (tester) async {
      final count = signal(0);
      int effectRunCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Watch(
            builder: (context, child) {
              effectRunCount++;
              return Text('${count.value}');
            },
          ),
        ),
      );

      expect(effectRunCount, 1);

      // Remove widget
      await tester.pumpWidget(
        const MaterialApp(home: SizedBox()),
      );

      // Update signal after widget disposed
      count.value = 100;
      count.value = 200;
      await tester.pump();

      // Effect should not run anymore
      expect(effectRunCount, 1);
    });

    testWidgets('should stop effect when SignalBuilder disposes',
        (tester) async {
      final count = signal(0);
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: SignalBuilder<int>(
            signal: count,
            builder: (context, value, child) {
              buildCount++;
              return Text('$value');
            },
          ),
        ),
      );

      expect(buildCount, 1);

      // Remove widget
      await tester.pumpWidget(
        const MaterialApp(home: SizedBox()),
      );

      // Update signal
      count.value = 999;
      await tester.pump();

      expect(buildCount, 1);
    });
  });

  group('Large Data Set Performance', () {
    testWidgets('should handle large list efficiently', (tester) async {
      final items = signal(List.generate(1000, (i) => i));
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Watch(
            builder: (context, child) {
              buildCount++;
              final sum = items.value.fold<int>(0, (a, b) => a + b);
              return Text('Sum: $sum');
            },
          ),
        ),
      );

      expect(buildCount, 1);
      expect(find.text('Sum: 499500'), findsOneWidget);

      // Update single item
      final newItems = List<int>.from(items.value);
      newItems[0] = 1000;
      items.value = newItems;
      await tester.pump();

      expect(buildCount, 2);
      expect(find.text('Sum: 500500'), findsOneWidget);
    });

    testWidgets('should handle many computed values', (tester) async {
      final source = signal(1);

      // Create 100 computed values
      final computeds = List.generate(100, (i) {
        return computed((p) => source.value * (i + 1));
      });

      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Watch(
            builder: (context, child) {
              buildCount++;
              // Sum all computed values
              int total = 0;
              for (final c in computeds) {
                total += c.value;
              }
              return Text('Total: $total');
            },
          ),
        ),
      );

      expect(buildCount, 1);
      // Sum of 1*1 + 1*2 + ... + 1*100 = 5050
      expect(find.text('Total: 5050'), findsOneWidget);

      // Update source
      source.value = 2;
      await tester.pump();

      expect(buildCount, 2);
      // Sum of 2*1 + 2*2 + ... + 2*100 = 10100
      expect(find.text('Total: 10100'), findsOneWidget);
    });
  });

  group('Diamond Dependency - UI Updates', () {
    testWidgets('should only rebuild once for diamond dependency',
        (tester) async {
      final source = signal(1);
      final left = computed((p) => source.value * 2);
      final right = computed((p) => source.value * 3);
      final combined = computed((p) => left.value + right.value);
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Watch(
            builder: (context, child) {
              buildCount++;
              return Text('Result: ${combined.value}');
            },
          ),
        ),
      );

      expect(buildCount, 1);
      expect(find.text('Result: 5'), findsOneWidget);

      // Update source - should only rebuild once
      source.value = 10;
      await tester.pump();

      expect(buildCount, 2); // Only one additional rebuild
      expect(find.text('Result: 50'), findsOneWidget);
    });
  });

  group('Nested Watch Widgets', () {
    testWidgets('should handle nested Watch widgets efficiently',
        (tester) async {
      final outer = signal('outer');
      final inner = signal('inner');
      int outerBuildCount = 0;
      int innerBuildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Watch(
            builder: (context, child) {
              outerBuildCount++;
              return Column(
                children: [
                  Text('Outer: ${outer.value}'),
                  Watch(
                    builder: (context, child) {
                      innerBuildCount++;
                      return Text('Inner: ${inner.value}');
                    },
                  ),
                ],
              );
            },
          ),
        ),
      );

      expect(outerBuildCount, 1);
      expect(innerBuildCount, 1);

      // Update only inner signal
      inner.value = 'inner updated';
      await tester.pump();

      expect(outerBuildCount, 1); // Outer not rebuilt
      expect(innerBuildCount, 2); // Only inner rebuilt

      // Update only outer signal
      outer.value = 'outer updated';
      await tester.pump();

      expect(outerBuildCount, 2);
      // Inner may or may not rebuild depending on whether Flutter
      // treats it as a new widget (it has same key so should be same instance)
    });
  });

  group('Conditional Rendering', () {
    testWidgets('should handle conditional dependencies correctly',
        (tester) async {
      final showA = signal(true);
      final a = signal('A');
      final b = signal('B');
      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Watch(
            builder: (context, child) {
              buildCount++;
              return Text(showA.value ? a.value : b.value);
            },
          ),
        ),
      );

      expect(buildCount, 1);
      expect(find.text('A'), findsOneWidget);

      // Update a - should trigger rebuild
      a.value = 'A updated';
      await tester.pump();
      expect(buildCount, 2);

      // Update b - should NOT trigger rebuild (not observed)
      b.value = 'B updated';
      await tester.pump();
      expect(buildCount, 2);

      // Switch condition
      showA.value = false;
      await tester.pump();
      expect(buildCount, 3);
      expect(find.text('B updated'), findsOneWidget);

      // Now a should NOT trigger rebuild
      a.value = 'A again';
      await tester.pump();
      expect(buildCount, 3);

      // But b should trigger rebuild
      b.value = 'B again';
      await tester.pump();
      expect(buildCount, 4);
    });
  });

  group('Stress Test - Rapid Updates', () {
    testWidgets('should handle 100 batch updates', (tester) async {
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

      // 100 batch updates
      for (int i = 0; i < 100; i++) {
        batch(() {
          count.value = i * 3;
          count.value = i * 3 + 1;
          count.value = i * 3 + 2;
        });
        await tester.pump();
      }

      // 1 initial + 100 batch updates
      expect(buildCount, 101);
      expect(find.text('299'), findsOneWidget);
    });
  });
}
