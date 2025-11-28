import 'package:flutter/material.dart';

import '../models/signal_info.dart';

/// A search and filter panel for signals.
class SignalSearchFilter extends StatefulWidget {
  final SignalFilter filter;
  final ValueChanged<SignalFilter> onFilterChanged;

  const SignalSearchFilter({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  State<SignalSearchFilter> createState() => _SignalSearchFilterState();
}

class _SignalSearchFilterState extends State<SignalSearchFilter> {
  late TextEditingController _searchController;
  bool _showAdvanced = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.filter.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchRow(),
        if (_showAdvanced) ...[
          const SizedBox(height: 8),
          _buildAdvancedFilters(),
        ],
      ],
    );
  }

  Widget _buildSearchRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name, label, or value...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        widget.onFilterChanged(
                          widget.filter.copyWith(searchQuery: ''),
                        );
                      },
                    )
                  : null,
              isDense: true,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              widget.onFilterChanged(
                widget.filter.copyWith(searchQuery: value),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        // Type filter chips
        ..._buildTypeChips(),
        const SizedBox(width: 8),
        // Advanced filters toggle
        IconButton(
          icon: Icon(
            _showAdvanced ? Icons.filter_list_off : Icons.filter_list,
          ),
          tooltip: _showAdvanced ? 'Hide filters' : 'Show more filters',
          onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
        ),
      ],
    );
  }

  List<Widget> _buildTypeChips() {
    final types = ['signal', 'computed', 'effect'];

    return types.map((type) {
      final isSelected = widget.filter.types.contains(type);
      final color = switch (type) {
        'signal' => Colors.blue,
        'computed' => Colors.green,
        'effect' => Colors.orange,
        _ => Colors.grey,
      };
      final icon = switch (type) {
        'signal' => Icons.radio_button_checked,
        'computed' => Icons.functions,
        'effect' => Icons.bolt,
        _ => Icons.help,
      };

      return Padding(
        padding: const EdgeInsets.only(right: 4),
        child: FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: isSelected ? Colors.white : color),
              const SizedBox(width: 4),
              Text(
                type[0].toUpperCase() + type.substring(1),
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : null,
                ),
              ),
            ],
          ),
          selected: isSelected,
          selectedColor: color,
          checkmarkColor: Colors.white,
          showCheckmark: false,
          onSelected: (selected) {
            final newTypes = Set<String>.from(widget.filter.types);
            if (selected) {
              newTypes.add(type);
            } else {
              newTypes.remove(type);
            }
            widget.onFilterChanged(widget.filter.copyWith(types: newTypes));
          },
        ),
      );
    }).toList();
  }

  Widget _buildAdvancedFilters() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildCheckboxFilter(
                  'Show only dirty computeds',
                  widget.filter.showOnlyDirty,
                  (value) => widget.onFilterChanged(
                    widget.filter.copyWith(showOnlyDirty: value),
                  ),
                ),
              ),
              Expanded(
                child: _buildCheckboxFilter(
                  'Show only active effects',
                  widget.filter.showOnlyActive,
                  (value) => widget.onFilterChanged(
                    widget.filter.copyWith(showOnlyActive: value),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Sort by:'),
              const SizedBox(width: 12),
              DropdownButton<SortOption>(
                value: widget.filter.sortBy,
                isDense: true,
                items: SortOption.values.map((option) {
                  return DropdownMenuItem(
                    value: option,
                    child: Text(_sortOptionLabel(option)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    widget.onFilterChanged(
                      widget.filter.copyWith(sortBy: value),
                    );
                  }
                },
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: Icon(
                  widget.filter.sortDescending
                      ? Icons.arrow_downward
                      : Icons.arrow_upward,
                ),
                tooltip: widget.filter.sortDescending
                    ? 'Sort ascending'
                    : 'Sort descending',
                onPressed: () {
                  widget.onFilterChanged(
                    widget.filter.copyWith(
                      sortDescending: !widget.filter.sortDescending,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxFilter(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: (v) => onChanged(v ?? false),
        ),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  String _sortOptionLabel(SortOption option) {
    return switch (option) {
      SortOption.name => 'Name',
      SortOption.type => 'Type',
      SortOption.lastUpdated => 'Last Updated',
      SortOption.subscriberCount => 'Subscribers',
      SortOption.updateCount => 'Update Count',
    };
  }
}

/// Extension to apply filters to signal lists.
extension SignalFilterExtension on SignalFilter {
  List<SignalInfo> filterSignals(List<SignalInfo> signals) {
    var result = signals.where((s) {
      if (!types.contains('signal')) return false;
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        if (!s.name.toLowerCase().contains(query) &&
            !(s.label?.toLowerCase().contains(query) ?? false) &&
            !s.value.toLowerCase().contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();

    result = _sortSignals(result);
    return result;
  }

  List<ComputedInfo> filterComputeds(List<ComputedInfo> computeds) {
    var result = computeds.where((c) {
      if (!types.contains('computed')) return false;
      if (showOnlyDirty && !c.isDirty) return false;
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        if (!c.name.toLowerCase().contains(query) &&
            !(c.label?.toLowerCase().contains(query) ?? false) &&
            !c.value.toLowerCase().contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();

    return result;
  }

  List<EffectInfo> filterEffects(List<EffectInfo> effects) {
    var result = effects.where((e) {
      if (!types.contains('effect')) return false;
      if (showOnlyActive && !e.isActive) return false;
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        if (!e.name.toLowerCase().contains(query) &&
            !(e.label?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
      }
      return true;
    }).toList();

    return result;
  }

  List<SignalInfo> _sortSignals(List<SignalInfo> signals) {
    signals.sort((a, b) {
      final comparison = switch (sortBy) {
        SortOption.name => a.displayName.compareTo(b.displayName),
        SortOption.type => a.type.compareTo(b.type),
        SortOption.lastUpdated => (a.lastUpdated ?? DateTime(0))
            .compareTo(b.lastUpdated ?? DateTime(0)),
        SortOption.subscriberCount =>
          a.subscriberCount.compareTo(b.subscriberCount),
        SortOption.updateCount => a.updateCount.compareTo(b.updateCount),
      };
      return sortDescending ? -comparison : comparison;
    });
    return signals;
  }
}
