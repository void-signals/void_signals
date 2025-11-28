# void_signals

A high-performance signal reactivity library for Dart and Flutter, based on [alien-signals](https://github.com/stackblitz/alien-signals).

[![Pub Version](https://img.shields.io/pub/v/void_signals)](https://pub.dev/packages/void_signals)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

English | [简体中文](README_CN.md)

## Features

- ⚡ **High Performance**: Based on alien-signals, one of the fastest signal implementations
- 🎯 **Zero Overhead Abstractions**: Uses Dart extension types for zero-cost abstractions
- 🔄 **Fine-Grained Reactivity**: Only updates what actually changed
- 🧩 **Minimal API**: Just `signal()`, `computed()`, `effect()` - that's it!
- 📦 **Flutter Ready**: Seamless integration with Flutter widgets
- 🪝 **Hooks Support**: Optional flutter_hooks integration

## Packages

| Package | Description |
|---------|-------------|
| [void_signals](packages/void_signals/) | Core reactive primitives for Dart |
| [void_signals_flutter](packages/void_signals_flutter/) | Flutter bindings and widgets |
| [void_signals_hooks](packages/void_signals_hooks/) | Flutter hooks integration |

## Quick Start

### Installation

```yaml
dependencies:
  void_signals: ^1.0.0
  void_signals_flutter: ^1.0.0  # For Flutter
  void_signals_hooks: ^1.0.0    # For flutter_hooks users
```

### Basic Usage

```dart
import 'package:void_signals/void_signals.dart';

void main() {
  // Create a signal
  final count = signal(0);
  
  // Create a computed value
  final doubled = computed((prev) => count() * 2);
  
  // Create an effect
  effect(() {
    print('Count: ${count()}, Doubled: ${doubled()}');
  });
  
  count.value = 1;  // Prints: Count: 1, Doubled: 2
  count.value = 2;  // Prints: Count: 2, Doubled: 4
}
```

### Flutter Usage

```dart
import 'package:flutter/material.dart';
import 'package:void_signals_flutter/void_signals_flutter.dart';

// Define signals at file top-level
final counter = signal(0);

class CounterWidget extends StatelessWidget {
  const CounterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Obs(() => Column(
      children: [
        Text('Count: ${counter.value}'),
        ElevatedButton(
          onPressed: () => counter.value++,
          child: const Text('Increment'),
        ),
      ],
    ));
  }
}
```

## Core Concepts

### Signal

A signal is a reactive value that notifies subscribers when it changes.

```dart
final name = signal('John');
print(name.value);  // 'John'
name.value = 'Jane';  // Notifies all subscribers
```

### Computed

A computed value is derived from other signals and automatically updates when dependencies change.

```dart
final firstName = signal('John');
final lastName = signal('Doe');
final fullName = computed((prev) => '${firstName()} ${lastName()}');

print(fullName());  // 'John Doe'
firstName.value = 'Jane';
print(fullName());  // 'Jane Doe'
```

### Effect

An effect runs automatically when its dependencies change.

```dart
final count = signal(0);

final eff = effect(() {
  print('Count changed to: ${count()}');
});

count.value = 1;  // Prints: Count changed to: 1
eff.stop();  // Stop listening to changes
```

### Batch

Batch multiple updates to run effects only once.

```dart
final a = signal(1);
final b = signal(2);

effect(() {
  print('Sum: ${a() + b()}');
});

batch(() {
  a.value = 10;
  b.value = 20;
});
// Prints only once: Sum: 30
```

## Advanced Features

### Effect Scope

Group multiple effects together for easy cleanup.

```dart
final scope = effectScope(() {
  effect(() { /* effect 1 */ });
  effect(() { /* effect 2 */ });
});

scope.stop();  // Stops all effects in the scope
```

### Untrack

Read a signal without creating a dependency.

```dart
effect(() {
  print(count());  // Creates dependency
  untrack(() => otherSignal());  // Does not create dependency
});
```

## Performance

void_signals is built on alien-signals, which is one of the fastest signal implementations available. Key optimizations include:

- **Extension types** for zero-cost abstractions
- **Lazy evaluation** for computed values
- **Efficient dependency tracking** with O(1) operations
- **Minimal memory allocations** through object pooling

## Contributing

Contributions are welcome! Please read our [contributing guidelines](CONTRIBUTING.md) before submitting a PR.

## License

MIT License - see [LICENSE](LICENSE) for details.
