# void_signals_flutter

Flutter bindings for [void_signals](https://pub.dev/packages/void_signals) - a high-performance reactive state management solution.

[![Pub Version](https://img.shields.io/pub/v/void_signals_flutter)](https://pub.dev/packages/void_signals_flutter)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

English | [简体中文](README_CN.md)

## Why void_signals?

| Feature | void_signals | Riverpod | GetX |
|---------|-------------|----------|------|
| API Complexity | ⭐ 2 concepts | 8+ concepts | 5+ concepts |
| Learning Curve | Minutes | Hours | Hours |
| Performance | Fine-grained | Fine-grained | Coarse |
| Boilerplate | Minimal | Moderate | Low |

## Quick Start: Just 2 Concepts!

```dart
import 'package:void_signals_flutter/void_signals_flutter.dart';

// 1. signal() - Create reactive state
final count = signal(0);

// 2. Watch() - React to changes
Watch(builder: (context, _) => Text('Count: ${count.value}'));

// Update triggers rebuild
count.value++;
```

That's the entire API for 95% of use cases!

## Core Concepts

### 📦 signal(value) - Reactive State

```dart
// Create signals at module/file level
final counter = signal(0);
final user = signal<User?>(null);
final items = signal<List<Item>>([]);
final settings = signal({'darkMode': false, 'fontSize': 14});

// Read value (inside Watch, automatically tracked)
print(counter.value);  // 0

// Write value (triggers reactive updates)
counter.value = 10;
counter.value++;

// Peek without tracking (for event handlers)
final current = counter.peek();
```

### 👀 Watch() - Reactive Widget

The `Watch` widget automatically tracks ALL signals accessed inside its builder:

```dart
// Simple case
Watch(builder: (context, _) => Text('${counter.value}'));

// Multiple signals - all tracked automatically!
Watch(builder: (context, child) {
  if (isLoading.value) return CircularProgressIndicator();
  
  return Column(children: [
    Text('User: ${user.value?.name}'),
    Text('Items: ${items.value.length}'),
    child!, // Static child won't rebuild
  ]);
}, child: const ExpensiveWidget());

// With context for theming
Watch(builder: (context, _) => Text(
  '${counter.value}',
  style: Theme.of(context).textTheme.headlineLarge,
));
```

### 🧮 computed() - Derived Values

```dart
final items = signal<List<Item>>([]);

// Derived values update automatically
final itemCount = computed((_) => items.value.length);
final totalPrice = computed((_) => 
    items.value.fold(0.0, (sum, item) => sum + item.price));
final isEmpty = computed((_) => items.value.isEmpty);

// Use in Watch
Watch(builder: (context, _) => Text('Total: \$${totalPrice.value}'));
```

### ⚡ effect() - Side Effects

```dart
// Runs immediately, then whenever dependencies change
effect(() {
  print('Counter changed: ${counter.value}');
});

// Useful in initState for logging, analytics, etc.
late final Effect _logEffect;

@override
void initState() {
  super.initState();
  _logEffect = effect(() {
    analytics.log('page_view', {'count': counter.value});
  });
}

@override
void dispose() {
  _logEffect.stop();
  super.dispose();
}
```

## Essential APIs

### Read vs Peek

```dart
// Inside Watch builder - use .value (tracked)
Watch(builder: (context, _) => Text('${counter.value}'));

// In event handlers - use .peek() (not tracked)
ElevatedButton(
  onPressed: () {
    final current = counter.peek();
    counter.value = current + 1;
  },
  child: Text('Increment'),
)
```

### Batch Updates

```dart
// Without batch: 3 rebuilds
counter.value = 1;
name.value = 'John';
active.value = true;

// With batch: 1 rebuild
batch(() {
  counter.value = 1;
  name.value = 'John';
  active.value = true;
});
```

### Convenience Extensions

```dart
// Integer signals
counter.increment();     // counter.value++
counter.decrement();     // counter.value--
counter.increment(5);    // counter.value += 5

// Boolean signals
isOpen.toggle();         // isOpen.value = !isOpen.value

// List signals
items.add('item');
items.remove('item');
items.clear();

// Map signals
settings.set('key', 42);
settings.remove('key');

// Nullable signals
user.clear();            // user.value = null
user.orDefault(guest);   // user.value ?? guest

// Transform
counter.modify((v) => v * 2);
```

## Real-World Examples

### Counter App

```dart
final counter = signal(0);

class CounterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Counter')),
      body: Center(
        child: Watch(builder: (context, _) => Text(
          '${counter.value}',
          style: Theme.of(context).textTheme.displayLarge,
        )),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => counter.value++,
        child: Icon(Icons.add),
      ),
    );
  }
}
```

### Todo App

```dart
final todos = signal<List<Todo>>([]);
final filter = signal(TodoFilter.all);

final filteredTodos = computed((_) {
  switch (filter.value) {
    case TodoFilter.all: return todos.value;
    case TodoFilter.active: return todos.value.where((t) => !t.done).toList();
    case TodoFilter.completed: return todos.value.where((t) => t.done).toList();
  }
});

final activeCount = computed((_) => todos.value.where((t) => !t.done).length);

class TodoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Watch(builder: (_, __) => Text('${activeCount.value} items left')),
      ),
      body: Watch(builder: (context, _) => ListView.builder(
        itemCount: filteredTodos.value.length,
        itemBuilder: (context, index) => TodoTile(todo: filteredTodos.value[index]),
      )),
    );
  }
}
```

### Async Data Loading

```dart
class SearchState {
  final query = signal('');
  final results = signal<AsyncValue<List<Package>>>(const AsyncLoading());
  
  Future<void> search(String q) async {
    query.value = q;
    if (q.isEmpty) {
      results.value = const AsyncData([]);
      return;
    }
    
    results.value = const AsyncLoading();
    try {
      final data = await api.search(q);
      results.value = AsyncData(data);
    } catch (e, s) {
      results.value = AsyncError(e, s);
    }
  }
}

final searchState = SearchState();

class SearchPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      TextField(onChanged: searchState.search),
      Expanded(
        child: Watch(builder: (context, _) => searchState.results.value.when(
          loading: () => Center(child: CircularProgressIndicator()),
          data: (packages) => ListView.builder(
            itemCount: packages.length,
            itemBuilder: (_, i) => PackageTile(packages[i]),
          ),
          error: (e, _) => Center(child: Text('Error: $e')),
        )),
      ),
    ]);
  }
}
```

## Advanced Features

### SignalScope - Route-Level State Override

For pages that need independent state:

```dart
final counter = signal(0);  // Global: 0

// Navigate to page with overridden value
Navigator.push(context, MaterialPageRoute(
  builder: (_) => SignalScope(
    overrides: [counter.override(100)],  // Local: 100
    child: DetailPage(),
  ),
));

// In DetailPage
class DetailPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final localCounter = counter.scoped(context);  // Gets 100, not 0
    
    return Watch(builder: (context, _) => Text('${localCounter.value}'));
  }
}
```

### SignalSelector - Performance Optimization

Only rebuild when selected part changes:

```dart
final user = signal(User(name: 'John', email: 'john@example.com', age: 30));

// Only rebuilds when name changes, not email or age
SignalSelector<User, String>(
  signal: user,
  selector: (u) => u.name,
  builder: (context, name, _) => Text(name),
)
```

### Time-Based Utilities

```dart
final searchQuery = signal('');

// Debounce - wait for pause in typing
final debouncedQuery = debounced(searchQuery, Duration(milliseconds: 300));

// Throttle - max one update per duration
final throttledQuery = throttled(searchQuery, Duration(milliseconds: 100));

// Don't forget to dispose!
@override
void dispose() {
  debouncedQuery.dispose();
  throttledQuery.dispose();
  super.dispose();
}
```

### Form Validation

```dart
final emailField = SignalField<String>(
  initialValue: '',
  validators: [
    requiredValidator('Email required'),
    emailValidator('Invalid email'),
  ],
);

SignalFieldBuilder<String>(
  field: emailField,
  builder: (context, value, errorMessage, field) => TextField(
    onChanged: (v) => field.value = v,
    decoration: InputDecoration(
      labelText: 'Email',
      errorText: errorMessage,
    ),
  ),
)
```

## Migration from Other Libraries

### From Riverpod

```dart
// BEFORE (Riverpod)
final counterProvider = StateProvider((ref) => 0);

class MyWidget extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);
    return Text('$count');
  }
}

// AFTER (void_signals)
final counter = signal(0);

class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return Watch(builder: (_, __) => Text('${counter.value}'));
  }
}
```

### From GetX

```dart
// BEFORE (GetX)
final count = 0.obs;
Obx(() => Text('${count.value}'));

// AFTER (void_signals)
final count = signal(0);
Watch(builder: (_, __) => Text('${count.value}'));
```

## Best Practices

1. **Define signals at module level** - Easy to access and test
2. **Use Watch for UI** - Simplest reactive widget
3. **Use computed for derived state** - Not effects
4. **Use batch for multiple updates** - Minimize rebuilds
5. **Use peek() in callbacks** - Avoid unnecessary tracking
6. **Dispose effects in dispose()** - Prevent memory leaks

## Performance & Frame Synchronization

### How Watch Handles Frame Sync

`Watch` automatically synchronizes with Flutter's frame lifecycle:

```dart
// Multiple rapid updates
counter.value = 1;
counter.value = 2;
counter.value = 3;
// Watch only rebuilds once with final value

// During build phase, updates are deferred to next frame
batch(() {
  items.add(newItem);
  total.value = calculateTotal();
});
```

You don't need to worry about:
- Updates during build phase (automatically deferred)
- Multiple updates in same frame (batched by Flutter)
- Synchronization with animation frames

### batch() for Explicit Batching

When you know you're making multiple related updates:

```dart
// Single atomic update, single rebuild
batch(() {
  user.value = newUser;
  isLoading.value = false;
  errorMessage.value = null;
});
```

This is the recommended approach for coordinated state changes.

### batchLater() for Deferred Flush

Use `batchLater()` when you want values to update immediately, but defer effect/computed propagation to the next microtask. This is useful for cross-component batching where multiple independent components update signals:

```dart
// Values update immediately, but flush is deferred to microtask
void onButtonPressed() {
  batchLater(() {
    counter.value = 10;  // Value updates now
    name.value = 'Updated';
  });
  // Effects and Watch rebuilds happen after all microtasks complete
}

// Multiple calls are merged into one flush
batchLater(() => a.value = 1);
batchLater(() => b.value = 2);  
// Only one flush happens at microtask boundary
```

**Comparison with `batch()`:**
- `batch()`: Values update, effects flush immediately when batch ends
- `batchLater()`: Values update immediately, effects flush at microtask end (can merge multiple batchLater calls)

### queueUpdate() for Fully Deferred Updates

Use `queueUpdate()` when you want to completely defer both the value update AND the flush. Updates are queued and executed together at the next `FrameBatchScope.flush()`:

```dart
// Queue updates without executing them
queueUpdate(() => counter.value = 1);
queueUpdate(() => name.value = 'Deferred');

// Updates don't execute until flush
print(counter.peek());  // Still old value!

// Later, flush all queued updates
await Future.microtask(() {});  // Automatic flush happens here

// Or manually flush
FrameBatchScope.flush();
```

### FrameBatchScope for Manual Control

`FrameBatchScope` provides low-level control over the update queue:

```dart
// Queue an update
FrameBatchScope.update(() {
  expensiveSignal.value = computeExpensiveValue();
});

// Queue another
FrameBatchScope.update(() {
  anotherSignal.value = computeAnother();
});

// Manually flush all queued updates in a single batch
FrameBatchScope.flush();
```

This is useful for:
- Animation frame synchronization
- Debouncing rapid updates across components
- Custom scheduling strategies

**Choosing the Right API:**

| API | Value Updates | Flush Timing | Use Case |
|-----|---------------|--------------|----------|
| `batch()` | Immediately | When batch ends | Multiple related updates |
| `batchLater()` | Immediately | Microtask end | Cross-component batching |
| `queueUpdate()` | At flush | Manual/microtask | Full deferral control |

## Alternative API: Consumer Pattern

For developers familiar with Riverpod, void_signals also provides a Consumer pattern:

```dart
// Riverpod-style API (alternative)
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, SignalRef ref) {
    final count = ref.watch(counter);  // Explicit watch
    final name = ref.read(nameSignal); // Explicit read (no tracking)
    
    ref.listen(errorSignal, (prev, error) {
      // Side effect listener
    });
    
    return Text('$count');
  }
}
```

Choose this if you prefer explicit `ref.watch` / `ref.read` distinction.

The `Watch` widget is recommended for most use cases due to simpler API.

## API Reference

| Concept | When to Use |
|---------|------------|
| `signal(value)` | Create reactive state |
| `Watch(builder: ...)` | Rebuild widget on signal changes |
| `computed((_) => ...)` | Derive values from signals |
| `effect(() => ...)` | Run side effects |
| `batch(() => ...)` | Group multiple updates |
| `signal.peek()` | Read without tracking |
| `untrack(() => ...)` | Run code without tracking |

## DevTools Extension

This package includes a DevTools extension for debugging signals:

```dart
void main() {
  VoidSignalsDebugService.initialize();
  runApp(MyApp());
}
```

## Related Packages

- [void_signals](https://pub.dev/packages/void_signals) - Core library
- [void_signals_hooks](https://pub.dev/packages/void_signals_hooks) - Flutter hooks integration

## License

MIT License - see [LICENSE](LICENSE) for details.
