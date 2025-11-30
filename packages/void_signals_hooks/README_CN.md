<p align="center">
  <img src="https://raw.githubusercontent.com/void-signals/void-signals/main/art/void.png" alt="void_signals logo" width="180" />
</p>

<h1 align="center">void_signals_hooks</h1>

<p align="center">
  <a href="https://pub.dev/packages/void_signals">void_signals</a> 的 Flutter hooks 集成 - 使用响应式信号与 flutter_hooks。
</p>

<p align="center">
  <a href="https://pub.dev/packages/void_signals_hooks"><img src="https://img.shields.io/pub/v/void_signals_hooks" alt="Pub Version" /></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT" /></a>
</p>

<p align="center">
  <a href="README.md">English</a> | 简体中文
</p>

---

## 特性

- 🪝 **基于 Hook**: 与 flutter_hooks 无缝集成
- 📦 **记忆化信号**: 信号在重建间持久化
- 🔄 **自动清理**: Effects 自动释放
- 🎯 **细粒度**: 只重建变化的部分

## 安装

```yaml
dependencies:
  void_signals_hooks: ^1.0.0
```

## 快速开始

```dart
import 'package:flutter/material.dart';
import 'package:void_signals_hooks/void_signals_hooks.dart';

class Counter extends HookWidget {
  const Counter({super.key});

  @override
  Widget build(BuildContext context) {
    // 创建信号（跨重建记忆化）
    final count = useSignal(0);
    
    // 监听信号（值变化时重建）
    final value = useWatch(count);
    
    return Column(
      children: [
        Text('计数: $value'),
        ElevatedButton(
          onPressed: () => count.value++,
          child: const Text('增加'),
        ),
      ],
    );
  }
}
```

## 核心 Hooks

### useSignal

创建并记忆化一个信号。

```dart
final count = useSignal(0);
final user = useSignal<User?>(null);
final items = useSignal<List<String>>([]);
```

### useComputed

创建并记忆化一个计算值。

```dart
final firstName = useSignal('张');
final lastName = useSignal('三');

// 带前值
final fullName = useComputed((prev) => '${firstName.value} ${lastName.value}');

// 简单形式（不需要前值）
final doubled = useComputedSimple(() => count.value * 2);
```

### useWatch

监听信号并在变化时触发重建。

```dart
final count = useSignal(0);
final value = useWatch(count);  // count 变化时重建

// 对于计算值
final computedValue = useWatchComputed(someComputed);
```

### useReactive

一次调用创建信号并监听。返回 (value, setValue) 元组。

```dart
final (count, setCount) = useReactive(0);

// 像 useState 一样使用
Text('计数: $count'),
ElevatedButton(
  onPressed: () => setCount(count + 1),
  child: const Text('增加'),
),
```

### useSignalEffect

创建在依赖变化时重新运行的副作用。

```dart
final count = useSignal(0);

useSignalEffect(() {
  print('计数变为: ${count.value}');
});

// 带 keys（keys 变化时重建副作用）
useSignalEffect(() {
  fetchData(userId);
}, [userId]);
```

### useEffectScope

创建用于组合副作用的作用域。

```dart
final scope = useEffectScope(() {
  // 在这里设置副作用
});

// widget 卸载时自动释放副作用
```

## 选择 Hooks

### useSelect

选择信号值的一部分。只在选择的值变化时重建。

```dart
final user = useSignal(User(name: '张三', age: 30));

// 只在 name 变化时重建，age 变化不重建
final name = useSelect(user, (u) => u.name);
```

### useSelectComputed

与 useSelect 相同，但用于计算值。

```dart
final users = useComputed((_) => fetchUsers());
final count = useSelectComputed(users, (list) => list.length);
```

## 工具 Hooks

### useBatch

批量多个信号更新。

```dart
final a = useSignal(0);
final b = useSignal(0);

// 更新两个信号，副作用只运行一次
useBatch(() {
  a.value = 10;
  b.value = 20;
});
```

### useUntrack

无依赖读取信号。

```dart
final other = useUntrack(() => someSignal.value);
```

### useSignalFromStream

从流创建信号。

```dart
final messages = useSignalFromStream(
  messageStream,
  initialValue: [],
);
```

### useSignalFromFuture

从 Future 创建信号。

```dart
final user = useSignalFromFuture(
  fetchUser(),
  initialValue: null,
);
```

## 时间相关 Hooks

### useDebounced

创建延迟后更新的防抖信号。

```dart
final searchQuery = useSignal('');
final debouncedQuery = useDebounced(searchQuery, Duration(milliseconds: 300));

// 使用 debouncedQuery 进行 API 调用
useSignalEffect(() {
  fetchSearchResults(debouncedQuery.value);
});
```

### useThrottled

创建每段时间最多更新一次的节流信号。

```dart
final scrollPosition = useSignal(0.0);
final throttled = useThrottled(scrollPosition, Duration(milliseconds: 100));
```

## 组合 Hooks

### useCombine2 / useCombine3

将多个信号组合为计算值。

```dart
final firstName = useSignal('张');
final lastName = useSignal('三');

final fullName = useCombine2(
  firstName,
  lastName,
  (first, last) => '$first $last',
);
```

### usePrevious

追踪信号的当前和前一个值。

