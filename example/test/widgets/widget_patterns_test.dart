import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_signals_flutter/void_signals_flutter.dart';

/// Tests for widget components used in the example app
void main() {
  group('Package Card Pattern', () {
    testWidgets('should display loading state initially', (tester) async {
      final info = signal<AsyncValue<Map<String, String>>>(
        const AsyncLoading(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Watch(
              builder:
                  (context, _) => info.value.when(
                    loading: () => const CircularProgressIndicator(),
                    data: (data) => Text(data['name']!),
                    error: (e, _) => Text('Error: $e'),
                  ),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should transition to data state', (tester) async {
      final info = signal<AsyncValue<Map<String, String>>>(
        const AsyncLoading(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Watch(
              builder:
                  (context, _) => info.value.when(
                    loading: () => const CircularProgressIndicator(),
                    data: (data) => Text(data['name']!),
                    error: (e, _) => Text('Error: $e'),
                  ),
            ),
          ),
        ),
      );

      info.value = const AsyncData({'name': 'flutter_bloc'});
      await tester.pump();

      expect(find.text('flutter_bloc'), findsOneWidget);
    });

    testWidgets('should handle error state', (tester) async {
      final info = signal<AsyncValue<String>>(const AsyncLoading());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Watch(
              builder:
                  (context, _) => info.value.when(
                    loading: () => const CircularProgressIndicator(),
                    data: (data) => Text(data),
                    error: (e, _) => Text('Error: $e'),
                  ),
            ),
          ),
        ),
      );

      info.value = AsyncError(Exception('Network error'), StackTrace.current);
      await tester.pump();

      expect(find.textContaining('Error'), findsOneWidget);
    });
  });

  group('Search Input Pattern', () {
    testWidgets('should update signal on text change', (tester) async {
      final query = signal('');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(onChanged: (value) => query.value = value),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'flutter');
      expect(query.value, 'flutter');
    });

    testWidgets('should show clear button when query not empty', (
      tester,
    ) async {
      final query = signal('');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Expanded(
                  child: TextField(onChanged: (value) => query.value = value),
                ),
                Watch(
                  builder: (context, _) {
                    if (query.value.isNotEmpty) {
                      return IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => query.value = '',
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      );

      // Initially no clear button
      expect(find.byIcon(Icons.clear), findsNothing);

      // Type something
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      // Clear button should appear
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });
  });

  group('List with Pagination Pattern', () {
    testWidgets('should show loading more indicator', (tester) async {
      final packages = signal<List<String>>(['pkg1', 'pkg2']);
      final isLoadingMore = signal(false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Watch(
              builder:
                  (context, _) => ListView.builder(
                    itemCount:
                        packages.value.length + (isLoadingMore.value ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= packages.value.length) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return ListTile(title: Text(packages.value[index]));
                    },
                  ),
            ),
          ),
        ),
      );

      expect(find.text('pkg1'), findsOneWidget);
      expect(find.text('pkg2'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Start loading more
      isLoadingMore.value = true;
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should append new items', (tester) async {
      final packages = signal<List<String>>(['pkg1', 'pkg2']);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Watch(
              builder:
                  (context, _) => ListView.builder(
                    itemCount: packages.value.length,
                    itemBuilder: (context, index) {
                      return ListTile(title: Text(packages.value[index]));
                    },
                  ),
            ),
          ),
        ),
      );

      expect(find.text('pkg1'), findsOneWidget);
      expect(find.text('pkg2'), findsOneWidget);
      expect(find.text('pkg3'), findsNothing);

      // Load more
      packages.value = [...packages.value, 'pkg3', 'pkg4'];
      await tester.pump();

      expect(find.text('pkg3'), findsOneWidget);
      expect(find.text('pkg4'), findsOneWidget);
    });
  });

  group('Navigation Tab Pattern', () {
    testWidgets('should switch pages with signal', (tester) async {
      final selectedIndex = signal(0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Watch(
              builder:
                  (context, _) => IndexedStack(
                    index: selectedIndex.value,
                    children: const [
                      Center(child: Text('Page 0')),
                      Center(child: Text('Page 1')),
                      Center(child: Text('Page 2')),
                    ],
                  ),
            ),
            bottomNavigationBar: Watch(
              builder:
                  (context, _) => NavigationBar(
                    selectedIndex: selectedIndex.value,
                    onDestinationSelected:
                        (index) => selectedIndex.value = index,
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.home),
                        label: 'Home',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.search),
                        label: 'Search',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.settings),
                        label: 'Settings',
                      ),
                    ],
                  ),
            ),
          ),
        ),
      );

      expect(find.text('Page 0'), findsOneWidget);

      // Tap search tab
      await tester.tap(find.text('Search'));
      await tester.pump();

      expect(selectedIndex.value, 1);
    });
  });

  group('Form Validation Pattern', () {
    testWidgets('should show validation errors', (tester) async {
      final emailField = SignalField<String>(
        initialValue: '',
        validators: [
          requiredValidator('Email is required'),
          emailValidator('Invalid email format'),
        ],
      );

      // Touch the field to show validation errors
      emailField.touch();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SignalFieldBuilder<String>(
              field: emailField,
              builder:
                  (context, value, error, field) => TextField(
                    decoration: InputDecoration(
                      labelText: 'Email',
                      errorText: error,
                    ),
                    onChanged: (v) => field.value = v,
                  ),
            ),
          ),
        ),
      );

      // Shows required error because field is touched
      expect(emailField.errorMessage, 'Email is required');

      // Type invalid email
      await tester.enterText(find.byType(TextField), 'invalid');
      await tester.pump();

      expect(emailField.errorMessage, 'Invalid email format');

      // Type valid email
      await tester.enterText(find.byType(TextField), 'test@example.com');
      await tester.pump();

      expect(emailField.errorMessage, isNull);
      expect(emailField.isValid, true);
    });
  });

  group('Pull to Refresh Pattern', () {
    testWidgets('should trigger refresh', (tester) async {
      final data = signal<AsyncValue<List<String>>>(
        const AsyncData(['item1', 'item2']),
      );
      var refreshCalled = false;

      Future<void> refresh() async {
        refreshCalled = true;
        data.value = const AsyncLoading();
        await Future.delayed(const Duration(milliseconds: 100));
        data.value = const AsyncData(['item1', 'item2', 'item3']);
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RefreshIndicator(
              onRefresh: refresh,
              child: Watch(
                builder:
                    (context, _) => data.value.when(
                      loading:
                          () =>
                              const Center(child: CircularProgressIndicator()),
                      data:
                          (items) => ListView.builder(
                            itemCount: items.length,
                            itemBuilder:
                                (context, index) =>
                                    ListTile(title: Text(items[index])),
                          ),
                      error: (e, _) => Text('Error: $e'),
                    ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('item1'), findsOneWidget);
      expect(find.text('item2'), findsOneWidget);

      // Pull to refresh - use drag instead of fling for more reliable testing
      await tester.drag(find.byType(ListView), const Offset(0, 500));
      await tester.pump();
      await tester.pump(
        const Duration(milliseconds: 50),
      ); // Allow indicator to appear
      await tester.pumpAndSettle(); // Complete the refresh animation

      expect(refreshCalled, true);
    });
  });

  group('Stats Display Pattern', () {
    testWidgets('should display score metrics', (tester) async {
      final score = signal<AsyncValue<Map<String, int>>>(const AsyncLoading());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Watch(
              builder:
                  (context, _) => score.value.when(
                    loading: () => const CircularProgressIndicator(),
                    data:
                        (data) => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Icon(Icons.star),
                                Text('${data['points']}'),
                                const Text('Points'),
                              ],
                            ),
                            Column(
                              children: [
                                const Icon(Icons.favorite),
                                Text('${data['likes']}'),
                                const Text('Likes'),
                              ],
                            ),
                            Column(
                              children: [
                                const Icon(Icons.download),
                                Text('${data['downloads']}'),
                                const Text('Downloads'),
                              ],
                            ),
                          ],
                        ),
                    error: (e, _) => Text('Error: $e'),
                  ),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      score.value = const AsyncData({
        'points': 150,
        'likes': 1200,
        'downloads': 50000,
      });
      await tester.pump();

      expect(find.text('150'), findsOneWidget);
      expect(find.text('1200'), findsOneWidget);
      expect(find.text('50000'), findsOneWidget);
    });
  });

  group('Chip Filter Pattern', () {
    testWidgets('should toggle filter chips', (tester) async {
      final selectedFilters = SignalSet<String>({'flutter'});

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Watch(
              builder:
                  (context, _) => Wrap(
                    spacing: 8,
                    children:
                        ['flutter', 'dart', 'web', 'mobile'].map((filter) {
                          return FilterChip(
                            label: Text(filter),
                            selected: selectedFilters.contains(filter),
                            onSelected: (_) => selectedFilters.toggle(filter),
                          );
                        }).toList(),
                  ),
            ),
          ),
        ),
      );

      // Flutter should be selected
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, 'flutter'))
            .selected,
        true,
      );

      // Tap dart to select
      await tester.tap(find.widgetWithText(FilterChip, 'dart'));
      await tester.pump();

      expect(selectedFilters.contains('dart'), true);

      // Tap flutter to deselect
      await tester.tap(find.widgetWithText(FilterChip, 'flutter'));
      await tester.pump();

      expect(selectedFilters.contains('flutter'), false);
    });
  });

  group('Counter Demo Pattern', () {
    testWidgets('should increment and decrement', (tester) async {
      final counter = signal(0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Watch(
                  builder:
                      (context, _) => Text(
                        'Count: ${counter.value}',
                        style: const TextStyle(fontSize: 24),
                      ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () => counter.value--,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => counter.value++,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Count: 0'), findsOneWidget);

      // Increment
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(find.text('Count: 1'), findsOneWidget);

      // Increment again
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(find.text('Count: 2'), findsOneWidget);

      // Decrement
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();
      expect(find.text('Count: 1'), findsOneWidget);
    });
  });

  group('Computed Display Pattern', () {
    testWidgets('should display computed values', (tester) async {
      final price = signal(10.0);
      final quantity = signal(2);
      final taxRate = signal(0.1);

      final subtotal = computed((_) => price.value * quantity.value);
      final tax = computed((_) => subtotal.value * taxRate.value);
      final total = computed((_) => subtotal.value + tax.value);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Watch(
                  builder:
                      (_, __) => Text(
                        'Subtotal: \$${subtotal.value.toStringAsFixed(2)}',
                      ),
                ),
                Watch(
                  builder:
                      (_, __) => Text('Tax: \$${tax.value.toStringAsFixed(2)}'),
                ),
                Watch(
                  builder:
                      (_, __) =>
                          Text('Total: \$${total.value.toStringAsFixed(2)}'),
                ),
                ElevatedButton(
                  onPressed: () => quantity.value++,
                  child: const Text('Add Item'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Subtotal: \$20.00'), findsOneWidget);
      expect(find.text('Tax: \$2.00'), findsOneWidget);
      expect(find.text('Total: \$22.00'), findsOneWidget);

      // Add item
      await tester.tap(find.text('Add Item'));
      await tester.pump();

      expect(find.text('Subtotal: \$30.00'), findsOneWidget);
      expect(find.text('Tax: \$3.00'), findsOneWidget);
      expect(find.text('Total: \$33.00'), findsOneWidget);
    });
  });

  group('Batch Update Pattern', () {
    testWidgets('should batch UI updates', (tester) async {
      final a = signal(0);
      final b = signal(0);
      var buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Watch(
                  builder: (context, _) {
                    buildCount++;
                    return Text('a=${a.value}, b=${b.value}');
                  },
                ),
                ElevatedButton(
                  onPressed: () {
                    batch(() {
                      a.value = 10;
                      b.value = 20;
                    });
                  },
                  child: const Text('Batch Update'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(buildCount, 1);

      await tester.tap(find.text('Batch Update'));
      await tester.pump();

      expect(buildCount, 2); // Only one additional build
      expect(find.text('a=10, b=20'), findsOneWidget);
    });
  });

  group('Effect Cleanup Pattern', () {
    testWidgets('should cleanup effect on dispose', (tester) async {
      final counter = signal(0);
      var effectRuns = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: _EffectTestWidget(
            counter: counter,
            onEffectRun: () => effectRuns++,
          ),
        ),
      );

      expect(effectRuns, 1);

      counter.value = 1;
      await tester.pump();
      expect(effectRuns, 2);

      // Dispose widget
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      // Effect should not run after dispose
      counter.value = 2;
      await tester.pump();
      expect(effectRuns, 2);
    });
  });
}

class _EffectTestWidget extends StatefulWidget {
  final Signal<int> counter;
  final VoidCallback onEffectRun;

  const _EffectTestWidget({required this.counter, required this.onEffectRun});

  @override
  State<_EffectTestWidget> createState() => _EffectTestWidgetState();
}

class _EffectTestWidgetState extends State<_EffectTestWidget> {
  Effect? _effect;

  @override
  void initState() {
    super.initState();
    _effect = effect(() {
      widget.counter.value;
      widget.onEffectRun();
    });
  }

  @override
  void dispose() {
    _effect?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Watch(
      builder: (context, _) => Text('Count: ${widget.counter.value}'),
    );
  }
}
