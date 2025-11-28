# void_signals_flutter

[void_signals](https://pub.dev/packages/void_signals) 的 Flutter 绑定 - 高性能响应式状态管理解决方案。

[![Pub Version](https://img.shields.io/pub/v/void_signals_flutter)](https://pub.dev/packages/void_signals_flutter)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

[English](README.md) | 简体中文

## 为什么选择 void_signals？

| 特性 | void_signals | Riverpod | GetX |
|------|-------------|----------|------|
| API 复杂度 | ⭐ 2 个概念 | 8+ 概念 | 5+ 概念 |
| 学习曲线 | 分钟级 | 小时级 | 小时级 |
| 性能 | 细粒度 | 细粒度 | 粗粒度 |
| 样板代码 | 极少 | 中等 | 较少 |

## 快速开始：只需 2 个概念！

```dart
import 'package:void_signals_flutter/void_signals_flutter.dart';

// 1. signal() - 创建响应式状态
final count = signal(0);

// 2. Watch() - 响应变化
Watch(builder: (context, _) => Text('计数: ${count.value}'));

// 更新触发重建
count.value++;
```

这就是 95% 场景下需要的全部 API！

## 核心概念

### 📦 signal(value) - 响应式状态

```dart
// 在模块/文件级别创建信号
final counter = signal(0);
final user = signal<User?>(null);
final items = signal<List<Item>>([]);

// 读取值（在 Watch 内自动追踪）
print(counter.value);  // 0

// 写入值（触发响应式更新）
counter.value = 10;
counter.value++;

// Peek 无追踪读取（用于事件处理器）
final current = counter.peek();
```

### 👀 Watch() - 响应式 Widget

`Watch` widget 自动追踪其 builder 内访问的所有信号：

```dart
// 简单情况
Watch(builder: (context, _) => Text('${counter.value}'));

// 多个信号 - 全部自动追踪！
Watch(builder: (context, child) {
  if (isLoading.value) return CircularProgressIndicator();
  
  return Column(children: [
    Text('用户: ${user.value?.name}'),
    Text('项目: ${items.value.length}'),
    child!, // 静态 child 不会重建
  ]);
}, child: const ExpensiveWidget());
```

### 🧮 computed() - 派生值

```dart
final items = signal<List<Item>>([]);

// 派生值自动更新
final itemCount = computed((_) => items.value.length);
final totalPrice = computed((_) => 
    items.value.fold(0.0, (sum, item) => sum + item.price));

// 在 Watch 中使用
Watch(builder: (context, _) => Text('总计: ¥${totalPrice.value}'));
```

### ⚡ effect() - 副作用

```dart
// 立即运行，然后在依赖变化时运行
effect(() {
  print('计数器变化: ${counter.value}');
});

// 在 initState 中用于日志、分析等
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

## 基础 API

### 读取 vs Peek

```dart
// Watch builder 内 - 使用 .value（被追踪）
Watch(builder: (context, _) => Text('${counter.value}'));

// 事件处理器中 - 使用 .peek()（不被追踪）
ElevatedButton(
  onPressed: () {
    final current = counter.peek();
    counter.value = current + 1;
  },
  child: Text('增加'),
)
```

### 批量更新

```dart
// 不使用 batch：3 次重建
counter.value = 1;
name.value = '张三';
active.value = true;

// 使用 batch：1 次重建
batch(() {
  counter.value = 1;
  name.value = '张三';
  active.value = true;
});
```

### 便捷扩展

```dart
// 整数信号
counter.increment();     // counter.value++
counter.decrement();     // counter.value--

// 布尔信号
isOpen.toggle();         // isOpen.value = !isOpen.value

// 列表信号
items.add('item');
items.remove('item');
items.clear();

// Map 信号
settings.set('key', 42);
settings.remove('key');

// 可空信号
user.clear();            // user.value = null
user.orDefault(guest);   // user.value ?? guest

// 转换
counter.modify((v) => v * 2);
```

## 实际示例

### 计数器应用

```dart
final counter = signal(0);

class CounterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('计数器')),
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

### Todo 应用

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
        title: Watch(builder: (_, __) => Text('${activeCount.value} 项待办')),
      ),
      body: Watch(builder: (context, _) => ListView.builder(
        itemCount: filteredTodos.value.length,
        itemBuilder: (context, index) => TodoTile(todo: filteredTodos.value[index]),
      )),
    );
  }
}
```

## 高级特性

### SignalScope - 路由级状态覆盖

用于需要独立状态的页面：

```dart
final counter = signal(0);  // 全局: 0