```dart
final count = useSignal(0);
final (current, previous) = usePrevious(count);

// current.value: 5
// previous.value: 4（如果是第一个值则为 null）
```

## 异步 Hooks

### useAsync

处理异步操作的 Hook，支持手动执行控制。

```dart
final (state, execute, reset) = useAsync<User>();

// 执行异步操作
void loadUser() async {
  await execute(() async {
    await Future.delayed(Duration(seconds: 1));
    return User(name: '张三', age: 30);
  });
}

// 使用模式匹配处理状态
state.when(
  idle: () => const Text('点击按钮加载'),
  loading: () => const CircularProgressIndicator(),
  success: (user) => Text('你好, ${user.name}'),
  error: (error) => Text('错误: $error'),
);

// 重置为空闲状态
reset();
```

### useAsyncData

自动执行异步操作的 Hook，支持依赖键。

```dart
// userId 变化时自动重新执行
final state = useAsyncData(
  () async {
    final response = await api.fetchUser(userId);
    return response;
  },
  keys: [userId],
);

// 使用 maybeWhen 进行部分处理
state.maybeWhen(
  success: (user) => UserCard(user: user),
  orElse: () => const LoadingPlaceholder(),
);
```

### useLatest

获取最新值的引用，不会订阅变化。

```dart
final count = useSignal(0);
final latestRef = useLatest(count);

// 在回调中访问最新值而不触发重建
void handleClick() {
  print('当前计数: ${latestRef.value}');
}
```

### useListener

监听信号变化执行副作用。

```dart
final count = useSignal(0);

useListener(
  count,
  (value) {
    print('计数变为: $value');
    analytics.log('count_changed', value);
  },
  fireImmediately: true,  // 立即用当前值触发
);
```

## 状态 Hooks

### useToggle

简单的布尔开关 Hook。

```dart
final (isOn, toggle, setOn, setOff) = useToggle(false);

// 切换值
toggle();

// 设置特定值
setOn();   // 设为 true
setOff();  // 设为 false
```

### useCounter

计数器 Hook，支持增加、减少、重置和设值。

```dart
final (count, increment, decrement, reset, setValue) = useCounter(
  initialValue: 0,
  step: 1,
  min: 0,
  max: 100,
);

increment();     // 计数 + step
decrement();     // 计数 - step
reset();         // 回到初始值
setValue(50);    // 设置特定值
```

## 定时器 Hooks

### useInterval

定期运行回调。

```dart
// 每秒运行一次
useInterval(
  () {
    fetchNewMessages();
  },
  Duration(seconds: 1),
);

// 传入 null 回调来暂停
useInterval(
  isPaused ? null : () => tick(),
  Duration(seconds: 1),
);
```

### useTimeout

延迟后运行回调。

```dart
final (isActive, cancel, restart) = useTimeout(
  () {
    showNotification('时间到!');
  },
  Duration(seconds: 5),
);

// 取消超时
cancel();

// 重新开始超时
restart();
```

## 集合 Hooks

### useSignalList

创建响应式列表。

```dart
final items = useSignalList<String>(['a', 'b', 'c']);

items.add('d');
items.remove('a');
items.clear();
```

### useSignalMap

创建响应式 Map。

```dart
final settings = useSignalMap<String, dynamic>({
  'theme': 'dark',
  'fontSize': 14,
});

settings['language'] = 'zh';
settings.remove('theme');
```

### useSignalSet

创建响应式 Set。

```dart
final selected = useSignalSet<int>({1, 2, 3});

selected.add(4);
selected.toggle(1);  // 不存在则添加，存在则移除
```

## 示例：Todo 应用

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
        Text('$watchedActiveCount 项待办'),
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

## 最佳实践

1. **使用 useSignal 处理本地状态** 需要在重建间持久化
2. **使用 useWatch 触发重建** 当需要 widget 更新时
3. **使用 useSelect 进行部分更新** 以最小化重建
4. **使用 useDebounced 处理用户输入** 避免过度更新
5. **优先使用 useComputed 而非 useSignalEffect** 处理派生值
6. **使用 useBatch 处理相关更新** 副作用只运行一次

## 🔍 Lint 支持

安装 [void_signals_lint](https://pub.dev/packages/void_signals_lint) 获得全面的静态分析：

```yaml
dev_dependencies:
  void_signals_lint: ^1.0.0
  custom_lint: ^0.8.0
```

可用的 hooks 相关规则：

| 规则 | 严重性 | 描述 |
|------|--------|------|
| `hooks_outside_hook_widget` | 🔴 错误 | 确保 hooks 在 HookWidget.build() 中 |
| `conditional_hook_call` | 🔴 错误 | 防止 hooks 在条件/循环中 |
| `hook_in_callback` | 🔴 错误 | 防止 hooks 在回调中 |
| `use_signal_without_watch` | ⚠️ 警告 | useSignal 未被 watch 时警告 |
| `use_select_pure_selector` | ⚠️ 警告 | 确保 useSelect 选择器是纯函数 |
| `prefer_use_computed_over_effect` | ℹ️ 信息 | 建议用 useComputed 处理派生值 |

## 相关包

- [void_signals](https://pub.dev/packages/void_signals) - 核心库
- [void_signals_flutter](https://pub.dev/packages/void_signals_flutter) - Flutter widgets

## 许可证

MIT 许可证 - 详见 [LICENSE](LICENSE)。
