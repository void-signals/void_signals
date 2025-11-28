import 'package:flutter_test/flutter_test.dart';
import 'package:void_signals_flutter/void_signals_flutter.dart';

void main() {
  group('SignalList', () {
    test('should create with initial values', () {
      final list = SignalList<int>([1, 2, 3]);
      expect(list.value, equals([1, 2, 3]));
      expect(list.length, equals(3));
    });

    test('should create empty list', () {
      final list = SignalList<int>();
      expect(list.value, isEmpty);
      expect(list.isEmpty, isTrue);
      expect(list.isNotEmpty, isFalse);
    });

    test('should add elements', () {
      final list = SignalList<int>();
      list.add(1);
      list.add(2);
      expect(list.value, equals([1, 2]));
    });

    test('should add all elements', () {
      final list = SignalList<int>([1]);
      list.addAll([2, 3, 4]);
      expect(list.value, equals([1, 2, 3, 4]));
    });

    test('should insert element at index', () {
      final list = SignalList<int>([1, 3]);
      list.insert(1, 2);
      expect(list.value, equals([1, 2, 3]));
    });

    test('should access elements by index', () {
      final list = SignalList<int>([10, 20, 30]);
      expect(list[0], equals(10));
      expect(list[1], equals(20));
      expect(list[2], equals(30));
    });

    test('should set elements by index', () {
      final list = SignalList<int>([1, 2, 3]);
      list[1] = 99;
      expect(list.value, equals([1, 99, 3]));
    });

    test('should remove element', () {
      final list = SignalList<int>([1, 2, 3]);
      final removed = list.remove(2);
      expect(removed, isTrue);
      expect(list.value, equals([1, 3]));
    });

    test('should return false when removing non-existent element', () {
      final list = SignalList<int>([1, 2, 3]);
      final removed = list.remove(99);
      expect(removed, isFalse);
      expect(list.value, equals([1, 2, 3]));
    });

    test('should remove element at index', () {
      final list = SignalList<int>([1, 2, 3]);
      final removed = list.removeAt(1);
      expect(removed, equals(2));
      expect(list.value, equals([1, 3]));
    });

    test('should remove last element', () {
      final list = SignalList<int>([1, 2, 3]);
      final removed = list.removeLast();
      expect(removed, equals(3));
      expect(list.value, equals([1, 2]));
    });

    test('should remove elements where condition matches', () {
      final list = SignalList<int>([1, 2, 3, 4, 5]);
      list.removeWhere((e) => e.isEven);
      expect(list.value, equals([1, 3, 5]));
    });

    test('should clear all elements', () {
      final list = SignalList<int>([1, 2, 3]);
      list.clear();
      expect(list.value, isEmpty);
    });

    test('should replace entire list', () {
      final list = SignalList<int>([1, 2, 3]);
      list.replace([10, 20]);
      expect(list.value, equals([10, 20]));
    });

    test('should return null for firstOrNull and lastOrNull when empty', () {
      final list = SignalList<int>();
      expect(list.firstOrNull, isNull);
      expect(list.lastOrNull, isNull);
    });

    test('should return values for firstOrNull and lastOrNull when not empty',
        () {
      final list = SignalList<int>([1, 2, 3]);
      expect(list.firstOrNull, equals(1));
      expect(list.lastOrNull, equals(3));
    });

    test('should filter elements with where', () {
      final list = SignalList<int>([1, 2, 3, 4, 5]);
      final evens = list.where((e) => e.isEven);
      expect(evens, equals([2, 4]));
    });

    test('should map elements', () {
      final list = SignalList<int>([1, 2, 3]);
      final doubled = list.map((e) => e * 2);
      expect(doubled, equals([2, 4, 6]));
    });

    test('should check any element matches condition', () {
      final list = SignalList<int>([1, 2, 3]);
      expect(list.any((e) => e > 2), isTrue);
      expect(list.any((e) => e > 10), isFalse);
    });

    test('should check every element matches condition', () {
      final list = SignalList<int>([2, 4, 6]);
      expect(list.every((e) => e.isEven), isTrue);
      expect(list.every((e) => e > 5), isFalse);
    });

    test('should perform batch operations', () {
      final list = SignalList<int>([1, 2, 3]);
      list.batchOp((l) {
        l.add(4);
        l.add(5);
        l.removeAt(0);
      });
      expect(list.value, equals([2, 3, 4, 5]));
    });

    test('should create select computed', () {
      final list = SignalList<int>([1, 2, 3]);
      final sum = list.select((l) => l.fold(0, (a, b) => a + b));
      expect(sum.value, equals(6));

      list.add(4);
      expect(sum.value, equals(10));
    });

    test('should create lengthComputed', () {
      final list = SignalList<int>([1, 2, 3]);
      final lengthComp = list.lengthComputed;
      expect(lengthComp.value, equals(3));

      list.add(4);
      expect(lengthComp.value, equals(4));
    });

    test('should expose listSignal', () {
      final list = SignalList<int>([1, 2, 3]);
      expect(list.listSignal, isA<Signal<List<int>>>());
      expect(list.listSignal.value, equals([1, 2, 3]));
    });

    test('should not notify when clearing empty list', () {
      final list = SignalList<int>();
      var notifyCount = 0;
      effect(() {
        list.listSignal.value;
        notifyCount++;
      });
      final initialCount = notifyCount;
      list.clear();
      // Should not trigger notification for already empty list
      expect(notifyCount, equals(initialCount));
    });

    test('should not change when removeWhere matches nothing', () {
      final list = SignalList<int>([1, 3, 5]);
      list.removeWhere((e) => e.isEven);
      expect(list.value, equals([1, 3, 5]));
    });

    test('should trigger subscribers on add', () {
      final list = SignalList<int>();
      int notifications = 0;
      effect(() {
        list.listSignal.value;
        notifications++;
      });

      expect(notifications, 1);

      list.add(1);
      expect(notifications, 2);
      expect(list.length, 1);
    });
  });

  group('SignalMap', () {
    test('should create with initial values', () {
      final map = SignalMap<String, int>({'a': 1, 'b': 2});
      expect(map.value, equals({'a': 1, 'b': 2}));
      expect(map.length, equals(2));
    });

    test('should create empty map', () {
      final map = SignalMap<String, int>();
      expect(map.value, isEmpty);
      expect(map.isEmpty, isTrue);
      expect(map.isNotEmpty, isFalse);
    });

    test('should access values by key', () {
      final map = SignalMap<String, int>({'a': 1, 'b': 2});
      expect(map['a'], equals(1));
      expect(map['b'], equals(2));
      expect(map['c'], isNull);
    });

    test('should set values by key', () {
      final map = SignalMap<String, int>();
      map['a'] = 1;
      map['b'] = 2;
      expect(map.value, equals({'a': 1, 'b': 2}));
    });

    test('should check containsKey', () {
      final map = SignalMap<String, int>({'a': 1});
      expect(map.containsKey('a'), isTrue);
      expect(map.containsKey('b'), isFalse);
    });

    test('should check containsValue', () {
      final map = SignalMap<String, int>({'a': 1, 'b': 2});
      expect(map.containsValue(1), isTrue);
      expect(map.containsValue(99), isFalse);
    });

    test('should remove entry by key', () {
      final map = SignalMap<String, int>({'a': 1, 'b': 2});
      final removed = map.remove('a');
      expect(removed, equals(1));
      expect(map.value, equals({'b': 2}));
    });

    test('should return null when removing non-existent key', () {
      final map = SignalMap<String, int>({'a': 1});
      final removed = map.remove('b');
      expect(removed, isNull);
    });

    test('should add all entries', () {
      final map = SignalMap<String, int>({'a': 1});
      map.addAll({'b': 2, 'c': 3});
      expect(map.value, equals({'a': 1, 'b': 2, 'c': 3}));
    });

    test('should update entry', () {
      final map = SignalMap<String, int>({'a': 1});
      map.update('a', (v) => v * 2);
      expect(map['a'], equals(2));
    });

    test('should update entry with ifAbsent', () {
      final map = SignalMap<String, int>({'a': 1});
      map.update('b', (v) => v * 2, ifAbsent: () => 10);
      expect(map['b'], equals(10));
    });

    test('should clear all entries', () {
      final map = SignalMap<String, int>({'a': 1, 'b': 2});
      map.clear();
      expect(map.value, isEmpty);
    });

    test('should replace entire map', () {
      final map = SignalMap<String, int>({'a': 1});
      map.replace({'x': 10, 'y': 20});
      expect(map.value, equals({'x': 10, 'y': 20}));
    });

    test('should get keys and values', () {
      final map = SignalMap<String, int>({'a': 1, 'b': 2});
      expect(map.keys.toList()..sort(), equals(['a', 'b']));
      expect(map.values.toList()..sort(), equals([1, 2]));
    });

    test('should perform batch operations', () {
      final map = SignalMap<String, int>({'a': 1});
      map.batchOp((m) {
        m['b'] = 2;
        m['c'] = 3;
        m.remove('a');
      });
      expect(map.value, equals({'b': 2, 'c': 3}));
    });

    test('should create select computed', () {
      final map = SignalMap<String, int>({'a': 1, 'b': 2});
      final sum = map.select((m) => m.values.fold(0, (a, b) => a + b));
      expect(sum.value, equals(3));

      map['c'] = 3;
      expect(sum.value, equals(6));
    });

    test('should expose mapSignal', () {
      final map = SignalMap<String, int>({'a': 1});
      expect(map.mapSignal, isA<Signal<Map<String, int>>>());
    });

    test('should not notify when clearing empty map', () {
      final map = SignalMap<String, int>();
      map.clear();
      expect(map.isEmpty, isTrue);
    });

    test('should handle removing key with null value', () {
      final map = SignalMap<String, int?>({'a': null});
      final removed = map.remove('a');
      expect(removed, isNull);
      expect(map.containsKey('a'), isFalse);
    });

    test('should trigger subscribers on put', () {
      final map = SignalMap<String, int>();
      int notifications = 0;
      effect(() {
        map.mapSignal.value;
        notifications++;
      });

      map['a'] = 1;
      expect(notifications, 2);
      expect(map['a'], 1);
    });
  });

  group('SignalSet', () {
    test('should create with initial values', () {
      final set = SignalSet<int>({1, 2, 3});
      expect(set.value, equals({1, 2, 3}));
      expect(set.length, equals(3));
    });

    test('should create empty set', () {
      final set = SignalSet<int>();
      expect(set.value, isEmpty);
      expect(set.isEmpty, isTrue);
      expect(set.isNotEmpty, isFalse);
    });

    test('should add element', () {
      final set = SignalSet<int>();
      final added = set.add(1);
      expect(added, isTrue);
      expect(set.value, equals({1}));
    });

    test('should return false when adding duplicate', () {
      final set = SignalSet<int>({1});
      final added = set.add(1);
      expect(added, isFalse);
      expect(set.value, equals({1}));
    });

    test('should add all elements', () {
      final set = SignalSet<int>({1});
      set.addAll([2, 3]);
      expect(set.value, equals({1, 2, 3}));
    });

    test('should check contains', () {
      final set = SignalSet<int>({1, 2, 3});
      expect(set.contains(2), isTrue);
      expect(set.contains(99), isFalse);
    });

    test('should remove element', () {
      final set = SignalSet<int>({1, 2, 3});
      final removed = set.remove(2);
      expect(removed, isTrue);
      expect(set.value, equals({1, 3}));
    });

    test('should return false when removing non-existent element', () {
      final set = SignalSet<int>({1, 2});
      final removed = set.remove(99);
      expect(removed, isFalse);
    });

    test('should clear all elements', () {
      final set = SignalSet<int>({1, 2, 3});
      set.clear();
      expect(set.value, isEmpty);
    });

    test('should toggle element', () {
      final set = SignalSet<int>({1, 2});

      final removed = set.toggle(1);
      expect(removed, isFalse);
      expect(set.value, equals({2}));

      final added = set.toggle(3);
      expect(added, isTrue);
      expect(set.value, equals({2, 3}));
    });

    test('should replace entire set', () {
      final set = SignalSet<int>({1, 2});
      set.replace({10, 20, 30});
      expect(set.value, equals({10, 20, 30}));
    });

    test('should expose setSignal', () {
      final set = SignalSet<int>({1, 2});
      expect(set.setSignal, isA<Signal<Set<int>>>());
    });

    test('should not notify when clearing empty set', () {
      final set = SignalSet<int>();
      set.clear();
      expect(set.isEmpty, isTrue);
    });

    test('should handle multiple toggles', () {
      final set = SignalSet<int>();

      set.toggle(1); // Add
      expect(set.contains(1), isTrue);

      set.toggle(1); // Remove
      expect(set.contains(1), isFalse);

      set.toggle(1); // Add again
      expect(set.contains(1), isTrue);
    });

    test('should trigger subscribers on add', () {
      final set = SignalSet<int>();
      int notifications = 0;
      effect(() {
        set.setSignal.value;
        notifications++;
      });

      set.add(1);
      expect(notifications, 2);
      expect(set.contains(1), true);
    });
  });

  group('Collection reactivity', () {
    test('SignalList should trigger effects on changes', () {
      final list = SignalList<int>([1, 2, 3]);
      var effectCount = 0;

      effect(() {
        list.listSignal.value;
        effectCount++;
      });

      expect(effectCount, equals(1));

      list.add(4);
      expect(effectCount, equals(2));

      list.removeAt(0);
      expect(effectCount, equals(3));
    });

    test('SignalMap should trigger effects on changes', () {
      final map = SignalMap<String, int>({'a': 1});
      var effectCount = 0;

      effect(() {
        map.mapSignal.value;
        effectCount++;
      });

      expect(effectCount, equals(1));

      map['b'] = 2;
      expect(effectCount, equals(2));

      map.remove('a');
      expect(effectCount, equals(3));
    });

    test('SignalSet should trigger effects on changes', () {
      final set = SignalSet<int>({1, 2});
      var effectCount = 0;

      effect(() {
        set.setSignal.value;
        effectCount++;
      });

      expect(effectCount, equals(1));

      set.add(3);
      expect(effectCount, equals(2));

      set.remove(1);
      expect(effectCount, equals(3));
    });
  });
}
