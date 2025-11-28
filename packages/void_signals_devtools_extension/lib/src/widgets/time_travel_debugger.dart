import 'dart:async';

import 'package:flutter/material.dart';

import '../models/signal_info.dart';

/// Time travel debugger for void_signals.
///
/// This widget allows developers to step through signal value changes,
/// providing a powerful debugging experience similar to Redux DevTools.
class TimeTravelDebugger extends StatefulWidget {
  final List<ValueHistoryEntry> history;
  final void Function(int index, Map<String, String> snapshot)? onRestore;
  final void Function()? onClearHistory;

  const TimeTravelDebugger({
    super.key,
    required this.history,
    this.onRestore,
    this.onClearHistory,
  });

  @override
  State<TimeTravelDebugger> createState() => _TimeTravelDebuggerState();
}

class _TimeTravelDebuggerState extends State<TimeTravelDebugger> {
  int _currentIndex = -1;
  bool _isPlaying = false;
  Timer? _playTimer;
  double _playbackSpeed = 1.0;

  @override
  void didUpdateWidget(TimeTravelDebugger oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.history.length != oldWidget.history.length) {
      if (_currentIndex == -1) {
        _currentIndex = widget.history.length - 1;
      }
    }
  }

  @override
  void dispose() {
    _playTimer?.cancel();
    super.dispose();
  }

  void _jumpTo(int index) {
    if (index < 0 || index >= widget.history.length) return;

    setState(() {
      _currentIndex = index;
    });

    // Build snapshot up to this point
    final snapshot = _buildSnapshot(index);
    widget.onRestore?.call(index, snapshot);
  }

  Map<String, String> _buildSnapshot(int upToIndex) {
    final snapshot = <String, String>{};

    // Replay all changes up to the given index
    for (int i = 0; i <= upToIndex; i++) {
      final entry = widget.history[i];
      snapshot[entry.signalId] = entry.newValue;
    }

    return snapshot;
  }

  void _togglePlay() {
    if (_isPlaying) {
      _playTimer?.cancel();
      setState(() => _isPlaying = false);
    } else {
      setState(() => _isPlaying = true);
      _playTimer = Timer.periodic(
        Duration(milliseconds: (1000 / _playbackSpeed).round()),
        (timer) {
          if (_currentIndex < widget.history.length - 1) {
            _jumpTo(_currentIndex + 1);
          } else {
            timer.cancel();
            setState(() => _isPlaying = false);
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.history.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildControls(),
        const Divider(height: 1),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildStateList(),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 3,
                child: _buildDiffView(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No history yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Signal changes will be recorded here for time travel debugging.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Playback controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous),
                tooltip: 'Jump to start',
                onPressed: widget.history.isNotEmpty ? () => _jumpTo(0) : null,
              ),
              IconButton(
                icon: const Icon(Icons.fast_rewind),
                tooltip: 'Previous step',
                onPressed:
                    _currentIndex > 0 ? () => _jumpTo(_currentIndex - 1) : null,
              ),
              IconButton(
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                tooltip: _isPlaying ? 'Pause' : 'Play',
                onPressed: _togglePlay,
              ),
              IconButton(
                icon: const Icon(Icons.fast_forward),
                tooltip: 'Next step',
                onPressed: _currentIndex < widget.history.length - 1
                    ? () => _jumpTo(_currentIndex + 1)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.skip_next),
                tooltip: 'Jump to latest',
                onPressed: widget.history.isNotEmpty
                    ? () => _jumpTo(widget.history.length - 1)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress slider
          Row(
            children: [
              Text(
                '${_currentIndex + 1}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: Slider(
                  value: _currentIndex >= 0 ? _currentIndex.toDouble() : 0,
                  min: 0,
                  max: (widget.history.length - 1)
                      .toDouble()
                      .clamp(0, double.infinity),
                  divisions:
                      widget.history.length > 1 ? widget.history.length - 1 : 1,
                  onChanged: (value) => _jumpTo(value.round()),
                ),
              ),
              Text('${widget.history.length}'),
            ],
          ),
          // Speed control
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Speed:'),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('0.5x'),
                selected: _playbackSpeed == 0.5,
                onSelected: (selected) {
                  if (selected) setState(() => _playbackSpeed = 0.5);
                },
              ),
              const SizedBox(width: 4),
              ChoiceChip(
                label: const Text('1x'),
                selected: _playbackSpeed == 1.0,
                onSelected: (selected) {
                  if (selected) setState(() => _playbackSpeed = 1.0);
                },
              ),
              const SizedBox(width: 4),
              ChoiceChip(
                label: const Text('2x'),
                selected: _playbackSpeed == 2.0,
                onSelected: (selected) {
                  if (selected) setState(() => _playbackSpeed = 2.0);
                },
              ),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.delete_outline),
                label: const Text('Clear'),
                onPressed: widget.onClearHistory,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStateList() {
    return ListView.builder(
      itemCount: widget.history.length,
      itemBuilder: (context, index) {
        final entry = widget.history[index];
        final isSelected = index == _currentIndex;

        return ListTile(
          dense: true,
          selected: isSelected,
          selectedTileColor:
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
          leading: CircleAvatar(
            radius: 14,
            backgroundColor: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ),
          title: Text(
            entry.signalId.split('_').skip(1).join('_'),
            style: const TextStyle(fontSize: 13),
          ),
          subtitle: Text(
            _formatTime(entry.timestamp),
            style: const TextStyle(fontSize: 11),
          ),
          trailing: index <= _currentIndex
              ? const Icon(Icons.check, size: 16, color: Colors.green)
              : null,
          onTap: () => _jumpTo(index),
        );
      },
    );
  }

  Widget _buildDiffView() {
    if (_currentIndex < 0 || _currentIndex >= widget.history.length) {
      return const Center(child: Text('Select a state'));
    }

    final entry = widget.history[_currentIndex];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'State Change #${_currentIndex + 1}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time, size: 14),
              const SizedBox(width: 4),
              Text(_formatFullTime(entry.timestamp)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Signal: ${entry.signalId}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildDiffCard(
            'Before',
            entry.oldValue,
            Colors.red,
            Icons.remove_circle_outline,
          ),
          const SizedBox(height: 8),
          _buildDiffCard(
            'After',
            entry.newValue,
            Colors.green,
            Icons.add_circle_outline,
          ),
          if (entry.triggerSource != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.source, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Triggered by: ${entry.triggerSource}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDiffCard(
      String label, String value, Color color, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            value,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }

  String _formatFullTime(DateTime time) {
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-'
        '${time.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}.'
        '${time.millisecond.toString().padLeft(3, '0')}';
  }
}
