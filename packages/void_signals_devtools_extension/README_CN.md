# void_signals DevTools 扩展

[![pub package](https://img.shields.io/pub/v/void_signals_devtools_extension.svg)](https://pub.dev/packages/void_signals_devtools_extension)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

用于可视化和调试 [void_signals](https://pub.dev/packages/void_signals) 响应式状态管理的强大 DevTools 扩展。

[English](README.md) | 简体中文

## ✨ 特性

- 🔍 **信号列表视图**: 浏览所有信号、计算值和副作用，支持过滤和搜索
- 📊 **依赖图**: 响应式依赖的交互式可视化
- ⏱️ **时间线视图**: 通过可视时间线追踪值的变化
- 📈 **统计仪表板**: 性能指标、更新频率和洞察
- ✏️ **实时编辑**: 实时修改信号值进行调试
- 🔄 **自动刷新**: 实时状态同步
- 🎯 **快速导航**: 跳转到源代码定义

## 🚀 设置

### 1. 在应用中添加 DevTools 集成

在应用的 `main.dart` 中，初始化调试服务：

```dart
import 'package:flutter/material.dart';
import 'package:void_signals_flutter/void_signals_flutter.dart';

void main() {
  // 初始化 DevTools 集成（仅在调试模式下激活）
  VoidSignalsDebugService.initialize();
  
  runApp(MyApp());
}
```

### 2. 追踪信号用于调试

使用 `.tracked()` 扩展使信号在 DevTools 中可见：

```dart
// 使用可选标签追踪信号
final count = signal(0).tracked(label: 'Counter');
final name = signal('张三').tracked(label: 'User Name');

// 追踪计算值
final doubled = computed((prev) => count() * 2).tracked(label: 'Doubled');

// 追踪副作用
effect(() {
  print('计数变化: ${count()}');
}).tracked(label: 'Log Effect');
```

### 3. 打开 DevTools

1. 以调试模式运行 Flutter 应用: `flutter run`
2. 打开 DevTools (VS Code: `Ctrl+Shift+P` → "Dart: Open DevTools")
3. 在 DevTools 标签栏中查找 **"void_signals"** 标签

## 📖 视图指南

### 🔍 信号列表视图

显示所有追踪的响应式原语的主视图：

| 图标 | 类型 | 描述 |
|------|------|------|
| 🔵 | Signal | 响应式状态值 |
| 🟢 | Computed | 自动更新的派生值 |
| 🟠 | Effect | 变化时运行的副作用 |

**功能:**
- **搜索**: 按名称或值过滤
- **类型过滤**: 只显示信号、计算值或副作用
- **排序选项**: 按名称、类型、更新时间或订阅者数量
- **快速操作**: 查看值、编辑、跳转到源码

### 📊 依赖图视图

响应式依赖树的交互式可视化：

- **节点**: 每个响应式原语作为一个节点
- **边**: 箭头显示依赖方向
- **颜色**: 基于类型的着色便于识别
- **交互**: 
  - 悬停高亮连接
  - 点击选择并查看详情
  - 拖拽重新定位节点
  - 鼠标滚轮缩放
  - 拖拽背景平移

### ⏱️ 时间线视图

追踪值随时间的变化：

- **可视时间线**: 带变化标记的水平时间线
- **变化详情**: 点击标记查看值转换
- **时间过滤**: 聚焦特定时间范围
- **值比较**: 查看前后值

### 📈 统计仪表板

性能洞察和指标：

| 指标 | 描述 |
|------|------|
| 总信号数 | 所有响应式原语的计数 |
| 更新/秒 | 平均更新频率 |
| 平均订阅者 | 每个信号的平均订阅者数 |
| 内存使用 | 估计的内存占用 |
| 最活跃 | 更新率最高的信号 |
| 最大 | 订阅者最多的信号 |

## ⚙️ 配置

### 调试标签

始终使用描述性标签以获得更好的 DevTools 体验：

```dart
// ❌ 无标签 - 难以识别
final count = signal(0);

// ✅ 有标签 - 在 DevTools 中易于找到
final count = signal(0).tracked(label: 'cart_item_count');
```

### 自动追踪（可选）

在开发时，你可以启用所有信号的自动追踪：

```dart
void main() {
  VoidSignalsDebugService.initialize(
    autoTrack: true,  // 自动追踪所有信号
    maxHistorySize: 100,  // 保留最后 100 次值变化
  );
  
  runApp(MyApp());
}
```

## 🔧 API 参考

### VoidSignalsDebugService

```dart
/// 初始化调试服务（在 main() 中调用一次）
VoidSignalsDebugService.initialize({
  bool autoTrack = false,
  int maxHistorySize = 50,
});

/// 访问调试追踪器
final tracker = VoidSignalsDebugService.tracker;

/// 获取所有追踪的信号
final signals = VoidSignalsDebugService.getSignals();

/// 监听信号更新
VoidSignalsDebugService.onSignalUpdate.listen((update) {
  print('信号 ${update.label} 变为 ${update.value}');
});
```

### 信号追踪扩展

```dart
/// 追踪信号以便 DevTools 可见
final count = signal(0).tracked(
  label: 'counter',
  group: 'user_state',  // 可选分组
);

/// 追踪计算值
final fullName = computed((_) => '$first $last').tracked(
  label: 'full_name',
);

/// 追踪副作用
effect(() {
  saveToStorage(count());
}).tracked(label: 'persist_effect');
```

## 💡 最佳实践

### 1. 使用有意义的标签

```dart
// ❌ 不好
final s1 = signal(0).tracked(label: 's1');

// ✅ 好  
final cartItemCount = signal(0).tracked(label: 'cart_item_count');
```

### 2. 分组相关信号

```dart
final firstName = signal('').tracked(label: 'first_name', group: 'user_profile');
final lastName = signal('').tracked(label: 'last_name', group: 'user_profile');
final email = signal('').tracked(label: 'email', group: 'user_profile');
```

### 3. 策略性追踪

不要在生产应用中追踪每个信号。重点关注：
- 难以调试的复杂状态
- 频繁更新的值
- 有多个依赖的状态

### 4. 使用时间线进行调试

调试意外行为时：
1. 打开时间线视图
2. 重现问题
3. 查看值变化序列
4. 识别问题更新

## ⚠️ 性能注意事项

- 调试服务仅在调试模式下激活 (`kDebugMode`)
- 追踪增加最小开销（每次更新约 1ms）
- 所有追踪代码在发布构建中被 tree-shaken
- 大量信号（>1000）可能影响 DevTools 性能
- 历史记录自动限制以防止内存问题

## 🔌 与 void_signals_lint 集成

为获得最佳开发体验，与 [void_signals_lint](https://pub.dev/packages/void_signals_lint) 一起使用：

```yaml
dev_dependencies:
  void_signals_lint: ^1.0.0
  custom_lint: ^0.8.0
```

lint 包会建议为信号添加标签以提高 DevTools 可见性！

## 🐛 故障排除

### 信号未出现在 DevTools 中

1. 确保在 `main()` 中调用了 `VoidSignalsDebugService.initialize()`
2. 检查信号是否使用了 `.tracked()` 扩展
3. 验证应用以调试模式运行
4. 尝试刷新 DevTools 扩展

### 性能问题

1. 减少配置中的 `maxHistorySize`
2. 使用过滤器限制可见信号
3. 不需要时禁用自动刷新
4. 只追踪必要的信号

### 图形视图混乱

1. 使用搜索/过滤聚焦相关信号
2. 拖拽节点组织布局
3. 使用缩放控件调整视图
4. 按信号组过滤

## 🤝 贡献

欢迎贡献！请参阅[贡献指南](https://github.com/void-signals/void_signals/blob/main/CONTRIBUTING.md)。

## 📄 许可证

MIT 许可证 - 详见 [LICENSE](LICENSE)。
