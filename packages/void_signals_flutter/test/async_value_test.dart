import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_signals_flutter/void_signals_flutter.dart';

void main() {
  group('AsyncValue', () {
    group('AsyncLoading', () {
      test('should create loading state', () {
        const loading = AsyncValue<int>.loading();
        expect(loading.isLoading, isTrue);
        expect(loading.hasData, isFalse);
        expect(loading.hasError, isFalse);
      });

      test('should return null for valueOrNull', () {
        const loading = AsyncValue<int>.loading();
        expect(loading.valueOrNull, isNull);
      });

      test('should return null for errorOrNull', () {
        const loading = AsyncValue<int>.loading();
        expect(loading.errorOrNull, isNull);
      });

      test('should return null for stackTraceOrNull', () {
        const loading = AsyncValue<int>.loading();
        expect(loading.stackTraceOrNull, isNull);
      });

      test('should have correct equality', () {
        const loading1 = AsyncValue<int>.loading();
        const loading2 = AsyncValue<int>.loading();
        expect(loading1, equals(loading2));
        expect(loading1.hashCode, equals(loading2.hashCode));
      });

      test('should have correct toString', () {
        const loading = AsyncValue<int>.loading();
        expect(loading.toString(), equals('AsyncLoading<int>()'));
      });
    });

    group('AsyncData', () {
      test('should create data state', () {
        const data = AsyncValue<int>.data(42);
        expect(data.isLoading, isFalse);
        expect(data.hasData, isTrue);
        expect(data.hasError, isFalse);
      });

      test('should return value for valueOrNull', () {
        const data = AsyncValue<int>.data(42);
        expect(data.valueOrNull, equals(42));
      });

      test('should return null for errorOrNull', () {
        const data = AsyncValue<int>.data(42);
        expect(data.errorOrNull, isNull);
      });

      test('should have correct equality', () {
        const data1 = AsyncValue<int>.data(42);
        const data2 = AsyncValue<int>.data(42);
        const data3 = AsyncValue<int>.data(99);
        expect(data1, equals(data2));
        expect(data1, isNot(equals(data3)));
      });

      test('should have correct toString', () {
        const data = AsyncValue<int>.data(42);
        expect(data.toString(), equals('AsyncData<int>(42)'));
      });

      test('should access value from AsyncData', () {
        const data = AsyncValue<int>.data(42);
        if (data is AsyncData<int>) {
          expect(data.value, equals(42));
        }
      });
    });

    group('AsyncError', () {
      test('should create error state', () {
        final error = AsyncValue<int>.error('error', StackTrace.current);
        expect(error.isLoading, isFalse);
        expect(error.hasData, isFalse);
        expect(error.hasError, isTrue);
      });

      test('should return null for valueOrNull', () {
        final error = AsyncValue<int>.error('error', StackTrace.current);
        expect(error.valueOrNull, isNull);
      });

      test('should return error for errorOrNull', () {
        final error = AsyncValue<int>.error('test error', StackTrace.current);
        expect(error.errorOrNull, equals('test error'));
      });

      test('should return stackTrace for stackTraceOrNull', () {
        final stackTrace = StackTrace.current;
        final error = AsyncValue<int>.error('error', stackTrace);
        expect(error.stackTraceOrNull, equals(stackTrace));
      });

      test('should access error and stackTrace from AsyncError', () {
        final stackTrace = StackTrace.current;
        final error = AsyncValue<int>.error('test error', stackTrace);
        if (error is AsyncError<int>) {
          expect(error.error, equals('test error'));
          expect(error.stackTrace, equals(stackTrace));
        }
      });

      test('should have correct toString', () {
        final error = AsyncValue<int>.error('test error', StackTrace.current);
        expect(error.toString(), equals('AsyncError<int>(test error)'));
      });
    });

    group('when', () {
      test('should call loading callback for loading state', () {
        const loading = AsyncValue<int>.loading();
        final result = loading.when(
          loading: () => 'loading',
          data: (v) => 'data: $v',
          error: (e, s) => 'error: $e',
        );
        expect(result, equals('loading'));
      });

      test('should call data callback for data state', () {
        const data = AsyncValue<int>.data(42);
        final result = data.when(
          loading: () => 'loading',
          data: (v) => 'data: $v',
          error: (e, s) => 'error: $e',
        );
        expect(result, equals('data: 42'));
      });

      test('should call error callback for error state', () {
        final error = AsyncValue<int>.error('oops', StackTrace.current);
        final result = error.when(
          loading: () => 'loading',
          data: (v) => 'data: $v',
          error: (e, s) => 'error: $e',
        );
        expect(result, equals('error: oops'));
      });
    });

    group('maybeWhen', () {
      test('should call loading callback if provided', () {
        const loading = AsyncValue<int>.loading();
        final result = loading.maybeWhen(
          loading: () => 'loading',
          orElse: () => 'else',
        );
        expect(result, equals('loading'));
      });

      test('should call orElse if loading callback not provided', () {
        const loading = AsyncValue<int>.loading();
        final result = loading.maybeWhen(
          data: (v) => 'data: $v',
          orElse: () => 'else',
        );
        expect(result, equals('else'));
      });

      test('should call data callback if provided', () {
        const data = AsyncValue<int>.data(42);
        final result = data.maybeWhen(
          data: (v) => 'data: $v',
          orElse: () => 'else',
        );
        expect(result, equals('data: 42'));
      });

      test('should call orElse if data callback not provided', () {
        const data = AsyncValue<int>.data(42);
        final result = data.maybeWhen(
          loading: () => 'loading',
          orElse: () => 'else',
        );
        expect(result, equals('else'));
      });

      test('should call error callback if provided', () {
        final error = AsyncValue<int>.error('oops', StackTrace.current);
        final result = error.maybeWhen(
          error: (e, s) => 'error: $e',
          orElse: () => 'else',
        );
        expect(result, equals('error: oops'));
      });

      test('should call orElse if error callback not provided', () {
        final error = AsyncValue<int>.error('oops', StackTrace.current);
        final result = error.maybeWhen(
          loading: () => 'loading',
          orElse: () => 'else',
        );
        expect(result, equals('else'));
      });
    });

    group('map', () {
      test('should preserve loading state', () {
        const loading = AsyncValue<int>.loading();
        final mapped = loading.map((v) => v.toString());
        expect(mapped.isLoading, isTrue);
      });

      test('should transform data value', () {
        const data = AsyncValue<int>.data(42);
        final mapped = data.map((v) => v * 2);
        expect(mapped.valueOrNull, equals(84));
      });

      test('should preserve error state', () {
        final error = AsyncValue<int>.error('oops', StackTrace.current);
        final mapped = error.map((v) => v.toString());
        expect(mapped.hasError, isTrue);
        expect(mapped.errorOrNull, equals('oops'));
      });
    });

    group('flatMap', () {
      test('should preserve loading state', () {
        const loading = AsyncValue<int>.loading();
        final result = loading.flatMap((v) => AsyncValue.data(v * 2));
        expect(result.isLoading, isTrue);
      });

      test('should transform data to new AsyncValue', () {
        const data = AsyncValue<int>.data(42);
        final result = data.flatMap((v) => AsyncValue.data(v * 2));
        expect(result.valueOrNull, equals(84));
      });

      test('should allow flatMap to return error', () {
        const data = AsyncValue<int>.data(42);
        final result = data.flatMap(
            (v) => AsyncValue<int>.error('flatMap error', StackTrace.current));
        expect(result.hasError, isTrue);
      });

      test('should preserve error state', () {
        final error = AsyncValue<int>.error('oops', StackTrace.current);
        final result = error.flatMap((v) => AsyncValue.data(v * 2));
        expect(result.hasError, isTrue);
      });
    });

    group('getOrElse', () {
      test('should return value for data state', () {
        const data = AsyncValue<int>.data(42);
        expect(data.getOrElse(0), equals(42));
      });

      test('should return default for loading state', () {
        const loading = AsyncValue<int>.loading();
        expect(loading.getOrElse(0), equals(0));
      });

      test('should return default for error state', () {
        final error = AsyncValue<int>.error('oops', StackTrace.current);
        expect(error.getOrElse(0), equals(0));
      });
    });

    group('getOrCompute', () {
      test('should return value for data state', () {
        const data = AsyncValue<int>.data(42);
        expect(data.getOrCompute(() => 0), equals(42));
      });

      test('should compute default for loading state', () {
        const loading = AsyncValue<int>.loading();
        var computed = false;
        final result = loading.getOrCompute(() {
          computed = true;
          return 0;
        });
        expect(result, equals(0));
        expect(computed, isTrue);
      });

      test('should compute default for error state', () {
        final error = AsyncValue<int>.error('oops', StackTrace.current);
        expect(error.getOrCompute(() => 99), equals(99));
      });
    });
  });

  group('asyncSignal', () {
    test('should start in loading state', () async {
      final completer = Completer<int>();
      final sig = asyncSignal(completer.future);
      expect(sig.value.isLoading, isTrue);
    });

    test('should transition to data state on success', () async {
      final sig = asyncSignal(Future.value(42));
      // Wait for the future to complete
      await Future.delayed(Duration.zero);
      expect(sig.value.hasData, isTrue);
      expect(sig.value.valueOrNull, equals(42));
    });

    test('should transition to error state on failure', () async {
      final sig = asyncSignal(Future<int>.error('oops'));
      // Wait for the future to complete
      await Future.delayed(Duration.zero);
      expect(sig.value.hasError, isTrue);
      expect(sig.value.errorOrNull, equals('oops'));
    });
  });

  group('asyncSignalFromStream', () {
    test('should start in loading state without initial value', () {
      final controller = StreamController<int>();
      final sig = asyncSignalFromStream(controller.stream);
      expect(sig.value.isLoading, isTrue);
      controller.close();
    });

    test('should start with data state if initial value provided', () {
      final controller = StreamController<int>();
      final sig = asyncSignalFromStream(controller.stream, initialValue: 0);
      expect(sig.value.hasData, isTrue);
      expect(sig.value.valueOrNull, equals(0));
      controller.close();
    });

    test('should update on stream events', () async {
      final controller = StreamController<int>();
      final sig = asyncSignalFromStream(controller.stream);

      controller.add(1);
      await Future.delayed(Duration.zero);
      expect(sig.value.valueOrNull, equals(1));

      controller.add(2);
      await Future.delayed(Duration.zero);
      expect(sig.value.valueOrNull, equals(2));

      controller.close();
    });

    test('should handle stream errors', () async {
      final controller = StreamController<int>();
      final sig = asyncSignalFromStream(controller.stream);

      controller.addError('stream error');
      await Future.delayed(Duration.zero);
      expect(sig.value.hasError, isTrue);
      expect(sig.value.errorOrNull, equals('stream error'));

      controller.close();
    });
  });

  group('AsyncValueWidgetExtension', () {
    testWidgets('widget should build correct widget for loading',
        (tester) async {
      const loading = AsyncValue<int>.loading();
      await tester.pumpWidget(MaterialApp(
        home: loading.widget(
          loading: () => const Text('Loading'),
          data: (v) => Text('Data: $v'),
          error: (e, s) => Text('Error: $e'),
        ),
      ));
      expect(find.text('Loading'), findsOneWidget);
    });

    testWidgets('widget should build correct widget for data', (tester) async {
      const data = AsyncValue<int>.data(42);
      await tester.pumpWidget(MaterialApp(
        home: data.widget(
          loading: () => const Text('Loading'),
          data: (v) => Text('Data: $v'),
          error: (e, s) => Text('Error: $e'),
        ),
      ));
      expect(find.text('Data: 42'), findsOneWidget);
    });

    testWidgets('widget should build correct widget for error', (tester) async {
      final error = AsyncValue<int>.error('oops', StackTrace.current);
      await tester.pumpWidget(MaterialApp(
        home: error.widget(
          loading: () => const Text('Loading'),
          data: (v) => Text('Data: $v'),
          error: (e, s) => Text('Error: $e'),
        ),
      ));
      expect(find.text('Error: oops'), findsOneWidget);
    });

    testWidgets('whenData should build data widget', (tester) async {
      const data = AsyncValue<int>.data(42);
      await tester.pumpWidget(MaterialApp(
        home: data.whenData((v) => Text('Data: $v')),
      ));
      expect(find.text('Data: 42'), findsOneWidget);
    });

    testWidgets('whenData should build empty widget for loading by default',
        (tester) async {
      const loading = AsyncValue<int>.loading();
      await tester.pumpWidget(MaterialApp(
        home: loading.whenData((v) => Text('Data: $v')),
      ));
      expect(find.text('Data: 42'), findsNothing);
    });

    testWidgets('whenData should use custom loading widget', (tester) async {
      const loading = AsyncValue<int>.loading();
      await tester.pumpWidget(MaterialApp(
        home: loading.whenData(
          (v) => Text('Data: $v'),
          loading: () => const Text('Custom Loading'),
        ),
      ));
      expect(find.text('Custom Loading'), findsOneWidget);
    });

    testWidgets('whenData should use custom error widget', (tester) async {
      final error = AsyncValue<int>.error('oops', StackTrace.current);
      await tester.pumpWidget(MaterialApp(
        home: error.whenData(
          (v) => Text('Data: $v'),
          error: (e, s) => Text('Custom Error: $e'),
        ),
      ));
      expect(find.text('Custom Error: oops'), findsOneWidget);
    });
  });

  group('AsyncSignalBuilder', () {
    testWidgets('should rebuild when signal changes', (tester) async {
      final sig = signal<AsyncValue<int>>(const AsyncValue.loading());

      await tester.pumpWidget(MaterialApp(
        home: AsyncSignalBuilder<int>(
          signal: sig,
          loading: (context) => const Text('Loading'),
          data: (context, value) => Text('Data: $value'),
          error: (context, error, stackTrace) => Text('Error: $error'),
        ),
      ));

      expect(find.text('Loading'), findsOneWidget);

      sig.value = const AsyncValue.data(42);
      await tester.pump();
      expect(find.text('Data: 42'), findsOneWidget);

      sig.value = AsyncValue.error('oops', StackTrace.current);
      await tester.pump();
      expect(find.text('Error: oops'), findsOneWidget);
    });

    testWidgets('should handle signal replacement', (tester) async {
      final sig1 = signal<AsyncValue<int>>(const AsyncValue.data(1));
      final sig2 = signal<AsyncValue<int>>(const AsyncValue.data(2));
      final useFirst = ValueNotifier(true);

      await tester.pumpWidget(MaterialApp(
        home: ValueListenableBuilder<bool>(
          valueListenable: useFirst,
          builder: (context, value, child) {
            return AsyncSignalBuilder<int>(
              signal: value ? sig1 : sig2,
              loading: (context) => const Text('Loading'),
              data: (context, value) => Text('Data: $value'),
              error: (context, error, stackTrace) => Text('Error: $error'),
            );
          },
        ),
      ));

      expect(find.text('Data: 1'), findsOneWidget);

      useFirst.value = false;
      await tester.pump();
      expect(find.text('Data: 2'), findsOneWidget);
    });
  });

  group('AsyncValue pattern matching', () {
    test('should work with switch expression', () {
      AsyncValue<int> getValue(bool hasData) {
        if (hasData) {
          return const AsyncValue.data(42);
        }
        return const AsyncValue.loading();
      }

      final result = getValue(true);
      final message = switch (result) {
        AsyncLoading() || AsyncLoadingWithPrevious() => 'loading',
        AsyncData(:final value) => 'data: $value',
        AsyncError(:final error) ||
        AsyncErrorWithPrevious(:final error) =>
          'error: $error',
      };
      expect(message, equals('data: 42'));
    });

    test('should work with if-case', () {
      const data = AsyncValue<int>.data(42);

      if (data case AsyncData(:final value)) {
        expect(value, equals(42));
      } else {
        fail('Should match AsyncData');
      }
    });
  });
}
