import 'dart:async';

import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';
import 'package:vm_service/vm_service.dart';

import 'models/signal_info.dart';
import 'widgets/signal_list_view.dart';
import 'widgets/signal_detail_view.dart';
import 'widgets/dependency_graph_view.dart';
import 'widgets/timeline_view.dart';
import 'widgets/stats_view.dart';
import 'widgets/signal_search_filter.dart';

/// The main panel for the void_signals DevTools extension.
///
/// This extension provides comprehensive debugging tools for void_signals:
/// - Signal/Computed/Effect listing with filtering
/// - Value editing for signals
/// - Dependency graph visualization
/// - Timeline of value changes
/// - Statistics dashboard
class VoidSignalsExtensionPanel extends StatefulWidget {
  const VoidSignalsExtensionPanel({super.key});

  @override
  State<VoidSignalsExtensionPanel> createState() =>
      _VoidSignalsExtensionPanelState();
}

class _VoidSignalsExtensionPanelState extends State<VoidSignalsExtensionPanel>
    with SingleTickerProviderStateMixin {
  // Data
  List<SignalInfo> _signals = [];
  List<ComputedInfo> _computeds = [];
  List<EffectInfo> _effects = [];
  List<ScopeInfo> _scopes = [];
  List<ValueHistoryEntry> _history = [];
  ReactiveStats _stats = ReactiveStats.empty();

  // UI State
  SignalInfo? _selectedSignal;
  bool _isLoading = false;
  String? _error;
  Timer? _refreshTimer;
  int _refreshInterval = 2; // seconds
  bool _isPaused = false;
  SignalFilter _filter = const SignalFilter();

  // Tab controller
  late TabController _tabController;

  // View indices
  static const int _listViewIndex = 0;
  static const int _graphViewIndex = 1;
  static const int _timelineViewIndex = 2;
  static const int _statsViewIndex = 3;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _refreshData();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      Duration(seconds: _refreshInterval),
      (_) {
        if (!_isPaused) {
          _refreshData();
        }
      },
    );
  }

  Future<void> _refreshData() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _fetchSignalsData();
      if (mounted) {
        setState(() {
          _signals = result.signals;
          _computeds = result.computeds;
          _effects = result.effects;
          _scopes = result.scopes;
          _history = [..._history, ...result.newHistory];
          _stats = result.stats;
          _isLoading = false;

          // Keep history limited
          if (_history.length > 1000) {
            _history = _history.sublist(_history.length - 500);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<SignalsData> _fetchSignalsData() async {
    final vmService = serviceManager.service;
    if (vmService == null) {
      throw Exception('VM Service not available');
    }

    try {
      final isolateId = serviceManager.isolateManager.mainIsolate.value?.id;
      if (isolateId == null) {
        throw Exception('No isolate available');
      }

      final response = await vmService.callServiceExtension(
        'ext.void_signals.getSignalsInfo',
        isolateId: isolateId,
      );

      final json = response.json;
      if (json == null) {
        return SignalsData.empty();
      }

      return SignalsData.fromJson(json);
    } on RPCError catch (e) {
      if (e.code == -32601) {
        // Extension not registered
        return SignalsData.empty();
      }
      rethrow;
    }
  }

  Future<bool> _setSignalValue(String id, String value) async {
    final vmService = serviceManager.service;
    if (vmService == null) return false;

    try {
      final isolateId = serviceManager.isolateManager.mainIsolate.value?.id;
      if (isolateId == null) return false;

      final response = await vmService.callServiceExtension(
        'ext.void_signals.setSignalValue',
        isolateId: isolateId,
        args: {'id': id, 'value': value},
      );

      final json = response.json;
      return json?['success'] == true;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(),
        const Divider(height: 1),
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            children: [
              // Tab bar
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.list),
                    text: 'Signals',
                  ),
                  Tab(
                    icon: Icon(Icons.account_tree),
                    text: 'Graph',
                  ),
                  Tab(
                    icon: Icon(Icons.timeline),
                    text: 'Timeline',
                  ),
                  Tab(
                    icon: Icon(Icons.analytics),
                    text: 'Stats',
                  ),
                ],
                tabAlignment: TabAlignment.start,
              ),
              const Spacer(),
              // Stats chips
              _buildStatChip('Signals', _signals.length, Colors.blue),
              const SizedBox(width: 8),
              _buildStatChip('Computed',
                  _computeds.where((c) => !c.isAsync).length, Colors.green),
              const SizedBox(width: 8),
              _buildStatChip(
                  'Async',
                  _computeds.where((c) => c.isAsync && !c.isStream).length,
                  Colors.teal),
              const SizedBox(width: 8),
              _buildStatChip('Stream',
                  _computeds.where((c) => c.isStream).length, Colors.cyan),
              const SizedBox(width: 8),
              _buildStatChip('Effects', _effects.length, Colors.orange),
              const SizedBox(width: 16),
              // Pause/Resume button
              IconButton(
                icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                tooltip:
                    _isPaused ? 'Resume auto-refresh' : 'Pause auto-refresh',
                onPressed: () => setState(() => _isPaused = !_isPaused),
              ),
              // Refresh interval
              PopupMenuButton<int>(
                icon: const Icon(Icons.timer),
                tooltip: 'Refresh interval',
                initialValue: _refreshInterval,
                onSelected: (value) {
                  setState(() => _refreshInterval = value);
                  _startAutoRefresh();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 1, child: Text('1 second')),
                  const PopupMenuItem(value: 2, child: Text('2 seconds')),
                  const PopupMenuItem(value: 5, child: Text('5 seconds')),
                  const PopupMenuItem(value: 10, child: Text('10 seconds')),
                ],
              ),
              // Refresh button
              IconButton(
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                onPressed: _isLoading ? null : _refreshData,
                tooltip: 'Refresh now',
              ),
              // Settings
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Settings',
                onPressed: _showSettings,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_error != null) {
      return _buildErrorView();
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildListView(),
        _buildGraphView(),
        _buildTimelineView(),
        _buildStatsView(),
      ],
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading signals',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _showTroubleshooting,
            child: const Text('Troubleshooting'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.signal_cellular_alt,
            size: 64,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No signals detected',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Text(
              'Make sure your app:\n'
              '1. Uses void_signals for state management\n'
              '2. Calls VoidSignalsDebugService.initialize() in main()\n'
              '3. Uses .tracked() on signals you want to debug',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    if (_signals.isEmpty && _computeds.isEmpty && _effects.isEmpty) {
      return _buildEmptyView();
    }

    // Apply filters
    final filteredSignals = _filter.filterSignals(_signals);
    final filteredComputeds = _filter.filterComputeds(_computeds);
    final filteredEffects = _filter.filterEffects(_effects);

    return Column(
      children: [
        // Search and filter bar
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SignalSearchFilter(
            filter: _filter,
            onFilterChanged: (filter) => setState(() => _filter = filter),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: SignalListView(
                  signals: filteredSignals,
                  computeds: filteredComputeds,
                  effects: filteredEffects,
                  selectedSignal: _selectedSignal,
                  onSignalSelected: (signal) {
                    setState(() => _selectedSignal = signal);
                  },
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 3,
                child: _selectedSignal != null
                    ? SignalDetailView(
                        signal: _selectedSignal!,
                        computeds: _computeds,
                        effects: _effects,
                        onValueChanged: (value) =>
                            _setSignalValue(_selectedSignal!.id, value),
                      )
                    : const Center(
                        child: Text('Select a signal to view details'),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGraphView() {
    if (_signals.isEmpty && _computeds.isEmpty && _effects.isEmpty) {
      return _buildEmptyView();
    }

    return DependencyGraphView(
      signals: _signals,
      computeds: _computeds,
      effects: _effects,
    );
  }

  Widget _buildTimelineView() {
    return TimelineView(
      history: _history,
      signals: _signals,
      computeds: _computeds,
      onSignalTap: (id) {
        final signal = _signals.cast<SignalInfo?>().firstWhere(
              (s) => s?.id == id,
              orElse: () => null,
            );
        if (signal != null) {
          setState(() {
            _selectedSignal = signal;
            _tabController.animateTo(_listViewIndex);
          });
        }
      },
    );
  }

  Widget _buildStatsView() {
    return StatsView(
      stats: _stats,
      signals: _signals,
      computeds: _computeds,
      effects: _effects,
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('Auto-refresh'),
              subtitle: Text('Currently: ${_isPaused ? "Paused" : "Active"}'),
              value: !_isPaused,
              onChanged: (value) {
                setState(() => _isPaused = !value);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Refresh interval'),
              subtitle: Text('$_refreshInterval seconds'),
              trailing: DropdownButton<int>(
                value: _refreshInterval,
                items: [1, 2, 5, 10]
                    .map((v) => DropdownMenuItem(
                          value: v,
                          child: Text('$v sec'),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _refreshInterval = value);
                    _startAutoRefresh();
                    Navigator.pop(context);
                  }
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Clear timeline history'),
              onTap: () {
                setState(() => _history.clear());
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTroubleshooting() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Troubleshooting'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _troubleshootingItem(
                'No signals detected?',
                'Make sure you call VoidSignalsDebugService.initialize() '
                    'in your main() function before runApp().',
              ),
              _troubleshootingItem(
                'Signals not showing up?',
                'Use the .tracked() extension on signals you want to debug:\n'
                    'final count = signal(0).tracked(label: "count");',
              ),
              _troubleshootingItem(
                'Values not updating?',
                'Check that your app is running in debug mode. '
                    'The DevTools integration is disabled in release builds.',
              ),
              _troubleshootingItem(
                'Connection errors?',
                'Try hot restarting your app (Shift+R in terminal) '
                    'and refreshing this extension.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _troubleshootingItem(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(content),
        ],
      ),
    );
  }
}

/// Container for all signals data from the app.
class SignalsData {
  final List<SignalInfo> signals;
  final List<ComputedInfo> computeds;
  final List<EffectInfo> effects;
  final List<ScopeInfo> scopes;
  final List<ValueHistoryEntry> newHistory;
  final ReactiveStats stats;

  SignalsData({
    required this.signals,
    required this.computeds,
    required this.effects,
    required this.scopes,
    required this.newHistory,
    required this.stats,
  });

  factory SignalsData.empty() => SignalsData(
        signals: [],
        computeds: [],
        effects: [],
        scopes: [],
        newHistory: [],
        stats: ReactiveStats.empty(),
      );

  factory SignalsData.fromJson(Map<String, dynamic> json) {
    return SignalsData(
      signals: (json['signals'] as List<dynamic>?)
              ?.map((e) => SignalInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      computeds: (json['computeds'] as List<dynamic>?)
              ?.map((e) => ComputedInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      effects: (json['effects'] as List<dynamic>?)
              ?.map((e) => EffectInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      scopes: (json['scopes'] as List<dynamic>?)
              ?.map((e) => ScopeInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      newHistory: (json['newHistory'] as List<dynamic>?)
              ?.map(
                  (e) => ValueHistoryEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      stats: json['stats'] != null
          ? ReactiveStats.fromJson(json['stats'] as Map<String, dynamic>)
          : ReactiveStats.empty(),
    );
  }
}
