// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:void_signals_hooks/void_signals_hooks.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'void_signals_hooks Examples',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('void_signals_hooks Examples'),
      ),
      body: ListView(
        children: [
          _ExampleTile(
            title: 'Basic Counter',
            subtitle: 'useSignal + useWatch',
            page: const BasicCounterExample(),
          ),
          _ExampleTile(
            title: 'useReactive',
            subtitle: 'useState-like API',
            page: const ReactiveExample(),
          ),
          _ExampleTile(
            title: 'useAsync',
            subtitle: 'Async operation with manual control',
            page: const AsyncExample(),
          ),
          _ExampleTile(
            title: 'useAsyncData',
            subtitle: 'Auto-executing async with keys',
            page: const AsyncDataExample(),
          ),
          _ExampleTile(
            title: 'useToggle',
            subtitle: 'Boolean toggle state',
            page: const ToggleExample(),
          ),
          _ExampleTile(
            title: 'useCounter',
            subtitle: 'Counter with controls',
            page: const CounterExample(),
          ),
          _ExampleTile(
            title: 'useInterval & useTimeout',
            subtitle: 'Timer hooks',
            page: const TimerExample(),
          ),
          _ExampleTile(
            title: 'useListener',
            subtitle: 'Side effects on signal changes',
            page: const ListenerExample(),
          ),
          _ExampleTile(
            title: 'useDebounced',
            subtitle: 'Debounced search input',
            page: const DebouncedExample(),
          ),
          _ExampleTile(
            title: 'Collection Hooks',
            subtitle: 'useSignalList, useSignalMap, useSignalSet',
            page: const CollectionExample(),
          ),
        ],
      ),
    );
  }
}

class _ExampleTile extends StatelessWidget {
  const _ExampleTile({
    required this.title,
    required this.subtitle,
    required this.page,
  });

  final String title;
  final String subtitle;
  final Widget page;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text(title)),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: page,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Example 1: Basic Counter with useSignal + useWatch
// =============================================================================

class BasicCounterExample extends HookWidget {
  const BasicCounterExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Create a memoized signal
    final count = useSignal(0);

