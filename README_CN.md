<p align="center">
  <img src="art/void.png" alt="void_signals logo" width="180" />
</p>

<h1 align="center">void_signals</h1>

<p align="center">
  基于 <a href="https://github.com/stackblitz/alien-signals">alien-signals</a> 的高性能 Dart/Flutter 信号响应式库。
</p>

<p align="center">
  <a href="https://pub.dev/packages/void_signals"><img src="https://img.shields.io/pub/v/void_signals" alt="Pub Version" /></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT" /></a>
</p>

<p align="center">
  <a href="README.md">English</a> | 简体中文
</p>

---

## 特性

- ⚡ **高性能**: 基于 alien-signals，最快的信号实现之一
- 🎯 **零开销抽象**: 使用 Dart 扩展类型实现零成本抽象
- 🔄 **细粒度响应**: 只更新真正变化的部分
- 🧩 **极简 API**: 只需 `signal()`、`computed()`、`effect()` 三个概念
- 📦 **Flutter 支持**: 与 Flutter Widget 无缝集成
- 🪝 **Hooks 支持**: 可选的 flutter_hooks 集成

## 包列表

| 包 | 描述 |
|---|------|
| [void_signals](packages/void_signals/) | Dart 核心响应式原语 |
| [void_signals_flutter](packages/void_signals_flutter/) | Flutter 绑定和 Widget |
| [void_signals_hooks](packages/void_signals_hooks/) | Flutter hooks 集成 |
| [void_signals_lint](packages/void_signals_lint/) | 自定义 lint 规则 |
| [void_signals_devtools_extension](packages/void_signals_devtools_extension/) | DevTools 扩展 |

## 快速开始

### 安装

```yaml
dependencies:
  void_signals: ^1.0.0
  void_signals_flutter: ^1.0.0  # Flutter 项目
  void_signals_hooks: ^1.0.0    # flutter_hooks 用户
```

### 基本用法

```dart
import 'package:void_signals/void_signals.dart';

void main() {
  // 创建信号
  final count = signal(0);
  
  // 创建计算值
  final doubled = computed((prev) => count() * 2);
  
  // 创建副作用
  effect(() {
    print('Count: ${count()}, Doubled: ${doubled()}');
  });
  
  count.value = 1;  // 打印: Count: 1, Doubled: 2
  count.value = 2;  // 打印: Count: 2, Doubled: 4
}
```

### Flutter 用法

```dart
import 'package:flutter/material.dart';
import 'package:void_signals_flutter/void_signals_flutter.dart';

// 在文件顶层定义信号
final counter = signal(0);

class CounterWidget extends StatelessWidget {
  const CounterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Watch(builder: (context, _) => Column(
      children: [
        Text('计数: ${counter.value}'),
        ElevatedButton(
          onPressed: () => counter.value++,
          child: const Text('增加'),
        ),
      ],
    ));
  }
}
```

## 核心概念

### Signal (信号)

信号是一个响应式值，当它变化时会通知订阅者。

```dart
final name = signal('张三');
print(name.value);  // '张三'
name.value = '李四';  // 通知所有订阅者
```

### Computed (计算值)

计算值从其他信号派生，当依赖变化时自动更新。

```dart
final firstName = signal('张');
final lastName = signal('三');
final fullName = computed((prev) => '${firstName()} ${lastName()}');

print(fullName());  // '张 三'
firstName.value = '李';
print(fullName());  // '李 三'
```

### Effect (副作用)

副作用在依赖变化时自动运行。

```dart
final count = signal(0);

final eff = effect(() {
  print('计数变为: ${count()}');
});

count.value = 1;  // 打印: 计数变为: 1
eff.stop();  // 停止监听
```

### Batch (批量更新)

批量更新多个信号，副作用只运行一次。

```dart
final a = signal(1);
final b = signal(2);

effect(() {
  print('总和: ${a() + b()}');
});

batch(() {
  a.value = 10;
  b.value = 20;
});
// 只打印一次: 总和: 30
```

## 高级特性

### Effect Scope (副作用作用域)

将多个副作用组合在一起，便于统一清理。

```dart
final scope = effectScope(() {
  effect(() { /* 副作用 1 */ });
  effect(() { /* 副作用 2 */ });
});

scope.stop();  // 停止作用域内所有副作用
```

### Untrack (取消追踪)

读取信号但不创建依赖。

```dart
effect(() {
  print(count());  // 创建依赖
  untrack(() => otherSignal());  // 不创建依赖
});
```

## 性能

void_signals 基于 alien-signals 构建，是目前最快的信号实现之一。主要优化包括：

- **扩展类型** 实现零成本抽象
- **惰性求值** 用于计算值
- **高效依赖追踪** O(1) 操作
- **最小内存分配** 通过对象池

### 基准测试结果

我们运行全面的基准测试，将 void_signals 与其他流行的响应式库进行比较。基准测试在每次推送到主分支时自动运行。

📊 **[查看最新基准测试报告](benchmark/bench/BENCHMARK_REPORT.md)**

<!-- BENCHMARK_SUMMARY_START -->
| Rank | Framework | Wins | Pass Rate |
|------|-----------|------|-----------|
| 🥇 | void_signals | 22 | 100% |
| 🥈 | alien_signals | 10 | 100% |
| 🥉 | state_beacon | 3 | 100% |
| 4 | preact_signals | 1 | 100% |
| 5 | mobx | 0 | 100% |
| 6 | signals_core | 0 | 100% |
| 7 | solidart | 0 | 100% |
<!-- BENCHMARK_SUMMARY_END -->

基准测试包括：
- 传播模式（深度、广度、菱形、三角形）
- 动态依赖
- 单元格响应性
- 计算值链
- 信号创建和更新

## 贡献

欢迎贡献！请在提交 PR 前阅读我们的[贡献指南](CONTRIBUTING.md)。

## 许可证

MIT 许可证 - 详见 [LICENSE](LICENSE)。
