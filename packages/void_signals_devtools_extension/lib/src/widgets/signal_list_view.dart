import 'package:flutter/material.dart';

import '../models/signal_info.dart';

/// A list view showing all signals, computeds, and effects.
class SignalListView extends StatefulWidget {
  final List<SignalInfo> signals;
  final List<ComputedInfo> computeds;
  final List<EffectInfo> effects;
  final SignalInfo? selectedSignal;
  final ValueChanged<SignalInfo?>? onSignalSelected;

  const SignalListView({
    super.key,
    required this.signals,
    required this.computeds,
    required this.effects,
    this.selectedSignal,
    this.onSignalSelected,
  });

  @override
  State<SignalListView> createState() => _SignalListViewState();
}

class _SignalListViewState extends State<SignalListView> {
  String _searchQuery = '';
  String _filterType = 'all';
  String _filterSource = 'all'; // 'all', 'direct', 'hooks'
  bool _groupByWidget = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        const Divider(height: 1),
        Expanded(
          child: _buildList(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search signals...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _filterType,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'signal', child: Text('Signals')),
                  DropdownMenuItem(value: 'computed', child: Text('Computed')),
                  DropdownMenuItem(value: 'effect', child: Text('Effects')),
                ],
                onChanged: (value) {
                  setState(() {
                    _filterType = value ?? 'all';
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Source filter
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'all', label: Text('All')),
                  ButtonSegment(
                    value: 'direct',
                    icon: Icon(Icons.radio_button_checked, size: 16),
                    label: Text('Direct'),
                  ),
                  ButtonSegment(
                    value: 'hooks',
                    icon: Icon(Icons.anchor, size: 16),
                    label: Text('Hooks'),
                  ),
                ],
                selected: {_filterSource},
                onSelectionChanged: (selection) {
                  setState(() {
                    _filterSource = selection.first;
                  });
                },
              ),
              const Spacer(),
              // Group by widget toggle
              FilterChip(
                label: const Text('Group by Widget'),
                selected: _groupByWidget,
                onSelected: (value) {
                  setState(() {
                    _groupByWidget = value;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final items = <_ListItem>[];

    // Add signals
    if (_filterType == 'all' || _filterType == 'signal') {
      for (final signal in widget.signals) {
        if (!_matchesSearch(signal.name, signal.label, signal.widgetName)) {
          continue;
        }
        if (!_matchesSourceFilter(signal)) continue;

        items.add(_ListItem(
          type: 'signal',
          signal: signal,
        ));
      }
    }

    // Add computeds
    if (_filterType == 'all' || _filterType == 'computed') {
      for (final computed in widget.computeds) {
        if (_matchesSearch(computed.name, computed.label, null)) {
          items.add(_ListItem(
            type: 'computed',
            computed: computed,
          ));
        }
      }
    }

    // Add effects
    if (_filterType == 'all' || _filterType == 'effect') {
      for (final effect in widget.effects) {
        if (_matchesSearch(effect.name, effect.label, null)) {
          items.add(_ListItem(
            type: 'effect',
            effect: effect,
          ));
        }
      }
    }

    if (items.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty ? 'No items' : 'No matching items',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
        ),
      );
    }

    // Group by widget if enabled
    if (_groupByWidget) {
      return _buildGroupedList(items);
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildListTile(item);
      },
    );
  }