    // Watch the signal to trigger rebuilds
    final value = useWatch(count);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Count: $value',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => count.value--,
                child: const Icon(Icons.remove),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () => count.value++,
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Example 2: useReactive (useState-like API)
// =============================================================================

class ReactiveExample extends HookWidget {
  const ReactiveExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Create signal and watch in one call
    final (count, setCount) = useReactive(0);
    final (name, setName) = useReactive('World');

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Hello, $name!'),
          Text('Count: $count'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => setCount(count + 1),
            child: const Text('Increment'),
          ),
          const SizedBox(height: 10),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Enter name',
              border: OutlineInputBorder(),
            ),
            onChanged: setName,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Example 3: useAsync (Manual async control)
// =============================================================================

Future<String> _fetchUser(int id) async {
  await Future.delayed(const Duration(seconds: 1));
  if (id == 0) throw Exception('Invalid user ID');
  return 'User #$id';
}

class AsyncExample extends HookWidget {
  const AsyncExample({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = useAsync<String>();

    void loadUser(int id) {
      controller.execute(() => _fetchUser(id));
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Pattern matching on state
          controller.state.when(
            idle: () => const Text('Press a button to load user'),
            loading: () => const CircularProgressIndicator(),
            success: (user) => Text(
              user,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            error: (e, _) => Text(
              'Error: $e',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton(
                onPressed: () => loadUser(1),
                child: const Text('Load User 1'),
              ),
              ElevatedButton(
                onPressed: () => loadUser(2),
                child: const Text('Load User 2'),
              ),
              ElevatedButton(
                onPressed: () => loadUser(0),
                child: const Text('Trigger Error'),
              ),
              OutlinedButton(
                onPressed: controller.reset,
                child: const Text('Reset'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Example 4: useAsyncData (Auto-executing with keys)
// =============================================================================

class AsyncDataExample extends HookWidget {
  const AsyncDataExample({super.key});

  @override
  Widget build(BuildContext context) {
    final (userId, setUserId) = useReactive(1);

    // Auto-executes when userId changes
    final state = useAsyncData<String>(
      () => _fetchUser(userId),
      keys: [userId],
    );

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Selected User ID: $userId'),
          const SizedBox(height: 20),
          state.maybeWhen(
            loading: () => const CircularProgressIndicator(),
            success: (user) => Text(
              user,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            error: (e, _) => Text('Error: $e'),
            orElse: () => const Text('Loading...'),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            children: [
              for (var i = 1; i <= 5; i++)
                ElevatedButton(
                  onPressed: () => setUserId(i),
                  style: userId == i
                      ? ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                        )
                      : null,
                  child: Text('User $i'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Example 5: useToggle
// =============================================================================

class ToggleExample extends HookWidget {
  const ToggleExample({super.key});

  @override
  Widget build(BuildContext context) {
    final (isDarkMode, toggleDarkMode, setDarkOn, setDarkOff) =
        useToggle(false);
    final (isEnabled, toggleEnabled, _, __) = useToggle(true);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: isDarkMode,
            onChanged: (_) => toggleDarkMode(),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: setDarkOn,
                child: const Text('Force On'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: setDarkOff,
                child: const Text('Force Off'),
              ),
            ],
          ),
          const Divider(height: 40),
          SwitchListTile(
            title: const Text('Feature Enabled'),
            value: isEnabled,
            onChanged: (_) => toggleEnabled(),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Example 6: useCounter
// =============================================================================

class CounterExample extends HookWidget {
  const CounterExample({super.key});

  @override
  Widget build(BuildContext context) {
    final (count, increment, decrement, reset, setValue) = useCounter(0);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Count: $count',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Use increment/decrement buttons',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton(
                onPressed: decrement,
                child: const Icon(Icons.remove),
              ),
              ElevatedButton(
                onPressed: increment,
                child: const Icon(Icons.add),
              ),
              OutlinedButton(
                onPressed: reset,
                child: const Text('Reset'),
              ),
              OutlinedButton(
                onPressed: () => setValue(50),
                child: const Text('Set to 50'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Example 7: useInterval & useTimeout
// =============================================================================

class TimerExample extends HookWidget {
  const TimerExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Interval timer
    final (seconds, _, __, ___, setSeconds) = useCounter(0);
    final (isRunning, toggleRunning, setRunningOn, setRunningOff) =
        useToggle(true);

    useInterval(
      isRunning ? () => setSeconds(seconds + 1) : null,
      const Duration(seconds: 1),
    );

    // Timeout example
    final (showMessage, toggleMessage, setShowOn, setShowOff) =
        useToggle(false);

    final cancel = useTimeout(
      showMessage ? null : () => setShowOn(),
      const Duration(seconds: 3),
    );

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Interval section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('useInterval Example'),
                  const SizedBox(height: 10),
                  Text(
                    '$seconds seconds',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: toggleRunning,
                    child: Text(isRunning ? 'Pause' : 'Resume'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Timeout section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('useTimeout Example'),
                  const SizedBox(height: 10),
                  if (showMessage)
                    const Text(
                      '🎉 Message appeared!',
                      style: TextStyle(fontSize: 18),
                    )
                  else
                    const Text('Message in 3 seconds...'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (!showMessage)
                        ElevatedButton(
                          onPressed: cancel,
                          child: const Text('Cancel'),
                        ),
                      ElevatedButton(
                        onPressed: () {
                          setShowOff();
                          // Timer restarts automatically when widget rebuilds
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Example 8: useListener
// =============================================================================

class ListenerExample extends HookWidget {
  const ListenerExample({super.key});

  @override
  Widget build(BuildContext context) {
    final count = useSignal(0);
    final logs = useSignal<List<String>>([]);

    // Listen to count changes
    useListener(
      count,
      (value) {
        final newLogs = [
          ...logs.value,
          'Count changed to: $value at ${DateTime.now().toIso8601String()}'
        ];
        // Keep only last 5 logs
        if (newLogs.length > 5) {
          logs.value = newLogs.sublist(newLogs.length - 5);
        } else {
          logs.value = newLogs;
        }
      },
      fireImmediately: true,
    );

    final value = useWatch(count);
    final logList = useWatch(logs);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Count: $value',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => count.value++,
            child: const Text('Increment'),
          ),
          const SizedBox(height: 20),
          const Text('Event Logs:'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: logList
                  .map((log) => Text(log, style: const TextStyle(fontSize: 12)))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Example 9: useDebounced
// =============================================================================

class DebouncedExample extends HookWidget {
  const DebouncedExample({super.key});

  @override
  Widget build(BuildContext context) {
    final searchQuery = useSignal('');
    final debouncedQuery =
        useDebounced(searchQuery, const Duration(milliseconds: 500));
    final searchResults = useSignal<List<String>>([]);
    final isSearching = useSignal(false);

    // Watch the debounced value
    final debouncedValue = useWatchComputed(debouncedQuery);

    // Simulate search API call
    useSignalEffect(() {
      final query = debouncedValue;
      if (query.isEmpty) {
        searchResults.value = [];
        return;
      }

      isSearching.value = true;
      Future.delayed(const Duration(milliseconds: 300), () {
        searchResults.value = [
          'Result 1 for "$query"',
          'Result 2 for "$query"',
          'Result 3 for "$query"',
        ];
        isSearching.value = false;
      });
    });

    final results = useWatch(searchResults);
    final searching = useWatch(isSearching);

    return Column(
      children: [
        TextField(
          decoration: const InputDecoration(
            labelText: 'Search',
            hintText: 'Type to search (500ms debounce)',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => searchQuery.value = value,
        ),
        const SizedBox(height: 20),
        if (searching)
          const CircularProgressIndicator()
        else if (results.isEmpty)
          const Text('No results')
        else
          ...results.map((r) => ListTile(title: Text(r))),
      ],
    );
  }
}

// =============================================================================
// Example 10: Collection Hooks
// =============================================================================

class CollectionExample extends HookWidget {
  const CollectionExample({super.key});

  @override
  Widget build(BuildContext context) {
    // List
    final items = useSignalList<String>(['Apple', 'Banana', 'Cherry']);

    // Map
    final settings = useSignalMap<String, bool>({
      'notifications': true,
      'darkMode': false,
      'autoSave': true,
    });

    // Set
    final selected = useSignalSet<int>({});

    // Watch collections
    final itemsList = items.value;
    final settingsMap = settings.value;
    final selectedSet = selected.value;

    // Force rebuild when version changes
    useWatch(items.listSignal);
    useWatch(settings.mapSignal);
    useWatch(selected.setSignal);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // List section
          Text('SignalList', style: Theme.of(context).textTheme.titleLarge),
          Wrap(
            spacing: 8,
            children: itemsList
                .map((item) => Chip(
                      label: Text(item),
                      onDeleted: () => items.remove(item),
                    ))
                .toList(),
          ),
          ElevatedButton.icon(
            onPressed: () => items.add('Item ${items.length + 1}'),
            icon: const Icon(Icons.add),
            label: const Text('Add Item'),
          ),

          const Divider(height: 32),

          // Map section
          Text('SignalMap', style: Theme.of(context).textTheme.titleLarge),
          ...settingsMap.entries.map((e) => SwitchListTile(
                title: Text(e.key),
                value: e.value,
                onChanged: (v) => settings[e.key] = v,
              )),

          const Divider(height: 32),

          // Set section
          Text('SignalSet', style: Theme.of(context).textTheme.titleLarge),
          Text('Selected: ${selectedSet.toList()}'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: List.generate(
                5,
                (i) => FilterChip(
                      label: Text('Item $i'),
                      selected: selectedSet.contains(i),
                      onSelected: (_) => selected.toggle(i),
                    )),
          ),
        ],
      ),
    );
  }
}
