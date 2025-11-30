<p align="center">
  <img src="https://raw.githubusercontent.com/void-signals/void-signals/main/art/void.png" alt="void_signals logo" width="180" />
</p>

<h1 align="center">void_signals DevTools Extension</h1>

<p align="center">
  A powerful DevTools extension for visualizing and debugging <a href="https://pub.dev/packages/void_signals">void_signals</a> reactive state management.
</p>

<p align="center">
  <a href="https://pub.dev/packages/void_signals_devtools_extension"><img src="https://img.shields.io/pub/v/void_signals_devtools_extension.svg" alt="pub package" /></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT" /></a>
</p>

<p align="center">
  English | <a href="README_CN.md">简体中文</a>
</p>

---

## ✨ Features

- 🔍 **Signal List View**: Browse all signals, computed values, and effects with filtering & search
- 📊 **Dependency Graph**: Interactive visualization of reactive dependencies
- ⏱️ **Timeline View**: Track value changes over time with visual timeline
- 📈 **Statistics Dashboard**: Performance metrics, update frequencies, and insights
- ✏️ **Live Editing**: Modify signal values in real-time for debugging
- 🔄 **Auto-refresh**: Real-time state synchronization
- 🎯 **Quick Navigation**: Jump to source code definitions

## 📸 Screenshots

### Signal List View
Browse all reactive primitives with type indicators, current values, and quick actions.

### Dependency Graph
Interactive graph showing relationships between signals, computed values, and effects.

### Timeline View
Visual timeline of value changes with timestamps and change highlighting.

### Statistics Dashboard
Performance insights including update frequency, subscriber counts, and memory usage.

## 🚀 Setup

### 1. Add DevTools integration to your app

In your app's `main.dart`, initialize the debug service:

```dart
import 'package:flutter/material.dart';
import 'package:void_signals_flutter/void_signals_flutter.dart';

void main() {
  // Initialize DevTools integration (only active in debug mode)
  VoidSignalsDebugService.initialize();
  
  runApp(MyApp());
}
```

### 2. Track signals for debugging

Use the `.tracked()` extension to make signals visible in DevTools:

```dart
// Track signals with optional labels
final count = signal(0).tracked(label: 'Counter');
final name = signal('John').tracked(label: 'User Name');

// Track computed values
final doubled = computed((prev) => count() * 2).tracked(label: 'Doubled');

// Track effects
effect(() {
  print('Count changed: ${count()}');
}).tracked(label: 'Log Effect');
```

### 3. Open DevTools

1. Run your Flutter app in debug mode: `flutter run`
2. Open DevTools (VS Code: `Ctrl+Shift+P` → "Dart: Open DevTools")
3. Look for the **"void_signals"** tab in the DevTools tab bar

## 📖 Views Guide

### 🔍 Signal List View

The main view showing all tracked reactive primitives:

| Icon | Type | Description |
|------|------|-------------|
| 🔵 | Signal | Reactive state values |
| 🟢 | Computed | Auto-updating derived values |
| 🟠 | Effect | Side effects that run on changes |

**Features:**
- **Search**: Filter by name or value
- **Type Filter**: Show only signals, computed, or effects
- **Sort Options**: By name, type, update time, or subscriber count
- **Quick Actions**: Peek value, edit, jump to source

### 📊 Dependency Graph View

Interactive visualization of the reactive dependency tree:

- **Nodes**: Each reactive primitive as a node
- **Edges**: Arrows showing dependency direction
- **Colors**: Type-based coloring for easy identification
- **Interactions**: 
  - Hover to highlight connections
  - Click to select and view details
  - Drag to reposition nodes
  - Mouse wheel to zoom
  - Pan by dragging background

### ⏱️ Timeline View

Track value changes over time:

- **Visual Timeline**: Horizontal timeline with change markers
- **Change Details**: Click markers to see value transitions
- **Time Filtering**: Focus on specific time ranges
- **Value Comparison**: See before/after values

### 📈 Statistics Dashboard

Performance insights and metrics:

| Metric | Description |
|--------|-------------|
| Total Signals | Count of all reactive primitives |
| Updates/sec | Average update frequency |
| Avg Subscribers | Mean subscriber count per signal |
| Memory Usage | Estimated memory footprint |
| Most Active | Signals with highest update rates |
| Largest | Signals with most subscribers |