  Widget _buildGroupedList(List<_ListItem> items) {
    // Group items by widget
    final groups = <String?, List<_ListItem>>{};
    for (final item in items) {
      String? groupKey;
      if (item.signal != null && item.signal!.isFromHook) {
        groupKey = item.signal!.widgetName ?? 'Unknown Widget';
      }
      groups.putIfAbsent(groupKey, () => []).add(item);
    }

    // Sort groups: non-hook signals first, then by widget name
    final sortedKeys = groups.keys.toList()
      ..sort((a, b) {
        if (a == null) return -1;
        if (b == null) return 1;
        return a.compareTo(b);
      });

    return ListView.builder(
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final key = sortedKeys[index];
        final groupItems = groups[key]!;

        if (key == null) {
          // Direct signals (not from hooks)
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGroupHeader('Direct Signals', Icons.radio_button_checked,
                  Colors.blue, groupItems.length),
              ...groupItems.map(_buildListTile),
            ],
          );
        } else {
          // Hook signals grouped by widget
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGroupHeader(
                  key, Icons.widgets, Colors.purple, groupItems.length),
              ...groupItems.map(_buildListTile),
            ],
          );
        }
      },
    );
  }

  Widget _buildGroupHeader(
      String title, IconData icon, Color color, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color.withOpacity(0.05),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _matchesSourceFilter(SignalInfo signal) {
    if (_filterSource == 'all') return true;
    if (_filterSource == 'direct') return !signal.isFromHook;
    if (_filterSource == 'hooks') return signal.isFromHook;
    return true;
  }

  bool _matchesSearch(String name, String? label, String? widgetName) {
    if (_searchQuery.isEmpty) return true;
    if (name.toLowerCase().contains(_searchQuery)) return true;
    if (label?.toLowerCase().contains(_searchQuery) ?? false) return true;
    if (widgetName?.toLowerCase().contains(_searchQuery) ?? false) return true;
    return false;
  }

  Widget _buildListTile(_ListItem item) {
    final isSelected =
        item.signal != null && widget.selectedSignal?.id == item.signal!.id;

    return ListTile(
      leading: _buildTypeIcon(item),
      title: Text(
        item.displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: _buildSubtitle(item),
      trailing: _buildTrailing(item),
      selected: isSelected,
      onTap: () {
        if (item.signal != null) {
          widget.onSignalSelected?.call(item.signal);
        }
      },
    );
  }

  Widget _buildTypeIcon(_ListItem item) {
    IconData icon;
    Color color;

    if (item.signal != null) {
      icon = item.signal!.icon;
      color = item.signal!.color;
    } else if (item.computed != null) {
      icon = item.computed!.icon;
      color = item.computed!.color;
    } else {
      (icon, color) = switch (item.type) {
        'effect' => (Icons.bolt, Colors.orange),
        _ => (Icons.help_outline, Colors.grey),
      };
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildSubtitle(_ListItem item) {
    if (item.signal != null) {
      final signal = item.signal!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            signal.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
          if (signal.isFromHook) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.anchor, size: 10, color: Colors.purple.shade300),
                const SizedBox(width: 4),
                Text(
                  signal.source.displayName,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.purple.shade300,
                  ),
                ),
                if (signal.widgetName != null) ...[
                  Text(
                    ' • ',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  Text(
                    signal.widgetName!,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      );
    }

    if (item.computed != null) {
      final computed = item.computed!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            computed.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
          if (computed.isAsync) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  computed.isStream ? Icons.stream : Icons.cloud_sync,
                  size: 10,
                  color: computed.isStream ? Colors.cyan : Colors.teal,
                ),
                const SizedBox(width: 4),
                Text(
                  computed.isStream ? 'Stream' : 'Async',
                  style: TextStyle(
                    fontSize: 10,
                    color: computed.isStream ? Colors.cyan : Colors.teal,
                  ),
                ),
                if (computed.asyncState != null) ...[
                  Text(
                    ' • ',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  _buildAsyncStateChip(computed.asyncState!),
                ],
              ],
            ),
          ],
        ],
      );
    }

    if (item.effect != null) {
      return Text(
        'runs: ${item.effect!.runCount}',
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildTrailing(_ListItem item) {
    if (item.signal != null) {
      return _buildBadge('${item.signal!.subscriberCount}', item.signal!.color);
    }
    if (item.computed != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.computed!.isDirty)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'dirty',
                style: TextStyle(fontSize: 10, color: Colors.orange),
              ),
            ),
          _buildBadge('${item.computed!.subscriberCount}', Colors.green),
        ],
      );
    }
    if (item.effect != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!item.effect!.isActive)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'stopped',
                style: TextStyle(fontSize: 10, color: Colors.red),
              ),
            ),
          _buildBadge('${item.effect!.runCount}', Colors.orange),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildAsyncStateChip(String state) {
    final (color, icon) = switch (state) {
      'loading' => (Colors.amber, Icons.hourglass_empty),
      'data' => (Colors.green, Icons.check_circle_outline),
      'error' => (Colors.red, Icons.error_outline),
      _ => (Colors.grey, Icons.help_outline),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 2),
        Text(
          state,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ListItem {
  final String type;
  final SignalInfo? signal;
  final ComputedInfo? computed;
  final EffectInfo? effect;

  _ListItem({
    required this.type,
    this.signal,
    this.computed,
    this.effect,
  });

  String get displayName {
    if (signal != null) return signal!.label ?? signal!.name;
    if (computed != null) return computed!.label ?? computed!.name;
    if (effect != null) return effect!.label ?? effect!.name;
    return 'Unknown';
  }

  String get subtitle {
    if (signal != null) return signal!.value;
    if (computed != null) return computed!.value;
    if (effect != null) return 'runs: ${effect!.runCount}';
    return '';
  }
}
