import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_signals_hooks/void_signals_hooks.dart';

void main() {
  group('SignalList (hooks)', () {
    test('should initialize empty', () {
      final list = SignalList<int>();
      expect(list.isEmpty, true);
      expect(list.length, 0);
    });

    test('should initialize with values', () {
      final list = SignalList<int>([1, 2, 3]);
      expect(list.length, 3);
      expect(list[0], 1);
      expect(list[1], 2);
      expect(list[2], 3);
    });

    test('should add elements', () {
      final list = SignalList<int>();
      list.add(1);
      list.add(2);
      expect(list.value, [1, 2]);
    });

    test('should addAll elements', () {
      final list = SignalList<int>();
      list.addAll([1, 2, 3]);
      expect(list.value, [1, 2, 3]);
    });

    test('should remove elements', () {
      final list = SignalList<int>([1, 2, 3]);
      final result = list.remove(2);
      expect(result, true);
      expect(list.value, [1, 3]);
    });

    test('should clear elements', () {
      final list = SignalList<int>([1, 2, 3]);
      list.clear();
      expect(list.isEmpty, true);
    });

    test('should support index assignment', () {
      final list = SignalList<int>([1, 2, 3]);
      list[1] = 20;
      expect(list[1], 20);
    });

    test('should return unmodifiable value', () {
      final list = SignalList<int>([1, 2, 3]);
      expect(() => list.value.add(4), throwsUnsupportedError);
    });
  });

  group('SignalMap (hooks)', () {
    test('should initialize empty', () {
      final map = SignalMap<String, int>();
      expect(map.isEmpty, true);
      expect(map.length, 0);
    });

    test('should initialize with values', () {
      final map = SignalMap<String, int>({'a': 1, 'b': 2});
      expect(map.length, 2);
      expect(map['a'], 1);
      expect(map['b'], 2);
    });

    test('should add entries', () {
      final map = SignalMap<String, int>();
      map['a'] = 1;
      map['b'] = 2;
      expect(map.value, {'a': 1, 'b': 2});
    });

    test('should remove entries', () {
      final map = SignalMap<String, int>({'a': 1, 'b': 2});
      final removed = map.remove('a');
      expect(removed, 1);
      expect(map.containsKey('a'), false);
    });

    test('should clear entries', () {
      final map = SignalMap<String, int>({'a': 1, 'b': 2});
      map.clear();
      expect(map.isEmpty, true);
    });

    test('should return keys and values', () {
      final map = SignalMap<String, int>({'a': 1, 'b': 2});
      expect(map.keys.toSet(), {'a', 'b'});
      expect(map.values.toSet(), {1, 2});
    });

    test('should return unmodifiable value', () {
      final map = SignalMap<String, int>({'a': 1});
      expect(() => map.value['b'] = 2, throwsUnsupportedError);
    });
  });

  group('SignalSet (hooks)', () {
    test('should initialize empty', () {
      final set = SignalSet<int>();
      expect(set.isEmpty, true);
      expect(set.length, 0);
    });

    test('should initialize with values', () {
      final set = SignalSet<int>({1, 2, 3});
      expect(set.length, 3);
      expect(set.contains(1), true);
    });

    test('should add elements', () {
      final set = SignalSet<int>();
      set.add(1);
      set.add(2);
      expect(set.value, {1, 2});
    });

    test('should not add duplicates', () {
      final set = SignalSet<int>({1});
      final result = set.add(1);
      expect(result, false);
      expect(set.length, 1);
    });

    test('should remove elements', () {
      final set = SignalSet<int>({1, 2, 3});
      final result = set.remove(2);
      expect(result, true);
      expect(set.contains(2), false);
    });

    test('should clear elements', () {
      final set = SignalSet<int>({1, 2, 3});
      set.clear();
      expect(set.isEmpty, true);
    });

    test('should toggle elements', () {
      final set = SignalSet<int>();

      final added = set.toggle(1);
      expect(added, true);
      expect(set.contains(1), true);

      final removed = set.toggle(1);
      expect(removed, false);
      expect(set.contains(1), false);
    });

    test('should return unmodifiable value', () {
      final set = SignalSet<int>({1, 2});
      expect(() => set.value.add(3), throwsUnsupportedError);
    });
  });

  group('useSignalList', () {
    testWidgets('should create and memoize SignalList', (tester) async {
      late SignalList<int> list;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              list = useSignalList([1, 2, 3]);
              return Text('${list.length}');
            },
          ),
        ),
      );

      expect(find.text('3'), findsOneWidget);
      expect(list.value, [1, 2, 3]);
    });

    testWidgets('should preserve list across rebuilds', (tester) async {
      late SignalList<int> list;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              list = useSignalList([1, 2, 3]);
              return Text('${list.length}');
            },
          ),
        ),
      );

      list.add(4);
      final prevList = list;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              list = useSignalList([1, 2, 3]);
              return Text('${list.length}');
            },
          ),
        ),
      );

      expect(identical(list, prevList), true);
      expect(list.value, [1, 2, 3, 4]);
    });
  });

  group('useSignalMap', () {
    testWidgets('should create and memoize SignalMap', (tester) async {
      late SignalMap<String, int> map;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              map = useSignalMap({'a': 1, 'b': 2});
              return Text('${map.length}');
            },
          ),
        ),
      );

      expect(find.text('2'), findsOneWidget);
      expect(map['a'], 1);
      expect(map['b'], 2);
    });

    testWidgets('should preserve map across rebuilds', (tester) async {
      late SignalMap<String, int> map;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              map = useSignalMap({'a': 1});
              return Text('${map.length}');
            },
          ),
        ),
      );

      map['b'] = 2;
      final prevMap = map;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              map = useSignalMap({'a': 1});
              return Text('${map.length}');
            },
          ),
        ),
      );

      expect(identical(map, prevMap), true);
      expect(map['b'], 2);
    });
  });

  group('useSignalSet', () {
    testWidgets('should create and memoize SignalSet', (tester) async {
      late SignalSet<int> set;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              set = useSignalSet({1, 2, 3});
              return Text('${set.length}');
            },
          ),
        ),
      );

      expect(find.text('3'), findsOneWidget);
      expect(set.contains(1), true);
      expect(set.contains(2), true);
      expect(set.contains(3), true);
    });

    testWidgets('should preserve set across rebuilds', (tester) async {
      late SignalSet<int> set;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              set = useSignalSet({1, 2});
              return Text('${set.length}');
            },
          ),
        ),
      );

      set.add(3);
      final prevSet = set;

      await tester.pumpWidget(
        MaterialApp(
          home: HookBuilder(
            builder: (context) {
              set = useSignalSet({1, 2});
              return Text('${set.length}');
            },
          ),
        ),
      );

      expect(identical(set, prevSet), true);
      expect(set.contains(3), true);
    });
  });
}