## ⚙️ Configuration

### Debug Labels

Always use descriptive labels for better DevTools experience:

```dart
// ❌ Without label - hard to identify
final count = signal(0);

// ✅ With label - easy to find in DevTools
final count = signal(0).tracked(label: 'cart_item_count');
```

### Auto-tracking (Optional)

For development, you can enable automatic tracking of all signals:

```dart
void main() {
  VoidSignalsDebugService.initialize(
    autoTrack: true,  // Track all signals automatically
    maxHistorySize: 100,  // Keep last 100 value changes
  );
  
  runApp(MyApp());
}
```

## 🔧 API Reference

### VoidSignalsDebugService

```dart
/// Initialize the debug service (call once in main())
VoidSignalsDebugService.initialize({
  bool autoTrack = false,
  int maxHistorySize = 50,
});

/// Access the debug tracker
final tracker = VoidSignalsDebugService.tracker;

/// Get all tracked signals
final signals = VoidSignalsDebugService.getSignals();

/// Listen to signal updates
VoidSignalsDebugService.onSignalUpdate.listen((update) {
  print('Signal ${update.label} changed to ${update.value}');
});
```

### Signal Tracking Extensions

```dart
/// Track a signal for DevTools visibility
final count = signal(0).tracked(
  label: 'counter',
  group: 'user_state',  // Optional grouping
);

/// Track a computed
final fullName = computed((_) => '$first $last').tracked(
  label: 'full_name',
);

/// Track an effect
effect(() {
  saveToStorage(count());
}).tracked(label: 'persist_effect');
```

### SignalInfo Model

```dart
class SignalInfo {
  final String id;
  final String label;
  final NodeType type;  // signal, computed, effect
  final dynamic value;
  final String valueType;
  final List<String> dependencies;
  final List<String> subscribers;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final List<SignalChangeEvent> history;
  final String? stackTrace;
}
```

## 💡 Best Practices

### 1. Use Meaningful Labels

```dart
// ❌ Bad
final s1 = signal(0).tracked(label: 's1');

// ✅ Good  
final cartItemCount = signal(0).tracked(label: 'cart_item_count');
```

### 2. Group Related Signals

```dart
final firstName = signal('').tracked(label: 'first_name', group: 'user_profile');
final lastName = signal('').tracked(label: 'last_name', group: 'user_profile');
final email = signal('').tracked(label: 'email', group: 'user_profile');
```

### 3. Track Strategically

Don't track every signal in production apps. Focus on:
- Complex state that's hard to debug
- Frequently updated values
- State with many dependencies

### 4. Use Timeline for Debugging

When debugging unexpected behavior:
1. Open Timeline view
2. Reproduce the issue
3. Review the sequence of value changes
4. Identify the problematic update

## ⚠️ Performance Notes

- The debug service only activates in debug mode (`kDebugMode`)
- Tracking adds minimal overhead (~1ms per update)
- All tracking code is tree-shaken in release builds
- Large numbers of signals (>1000) may impact DevTools performance
- History is automatically limited to prevent memory issues

## 🔌 Integration with void_signals_lint

For the best development experience, use alongside [void_signals_lint](https://pub.dev/packages/void_signals_lint):

```yaml
dev_dependencies:
  void_signals_lint: ^1.0.0
  custom_lint: ^0.8.0
```

The lint package will suggest adding labels to signals for better DevTools visibility!

## 🐛 Troubleshooting

### Signals not appearing in DevTools

1. Ensure `VoidSignalsDebugService.initialize()` is called in `main()`
2. Check that signals use `.tracked()` extension
3. Verify app is running in debug mode
4. Try refreshing the DevTools extension

### Performance issues

1. Reduce `maxHistorySize` in configuration
2. Use filtering to limit visible signals
3. Disable auto-refresh when not needed
4. Track only essential signals

### Graph view is cluttered

1. Use search/filter to focus on relevant signals
2. Drag nodes to organize layout
3. Use zoom controls to adjust view
4. Filter by signal group

## 🤝 Contributing

Contributions are welcome! Please see the [contributing guidelines](https://github.com/void-signals/void_signals/blob/main/CONTRIBUTING.md).

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.
