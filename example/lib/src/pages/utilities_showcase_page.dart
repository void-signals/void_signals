import 'dart:async';

import 'package:flutter/material.dart';
import 'package:void_signals_flutter/void_signals_flutter.dart';

/// Utilities Showcase page demonstrating new Flutter utilities
class UtilitiesShowcasePage extends StatefulWidget {
  const UtilitiesShowcasePage({super.key});

  @override
  State<UtilitiesShowcasePage> createState() => _UtilitiesShowcasePageState();
}

class _UtilitiesShowcasePageState extends State<UtilitiesShowcasePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Utilities Showcase')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _SectionTitle('SignalTextController'),
          _TextControllerDemo(),
          SizedBox(height: 24),
          _SectionTitle('SignalScrollController'),
          _ScrollControllerDemo(),
          SizedBox(height: 24),
          _SectionTitle('SignalPageController'),
          _PageControllerDemo(),
          SizedBox(height: 24),
          _SectionTitle('SignalFocusNode'),
          _FocusNodeDemo(),
          SizedBox(height: 24),
          _SectionTitle('PaginatedSignal'),
          _PaginationDemo(),
          SizedBox(height: 24),
          _SectionTitle('CountdownSignal'),
          _CountdownDemo(),
          SizedBox(height: 24),
          _SectionTitle('StopwatchSignal'),
          _StopwatchDemo(),
          SizedBox(height: 24),
          _SectionTitle('IntervalSignal'),
          _IntervalDemo(),
          SizedBox(height: 24),
          _SectionTitle('ClockSignal'),
          _ClockDemo(),
          SizedBox(height: 24),
          _SectionTitle('UndoableSignal'),
          _UndoableDemo(),
          SizedBox(height: 24),
          _SectionTitle('SaveableSignal'),
          _SaveableDemo(),
          SizedBox(height: 24),
          _SectionTitle('SearchSignal'),
          _SearchDemo(),
          SizedBox(height: 24),
          _SectionTitle('FilterSignal'),
          _FilterDemo(),
          SizedBox(height: 24),
          _SectionTitle('SortSignal'),
          _SortDemo(),
          SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _DemoCard extends StatelessWidget {
  final Widget child;

  const _DemoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

// ============================================================
// SignalTextController Demo
// ============================================================
class _TextControllerDemo extends StatefulWidget {
  const _TextControllerDemo();

  @override
  State<_TextControllerDemo> createState() => _TextControllerDemoState();
}

class _TextControllerDemoState extends State<_TextControllerDemo> {
  final nameController = SignalTextController();
  final emailController = SignalTextController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SignalTextController wraps TextEditingController with reactive signals',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nameController.controller,
            decoration: const InputDecoration(
              labelText: 'Name',
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: emailController.controller,
            decoration: const InputDecoration(
              labelText: 'Email',
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          Watch(
            builder: (ctx, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: "${nameController.text.value}"'),
                Text('Name length: ${nameController.length.value}'),
                Text('Name isEmpty: ${nameController.isEmpty.value}'),
                const SizedBox(height: 4),
                Text('Email: "${emailController.text.value}"'),
                Text('Email isNotEmpty: ${emailController.isNotEmpty.value}'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  nameController.text.value = 'John Doe';
                  emailController.text.value = 'john@example.com';
                },
                child: const Text('Set Values'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  nameController.clear();
                  emailController.clear();
                },
                child: const Text('Clear'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SignalScrollController Demo
// ============================================================
class _ScrollControllerDemo extends StatefulWidget {
  const _ScrollControllerDemo();

  @override
  State<_ScrollControllerDemo> createState() => _ScrollControllerDemoState();
}

class _ScrollControllerDemoState extends State<_ScrollControllerDemo> {
  final scrollController = SignalScrollController(showBackToTopThreshold: 100);

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SignalScrollController tracks scroll position and direction',
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                ListView.builder(
                  controller: scrollController.controller,
                  itemCount: 50,
                  itemBuilder: (context, index) => ListTile(
                    title: Text('Item ${index + 1}'),
                    dense: true,
                  ),
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Watch(
                    builder: (ctx, _) {
                      if (scrollController.showBackToTop.value) {
                        return FloatingActionButton.small(
                          heroTag: 'utilities_scroll_demo',
                          onPressed: scrollController.animateToTop,
                          child: const Icon(Icons.arrow_upward),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Watch(
            builder: (ctx, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Offset: ${scrollController.offset.value.toStringAsFixed(1)}'),
                Text('Direction: ${scrollController.direction.value}'),
                Text(
                    'Show back to top: ${scrollController.showBackToTop.value}'),
                Text('Is at top: ${scrollController.isAtTop.value}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SignalPageController Demo
// ============================================================
class _PageControllerDemo extends StatefulWidget {
  const _PageControllerDemo();

  @override
  State<_PageControllerDemo> createState() => _PageControllerDemoState();
}

class _PageControllerDemoState extends State<_PageControllerDemo> {
  final pageController = SignalPageController();
  final colors = [Colors.red, Colors.green, Colors.blue, Colors.orange];

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SignalPageController tracks page position for PageView',
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: PageView.builder(
              controller: pageController.controller,
              itemCount: colors.length,
              itemBuilder: (context, index) => Container(
                color: colors[index].withValues(alpha: 0.3),
                child: Center(
                  child: Text(
                    'Page ${index + 1}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Watch(
            builder: (ctx, _) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                colors.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: pageController.currentPage.value == index
                        ? colors[index]
                        : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Watch(
            builder: (ctx, _) => Text(
              'Page: ${pageController.page.value.toStringAsFixed(2)} (current: ${pageController.currentPage.value})',
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: pageController.previousPage,
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                onPressed: pageController.nextPage,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SignalFocusNode Demo
// ============================================================
class _FocusNodeDemo extends StatefulWidget {
  const _FocusNodeDemo();

  @override
  State<_FocusNodeDemo> createState() => _FocusNodeDemoState();
}

class _FocusNodeDemoState extends State<_FocusNodeDemo> {
  final focusNode1 = SignalFocusNode(debugLabel: 'Field 1');
  final focusNode2 = SignalFocusNode(debugLabel: 'Field 2');

  @override
  void dispose() {
    focusNode1.dispose();
    focusNode2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SignalFocusNode tracks focus state reactively',
          ),
          const SizedBox(height: 12),
          Watch(
            builder: (ctx, _) => Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: focusNode1.hasFocus.value ? Colors.blue : Colors.grey,
                  width: focusNode1.hasFocus.value ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                focusNode: focusNode1.focusNode,
                decoration: const InputDecoration(
                  labelText: 'Field 1',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Watch(
            builder: (ctx, _) => Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: focusNode2.hasFocus.value ? Colors.green : Colors.grey,
                  width: focusNode2.hasFocus.value ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                focusNode: focusNode2.focusNode,
                decoration: const InputDecoration(
                  labelText: 'Field 2',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Watch(
            builder: (ctx, _) => Text(
              'Focus: Field 1 = ${focusNode1.hasFocus.value}, Field 2 = ${focusNode2.hasFocus.value}',
            ),
          ),
          Row(
            children: [
              ElevatedButton(
                onPressed: focusNode1.requestFocus,
                child: const Text('Focus 1'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: focusNode2.requestFocus,
                child: const Text('Focus 2'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  focusNode1.unfocus();
                  focusNode2.unfocus();
                },
                child: const Text('Unfocus All'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PaginatedSignal Demo
// ============================================================
class _PaginationDemo extends StatefulWidget {
  const _PaginationDemo();

  @override
  State<_PaginationDemo> createState() => _PaginationDemoState();
}

class _PaginationDemoState extends State<_PaginationDemo> {
  late final PaginatedSignal<String> items;

  @override
  void initState() {
    super.initState();
    items = PaginatedSignal<String>(
      config: const PaginationConfig(pageSize: 5),
      loader: (page, pageSize) async {
        await Future.delayed(const Duration(milliseconds: 500));
        final startIndex = page * pageSize;
        final hasMore = startIndex + pageSize < 20;
        return PaginationResult(
          items: List.generate(
            pageSize,
            (i) => 'Item ${startIndex + i + 1}',
          ),
          hasMore: hasMore,
          total: 20,
        );
      },
    );
  }

  @override
  void dispose() {
    items.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PaginatedSignal handles paginated data loading with load more',
          ),
          const SizedBox(height: 12),
          Watch(
            builder: (ctx, _) => Row(
              children: [
                Text('State: ${items.state.value}'),
                const Spacer(),
                Text('Items: ${items.itemCount.value}'),
                const SizedBox(width: 8),
                Text('Page: ${items.currentPage.value}'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 150,
            child: Watch(
              builder: (ctx, _) {
                if (items.state.value == PaginationState.initial) {
                  return const Center(
                      child: Text('Press "Load First" to start'));
                }
                if (items.state.value == PaginationState.loadingFirst) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (items.state.value == PaginationState.error) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Error: ${items.error.value}'),
                        ElevatedButton(
                          onPressed: () => items.retry(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final list = items.items.value;
                final isLoadingMore =
                    items.state.value == PaginationState.loadingMore;

                return ListView.builder(
                  itemCount: list.length + (isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= list.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    return ListTile(
                      title: Text(list[index]),
                      dense: true,
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: () => items.loadFirst(),
                child: const Text('Load First'),
              ),
              Watch(
                builder: (ctx, _) => ElevatedButton(
                  onPressed:
                      items.hasMore.value ? () => items.loadMore() : null,
                  child: Text(
                    items.hasMore.value ? 'Load More' : 'No More',
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => items.refresh(),
                child: const Text('Refresh'),
              ),
              ElevatedButton(
                onPressed: () => items.reset(),
                child: const Text('Reset'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CountdownSignal Demo
// ============================================================
class _CountdownDemo extends StatefulWidget {
  const _CountdownDemo();

  @override
  State<_CountdownDemo> createState() => _CountdownDemoState();
}

class _CountdownDemoState extends State<_CountdownDemo> {
  late CountdownSignal countdown;

  @override
  void initState() {
    super.initState();
    countdown = countdownSignal(
      const Duration(seconds: 30),
      interval: const Duration(milliseconds: 100),
      onFinished: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Countdown finished!')),
        );
      },
    );
  }

  @override
  void dispose() {
    countdown.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final centiseconds =
        (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$minutes:$seconds.$centiseconds';
  }

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CountdownSignal provides a reactive countdown timer',
          ),
          const SizedBox(height: 12),
          Watch(
            builder: (ctx, _) => Column(
              children: [
                Text(
                  _formatDuration(countdown.remaining.value),
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontFamily: 'monospace',
                      ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: countdown.progress),
                const SizedBox(height: 4),
                Text(
                  'Progress: ${(countdown.progress * 100).toStringAsFixed(1)}%',
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Watch(
            builder: (ctx, _) => Row(
              children: [
                Text('Running: ${countdown.isRunning.value}'),
                const SizedBox(width: 16),
                Text('Finished: ${countdown.isFinished.value}'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Watch(
                builder: (ctx, _) => ElevatedButton(
                  onPressed: countdown.isRunning.value
                      ? countdown.pause
                      : countdown.start,
                  child: Text(countdown.isRunning.value ? 'Pause' : 'Start'),
                ),
              ),
              ElevatedButton(
                onPressed: countdown.reset,
                child: const Text('Reset'),
              ),
              ElevatedButton(
                onPressed: () => countdown.addTime(const Duration(seconds: 10)),
                child: const Text('+10s'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// StopwatchSignal Demo
// ============================================================
class _StopwatchDemo extends StatefulWidget {
  const _StopwatchDemo();

  @override
  State<_StopwatchDemo> createState() => _StopwatchDemoState();
}

class _StopwatchDemoState extends State<_StopwatchDemo> {
  late StopwatchSignal stopwatch;
  final laps = signal<List<Duration>>([]);

  @override
  void initState() {
    super.initState();
    stopwatch = stopwatchSignal(
      updateInterval: const Duration(milliseconds: 50),
    );
  }

  @override
  void dispose() {
    stopwatch.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final centiseconds =
        (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$minutes:$seconds.$centiseconds';
  }

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'StopwatchSignal provides a reactive stopwatch with lap support',
          ),
          const SizedBox(height: 12),
          Watch(
            builder: (ctx, _) => Text(
              _formatDuration(stopwatch.elapsed.value),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontFamily: 'monospace',
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Watch(
                builder: (ctx, _) => ElevatedButton(
                  onPressed: stopwatch.isRunning.value
                      ? stopwatch.stop
                      : stopwatch.start,
                  child: Text(stopwatch.isRunning.value ? 'Stop' : 'Start'),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final lap = stopwatch.lap();
                  laps.value = [...laps.value, lap];
                },
                child: const Text('Lap'),
              ),
              ElevatedButton(
                onPressed: () {
                  stopwatch.reset();
                  laps.value = [];
                },
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Watch(
            builder: (ctx, _) {
              if (laps.value.isEmpty) {
                return const Text('No laps recorded');
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Laps:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ...laps.value.asMap().entries.map((e) => Text(
                        'Lap ${e.key + 1}: ${_formatDuration(e.value)}',
                        style: const TextStyle(fontFamily: 'monospace'),
                      )),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================
// IntervalSignal Demo
// ============================================================
class _IntervalDemo extends StatefulWidget {
  const _IntervalDemo();

  @override
  State<_IntervalDemo> createState() => _IntervalDemoState();
}

class _IntervalDemoState extends State<_IntervalDemo> {
  late IntervalSignal interval;

  @override
  void initState() {
    super.initState();
    interval = intervalSignal(
      const Duration(seconds: 1),
      startImmediately: false,
    );
  }

  @override
  void dispose() {
    interval.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'IntervalSignal fires at regular intervals',
          ),
          const SizedBox(height: 12),
          Watch(
            builder: (ctx, _) => Text(
              'Ticks: ${interval.value}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: 8),
          Watch(
            builder: (ctx, _) => Row(
              children: [
                Text('Running: ${interval.isRunning}'),
                const SizedBox(width: 16),
                Text('Paused: ${interval.isPaused}'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: interval.start,
                child: const Text('Start'),
              ),
              ElevatedButton(
                onPressed: interval.pause,
                child: const Text('Pause'),
              ),
              ElevatedButton(
                onPressed: interval.resume,
                child: const Text('Resume'),
              ),
              ElevatedButton(
                onPressed: interval.reset,
                child: const Text('Reset'),
              ),
              ElevatedButton(
                onPressed: interval.restart,
                child: const Text('Restart'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ClockSignal Demo
// ============================================================
class _ClockDemo extends StatefulWidget {
  const _ClockDemo();

  @override
  State<_ClockDemo> createState() => _ClockDemoState();
}

class _ClockDemoState extends State<_ClockDemo> {
  late ClockSignal clock;

  @override
  void initState() {
    super.initState();
    clock = clockSignal(updateInterval: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ClockSignal tracks the current time reactively',
          ),
          const SizedBox(height: 12),
          Watch(
            builder: (ctx, _) {
              final now = clock.now.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontFamily: 'monospace',
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
                  ),
                  Text('Weekday: ${_weekday(now.weekday)}'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _weekday(int day) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[day - 1];
  }
}

// ============================================================
// UndoableSignal Demo
// ============================================================
class _UndoableDemo extends StatefulWidget {
  const _UndoableDemo();

  @override
  State<_UndoableDemo> createState() => _UndoableDemoState();
}

class _UndoableDemoState extends State<_UndoableDemo> {
  final text = UndoableSignal<String>('');
  final controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller.addListener(() {
      if (controller.text != text.value) {
        text.value = controller.text;
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'UndoableSignal tracks history for undo/redo support',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Type and use undo/redo',
              isDense: true,
            ),
            onChanged: (value) => text.value = value,
          ),
          const SizedBox(height: 8),
          Watch(
            builder: (ctx, _) => Row(
              children: [
                IconButton(
                  onPressed: text.canUndo.value
                      ? () {
                          text.undo();
                          controller.text = text.value;
                        }
                      : null,
                  icon: const Icon(Icons.undo),
                  tooltip: 'Undo',
                ),
                IconButton(
                  onPressed: text.canRedo.value
                      ? () {
                          text.redo();
                          controller.text = text.value;
                        }
                      : null,
                  icon: const Icon(Icons.redo),
                  tooltip: 'Redo',
                ),
                const Spacer(),
                Text('History: ${text.historyLength}'),
                const SizedBox(width: 8),
                Text('Index: ${text.currentIndex}'),
              ],
            ),
          ),
          Watch(
            builder: (ctx, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Can undo: ${text.canUndo.value} (${text.undoCount.value} steps)'),
                Text(
                    'Can redo: ${text.canRedo.value} (${text.redoCount.value} steps)'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton(
                onPressed: () {
                  text.reset('');
                  controller.text = '';
                },
                child: const Text('Reset'),
              ),
              ElevatedButton(
                onPressed: text.clearHistory,
                child: const Text('Clear History'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SaveableSignal Demo
// ============================================================
class _SaveableDemo extends StatefulWidget {
  const _SaveableDemo();

  @override
  State<_SaveableDemo> createState() => _SaveableDemoState();
}

class _SaveableDemoState extends State<_SaveableDemo> {
  final document = SaveableSignal<String>('Initial content');
  final controller = TextEditingController(text: 'Initial content');

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SaveableSignal tracks unsaved changes with save/revert support',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Document content',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => document.value = value,
          ),
          const SizedBox(height: 8),
          Watch(
            builder: (ctx, _) => Row(
              children: [
                Icon(
                  document.hasUnsavedChanges.value
                      ? Icons.edit
                      : Icons.check_circle,
                  color: document.hasUnsavedChanges.value
                      ? Colors.orange
                      : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  document.hasUnsavedChanges.value
                      ? 'Unsaved changes'
                      : 'All changes saved',
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  document.markSaved();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Document saved!')),
                  );
                },
                icon: const Icon(Icons.save),
                label: const Text('Save'),
              ),
              Watch(
                builder: (ctx, _) => ElevatedButton.icon(
                  onPressed: document.hasUnsavedChanges.value
                      ? () {
                          document.revertToSaved();
                          controller.text = document.value;
                        }
                      : null,
                  icon: const Icon(Icons.restore),
                  label: const Text('Revert'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Watch(
            builder: (ctx, _) => Text(
              'Saved value: "${document.savedValue}"',
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SearchSignal Demo
// ============================================================
class _SearchDemo extends StatefulWidget {
  const _SearchDemo();

  @override
  State<_SearchDemo> createState() => _SearchDemoState();
}

class _SearchDemoState extends State<_SearchDemo> {
  late SearchSignal<String> search;
  final items = List.generate(100, (i) => 'Item ${i + 1}');

  @override
  void initState() {
    super.initState();
    search = SearchSignal<String>(
      searcher: (query) async {
        await Future.delayed(const Duration(milliseconds: 300));
        return items
            .where((item) => item.toLowerCase().contains(query.toLowerCase()))
            .take(10)
            .toList();
      },
      config: const SearchConfig(
        debounceDuration: Duration(milliseconds: 300),
        minQueryLength: 1,
        enableCache: true,
      ),
    );
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SearchSignal provides debounced search with caching',
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              labelText: 'Search items...',
              isDense: true,
              suffixIcon: Watch(
                builder: (ctx, _) {
                  if (search.isSearching.value) {
                    return const SizedBox(
                      width: 20,
                      height: 20,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  return const Icon(Icons.search);
                },
              ),
            ),
            onChanged: (value) => search.query.value = value,
          ),
          const SizedBox(height: 8),
          Watch(
            builder: (ctx, _) => Row(
              children: [
                _StateChip('State', search.state.value.name),
                const SizedBox(width: 8),
                _StateChip('Results', '${search.resultCount.value}'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 150,
            child: Watch(
              builder: (ctx, _) {
                switch (search.state.value) {
                  case SearchState.idle:
                    return const Center(child: Text('Enter a search query'));
                  case SearchState.debouncing:
                    return const Center(child: Text('Typing...'));
                  case SearchState.searching:
                    return const Center(child: CircularProgressIndicator());
                  case SearchState.empty:
                    return const Center(child: Text('No results found'));
                  case SearchState.error:
                    return Center(child: Text('Error: ${search.error.value}'));
                  case SearchState.results:
                    return ListView.builder(
                      itemCount: search.results.value.length,
                      itemBuilder: (context, index) => ListTile(
                        title: Text(search.results.value[index]),
                        dense: true,
                      ),
                    );
                }
              },
            ),
          ),
          Row(
            children: [
              ElevatedButton(
                onPressed: search.clear,
                child: const Text('Clear'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: search.clearCache,
                child: const Text('Clear Cache'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  final String label;
  final String value;

  const _StateChip(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('$label: $value', style: const TextStyle(fontSize: 12)),
    );
  }
}

// ============================================================
// FilterSignal Demo
// ============================================================
class _FilterDemo extends StatefulWidget {
  const _FilterDemo();

  @override
  State<_FilterDemo> createState() => _FilterDemoState();
}

class _FilterDemoState extends State<_FilterDemo> {
  final products = signal<List<Map<String, dynamic>>>([
    {'name': 'Apple', 'price': 1.5, 'inStock': true, 'category': 'fruit'},
    {'name': 'Banana', 'price': 0.5, 'inStock': true, 'category': 'fruit'},
    {'name': 'Carrot', 'price': 0.8, 'inStock': false, 'category': 'vegetable'},
    {'name': 'Milk', 'price': 2.0, 'inStock': true, 'category': 'dairy'},
    {'name': 'Cheese', 'price': 3.5, 'inStock': true, 'category': 'dairy'},
    {'name': 'Bread', 'price': 1.2, 'inStock': false, 'category': 'bakery'},
    {'name': 'Orange', 'price': 1.0, 'inStock': true, 'category': 'fruit'},
    {'name': 'Lettuce', 'price': 1.5, 'inStock': true, 'category': 'vegetable'},
  ]);

  late FilterSignal<Map<String, dynamic>> filter;

  @override
  void initState() {
    super.initState();
    filter = FilterSignal<Map<String, dynamic>>(
      source: products,
      filters: {
        'inStock': (p) => p['inStock'] as bool,
        'cheap': (p) => (p['price'] as double) < 1.5,
        'fruit': (p) => p['category'] == 'fruit',
        'dairy': (p) => p['category'] == 'dairy',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FilterSignal provides reactive filtering for lists',
          ),
          const SizedBox(height: 12),
          Watch(
            builder: (ctx, _) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: filter.availableFilters.map((name) {
                final isActive = filter.isActive(name);
                return FilterChip(
                  label: Text(name),
                  selected: isActive,
                  onSelected: (_) => filter.toggle(name),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Watch(
            builder: (ctx, _) => Text(
              'Active filters: ${filter.activeCount} | Showing ${filter.filtered.value.length} of ${products.value.length}',
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 150,
            child: Watch(
              builder: (ctx, _) => ListView.builder(
                itemCount: filter.filtered.value.length,
                itemBuilder: (context, index) {
                  final product = filter.filtered.value[index];
                  return ListTile(
                    title: Text(product['name'] as String),
                    subtitle: Text(
                      '\$${product['price']} | ${product['category']}',
                    ),
                    trailing: Icon(
                      product['inStock'] as bool
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: product['inStock'] as bool
                          ? Colors.green
                          : Colors.red,
                    ),
                    dense: true,
                  );
                },
              ),
            ),
          ),
          ElevatedButton(
            onPressed: filter.clearAll,
            child: const Text('Clear All Filters'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SortSignal Demo
// ============================================================
class _SortDemo extends StatefulWidget {
  const _SortDemo();

  @override
  State<_SortDemo> createState() => _SortDemoState();
}

class _SortDemoState extends State<_SortDemo> {
  final items = signal<List<Map<String, dynamic>>>([
    {'name': 'Charlie', 'age': 30, 'score': 85},
    {'name': 'Alice', 'age': 25, 'score': 92},
    {'name': 'Bob', 'age': 35, 'score': 78},
    {'name': 'Diana', 'age': 28, 'score': 95},
    {'name': 'Eve', 'age': 22, 'score': 88},
  ]);

  late SortSignal<Map<String, dynamic>> sort;

  @override
  void initState() {
    super.initState();
    sort = SortSignal<Map<String, dynamic>>(
      source: items,
      comparators: {
        'name': (a, b) => (a['name'] as String).compareTo(b['name'] as String),
        'age': (a, b) => (a['age'] as int).compareTo(b['age'] as int),
        'score': (a, b) => (a['score'] as int).compareTo(b['score'] as int),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SortSignal provides reactive sorting with direction toggle',
          ),
          const SizedBox(height: 12),
          Watch(
            builder: (ctx, _) => Row(
              children: [
                const Text('Sort by: '),
                ...sort.availableSorts.map((key) {
                  final isActive = sort.currentSort.value == key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(key),
                          if (isActive) ...[
                            const SizedBox(width: 4),
                            Icon(
                              sort.direction.value == SortDirection.ascending
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                      selected: isActive,
                      onSelected: (_) {
                        if (isActive) {
                          sort.toggleDirection();
                        } else {
                          sort.sortBy(key);
                        }
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 180,
            child: Watch(
              builder: (ctx, _) => ListView.builder(
                itemCount: sort.sorted.value.length,
                itemBuilder: (context, index) {
                  final item = sort.sorted.value[index];
                  return ListTile(
                    title: Text(item['name'] as String),
                    subtitle:
                        Text('Age: ${item['age']} | Score: ${item['score']}'),
                    dense: true,
                  );
                },
              ),
            ),
          ),
          ElevatedButton(
            onPressed: sort.clearSort,
            child: const Text('Clear Sort'),
          ),
        ],
      ),
    );
  }
}
