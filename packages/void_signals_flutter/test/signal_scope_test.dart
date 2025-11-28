import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_signals_flutter/void_signals_flutter.dart';

/// Tests for SignalScope - value override and scoped signals
void main() {
  group('SignalScope - Basic Override', () {
    testWidgets('should override signal value in subtree', (tester) async {
      final counter = signal(0);

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              // Outside scope - uses original value
              Watch(
                builder: (context, child) {
                  return Text('Outside: ${counter.value}');
                },
              ),
              // Inside scope - uses overridden value
              SignalScope(
                overrides: [counter.override(100)],
                child: Builder(
                  builder: (context) {
                    final localCounter = counter.scoped(context);
                    return Watch(
                      builder: (context, child) {
                        return Text('Inside: ${localCounter.value}');
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );

      expect(find.text('Outside: 0'), findsOneWidget);
      expect(find.text('Inside: 100'), findsOneWidget);
    });

    testWidgets('should allow modifying scoped signal independently',
        (tester) async {
      final counter = signal(0);

      late Signal<int> scopedCounter;

      await tester.pumpWidget(
        MaterialApp(
          home: SignalScope(
            overrides: [counter.override(50)],
            child: Builder(
              builder: (context) {
                scopedCounter = counter.scoped(context);
                return Watch(
                  builder: (context, child) {
                    return Column(
                      children: [
                        Text('Global: ${counter.value}'),
                        Text('Scoped: ${scopedCounter.value}'),
                        ElevatedButton(
                          onPressed: () => scopedCounter.value++,
                          child: const Text('Increment Scoped'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Global: 0'), findsOneWidget);
      expect(find.text('Scoped: 50'), findsOneWidget);

      // Tap button to increment scoped counter
      await tester.tap(find.text('Increment Scoped'));
      await tester.pump();

      expect(find.text('Global: 0'), findsOneWidget); // Unchanged
      expect(find.text('Scoped: 51'), findsOneWidget); // Changed
    });

    testWidgets('should return original signal when no scope', (tester) async {
      final counter = signal(42);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final scoped = counter.scoped(context);
              // Should be the same signal since no SignalScope
              return Watch(
                builder: (context, child) {
                  return Text('Value: ${scoped.value}');
                },
              );
            },
          ),
        ),
      );

      expect(find.text('Value: 42'), findsOneWidget);

      counter.value = 100;
      await tester.pump();

      expect(find.text('Value: 100'), findsOneWidget);
    });
  });

  group('SignalScope - Nested Scopes', () {
    testWidgets('should support nested scopes with different overrides',
        (tester) async {
      final counter = signal(0);

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              Watch(
                builder: (context, child) {
                  return Text('Root: ${counter.value}');
                },
              ),
              SignalScope(
                overrides: [counter.override(100)],
                child: Builder(
                  builder: (context) {
                    final level1 = counter.scoped(context);
                    return Column(
                      children: [
                        Watch(
                          builder: (context, child) {
                            return Text('Level1: ${level1.value}');
                          },
                        ),
                        SignalScope(
                          overrides: [counter.override(200)],
                          child: Builder(
                            builder: (context) {
                              final level2 = counter.scoped(context);
                              return Watch(
                                builder: (context, child) {
                                  return Text('Level2: ${level2.value}');
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );

      expect(find.text('Root: 0'), findsOneWidget);
      expect(find.text('Level1: 100'), findsOneWidget);
      expect(find.text('Level2: 200'), findsOneWidget);
    });

    testWidgets('should inherit from parent scope for non-overridden signals',
        (tester) async {
      final a = signal(1);
      final b = signal(2);

      await tester.pumpWidget(
        MaterialApp(
          home: SignalScope(
            overrides: [a.override(10), b.override(20)],
            child: SignalScope(
              overrides: [a.override(100)], // Only override a
              child: Builder(
                builder: (context) {
                  final scopedA = a.scoped(context);
                  final scopedB = b.scoped(context);
                  return Watch(
                    builder: (context, child) {
                      return Text('A: ${scopedA.value}, B: ${scopedB.value}');
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );

      // a should be from inner scope (100)
      // b should be from parent scope (20)
      expect(find.text('A: 100, B: 20'), findsOneWidget);
    });
  });

  group('SignalScope - Multiple Overrides', () {
    testWidgets('should support multiple signal overrides', (tester) async {
      final name = signal('John');
      final age = signal(30);
      final active = signal(false);

      await tester.pumpWidget(
        MaterialApp(
          home: SignalScope(
            overrides: [
              name.override('Jane'),
              age.override(25),
              active.override(true),
            ],
            child: Builder(
              builder: (context) {
                final scopedName = name.scoped(context);
                final scopedAge = age.scoped(context);
                final scopedActive = active.scoped(context);
                return Watch(
                  builder: (context, child) {
                    return Text(
                      '${scopedName.value}, ${scopedAge.value}, ${scopedActive.value}',
                    );
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Jane, 25, true'), findsOneWidget);
    });
  });

  group('SignalScope - With Navigation', () {
    testWidgets('should maintain separate state across routes', (tester) async {
      final counter = signal(0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Watch(
                  builder: (context, child) {
                    return Text('Home: ${counter.value}');
                  },
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(tester.element(find.byType(Scaffold))).push(
                      MaterialPageRoute(
                        builder: (_) => SignalScope(
                          overrides: [counter.override(999)],
                          child: Builder(
                            builder: (context) {
                              final localCounter = counter.scoped(context);
                              return Scaffold(
                                body: Watch(
                                  builder: (context, child) {
                                    return Column(
                                      children: [
                                        Text('Detail: ${localCounter.value}'),
                                        ElevatedButton(
                                          onPressed: () => localCounter.value++,
                                          child: const Text('Increment'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          child: const Text('Back'),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text('Go to Detail'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Home: 0'), findsOneWidget);

      // Navigate to detail
      await tester.tap(find.text('Go to Detail'));
      await tester.pumpAndSettle();

      expect(find.text('Detail: 999'), findsOneWidget);

      // Increment local counter
      await tester.tap(find.text('Increment'));
      await tester.pump();

      expect(find.text('Detail: 1000'), findsOneWidget);

      // Go back
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      // Global counter should be unchanged
      expect(find.text('Home: 0'), findsOneWidget);
    });
  });

  group('SignalScope - Edge Cases', () {
    testWidgets('should handle empty overrides list', (tester) async {
      final counter = signal(42);

      await tester.pumpWidget(
        MaterialApp(
          home: SignalScope(
            overrides: const [], // Empty
            child: Builder(
              builder: (context) {
                final scoped = counter.scoped(context);
                return Watch(
                  builder: (context, child) {
                    return Text('Value: ${scoped.value}');
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Value: 42'), findsOneWidget);
    });

    testWidgets('should handle scope disposed before child uses signal',
        (tester) async {
      final counter = signal(0);
      final showScope = signal(true);

      await tester.pumpWidget(
        MaterialApp(
          home: Watch(
            builder: (context, child) {
              if (!showScope.value) {
                return const Text('No Scope');
              }
              return SignalScope(
                overrides: [counter.override(100)],
                child: Builder(
                  builder: (context) {
                    final scoped = counter.scoped(context);
                    return Text('Scoped: ${scoped.value}');
                  },
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Scoped: 100'), findsOneWidget);

      // Hide scope
      showScope.value = false;
      await tester.pump();

      expect(find.text('No Scope'), findsOneWidget);

      // Show scope again
      showScope.value = true;
      await tester.pump();

      expect(find.text('Scoped: 100'), findsOneWidget);
    });

    testWidgets('should handle scope recreation correctly', (tester) async {
      final counter = signal(0);
      final overrideValue = signal(50);

      await tester.pumpWidget(
        MaterialApp(
          home: Watch(
            builder: (context, child) {
              return SignalScope(
                // Use a key based on override value to force widget recreation
                key: ValueKey(overrideValue.value),
                overrides: [counter.override(overrideValue.value)],
                child: Builder(
                  builder: (context) {
                    final scoped = counter.scoped(context);
                    return Watch(
                      builder: (context, child) {
                        return Text('Value: ${scoped.value}');
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Value: 50'), findsOneWidget);

      // Change override value - this creates a new SignalScope with new key
      overrideValue.value = 150;
      await tester.pump();

      // New scope with new override
      expect(find.text('Value: 150'), findsOneWidget);
    });
  });

  group('Signal Extensions - State Management', () {
    testWidgets('should support modify extension', (tester) async {
      final counter = signal(0);

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              Watch(
                builder: (context, child) {
                  return Text('Count: ${counter.value}');
                },
              ),
              ElevatedButton(
                onPressed: () => counter.modify((v) => v + 10),
                child: const Text('Add 10'),
              ),
            ],
          ),
        ),
      );

      expect(find.text('Count: 0'), findsOneWidget);

      await tester.tap(find.text('Add 10'));
      await tester.pump();

      expect(find.text('Count: 10'), findsOneWidget);
    });

    testWidgets('should support increment/decrement for int', (tester) async {
      final counter = signal(5);

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              Watch(
                builder: (context, child) {
                  return Text('Count: ${counter.value}');
                },
              ),
              ElevatedButton(
                onPressed: () => counter.increment(),
                child: const Text('+1'),
              ),
              ElevatedButton(
                onPressed: () => counter.decrement(),
                child: const Text('-1'),
              ),
              ElevatedButton(
                onPressed: () => counter.increment(5),
                child: const Text('+5'),
              ),
            ],
          ),
        ),
      );

      expect(find.text('Count: 5'), findsOneWidget);

      await tester.tap(find.text('+1'));
      await tester.pump();
      expect(find.text('Count: 6'), findsOneWidget);

      await tester.tap(find.text('-1'));
      await tester.pump();
      expect(find.text('Count: 5'), findsOneWidget);

      await tester.tap(find.text('+5'));
      await tester.pump();
      expect(find.text('Count: 10'), findsOneWidget);
    });

    testWidgets('should support toggle for bool', (tester) async {
      final isDark = signal(false);

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              Watch(
                builder: (context, child) {
                  return Text('Dark: ${isDark.value}');
                },
              ),
              ElevatedButton(
                onPressed: () => isDark.toggle(),
                child: const Text('Toggle'),
              ),
            ],
          ),
        ),
      );

      expect(find.text('Dark: false'), findsOneWidget);

      await tester.tap(find.text('Toggle'));
      await tester.pump();
      expect(find.text('Dark: true'), findsOneWidget);

      await tester.tap(find.text('Toggle'));
      await tester.pump();
      expect(find.text('Dark: false'), findsOneWidget);
    });

    testWidgets('should support list operations', (tester) async {
      final items = signal<List<String>>([]);

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              Watch(
                builder: (context, child) {
                  return Text('Items: ${items.value.length}');
                },
              ),
              ElevatedButton(
                onPressed: () => items.add('item'),
                child: const Text('Add'),
              ),
              ElevatedButton(
                onPressed: () => items.clear(),
                child: const Text('Clear'),
              ),
            ],
          ),
        ),
      );

      expect(find.text('Items: 0'), findsOneWidget);

      await tester.tap(find.text('Add'));
      await tester.pump();
      expect(find.text('Items: 1'), findsOneWidget);

      await tester.tap(find.text('Add'));
      await tester.pump();
      expect(find.text('Items: 2'), findsOneWidget);

      await tester.tap(find.text('Clear'));
      await tester.pump();
      expect(find.text('Items: 0'), findsOneWidget);
    });

    testWidgets('should support map operations', (tester) async {
      final data = signal<Map<String, int>>({});

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              Watch(
                builder: (context, child) {
                  return Text('Keys: ${data.value.keys.join(", ")}');
                },
              ),
              ElevatedButton(
                onPressed: () => data.set('a', 1),
                child: const Text('Add A'),
              ),
              ElevatedButton(
                onPressed: () => data.set('b', 2),
                child: const Text('Add B'),
              ),
              ElevatedButton(
                onPressed: () => data.remove('a'),
                child: const Text('Remove A'),
              ),
            ],
          ),
        ),
      );

      expect(find.text('Keys: '), findsOneWidget);

      await tester.tap(find.text('Add A'));
      await tester.pump();
      expect(find.text('Keys: a'), findsOneWidget);

      await tester.tap(find.text('Add B'));
      await tester.pump();
      expect(find.text('Keys: a, b'), findsOneWidget);

      await tester.tap(find.text('Remove A'));
      await tester.pump();
      expect(find.text('Keys: b'), findsOneWidget);
    });

    testWidgets('should support nullable operations', (tester) async {
      final user = signal<String?>(null);

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              Watch(
                builder: (context, child) {
                  return Text('User: ${user.orDefault("Guest")}');
                },
              ),
              ElevatedButton(
                onPressed: () => user.value = 'John',
                child: const Text('Login'),
              ),
              ElevatedButton(
                onPressed: () => user.clear(),
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      );

      expect(find.text('User: Guest'), findsOneWidget);

      await tester.tap(find.text('Login'));
      await tester.pump();
      expect(find.text('User: John'), findsOneWidget);

      await tester.tap(find.text('Logout'));
      await tester.pump();
      expect(find.text('User: Guest'), findsOneWidget);
    });
  });
}
