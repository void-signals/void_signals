# void_signals_lint

[![pub package](https://img.shields.io/pub/v/void_signals_lint.svg)](https://pub.dev/packages/void_signals_lint)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

English | [简体中文](README_CN.md)

Production-grade custom lint rules for [void_signals](https://pub.dev/packages/void_signals), [void_signals_flutter](https://pub.dev/packages/void_signals_flutter), and [void_signals_hooks](https://pub.dev/packages/void_signals_hooks).

This package provides comprehensive static analysis to help you write better code using void_signals, catching common mistakes, enforcing best practices, and providing **quick fixes** for most issues.

## ✨ Features

- 🔍 **33+ Lint Rules**: Comprehensive coverage of common patterns and mistakes
- 🪝 **Hooks Support**: Dedicated rules for void_signals_hooks
- 🔧 **Quick Fixes**: Most rules include automated fixes
- ⚡ **Real-time Analysis**: Instant feedback as you code
- 🎯 **Configurable**: Enable/disable rules per your project needs
- 📖 **Detailed Messages**: Clear explanations and suggestions

## 📦 Installation

Add `void_signals_lint` to your `pubspec.yaml`:

```yaml
dev_dependencies:
  void_signals_lint: ^1.0.0
  custom_lint: ^0.8.0
```

Enable `custom_lint` in your `analysis_options.yaml`:

```yaml
analyzer:
  plugins:
    - custom_lint
```

## 📋 Available Lint Rules

### Core Rules (Errors & Warnings)

| Rule | Severity | Description | Quick Fix |
|------|----------|-------------|-----------|
| `avoid_signal_in_build` | ⚠️ Warning | Prevents signal creation in build methods | ✅ Move to class level |
| `avoid_nested_effect_scope` | ⚠️ Warning | Warns against nested effect scopes | - |
| `missing_effect_cleanup` | ⚠️ Warning | Ensures effects are stored for cleanup | ✅ Store in variable |
| `avoid_signal_value_in_effect_condition` | ⚠️ Warning | Prevents conditional dependency issues | - |
| `avoid_signal_access_in_async` | ⚠️ Warning | Warns about signal access after await | - |
| `avoid_mutating_signal_collection` | ⚠️ Warning | Prevents direct mutation of collections | ✅ Use immutable update |
| `avoid_signal_creation_in_builder` | ⚠️ Warning | Prevents signals in builder callbacks | - |
| `missing_scope_dispose` | ⚠️ Warning | Ensures effect scopes are disposed | - |
| `avoid_set_state_with_signals` | ⚠️ Warning | Warns setState usage with signals | ✅ Use Watch widget |
| `caution_signal_in_init_state` | ⚠️ Warning | Cautions signal creation in initState | - |
| `watch_without_signal_access` | ⚠️ Warning | Warns Watch without signal access | - |
| `avoid_circular_computed` | ⚠️ Warning | Detects circular computed dependencies | - |
| `avoid_async_in_computed` | ⚠️ Warning | Warns async operations in computed | - |

### Best Practice Rules (Suggestions)

| Rule | Severity | Description | Quick Fix |
|------|----------|-------------|-----------|
| `prefer_watch_over_effect_in_widget` | ℹ️ Info | Suggests Watch over raw effects | ✅ Convert to Watch |
| `prefer_batch_for_multiple_updates` | ℹ️ Info | Suggests batching multiple updates | ✅ Wrap in batch() |
| `prefer_computed_over_derived_signal` | ℹ️ Info | Suggests computed over manual derivation | - |
| `prefer_final_signal` | ℹ️ Info | Suggests final for top-level signals | ✅ Add final |
| `prefer_signal_over_value_notifier` | ℹ️ Info | Migration from ValueNotifier | ✅ Convert to signal |
| `prefer_peek_in_non_reactive` | ℹ️ Info | Suggests peek() outside reactive context | ✅ Use peek() |
| `avoid_effect_for_ui` | ℹ️ Info | Suggests Watch over effect for UI | ✅ Use Watch |
| `prefer_signal_scope_for_di` | ℹ️ Info | Suggests SignalScope for DI | - |
| `prefer_signal_with_label` | ℹ️ Info | Suggests adding debug labels | ✅ Add label |
| `unnecessary_untrack` | ℹ️ Info | Removes unnecessary untrack calls | ✅ Remove untrack |

### Hooks Rules (void_signals_hooks)

| Rule | Severity | Description | Quick Fix |
|------|----------|-------------|-----------|
| `hooks_outside_hook_widget` | 🔴 Error | Ensures hooks are in HookWidget.build() | ✅ Convert to HookWidget |
| `conditional_hook_call` | 🔴 Error | Prevents hooks in conditionals/loops | ✅ Move to top level |
| `hook_in_callback` | 🔴 Error | Prevents hooks inside callbacks | ✅ Extract to top level |
| `use_signal_without_watch` | ⚠️ Warning | Warns when useSignal is not watched | ✅ Add useWatch |
| `use_select_pure_selector` | ⚠️ Warning | Ensures useSelect selector is pure | - |
| `use_debounced_zero_duration` | ⚠️ Warning | Warns against zero duration debounce | ✅ Fix duration |
| `use_effect_without_dependency` | ℹ️ Info | Warns when effect has no signal deps | - |
| `prefer_use_computed_over_effect` | ℹ️ Info | Suggests useComputed for derived values | ✅ Convert |
| `prefer_use_signal_with_label` | ℹ️ Info | Suggests debug labels for hooks | ✅ Add label |
| `unnecessary_use_batch` | ℹ️ Info | Flags unnecessary useBatch | ✅ Remove wrapper |
| `unnecessary_use_untrack` | ℹ️ Info | Flags unnecessary useUntrack | - |

---

## 📖 Rule Details

### `avoid_signal_in_build`
**Severity:** ⚠️ Warning | **Quick Fix:** ✅ Available

Warns when creating a signal inside a Flutter build method. Signals created in build methods will be recreated on every rebuild, losing their state.

```dart
// ❌ Bad - Signal recreated on every build
Widget build(BuildContext context) {
  final count = signal(0);  // Warning
  return Text('$count');
}

// ✅ Good - Signal outside build method
final count = signal(0);

Widget build(BuildContext context) {
  return Text('$count');
}
```

### `avoid_signal_access_in_async`
**Severity:** ⚠️ Warning

Warns when accessing signal values after an await statement, which can lead to stale values.

```dart
// ❌ Bad - Value may be stale after await
void fetchData() async {
  final id = userId.value;  // OK
  await someAsyncOperation();
  final name = userName.value;  // Warning: accessed after await
}

// ✅ Good - Capture value before await if needed for comparison
void fetchData() async {
  final id = userId.value;
  final name = userName.value;  // Capture before await
  await someAsyncOperation();
  // Use captured values
}
```

### `avoid_mutating_signal_collection`
**Severity:** ⚠️ Warning | **Quick Fix:** ✅ Available

Warns when directly mutating a signal's collection value, which won't trigger reactive updates.

```dart
// ❌ Bad - Direct mutation doesn't trigger updates
final items = signal<List<String>>(['a', 'b']);
items.value.add('c');  // Warning

// ✅ Good - Create new collection
items.value = [...items.value, 'c'];
```

### `prefer_watch_over_effect_in_widget`
**Severity:** ℹ️ Info | **Quick Fix:** ✅ Available

Suggests using `Watch` or `SignalBuilder` instead of creating raw effects inside widgets for UI updates.

```dart
// ❌ Not recommended
class MyWidget extends StatefulWidget {
  @override
  void initState() {
    effect(() {
      setState(() {});  // Info: Consider using Watch
    });
  }
}

// ✅ Recommended
Watch(builder: (context) => Text('${count.value}'))
```

### `prefer_batch_for_multiple_updates`
**Severity:** ℹ️ Info | **Quick Fix:** ✅ Available

Suggests using `batch()` when multiple signals are updated in sequence.

```dart
// ❌ Less efficient - Multiple notifications
firstName.value = 'John';
lastName.value = 'Doe';
age.value = 30;

// ✅ More efficient - Single notification
batch(() {
  firstName.value = 'John';
  lastName.value = 'Doe';
  age.value = 30;
});
```

### `prefer_final_signal`
**Severity:** ℹ️ Info | **Quick Fix:** ✅ Available

Suggests using `final` for top-level signals to prevent reassignment.

```dart
// ❌ Not recommended
var count = signal(0);  // Info: Prefer final

// ✅ Recommended
final count = signal(0);
```

### `prefer_signal_over_value_notifier`
**Severity:** ℹ️ Info | **Quick Fix:** ✅ Available

Suggests migrating from `ValueNotifier` to `signal` for better performance and simpler API.

```dart
// ❌ Old pattern
final counter = ValueNotifier<int>(0);  // Info: Consider using signal

// ✅ New pattern
final counter = signal(0);
```

### `avoid_circular_computed`
**Severity:** ⚠️ Warning

Detects potential circular dependencies in computed values.

```dart
// ❌ Bad - Circular dependency
final a = computed((_) => b.value + 1);
final b = computed((_) => a.value + 1);  // Warning: circular

// ✅ Good - No circular dependencies
final a = signal(1);
final b = computed((_) => a.value + 1);
```

### `avoid_async_in_computed`
**Severity:** ⚠️ Warning

Warns against async operations inside computed values, which can cause issues.

```dart
// ❌ Bad - Async in computed
final data = computed((_) async {  // Warning
  return await fetchData();
});

// ✅ Good - Use effect + signal for async
final data = signal<Data?>(null);
effect(() async {
  data.value = await fetchData();
});
```

### `missing_effect_cleanup`
**Severity:** ⚠️ Warning | **Quick Fix:** ✅ Available

Warns when an effect is created without being stored for cleanup.

```dart
// ❌ Bad - Effect cannot be stopped
void initState() {
  effect(() {  // Warning
    print(count.value);
  });
}

// ✅ Good - Effect stored for cleanup
Effect? _effect;

void initState() {
  _effect = effect(() {
    print(count.value);
  });
}

void dispose() {
  _effect?.stop();
}
```

### `prefer_peek_in_non_reactive`
**Severity:** ℹ️ Info | **Quick Fix:** ✅ Available

Suggests using `peek()` to read signal values outside of reactive contexts.

```dart
// ❌ Creates unnecessary subscription tracking
void logValue() {
  print(count.value);  // Info: Use peek() instead
}

// ✅ No subscription overhead
void logValue() {
  print(count.peek());
}
```

### `prefer_signal_with_label`
**Severity:** ℹ️ Info | **Quick Fix:** ✅ Available

Suggests adding debug labels to signals for better DevTools experience.

```dart
// ❌ No label
final count = signal(0);

// ✅ With label for debugging
final count = signal(0, label: 'counter');
```

---

## 🪝 Hooks Rules Details

### `hooks_outside_hook_widget`
**Severity:** 🔴 Error | **Quick Fix:** ✅ Available

Ensures hooks are only called inside `HookWidget.build()` or custom hook functions.

```dart
// ❌ Bad - Not in HookWidget
class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    final count = useSignal(0);  // Error!
    return Text('$count');
  }
}

// ✅ Good - Inside HookWidget
class MyWidget extends HookWidget {
  Widget build(BuildContext context) {
    final count = useSignal(0);
    return Text('${useWatch(count)}');
  }
}

// ✅ Good - Custom hook function
Signal<int> useCounter() {
  return useSignal(0);
}
```

### `conditional_hook_call`
**Severity:** 🔴 Error | **Quick Fix:** ✅ Available

Prevents hooks from being called inside conditionals or loops.

```dart
// ❌ Bad - Conditional hook call
Widget build(BuildContext context) {
  if (showCounter) {
    final count = useSignal(0);  // Error!
  }
  return Container();
}

// ✅ Good - Always call hooks
Widget build(BuildContext context) {
  final count = useSignal(0);  // Always called
  return showCounter ? Text('${useWatch(count)}') : Container();
}
```

### `hook_in_callback`
**Severity:** 🔴 Error | **Quick Fix:** ✅ Available

Prevents hooks from being called inside callbacks.

```dart
// ❌ Bad - Hook in callback
Widget build(BuildContext context) {
  return ElevatedButton(
    onPressed: () {
      final count = useSignal(0);  // Error!
    },
    child: Text('Click'),
  );
}

// ✅ Good - Hook at top level
Widget build(BuildContext context) {
  final count = useSignal(0);
  return ElevatedButton(
    onPressed: () => count.value++,
    child: Text('Click'),
  );
}
```

### `use_signal_without_watch`
**Severity:** ⚠️ Warning | **Quick Fix:** ✅ Available

Warns when a signal is created with `useSignal` but not subscribed with `useWatch`.

```dart
// ❌ Bad - Widget won't rebuild
Widget build(BuildContext context) {
  final count = useSignal(0);
  return Text('${count.value}');  // Warning!
}

// ✅ Good - Properly subscribed
Widget build(BuildContext context) {
  final count = useSignal(0);
  return Text('${useWatch(count)}');
}

// ✅ Alternative - Use useReactive
Widget build(BuildContext context) {
  final count = useReactive(0);  // Auto-subscribes
  return Text('${count.value}');
}
```

### `prefer_use_computed_over_effect`
**Severity:** ℹ️ Info | **Quick Fix:** ✅ Available

Suggests using `useComputed` instead of `useSignalEffect` for derived values.

```dart
// ❌ Not recommended
Widget build(BuildContext context) {
  final firstName = useSignal('John');
  final lastName = useSignal('Doe');
  final fullName = useSignal('');
  
  useSignalEffect(() {
    fullName.value = '${firstName.value} ${lastName.value}';
  });
  
  return Text(useWatch(fullName));
}

// ✅ Better - Use computed
Widget build(BuildContext context) {
  final firstName = useSignal('John');
  final lastName = useSignal('Doe');
  final fullName = useComputed((_) => 
    '${firstName.value} ${lastName.value}'
  );
  
  return Text(useWatch(fullName));
}
```

---

## ⚙️ Configuration

You can enable/disable specific rules in your `analysis_options.yaml`:

```yaml
custom_lint:
  rules:
    # Core rules (enabled by default)
    - avoid_signal_in_build: true
    - avoid_nested_effect_scope: true
    - missing_effect_cleanup: true
    - avoid_signal_access_in_async: true
    - avoid_mutating_signal_collection: true
    - avoid_signal_creation_in_builder: true
    - missing_scope_dispose: true
    - avoid_set_state_with_signals: true
    - avoid_circular_computed: true
    - avoid_async_in_computed: true
    
    # Best practice rules (can be disabled if needed)
    - prefer_watch_over_effect_in_widget: true
    - prefer_batch_for_multiple_updates: true
    - prefer_computed_over_derived_signal: true
    - prefer_final_signal: false  # Disabled
    - prefer_signal_over_value_notifier: true
    - prefer_peek_in_non_reactive: false  # Disabled
    - prefer_signal_with_label: false  # Optional for debugging
```

## 🚀 Running in CI

To get lint results in your CI/CD pipeline:

```bash
# Run all custom_lint rules
dart run custom_lint

# Exit with error code on issues (for CI)
dart run custom_lint --fatal-infos --fatal-warnings
```

## 🔧 Quick Fixes

Most rules come with automated quick fixes accessible via:

- **VS Code**: Click the lightbulb 💡 or press `Ctrl+.` / `Cmd+.`
- **IntelliJ/Android Studio**: Press `Alt+Enter`
- **Command line**: `dart run custom_lint --fix`

Available quick fixes:

| Rule | Fix Action |
|------|------------|
| `avoid_signal_in_build` | Move signal to class level |
| `prefer_batch_for_multiple_updates` | Wrap updates in batch() |
| `missing_effect_cleanup` | Store effect in a variable |
| `prefer_watch_over_effect_in_widget` | Convert to Watch widget |
| `avoid_mutating_signal_collection` | Use immutable update pattern |
| `prefer_final_signal` | Add final keyword |
| `prefer_signal_over_value_notifier` | Convert to signal |
| `prefer_peek_in_non_reactive` | Replace with peek() |
| `prefer_signal_with_label` | Add label parameter |
| `avoid_effect_for_ui` | Convert to Watch widget |
| `avoid_set_state_with_signals` | Replace with Watch |
| `unnecessary_untrack` | Remove untrack wrapper |

## 📊 Comparison with Other Solutions

| Feature | void_signals_lint | riverpod_lint | flutter_hooks_lint |
|---------|-------------------|---------------|-------------------|
| Signal lifecycle rules | ✅ | ❌ | ❌ |
| Async safety rules | ✅ | ✅ | ❌ |
| Collection mutation detection | ✅ | ❌ | ❌ |
| Circular dependency detection | ✅ | ❌ | ❌ |
| Migration helpers | ✅ | ✅ | ❌ |
| Quick fixes | ✅ 12+ | ✅ | ✅ |

## 🤝 Contributing

Contributions are welcome! Please see the [contributing guidelines](https://github.com/void-signals/void_signals/blob/main/CONTRIBUTING.md).

Have an idea for a new rule? [Open an issue](https://github.com/void-signals/void_signals/issues/new)!

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.
