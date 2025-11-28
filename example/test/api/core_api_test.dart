import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_signals_flutter/void_signals_flutter.dart';

/// Comprehensive tests for all void_signals API demonstrated in the example app
void main() {
  group('Core API: signal()', () {
    test('should create reactive state', () {
      final counter = signal(0);
      expect(counter.value, 0);

      counter.value = 10;
      expect(counter.value, 10);
    });

    test('should notify listeners on change', () {
      final counter = signal(0);
      var notified = false;

      effect(() {
        counter.value;
        notified = true;
      });

      counter.value = 1;
      expect(notified, true);
    });

    test('should support any type', () {
      final stringSignal = signal('hello');
      final listSignal = signal<List<int>>([1, 2, 3]);
      final mapSignal = signal<Map<String, dynamic>>({'key': 'value'});
      final nullableSignal = signal<String?>(null);

      expect(stringSignal.value, 'hello');
      expect(listSignal.value, [1, 2, 3]);
      expect(mapSignal.value, {'key': 'value'});
      expect(nullableSignal.value, null);
    });

    test('should support peek() without tracking', () {
      final counter = signal(0);
      var effectRuns = 0;

      effect(() {
        counter.peek(); // Not tracked
        effectRuns++;
      });

      expect(effectRuns, 1);
      counter.value = 1;
      expect(effectRuns, 1); // Should not re-run
    });

    test('should support call syntax', () {
      final counter = signal(0);
      expect(counter(), 0);

      counter.value = 5;
      expect(counter(), 5);
    });
  });

  group('Core API: computed()', () {
    test('should derive value from signals', () {
      final a = signal(1);
      final b = signal(2);
      final sum = computed((_) => a.value + b.value);

      expect(sum.value, 3);

      a.value = 10;
      expect(sum.value, 12);
    });

    test('should cache value', () {
      var computeCount = 0;
      final source = signal(1);
      final doubled = computed((_) {
        computeCount++;
        return source.value * 2;
      });

      // First access
      expect(doubled.value, 2);
      expect(computeCount, 1);

      // Second access without change - should use cache
      expect(doubled.value, 2);
      expect(computeCount, 1);

      // After change
      source.value = 5;
      expect(doubled.value, 10);
      expect(computeCount, 2);
    });

    test('should support chained computed', () {
      final base = signal(10);
      final doubled = computed((_) => base.value * 2);
      final quadrupled = computed((_) => doubled.value * 2);

      expect(quadrupled.value, 40);

      base.value = 5;
      expect(quadrupled.value, 20);
    });

    test('should receive previous value', () {
      final counter = signal(0);
      final changes = computed<int>((prev) {
        counter.value;
        return (prev ?? 0) + 1;
      });

      expect(changes.value, 1);

      counter.value = 1;
      expect(changes.value, 2);

      counter.value = 2;
      expect(changes.value, 3);
    });
  });

  group('Core API: effect()', () {
    test('should run immediately', () {
      var ran = false;
      final eff = effect(() {
        ran = true;
      });

      expect(ran, true);
      eff.stop();
    });

    test('should re-run on dependency change', () {
      final counter = signal(0);
      var runs = 0;

      final eff = effect(() {
        counter.value;
        runs++;
      });

      expect(runs, 1);

      counter.value = 1;
      expect(runs, 2);

      counter.value = 2;
      expect(runs, 3);

      eff.stop();
    });

    test('should stop when stop() called', () {
      final counter = signal(0);
      var runs = 0;

      final eff = effect(() {
        counter.value;
        runs++;
      });

      expect(runs, 1);
      eff.stop();

      counter.value = 1;
      expect(runs, 1); // Should not increment
    });

    test('should track multiple signals', () {
      final a = signal(1);
      final b = signal(2);
      var runs = 0;

      final eff = effect(() {
        a.value;
        b.value;
        runs++;
      });

      expect(runs, 1);

      a.value = 10;
      expect(runs, 2);

      b.value = 20;
      expect(runs, 3);

      eff.stop();
    });
  });

  group('Core API: effectScope()', () {
    test('should group effects', () {
      final counter = signal(0);
      var effect1Runs = 0;
      var effect2Runs = 0;

      final scope = effectScope(() {
        effect(() {
          counter.value;
          effect1Runs++;
        });
        effect(() {
          counter.value;
          effect2Runs++;
        });
      });

      expect(effect1Runs, 1);
      expect(effect2Runs, 1);

      counter.value = 1;
      expect(effect1Runs, 2);
      expect(effect2Runs, 2);

      scope.stop();

      counter.value = 2;
      expect(effect1Runs, 2); // Should not increment
      expect(effect2Runs, 2);
    });
  });

  group('Core API: batch()', () {
    test('should batch multiple updates', () {
      final a = signal(0);
      final b = signal(0);
      var effectRuns = 0;

      final eff = effect(() {
        a.value;
        b.value;
        effectRuns++;
      });

      expect(effectRuns, 1);

      batch(() {
        a.value = 1;
        b.value = 2;
      });

      expect(effectRuns, 2); // Only one additional run
      expect(a.value, 1);
      expect(b.value, 2);

      eff.stop();
    });

    test('should support nested batch', () {
      final counter = signal(0);
      var runs = 0;

      final eff = effect(() {
        counter.value;
        runs++;
      });

      expect(runs, 1);

      batch(() {
        counter.value = 1;
        batch(() {
          counter.value = 2;
        });
        counter.value = 3;
      });

      expect(runs, 2); // Only one additional run
      expect(counter.value, 3);

      eff.stop();
    });

    test('should return value', () {
      final result = batch(() {
        return 42;
      });
      expect(result, 42);
    });
  });

  group('Core API: untrack()', () {
    test('should not track inside untrack', () {
      final a = signal(1);
      final b = signal(2);
      var runs = 0;

      final eff = effect(() {
        a.value; // Tracked
        untrack(() => b.value); // Not tracked
        runs++;
      });

      expect(runs, 1);

      a.value = 10;
      expect(runs, 2);

      b.value = 20;
      expect(runs, 2); // Should not increment
      eff.stop();
    });
  });

  group('Extensions: Integer', () {
    test('should support increment()', () {
      final counter = signal(0);
      counter.increment();
      expect(counter.value, 1);

      counter.increment(5);
      expect(counter.value, 6);
    });

    test('should support decrement()', () {
      final counter = signal(10);
      counter.decrement();
      expect(counter.value, 9);

      counter.decrement(4);
      expect(counter.value, 5);
    });
  });

  group('Extensions: Boolean', () {
    test('should support toggle()', () {
      final flag = signal(false);
      flag.toggle();
      expect(flag.value, true);

      flag.toggle();
      expect(flag.value, false);
    });
  });

  group('Extensions: List', () {
    test('should support add()', () {
      final list = signal<List<int>>([1, 2]);
      list.add(3);
      expect(list.value, [1, 2, 3]);
    });

    test('should support remove()', () {
      final list = signal<List<int>>([1, 2, 3]);
      list.remove(2);
      expect(list.value, [1, 3]);
    });

    test('should support clear()', () {
      final list = signal<List<int>>([1, 2, 3]);
      list.clear();
      expect(list.value, isEmpty);
    });
  });

  group('Extensions: Map', () {
    test('should support set()', () {
      final map = signal<Map<String, int>>({'a': 1});
      map.set('b', 2);
      expect(map.value, {'a': 1, 'b': 2});
    });

    test('should support remove()', () {
      final map = signal<Map<String, int>>({'a': 1, 'b': 2});
      map.remove('a');
      expect(map.value, {'b': 2});
    });
  });

  group('Extensions: Nullable', () {
    test('should support clear()', () {
      final nullable = signal<String?>('hello');
      nullable.clear();
      expect(nullable.value, null);
    });

    test('should support orDefault()', () {
      final nullable = signal<String?>(null);
      expect(nullable.orDefault('default'), 'default');

      nullable.value = 'value';
      expect(nullable.orDefault('default'), 'value');
    });
  });

  group('Extensions: modify()', () {
    test('should update value with function', () {
      final counter = signal(5);
      counter.modify((v) => v * 2);
      expect(counter.value, 10);
    });

    test('should work with complex types', () {
      final user = signal({'name': 'John', 'age': 25});
      user.modify((u) => {...u, 'age': (u['age'] as int) + 1});
      expect(user.value, {'name': 'John', 'age': 26});
    });
  });

  group('SignalList', () {
    test('should provide reactive list operations', () {
      final list = SignalList<int>([1, 2, 3]);

      expect(list.length, 3);
      expect(list[0], 1);

      list.add(4);
      expect(list.length, 4);

      list.removeLast();
      expect(list.length, 3);
    });

    test('should notify on mutations', () {
      final list = SignalList<int>([1, 2]);
      var runs = 0;

      final eff = effect(() {
        list.value;
        runs++;
      });

      expect(runs, 1);

      list.add(3);
      expect(runs, 2);

      eff.stop();
    });
  });

  group('SignalMap', () {
    test('should provide reactive map operations', () {
      final map = SignalMap<String, int>({'a': 1});

      expect(map['a'], 1);
      expect(map.containsKey('a'), true);

      map['b'] = 2;
      expect(map['b'], 2);
    });
  });

  group('SignalSet', () {
    test('should provide reactive set operations', () {
      final set = SignalSet<int>({1, 2});

      expect(set.contains(1), true);
      expect(set.length, 2);

      set.add(3);
      expect(set.length, 3);
    });

    test('should support toggle()', () {
      final set = SignalSet<int>({1, 2});

      set.toggle(2);
      expect(set.contains(2), false);

      set.toggle(2);
      expect(set.contains(2), true);
    });
  });

  group('Combinators: mapped()', () {
    test('should transform signal value', () {
      final source = signal(5);
      final doubled = mapped(source, (v) => v * 2);

      expect(doubled.value, 10);

      source.value = 10;
      expect(doubled.value, 20);
    });
  });

  group('Combinators: combine2()', () {
    test('should combine two signals', () {
      final a = signal(1);
      final b = signal(2);
      final sum = combine2(a, b, (x, y) => x + y);

      expect(sum.value, 3);

      a.value = 10;
      expect(sum.value, 12);

      b.value = 20;
      expect(sum.value, 30);
    });
  });

  group('Combinators: withPrevious()', () {
    test('should track previous value', () {
      final source = signal(0);
      final (current, previous) = withPrevious(source);

      expect(current.value, 0);
      expect(previous.value, null);

      source.value = 1;
      expect(current.value, 1);
      expect(previous.value, 0);

      source.value = 5;
      expect(current.value, 5);
      expect(previous.value, 1);
    });
  });

  group('Time Utils: debounced()', () {
    testWidgets('should debounce signal changes', (tester) async {
      final source = signal('');
      final debounced_ = debounced(source, const Duration(milliseconds: 100));

      // Initial value
      expect(debounced_.value, '');

      // Rapid changes
      source.value = 'a';
      source.value = 'ab';
      source.value = 'abc';

      // Should not have updated yet
      expect(debounced_.value, '');

      // Wait for debounce
      await tester.pump(const Duration(milliseconds: 150));

      // Should have final value
      expect(debounced_.value, 'abc');

      debounced_.dispose();
    });
  });

  group('Time Utils: throttled()', () {
    test('should throttle signal changes', () async {
      final source = signal(0);
      // Use a shorter duration for faster tests
      final throttled_ = throttled(source, const Duration(milliseconds: 50));

      // First change goes through immediately
      source.value = 1;
      expect(throttled_.value, 1);

      // Rapid changes during throttle window are queued
      source.value = 2;
      source.value = 3;
      expect(throttled_.value, 1); // Still throttled

      // Wait for trailing update (the last pending value)
      await Future.delayed(const Duration(milliseconds: 100));
      expect(throttled_.value, 3); // Trailing update applied

      // Wait for next throttle window to pass
      await Future.delayed(const Duration(milliseconds: 100));

      // Now changes should go through immediately again
      source.value = 4;
      expect(throttled_.value, 4);

      throttled_.dispose();
    });
  });

  group('Form: SignalField', () {
    test('should validate with validators', () {
      final field = SignalField<String>(
        initialValue: '',
        validators: [
          requiredValidator('Required'),
          minLengthValidator(3, 'Min 3 chars'),
        ],
      );

      // Field is invalid from start
      expect(field.isValid, false);
      // errorMessage is only shown when touched
      expect(field.errorMessage, null); // Not touched yet
      expect(
        field.validation.errorMessage,
        'Required',
      ); // But validation result is available

      // Touch the field to show errors
      field.touch();
      expect(field.errorMessage, 'Required');

      field.value = 'ab';
      expect(field.isValid, false);
      expect(field.errorMessage, 'Min 3 chars');

      field.value = 'abc';
      expect(field.isValid, true);
      expect(field.errorMessage, null);
    });

    test('should support reset()', () {
      final field = SignalField<String>(
        initialValue: 'initial',
        validators: [requiredValidator('Required')],
      );

      field.value = 'changed';
      expect(field.value, 'changed');

      field.reset();
      expect(field.value, 'initial');
    });
  });

  group('Form: FormSignal', () {
    test('should manage multiple fields', () {
      final form = FormSignal({
        'username': SignalField<String>(
          initialValue: '',
          validators: [requiredValidator('Required')],
        ),
        'email': SignalField<String>(
          initialValue: '',
          validators: [
            requiredValidator('Required'),
            emailValidator('Invalid email'),
          ],
        ),
      });

      expect(form.isValid, false);

      form.field<String>('username')!.value = 'john';
      expect(form.isValid, false);

      form.field<String>('email')!.value = 'john@example.com';
      expect(form.isValid, true);
    });

    test('should validate all fields', () {
      final form = FormSignal({
        'name': SignalField<String>(
          initialValue: 'John',
          validators: [requiredValidator('Required')],
        ),
      });

      expect(form.validate(), true);
      expect(form.values, {'name': 'John'});
    });

    test('should reset all fields', () {
      final form = FormSignal({
        'name': SignalField<String>(initialValue: 'initial', validators: []),
      });

      form.field<String>('name')!.value = 'changed';
      form.reset();

      expect(form.field<String>('name')!.value, 'initial');
    });
  });

  group('AsyncValue', () {
    test('should represent loading state', () {
      const value = AsyncLoading<int>();

      expect(value.isLoading, true);
      expect(value.hasData, false);
      expect(value.hasError, false);
    });

    test('should represent data state', () {
      const value = AsyncData(42);

      expect(value.isLoading, false);
      expect(value.hasData, true);
      expect(value.hasError, false);
      expect(value.value, 42);
    });

    test('should represent error state', () {
      final value = AsyncError<int>(Exception('test'), StackTrace.current);

      expect(value.isLoading, false);
      expect(value.hasData, false);
      expect(value.hasError, true);
    });

    test('when() should pattern match', () {
      AsyncValue<int> value = const AsyncLoading();

      expect(
        value.when(
          loading: () => 'loading',
          data: (d) => 'data: $d',
          error: (e, _) => 'error',
        ),
        'loading',
      );

      value = const AsyncData(42);
      expect(
        value.when(
          loading: () => 'loading',
          data: (d) => 'data: $d',
          error: (e, _) => 'error',
        ),
        'data: 42',
      );
    });
  });

  group('asyncSignal()', () {
    test('should start in loading state', () {
      final sig = asyncSignal(Future.delayed(Duration.zero, () => 42));
      expect(sig.value, isA<AsyncLoading>());
    });

    test('should transition to data on completion', () async {
      final sig = asyncSignal(Future.value(42));

      await Future.delayed(Duration.zero);

      expect(sig.value, isA<AsyncData<int>>());
      expect((sig.value as AsyncData<int>).value, 42);
    });

    test('should transition to error on failure', () async {
      final sig = asyncSignal(Future<int>.error(Exception('test')));

      await Future.delayed(Duration.zero);

      expect(sig.value, isA<AsyncError>());
    });
  });

  group('Flutter Widgets: Watch', () {
    testWidgets('should rebuild on signal change', (tester) async {
      final counter = signal(0);

      await tester.pumpWidget(
        MaterialApp(
          home: Watch(
            builder: (context, child) => Text('Count: ${counter.value}'),
          ),
        ),
      );

      expect(find.text('Count: 0'), findsOneWidget);

      counter.value = 5;
      await tester.pump();

      expect(find.text('Count: 5'), findsOneWidget);
    });

    testWidgets('should preserve child widget', (tester) async {
      final counter = signal(0);

      await tester.pumpWidget(
        MaterialApp(
          home: Watch(
            builder:
                (context, child) =>
                    Column(children: [Text('Count: ${counter.value}'), child!]),
            child: const Text('Static Child'),
          ),
        ),
      );

      expect(find.text('Static Child'), findsOneWidget);

      counter.value = 1;
      await tester.pump();

      expect(find.text('Static Child'), findsOneWidget);
    });
  });

  group('Flutter Widgets: WatchValue', () {
    testWidgets('should watch getter function', (tester) async {
      final a = signal(2);
      final b = signal(3);

      await tester.pumpWidget(
        MaterialApp(
          home: WatchValue<int>(
            getter: () => a.value * b.value,
            builder: (context, value) => Text('Product: $value'),
          ),
        ),
      );

      expect(find.text('Product: 6'), findsOneWidget);

      a.value = 5;
      await tester.pump();

      expect(find.text('Product: 15'), findsOneWidget);
    });
  });

  group('Flutter Widgets: SignalBuilder', () {
    testWidgets('should build with signal value', (tester) async {
      final counter = signal(0);

      await tester.pumpWidget(
        MaterialApp(
          home: SignalBuilder<int>(
            signal: counter,
            builder: (context, value, child) => Text('Value: $value'),
          ),
        ),
      );

      expect(find.text('Value: 0'), findsOneWidget);

      counter.value = 10;
      await tester.pump();

      expect(find.text('Value: 10'), findsOneWidget);
    });
  });

  group('Flutter Widgets: ComputedBuilder', () {
    testWidgets('should build with computed value', (tester) async {
      final source = signal(5);
      final doubled = computed((_) => source.value * 2);

      await tester.pumpWidget(
        MaterialApp(
          home: ComputedBuilder<int>(
            computed: doubled,
            builder: (context, value, child) => Text('Doubled: $value'),
          ),
        ),
      );

      expect(find.text('Doubled: 10'), findsOneWidget);

      source.value = 10;
      await tester.pump();

      expect(find.text('Doubled: 20'), findsOneWidget);
    });
  });

  group('Flutter Widgets: MultiSignalBuilder', () {
    testWidgets('should watch multiple signals', (tester) async {
      final a = signal(1);
      final b = signal(2);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiSignalBuilder(
            signals: [a, b],
            builder: (context, _) => Text('Sum: ${a.value + b.value}'),
          ),
        ),
      );

      expect(find.text('Sum: 3'), findsOneWidget);

      a.value = 10;
      await tester.pump();

      expect(find.text('Sum: 12'), findsOneWidget);
    });
  });

  group('Flutter Widgets: SignalSelector', () {
    testWidgets('should only rebuild on selected value change', (tester) async {
      final user = signal({'name': 'John', 'age': 25});
      var buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: SignalSelector<Map<String, dynamic>, String>(
            signal: user,
            selector: (u) => u['name'] as String,
            builder: (context, name, _) {
              buildCount++;
              return Text('Name: $name');
            },
          ),
        ),
      );

      expect(buildCount, 1);
      expect(find.text('Name: John'), findsOneWidget);

      // Change age - should not rebuild
      user.value = {...user.value, 'age': 26};
      await tester.pump();
      expect(buildCount, 1);

      // Change name - should rebuild
      user.value = {...user.value, 'name': 'Jane'};
      await tester.pump();
      expect(buildCount, 2);
      expect(find.text('Name: Jane'), findsOneWidget);
    });
  });

  group('Flutter Widgets: AsyncSignalBuilder', () {
    testWidgets('should handle all async states', (tester) async {
      final asyncSig = signal<AsyncValue<String>>(const AsyncLoading());

      await tester.pumpWidget(
        MaterialApp(
          home: AsyncSignalBuilder<String>(
            signal: asyncSig,
            loading: (context) => const Text('Loading...'),
            data: (context, value) => Text('Data: $value'),
            error: (context, error, stackTrace) => const Text('Error'),
          ),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);

      asyncSig.value = const AsyncData('Hello');
      await tester.pump();
      expect(find.text('Data: Hello'), findsOneWidget);

      asyncSig.value = AsyncError(Exception('test'), StackTrace.current);
      await tester.pump();
      expect(find.text('Error'), findsOneWidget);
    });
  });

  group('Flutter Widgets: SignalScope', () {
    testWidgets('should override signal in subtree', (tester) async {
      final globalCounter = signal(0);

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              Watch(builder: (_, __) => Text('Global: ${globalCounter.value}')),
              SignalScope(
                overrides: [globalCounter.override(100)],
                child: Builder(
                  builder: (context) {
                    final scoped = globalCounter.scoped(context);
                    return Watch(
                      builder: (_, __) => Text('Scoped: ${scoped.value}'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );

      expect(find.text('Global: 0'), findsOneWidget);
      expect(find.text('Scoped: 100'), findsOneWidget);
    });
  });

  group('signal.watch() extension', () {
    testWidgets('should provide shorthand for SignalBuilder', (tester) async {
      final counter = signal(0);

      await tester.pumpWidget(
        MaterialApp(home: counter.watch((value) => Text('Count: $value'))),
      );

      expect(find.text('Count: 0'), findsOneWidget);

      counter.value = 42;
      await tester.pump();

      expect(find.text('Count: 42'), findsOneWidget);
    });
  });

  group('Best Practices', () {
    test('should use batch for multiple related updates', () {
      final name = signal('');
      final email = signal('');
      final age = signal(0);
      var effectRuns = 0;

      final eff = effect(() {
        name.value;
        email.value;
        age.value;
        effectRuns++;
      });

      expect(effectRuns, 1);

      // Best practice: batch related updates
      batch(() {
        name.value = 'John';
        email.value = 'john@example.com';
        age.value = 30;
      });

      expect(effectRuns, 2); // Only one additional run

      eff.stop();
    });

    test('should use peek() in callbacks', () {
      final counter = signal(0);
      var effectRuns = 0;

      final eff = effect(() {
        counter.value;
        effectRuns++;
      });

      expect(effectRuns, 1);

      // Simulating a callback that reads value
      final currentValue = counter.peek();
      expect(currentValue, 0);
      expect(effectRuns, 1); // Should not trigger effect

      eff.stop();
    });

    test('should dispose effects properly', () {
      final counter = signal(0);
      var effectRuns = 0;

      final scope = effectScope(() {
        effect(() {
          counter.value;
          effectRuns++;
        });
      });

      expect(effectRuns, 1);

      counter.value = 1;
      expect(effectRuns, 2);

      // Proper cleanup
      scope.stop();

      counter.value = 2;
      expect(effectRuns, 2); // No more runs
    });

    test('should use computed for derived state, not effects', () {
      final items = signal<List<int>>([1, 2, 3, 4, 5]);

      // Good: computed for derived state
      final evenItems = computed((_) {
        return items.value.where((i) => i.isEven).toList();
      });

      final total = computed((_) {
        return items.value.fold(0, (sum, i) => sum + i);
      });

      expect(evenItems.value, [2, 4]);
      expect(total.value, 15);

      items.value = [1, 2, 3, 4, 5, 6];
      expect(evenItems.value, [2, 4, 6]);
      expect(total.value, 21);
    });
  });
}
