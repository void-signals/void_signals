# void_signals_hooks

Flutter hooks integration for [void_signals](https://pub.dev/packages/void_signals) - use reactive signals with flutter_hooks.

[![Pub Version](https://img.shields.io/pub/v/void_signals_hooks)](https://pub.dev/packages/void_signals_hooks)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

English | [简体中文](README_CN.md)

## Features

- 🪝 **Hook-Based**: Seamlessly integrate with flutter_hooks
- 📦 **Memoized Signals**: Signals persist across rebuilds
- 🔄 **Auto-Cleanup**: Effects automatically disposed
- 🎯 **Fine-Grained**: Rebuild only what changed

## Installation

```yaml
dependencies:
  void_signals_hooks: ^1.0.0
```

## Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:void_signals_hooks/void_signals_hooks.dart';

class Counter extends HookWidget {
  const Counter({super.key});

  @override
  Widget build(BuildContext context) {
    // Create a signal (memoized across rebuilds)
    final count = useSignal(0);
    
    // Watch the signal (rebuilds when value changes)
    final value = useWatch(count);
    
    return Column(
      children: [
        Text('Count: $value'),
        ElevatedButton(
          onPressed: () => count.value++,
          child: const Text('Increment'),
        ),
      ],
    );
  }
}
```

## Core Hooks

### useSignal

Creates and memoizes a signal.

```dart
final count = useSignal(0);
final user = useSignal<User?>(null);
final items = useSignal<List<String>>([]);
```

### useComputed

Creates and memoizes a computed value.

```dart
final firstName = useSignal('John');
final lastName = useSignal('Doe');

// With previous value
final fullName = useComputed((prev) => '${firstName.value} ${lastName.value}');

// Simple form (no previous value needed)
final doubled = useComputedSimple(() => count.value * 2);
```

### useWatch

Watches a signal and triggers rebuild on change.

```dart
final count = useSignal(0);
final value = useWatch(count);  // Rebuilds when count changes

// For computed values
final computedValue = useWatchComputed(someComputed);
```

### useReactive

Creates a signal and watches it in one call. Returns a tuple of (value, setValue).

```dart
final (count, setCount) = useReactive(0);

// Use like useState
Text('Count: $count'),
ElevatedButton(
  onPressed: () => setCount(count + 1),
  child: const Text('Increment'),
),
```

### useSignalEffect

Creates an effect that re-runs when dependencies change.

```dart
final count = useSignal(0);

useSignalEffect(() {
  print('Count changed to: ${count.value}');
});

// With keys (re-creates effect when keys change)
useSignalEffect(() {
  fetchData(userId);
}, [userId]);
```

### useEffectScope

Creates an effect scope for grouping effects.

```dart
final scope = useEffectScope(() {
  // Setup effects here
});

// Effects are automatically disposed when widget unmounts
```

## Selection Hooks

### useSelect

Selects part of a signal's value. Only rebuilds when selected value changes.

```dart
final user = useSignal(User(name: 'John', age: 30));

// Only rebuilds when name changes, not age
final name = useSelect(user, (u) => u.name);
```

### useSelectComputed

Same as useSelect, but for computed values.

```dart
final users = useComputed((_) => fetchUsers());
final count = useSelectComputed(users, (list) => list.length);
```

## Utility Hooks

### useBatch

Batch multiple signal updates.

```dart
final a = useSignal(0);
final b = useSignal(0);

// Updates both signals, effect runs once
useBatch(() {
  a.value = 10;
  b.value = 20;
});
```

### useUntrack

Read signals without creating dependencies.

```dart
final other = useUntrack(() => someSignal.value);
```

### useSignalFromStream

Creates a signal from a stream.

```dart
final messages = useSignalFromStream(
  messageStream,
  initialValue: [],
);
```

### useSignalFromFuture

Creates a signal from a future.

```dart
final user = useSignalFromFuture(
  fetchUser(),
  initialValue: null,
);
```

## Time-Based Hooks

### useDebounced

Creates a debounced signal that updates after a delay.

```dart
final searchQuery = useSignal('');
final debouncedQuery = useDebounced(searchQuery, Duration(milliseconds: 300));

// Use debouncedQuery for API calls
useSignalEffect(() {
  fetchSearchResults(debouncedQuery.value);
});
```

### useThrottled

Creates a throttled signal that updates at most once per duration.

```dart
final scrollPosition = useSignal(0.0);
final throttled = useThrottled(scrollPosition, Duration(milliseconds: 100));
```

## Combinator Hooks

### useCombine2 / useCombine3

Combines multiple signals into a computed value.

```dart
final firstName = useSignal('John');
final lastName = useSignal('Doe');

final fullName = useCombine2(
  firstName,
  lastName,
  (first, last) => '$first $last',
);
```

### usePrevious

Tracks current and previous values of a signal.

```dart
final count = useSignal(0);
final (current, previous) = usePrevious(count);

// current.value: 5
// previous.value: 4 (or null if first value)
```

## Collection Hooks

### useSignalList

Creates a reactive list.

```dart
final items = useSignalList<String>(['a', 'b', 'c']);

items.add('d');
items.remove('a');
items.clear();
```

### useSignalMap

Creates a reactive map.

```dart
final settings = useSignalMap<String, dynamic>({
  'theme': 'dark',
  'fontSize': 14,
});

settings['language'] = 'en';
settings.remove('theme');
```

### useSignalSet

Creates a reactive set.

```dart
final selected = useSignalSet<int>({1, 2, 3});

selected.add(4);
selected.toggle(1);  // Adds if absent, removes if present
```

## Example: Todo App

```dart
class TodoApp extends HookWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final todos = useSignalList<Todo>([]);
    final filter = useSignal<Filter>(Filter.all);
    
    final filteredTodos = useComputed((prev) {
      return switch (filter.value) {
        Filter.all => todos.value,
        Filter.active => todos.where((t) => !t.done).toList(),
        Filter.completed => todos.where((t) => t.done).toList(),
      };
    });
    
    final activeCount = useSelectComputed(
      filteredTodos,
      (list) => list.where((t) => !t.done).length,
    );
    
    final watchedActiveCount = useWatchComputed(activeCount);
    final watchedFilter = useWatch(filter);
    
    return Column(
      children: [
        Text('$watchedActiveCount items left'),
        SegmentedButton(
          selected: {watchedFilter},
          onSelectionChanged: (s) => filter.value = s.first,
          segments: Filter.values.map((f) => 
            ButtonSegment(value: f, label: Text(f.name))).toList(),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filteredTodos.value.length,
            itemBuilder: (context, index) {
              final todo = filteredTodos.value[index];
              return TodoTile(
                todo: todo,
                onToggle: () => todos[index] = todo.copyWith(done: !todo.done),
                onDelete: () => todos.remove(todo),
              );
            },
          ),
        ),
      ],
    );
  }
}
```

## Best Practices

1. **Use useSignal for local state** that needs to persist across rebuilds
2. **Use useWatch to trigger rebuilds** when you need the widget to update
3. **Use useSelect for partial updates** to minimize rebuilds
4. **Use useDebounced for user input** to avoid excessive updates
5. **Prefer useComputed over useSignalEffect** for derived values
6. **Use useBatch for related updates** to run effects only once

## 🔍 Lint Support

Install [void_signals_lint](https://pub.dev/packages/void_signals_lint) for comprehensive static analysis:

```yaml
dev_dependencies:
  void_signals_lint: ^1.0.0
  custom_lint: ^0.8.0
```

Available hooks-specific rules:

| Rule | Severity | Description |
|------|----------|-------------|
| `hooks_outside_hook_widget` | 🔴 Error | Ensures hooks are in HookWidget.build() |
| `conditional_hook_call` | 🔴 Error | Prevents hooks in conditionals/loops |
| `hook_in_callback` | 🔴 Error | Prevents hooks inside callbacks |
| `use_signal_without_watch` | ⚠️ Warning | Warns when useSignal is not watched |
| `use_select_pure_selector` | ⚠️ Warning | Ensures useSelect selector is pure |
| `prefer_use_computed_over_effect` | ℹ️ Info | Suggests useComputed for derived values |

## Related Packages

- [void_signals](https://pub.dev/packages/void_signals) - Core library
- [void_signals_flutter](https://pub.dev/packages/void_signals_flutter) - Flutter widgets

## License

MIT License - see [LICENSE](LICENSE) for details.