// 导航到带覆盖值的页面
Navigator.push(context, MaterialPageRoute(
  builder: (_) => SignalScope(
    overrides: [counter.override(100)],  // 局部: 100
    child: DetailPage(),
  ),
));

// 在 DetailPage 中
class DetailPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final localCounter = counter.scoped(context);  // 获取 100，不是 0
    
    return Watch(builder: (context, _) => Text('${localCounter.value}'));
  }
}
```

### SignalSelector - 性能优化

只在选择的部分变化时重建：

```dart
final user = signal(User(name: '张三', email: 'zhang@example.com', age: 30));

// 只在 name 变化时重建，email 或 age 变化不重建
SignalSelector<User, String>(
  signal: user,
  selector: (u) => u.name,
  builder: (context, name, _) => Text(name),
)
```

### 时间相关工具

```dart
final searchQuery = signal('');

// Debounce - 等待输入暂停
final debouncedQuery = debounced(searchQuery, Duration(milliseconds: 300));

// Throttle - 每段时间最多更新一次
final throttledQuery = throttled(searchQuery, Duration(milliseconds: 100));

// 别忘了释放！
@override
void dispose() {
  debouncedQuery.dispose();
  throttledQuery.dispose();
  super.dispose();
}
```

## 从其他库迁移

### 从 Riverpod 迁移

```dart
// 之前 (Riverpod)
final counterProvider = StateProvider((ref) => 0);

class MyWidget extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);
    return Text('$count');
  }
}

// 之后 (void_signals)
final counter = signal(0);

class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return Watch(builder: (_, __) => Text('${counter.value}'));
  }
}
```

### 从 GetX 迁移

```dart
// 之前 (GetX)
final count = 0.obs;
Obx(() => Text('${count.value}'));

// 之后 (void_signals)
final count = signal(0);
Watch(builder: (_, __) => Text('${count.value}'));
```

## 最佳实践

1. **在模块级别定义信号** - 便于访问和测试
2. **使用 Watch 处理 UI** - 最简单的响应式 widget
3. **使用 computed 处理派生状态** - 而非 effects
4. **使用 batch 处理多个更新** - 最小化重建
5. **在回调中使用 peek()** - 避免不必要的追踪
6. **在 dispose() 中释放 effects** - 防止内存泄漏

## API 参考

| 概念 | 使用场景 |
|------|---------|
| `signal(value)` | 创建响应式状态 |
| `Watch(builder: ...)` | 信号变化时重建 widget |
| `computed((_) => ...)` | 从信号派生值 |
| `effect(() => ...)` | 运行副作用 |
| `batch(() => ...)` | 组合多个更新 |
| `signal.peek()` | 无追踪读取 |
| `untrack(() => ...)` | 无追踪运行代码 |

## DevTools 扩展

本包包含用于调试信号的 DevTools 扩展：

```dart
void main() {
  VoidSignalsDebugService.initialize();
  runApp(MyApp());
}
```

## 相关包

- [void_signals](https://pub.dev/packages/void_signals) - 核心库
- [void_signals_hooks](https://pub.dev/packages/void_signals_hooks) - Flutter hooks 集成

## 许可证

MIT 许可证 - 详见 [LICENSE](LICENSE)。
