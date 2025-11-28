import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_signals_flutter/void_signals_flutter.dart';

void main() {
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

      expect(find.text('0'), findsOneWidget);

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
            child: Builder(builder: (context) {
              childBuildCount++;
              return const Text('child');
            }),
            builder: (context, value, child) {
              return Column(
                children: [
                  Text('$value'),
                  child!,
                ],
              );
            },
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
      expect(find.text('child'), findsOneWidget);
      expect(childBuildCount, 1);

      count.value = 1;
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('child'), findsOneWidget);
      // Child should only be built once
      expect(childBuildCount, 1);
    });
  });

  group('ComputedBuilder', () {
    testWidgets('should build with computed value', (tester) async {
      final count = signal(0);
      final doubled = computed<int>((prev) => count() * 2);

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

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('should rebuild when computed changes', (tester) async {
      final count = signal(0);
      final doubled = computed<int>((prev) => count() * 2);

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

      expect(find.text('0'), findsOneWidget);

      count.value = 5;
      await tester.pump();

      expect(find.text('10'), findsOneWidget);
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
  });

  group('Signal Extensions', () {
    testWidgets('should create builder via extension', (tester) async {
      final count = signal(0);

      await tester.pumpWidget(
        MaterialApp(
          home: count.builder((context, value) => Text('$value')),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      count.value = 42;
      await tester.pump();

      expect(find.text('42'), findsOneWidget);
    });
  });

  group('EffectScope', () {
    testWidgets('should provide scope to children', (tester) async {
      EffectScope? capturedScope;

      await tester.pumpWidget(
        MaterialApp(
          home: EffectScopeWidget(
            onScopeCreated: (scope) {
              capturedScope = scope;
            },
            child: Builder(
              builder: (context) {
                return const Text('child');
              },
            ),
          ),
        ),
      );

      expect(capturedScope, isNotNull);
    });
  });

  group('Watch', () {
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
  });

  group('WatchValue', () {
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

      // Change age - should NOT rebuild since we're only watching name
      user.value = {'name': 'John', 'age': 31};
      await tester.pump();

      expect(buildCount, 1); // Still 1

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

  group('AsyncSignalBuilder', () {
    testWidgets('should show loading state', (tester) async {
      final asyncSig = signal<AsyncValue<String>>(const AsyncValue.loading());

      await tester.pumpWidget(
        MaterialApp(
          home: AsyncSignalBuilder<String>(
            signal: asyncSig,
            loading: (context) => const Text('Loading...'),
            data: (context, value) => Text(value),
            error: (context, error, stackTrace) => Text('Error: $error'),
          ),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('should show data state', (tester) async {
      final asyncSig =
          signal<AsyncValue<String>>(const AsyncValue.data('Hello'));

      await tester.pumpWidget(
        MaterialApp(
          home: AsyncSignalBuilder<String>(
            signal: asyncSig,
            loading: (context) => const Text('Loading...'),
            data: (context, value) => Text(value),
            error: (context, error, stackTrace) => Text('Error: $error'),
          ),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('should show error state', (tester) async {
      final asyncSig = signal<AsyncValue<String>>(
          AsyncValue.error('Oops', StackTrace.current));

      await tester.pumpWidget(
        MaterialApp(
          home: AsyncSignalBuilder<String>(
            signal: asyncSig,
            loading: (context) => const Text('Loading...'),
            data: (context, value) => Text(value),
            error: (context, error, stackTrace) => Text('Error: $error'),
          ),
        ),
      );

      expect(find.text('Error: Oops'), findsOneWidget);
    });

    testWidgets('should transition between states', (tester) async {
      final asyncSig = signal<AsyncValue<String>>(const AsyncValue.loading());

      await tester.pumpWidget(
        MaterialApp(
          home: AsyncSignalBuilder<String>(
            signal: asyncSig,
            loading: (context) => const Text('Loading...'),
            data: (context, value) => Text(value),
            error: (context, error, stackTrace) => Text('Error: $error'),
          ),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);

      asyncSig.value = const AsyncValue.data('Done!');
      await tester.pump();

      expect(find.text('Done!'), findsOneWidget);
    });
  });

  group('AsyncValue', () {
    test('should correctly report states', () {
      const loading = AsyncValue<int>.loading();
      const data = AsyncValue<int>.data(42);
      final error = AsyncValue<int>.error('error', StackTrace.current);

      expect(loading.isLoading, true);
      expect(loading.hasData, false);
      expect(loading.hasError, false);

      expect(data.isLoading, false);
      expect(data.hasData, true);
      expect(data.hasError, false);
      expect(data.valueOrNull, 42);

      expect(error.isLoading, false);
      expect(error.hasData, false);
      expect(error.hasError, true);
      expect(error.errorOrNull, 'error');
    });

    test('should map values correctly', () {
      const data = AsyncValue<int>.data(10);
      final mapped = data.map((v) => v * 2);

      expect(mapped.valueOrNull, 20);
    });

    test('should getOrElse correctly', () {
      const loading = AsyncValue<int>.loading();
      const data = AsyncValue<int>.data(42);

      expect(loading.getOrElse(0), 0);
      expect(data.getOrElse(0), 42);
    });
  });

  group('Value change detection optimization', () {
    testWidgets('should not rebuild when value is same', (tester) async {
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

      // Set same value - should NOT rebuild
      count.value = 0;
      await tester.pump();

      expect(buildCount, 1); // Still 1

      // Set different value - should rebuild
      count.value = 1;
      await tester.pump();

      expect(buildCount, 2);
    });
  });
}
