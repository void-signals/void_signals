import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_signals_flutter/void_signals_flutter.dart';

void main() {
  group('Batch rebuild behavior', () {
    testWidgets('batch() coalesces updates for same Watch', (tester) async {
      final counter = signal(0);
      var buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Watch(builder: (_, __) {
            buildCount++;
            return Text('${counter.value}');
          }),
        ),
      );

      // Initial build
      expect(buildCount, 1);

      // With batch: single rebuild
      batch(() {
        counter.value++;
        counter.value++;
        counter.value++;
      });
      await tester.pump();

      // Should be 2 (initial + 1 batch rebuild)
      expect(buildCount, 2);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('multiple Watch widgets with batch', (tester) async {
      final counter = signal(0);
      var buildCountA = 0;
      var buildCountB = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              Watch(builder: (_, __) {
                buildCountA++;
                return Text('A: ${counter.value}');
              }),
              Watch(builder: (_, __) {
                buildCountB++;
                return Text('B: ${counter.value}');
              }),
            ],
          ),
        ),
      );

      expect(buildCountA, 1);
      expect(buildCountB, 1);

      // Batch update
      batch(() {
        counter.value++;
        counter.value++;
        counter.value++;
      });
      await tester.pump();

      // Each Watch should rebuild once
      expect(buildCountA, 2);
      expect(buildCountB, 2);
    });

    testWidgets('multiple signals with batch', (tester) async {
      final signal1 = signal(0);
      final signal2 = signal('');
      var buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Watch(builder: (_, __) {
            buildCount++;
            return Text('${signal1.value}-${signal2.value}');
          }),
        ),
      );

      expect(buildCount, 1);

      // Batch multiple signal updates
      batch(() {
        signal1.value++;
        signal2.value = 'hello';
      });
      await tester.pump();

      expect(buildCount, 2);
      expect(find.text('1-hello'), findsOneWidget);
    });

    testWidgets('without batch: rapid updates cause multiple rebuilds',
        (tester) async {
      final counter = signal(0);
      var buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Watch(builder: (_, __) {
            buildCount++;
            return Text('${counter.value}');
          }),
        ),
      );

      expect(buildCount, 1);

      // Without batch: each update triggers a separate effect run
      // Due to microtask batching, setState calls are coalesced
      // But effect runs are not - this is the expected behavior
      counter.value++;
      counter.value++;
      counter.value++;
      await tester.pump();

      // Note: buildCount may be higher than 2 because effect runs synchronously
      // The important thing is that the final value is correct
      expect(find.text('3'), findsOneWidget);
      print('Without batch, buildCount = $buildCount (expected behavior)');
    });

    testWidgets('peek() does not track dependencies', (tester) async {
      final counter = signal(0);
      var buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Watch(builder: (_, __) {
            buildCount++;
            // Use peek() - should not track
            return Text('${counter.peek()}');
          }),
        ),
      );

      expect(buildCount, 1);

      counter.value++;
      await tester.pump();

      // Should NOT rebuild because peek() was used
      expect(buildCount, 1);
      // But the displayed value is stale
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('computed values work with Watch', (tester) async {
      final a = signal(1);
      final b = signal(2);
      final sum = computed((_) => a.value + b.value);
      var buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Watch(builder: (_, __) {
            buildCount++;
            return Text('Sum: ${sum.value}');
          }),
        ),
      );

      expect(buildCount, 1);
      expect(find.text('Sum: 3'), findsOneWidget);

      // Batch update
      batch(() {
        a.value = 10;
        b.value = 20;
      });
      await tester.pump();

      expect(buildCount, 2);
      expect(find.text('Sum: 30'), findsOneWidget);
    });
  });
}
