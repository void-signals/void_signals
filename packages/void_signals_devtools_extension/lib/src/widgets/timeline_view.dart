import 'package:flutter/material.dart';

import '../models/signal_info.dart';

/// A timeline view showing signal value changes over time.
class TimelineView extends StatefulWidget {
  final List<ValueHistoryEntry> history;
  final List<SignalInfo> signals;
  final List<ComputedInfo> computeds;
  final ValueChanged<String>? onSignalTap;

  const TimelineView({
    super.key,
    required this.history,
    required this.signals,
    required this.computeds,
    this.onSignalTap,
  });

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;
  String? _selectedSignalId;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TimelineView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_autoScroll && widget.history.length > oldWidget.history.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(),
        const Divider(height: 1),
        Expanded(
          child: widget.history.isEmpty ? _buildEmptyState() : _buildTimeline(),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Text(
            'Timeline (${widget.history.length} events)',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const Spacer(),
          // Filter by signal
          if (widget.signals.isNotEmpty || widget.computeds.isNotEmpty)
            DropdownButton<String?>(
              value: _selectedSignalId,
              hint: const Text('Filter by signal'),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All signals'),
                ),
                ...widget.signals.map((s) => DropdownMenuItem(
                      value: s.id,
                      child: Text(s.displayName),
                    )),
              ],
              onChanged: (value) {
                setState(() => _selectedSignalId = value);
              },
            ),
          const SizedBox(width: 8),
          // Auto-scroll toggle
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Auto-scroll'),
              Switch(
                value: _autoScroll,
                onChanged: (value) => setState(() => _autoScroll = value),
              ),
            ],
          ),
          // Clear button
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear history',
            onPressed: () {
              // Would need a callback to clear history
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline,
            size: 64,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No value changes yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Signal value changes will appear here as they happen.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final filteredHistory = _selectedSignalId == null
        ? widget.history
        : widget.history.where((e) => e.signalId == _selectedSignalId).toList();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: filteredHistory.length,
      itemBuilder: (context, index) {
        final entry = filteredHistory[index];
        final isLast = index == filteredHistory.length - 1;

        return _buildTimelineEntry(entry, isLast);
      },
    );
  }

  Widget _buildTimelineEntry(ValueHistoryEntry entry, bool isLast) {
    final signalName = _getSignalName(entry.signalId);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Colors.grey.withOpacity(0.3),
                    ),
                  ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: () => widget.onSignalTap?.call(entry.signalId),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              signalName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatTime(entry.timestamp),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildValueBox(
                              'Before',
                              entry.oldValue,
                              Colors.red,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.arrow_forward, size: 16),
                          ),
                          Expanded(
                            child: _buildValueBox(
                              'After',
                              entry.newValue,
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                      if (entry.triggerSource != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Triggered by: ${entry.triggerSource}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getSignalName(String id) {
    final signal = widget.signals.cast<SignalInfo?>().firstWhere(
          (s) => s?.id == id,
          orElse: () => null,
        );
    if (signal != null) return signal.displayName;

    final computed = widget.computeds.cast<ComputedInfo?>().firstWhere(
          (c) => c?.id == id,
          orElse: () => null,
        );
    if (computed != null) return computed.displayName;

    return id;
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
    }
  }
}
