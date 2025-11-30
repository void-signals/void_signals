<p align="center">
  <img src="https://raw.githubusercontent.com/void-signals/void-signals/main/art/void.png" alt="void_signals logo" width="180" />
</p>

<h1 align="center">void_signals_lint</h1>

<p align="center">
  <a href="https://pub.dev/packages/void_signals">void_signals</a>、<a href="https://pub.dev/packages/void_signals_flutter">void_signals_flutter</a> 和 <a href="https://pub.dev/packages/void_signals_hooks">void_signals_hooks</a> 的生产级自定义 lint 规则。
</p>

<p align="center">
  <a href="https://pub.dev/packages/void_signals_lint"><img src="https://img.shields.io/pub/v/void_signals_lint.svg" alt="pub package" /></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT" /></a>
</p>

<p align="center">
  <a href="README.md">English</a> | 简体中文
</p>

---

本包提供全面的静态分析，帮助你使用 void_signals 编写更好的代码，捕获常见错误，强制执行最佳实践，并为大多数问题提供**快速修复**。

## ✨ 特性

- 🔍 **33+ Lint 规则**: 全面覆盖常见模式和错误
- 🪝 **Hooks 支持**: void_signals_hooks 专用规则
- 🔧 **快速修复**: 大多数规则包含自动修复
- ⚡ **实时分析**: 编码时即时反馈
- 🎯 **可配置**: 根据项目需求启用/禁用规则
- 📖 **详细消息**: 清晰的解释和建议

## 📦 安装

在 `pubspec.yaml` 中添加 `void_signals_lint`：

```yaml
dev_dependencies:
  void_signals_lint: ^1.0.0
  custom_lint: ^0.8.0
```

在 `analysis_options.yaml` 中启用 `custom_lint`：

```yaml
analyzer:
  plugins:
    - custom_lint
```

## 📋 可用 Lint 规则

### 核心规则（错误和警告）

| 规则 | 严重性 | 描述 | 快速修复 |
|------|--------|------|---------|
| `avoid_signal_in_build` | ⚠️ 警告 | 防止在 build 方法中创建信号 | ✅ 移到类级别 |
| `avoid_nested_effect_scope` | ⚠️ 警告 | 警告嵌套的副作用作用域 | - |
| `missing_effect_cleanup` | ⚠️ 警告 | 确保副作用被存储以便清理 | ✅ 存储到变量 |
| `avoid_signal_value_in_effect_condition` | ⚠️ 警告 | 防止条件依赖问题 | - |
| `avoid_signal_access_in_async` | ⚠️ 警告 | 警告 await 后访问信号 | - |
| `avoid_mutating_signal_collection` | ⚠️ 警告 | 防止直接修改集合 | ✅ 使用不可变更新 |
| `avoid_signal_creation_in_builder` | ⚠️ 警告 | 防止在 builder 回调中创建信号 | - |
| `missing_scope_dispose` | ⚠️ 警告 | 确保副作用作用域被释放 | - |
| `avoid_set_state_with_signals` | ⚠️ 警告 | 警告与信号一起使用 setState | ✅ 使用 Watch widget |
| `caution_signal_in_init_state` | ⚠️ 警告 | 警告在 initState 中创建信号 | - |
| `watch_without_signal_access` | ⚠️ 警告 | 警告 Watch 中没有信号访问 | - |
| `avoid_circular_computed` | ⚠️ 警告 | 检测循环计算依赖 | - |
| `avoid_async_in_computed` | ⚠️ 警告 | 警告计算中的异步操作 | - |

### 最佳实践规则（建议）

| 规则 | 严重性 | 描述 | 快速修复 |
|------|--------|------|---------|
| `prefer_watch_over_effect_in_widget` | ℹ️ 信息 | 建议用 Watch 代替原始 effects | ✅ 转换为 Watch |
| `prefer_batch_for_multiple_updates` | ℹ️ 信息 | 建议批量多个更新 | ✅ 包装在 batch() 中 |
| `prefer_computed_over_derived_signal` | ℹ️ 信息 | 建议用 computed 代替手动派生 | - |
| `prefer_final_signal` | ℹ️ 信息 | 建议顶层信号使用 final | ✅ 添加 final |
| `prefer_signal_over_value_notifier` | ℹ️ 信息 | 从 ValueNotifier 迁移 | ✅ 转换为 signal |
| `prefer_peek_in_non_reactive` | ℹ️ 信息 | 建议在响应式上下文外使用 peek() | ✅ 使用 peek() |
| `avoid_effect_for_ui` | ℹ️ 信息 | 建议用 Watch 代替 effect 处理 UI | ✅ 使用 Watch |
| `prefer_signal_scope_for_di` | ℹ️ 信息 | 建议用 SignalScope 进行 DI | - |
| `prefer_signal_with_label` | ℹ️ 信息 | 建议添加调试标签 | ✅ 添加 label |
| `unnecessary_untrack` | ℹ️ 信息 | 移除不必要的 untrack 调用 | ✅ 移除 untrack |

### Hooks 规则 (void_signals_hooks)

| 规则 | 严重性 | 描述 | 快速修复 |
|------|--------|------|---------|
| `hooks_outside_hook_widget` | 🔴 错误 | 确保 hooks 在 HookWidget.build() 中 | ✅ 转换为 HookWidget |
| `conditional_hook_call` | 🔴 错误 | 防止 hooks 在条件/循环中 | ✅ 移到顶层 |
| `hook_in_callback` | 🔴 错误 | 防止 hooks 在回调中 | ✅ 提取到顶层 |
| `use_signal_without_watch` | ⚠️ 警告 | useSignal 未被 watch 时警告 | ✅ 添加 useWatch |
| `use_select_pure_selector` | ⚠️ 警告 | 确保 useSelect 选择器是纯函数 | - |
| `use_debounced_zero_duration` | ⚠️ 警告 | 警告零时长防抖 | ✅ 修复 duration |
| `use_effect_without_dependency` | ℹ️ 信息 | 副作用无信号依赖时警告 | - |
| `prefer_use_computed_over_effect` | ℹ️ 信息 | 建议用 useComputed 处理派生值 | ✅ 转换 |
| `prefer_use_signal_with_label` | ℹ️ 信息 | 建议 hooks 添加调试标签 | ✅ 添加 label |
| `unnecessary_use_batch` | ℹ️ 信息 | 标记不必要的 useBatch | ✅ 移除包装 |
| `unnecessary_use_untrack` | ℹ️ 信息 | 标记不必要的 useUntrack | - |

---

## 📖 规则详情

### `avoid_signal_in_build`
**严重性:** ⚠️ 警告 | **快速修复:** ✅ 可用

在 Flutter build 方法中创建信号时警告。在 build 方法中创建的信号会在每次重建时重新创建，丢失其状态。

```dart
// ❌ 不好 - 信号在每次 build 时重新创建
Widget build(BuildContext context) {
  final count = signal(0);  // 警告
  return Text('$count');
}

// ✅ 好 - 信号在 build 方法外
final count = signal(0);

Widget build(BuildContext context) {
  return Text('$count');
}
```

### `avoid_mutating_signal_collection`
**严重性:** ⚠️ 警告 | **快速修复:** ✅ 可用

直接修改信号的集合值时警告，这不会触发响应式更新。

```dart
// ❌ 不好 - 直接修改不触发更新
final items = signal<List<String>>(['a', 'b']);
items.value.add('c');  // 警告

// ✅ 好 - 创建新集合
items.value = [...items.value, 'c'];
```

### `prefer_batch_for_multiple_updates`
**严重性:** ℹ️ 信息 | **快速修复:** ✅ 可用

连续更新多个信号时建议使用 `batch()`。

```dart
// ❌ 效率较低 - 多次通知
firstName.value = '张';
lastName.value = '三';
age.value = 30;

// ✅ 更高效 - 单次通知
batch(() {
  firstName.value = '张';
  lastName.value = '三';
  age.value = 30;
});
```

---

## ⚙️ 配置

你可以在 `analysis_options.yaml` 中启用/禁用特定规则：

```yaml
custom_lint:
  rules:
    # 核心规则（默认启用）
    - avoid_signal_in_build: true
    - avoid_nested_effect_scope: true
    - missing_effect_cleanup: true
    
    # 最佳实践规则（可按需禁用）
    - prefer_final_signal: false  # 禁用
    - prefer_signal_with_label: false  # 可选用于调试
```

## 🚀 在 CI 中运行

在 CI/CD 管道中获取 lint 结果：

```bash
# 运行所有 custom_lint 规则
dart run custom_lint

# 有问题时以错误码退出（用于 CI）
dart run custom_lint --fatal-infos --fatal-warnings
```

## 🔧 快速修复

大多数规则都有自动快速修复，可通过以下方式访问：

- **VS Code**: 点击灯泡 💡 或按 `Ctrl+.` / `Cmd+.`
- **IntelliJ/Android Studio**: 按 `Alt+Enter`
- **命令行**: `dart run custom_lint --fix`

## 🤝 贡献

欢迎贡献！请参阅[贡献指南](https://github.com/void-signals/void_signals/blob/main/CONTRIBUTING.md)。

有新规则的想法？[提交 issue](https://github.com/void-signals/void_signals/issues/new)！

## 📄 许可证

MIT 许可证 - 详见 [LICENSE](LICENSE)。
