import 'package:flutter/material.dart';

import '../models/signal_info.dart';

/// A statistics dashboard showing reactive system metrics.
class StatsView extends StatelessWidget {
  final ReactiveStats stats;
  final List<SignalInfo> signals;
  final List<ComputedInfo> computeds;
  final List<EffectInfo> effects;

  const StatsView({
    super.key,
    required this.stats,
    required this.signals,
    required this.computeds,
    required this.effects,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewCards(context),
          const SizedBox(height: 24),
          _buildPerformanceSection(context),
          const SizedBox(height: 24),
          _buildDistributionSection(context),
          const SizedBox(height: 24),
          _buildTopSignalsSection(context),
        ],
      ),
    );
  }

  Widget _buildOverviewCards(BuildContext context) {
    // Calculate async computed counts
    final asyncComputeds =
        computeds.where((c) => c.isAsync && !c.isStream).length;
    final streamComputeds = computeds.where((c) => c.isStream).length;
    final syncComputeds = computeds.length - asyncComputeds - streamComputeds;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 64) / 5;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _StatCard(
              title: 'Signals',
              value: stats.totalSignals.toString(),
              icon: Icons.radio_button_checked,
              color: Colors.blue,
              subtitle: '${stats.totalUpdates} total updates',
              width: cardWidth.clamp(140, 220),
            ),
            _StatCard(
              title: 'Computeds',
              value: syncComputeds.toString(),
              icon: Icons.functions,
              color: Colors.green,
              subtitle: '${stats.dirtyComputeds} dirty',
              width: cardWidth.clamp(140, 220),
            ),
            _StatCard(
              title: 'Async',
              value: asyncComputeds.toString(),
              icon: Icons.cloud_sync,
              color: Colors.teal,
              subtitle: '${stats.loadingAsyncComputeds} loading',
              width: cardWidth.clamp(140, 220),
            ),
            _StatCard(
              title: 'Streams',
              value: streamComputeds.toString(),
              icon: Icons.stream,
              color: Colors.cyan,
              subtitle: 'Stream computeds',
              width: cardWidth.clamp(140, 220),
            ),
            _StatCard(
              title: 'Effects',
              value: stats.totalEffects.toString(),
              icon: Icons.bolt,
              color: Colors.orange,
              subtitle: '${stats.activeEffects} active',
              width: cardWidth.clamp(140, 220),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPerformanceSection(BuildContext context) {
    return _Section(
      title: 'Performance',
      icon: Icons.speed,
      child: Column(
        children: [
          _buildPerformanceRow(
            context,
            'Total Computations',
            stats.totalComputations.toString(),
            Icons.calculate,
          ),
          _buildPerformanceRow(
            context,
            'Total Effect Runs',
            stats.totalEffectRuns.toString(),
            Icons.play_arrow,
          ),
          if (stats.avgComputeTime != null)
            _buildPerformanceRow(
              context,
              'Avg Compute Time',
              _formatDuration(stats.avgComputeTime!),
              Icons.timer,
            ),
          if (stats.avgEffectTime != null)
            _buildPerformanceRow(
              context,
              'Avg Effect Time',
              _formatDuration(stats.avgEffectTime!),
              Icons.timer_outlined,
            ),
        ],
      ),
    );
  }

  Widget _buildPerformanceRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionSection(BuildContext context) {
    final total = signals.length + computeds.length + effects.length;
    if (total == 0) return const SizedBox.shrink();

    // Calculate hook vs direct signal distribution
    final hookSignals = signals.where((s) => s.isFromHook).length;
    final directSignals = signals.length - hookSignals;

    // Calculate async computed distribution
    final asyncComputeds =
        computeds.where((c) => c.isAsync && !c.isStream).length;
    final streamComputeds = computeds.where((c) => c.isStream).length;
    final syncComputeds = computeds.length - asyncComputeds - streamComputeds;

    // Calculate async state distribution
    final loadingAsync =
        computeds.where((c) => c.isAsync && c.asyncState == 'loading').length;
    final dataAsync =
        computeds.where((c) => c.isAsync && c.asyncState == 'data').length;
    final errorAsync =
        computeds.where((c) => c.isAsync && c.asyncState == 'error').length;

    return _Section(
      title: 'Distribution',
      icon: Icons.pie_chart,
      child: Column(
        children: [
          // Type distribution
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: signals.length,
                child: Container(
                  height: 24,
                  color: Colors.blue,
                ),
              ),
              Expanded(
                flex: syncComputeds,
                child: Container(
                  height: 24,
                  color: Colors.green,
                ),
              ),
              Expanded(
                flex: asyncComputeds,
                child: Container(
                  height: 24,
                  color: Colors.teal,
                ),
              ),
              Expanded(
                flex: streamComputeds,
                child: Container(
                  height: 24,
                  color: Colors.cyan,
                ),
              ),
              Expanded(
                flex: effects.length,
                child: Container(
                  height: 24,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _DistributionLegend(
                color: Colors.blue,
                label: 'Signals',
                count: signals.length,
                percentage: (signals.length / total * 100).toStringAsFixed(0),
              ),
              _DistributionLegend(
                color: Colors.green,
                label: 'Computed',
                count: syncComputeds,
                percentage: (syncComputeds / total * 100).toStringAsFixed(0),
              ),
              _DistributionLegend(
                color: Colors.teal,
                label: 'Async',
                count: asyncComputeds,
                percentage: (asyncComputeds / total * 100).toStringAsFixed(0),
              ),
              _DistributionLegend(
                color: Colors.cyan,
                label: 'Stream',
                count: streamComputeds,
                percentage: (streamComputeds / total * 100).toStringAsFixed(0),
              ),
              _DistributionLegend(
                color: Colors.orange,
                label: 'Effects',
                count: effects.length,
                percentage: (effects.length / total * 100).toStringAsFixed(0),
              ),
            ],
          ),
          // Async state distribution
          if (asyncComputeds + streamComputeds > 0) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Async State',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (loadingAsync > 0)
                  Expanded(
                    flex: loadingAsync,
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius:
                            loadingAsync == asyncComputeds + streamComputeds
                                ? BorderRadius.circular(4)
                                : const BorderRadius.horizontal(
                                    left: Radius.circular(4)),
                      ),
                    ),
                  ),
                if (dataAsync > 0)
                  Expanded(
                    flex: dataAsync,
                    child: Container(
                      height: 20,
                      color: Colors.green,
                    ),
                  ),
                if (errorAsync > 0)
                  Expanded(
                    flex: errorAsync,
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius:
                            errorAsync == asyncComputeds + streamComputeds
                                ? BorderRadius.circular(4)
                                : const BorderRadius.horizontal(
                                    right: Radius.circular(4)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _DistributionLegend(
                  color: Colors.amber,
                  label: 'Loading',
                  count: loadingAsync,
                  percentage: asyncComputeds + streamComputeds > 0
                      ? (loadingAsync /
                              (asyncComputeds + streamComputeds) *
                              100)
                          .toStringAsFixed(0)
                      : '0',
                ),
                _DistributionLegend(
                  color: Colors.green,
                  label: 'Data',
                  count: dataAsync,
                  percentage: asyncComputeds + streamComputeds > 0
                      ? (dataAsync / (asyncComputeds + streamComputeds) * 100)
                          .toStringAsFixed(0)
                      : '0',
                ),
                _DistributionLegend(
                  color: Colors.red,
                  label: 'Error',
                  count: errorAsync,
                  percentage: asyncComputeds + streamComputeds > 0
                      ? (errorAsync / (asyncComputeds + streamComputeds) * 100)
                          .toStringAsFixed(0)
                      : '0',
                ),
              ],
            ),
          ],
          // Signal source distribution
          if (signals.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Signal Sources',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (directSignals > 0)
                  Expanded(
                    flex: directSignals,
                    child: Container(
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        borderRadius:
                            BorderRadius.horizontal(left: Radius.circular(4)),
                      ),
                    ),
                  ),
                if (hookSignals > 0)
                  Expanded(
                    flex: hookSignals,
                    child: Container(
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.purple,
                        borderRadius:
                            BorderRadius.horizontal(right: Radius.circular(4)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _DistributionLegend(
                  color: Colors.blue,
                  label: 'Direct',
                  count: directSignals,
                  percentage: signals.isNotEmpty
                      ? (directSignals / signals.length * 100)
                          .toStringAsFixed(0)
                      : '0',
                ),
                _DistributionLegend(
                  color: Colors.purple,
                  label: 'Hooks',
                  count: hookSignals,
                  percentage: signals.isNotEmpty
                      ? (hookSignals / signals.length * 100).toStringAsFixed(0)
                      : '0',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopSignalsSection(BuildContext context) {
    // Sort signals by update count
    final sortedSignals = [...signals]
      ..sort((a, b) => b.updateCount.compareTo(a.updateCount));

    final topSignals = sortedSignals.take(5).toList();

    if (topSignals.isEmpty) return const SizedBox.shrink();

    return _Section(
      title: 'Most Updated Signals',
      icon: Icons.trending_up,
      child: Column(
        children: topSignals.map((signal) {
          final maxCount = topSignals.first.updateCount;
          final percentage = maxCount > 0 ? signal.updateCount / maxCount : 0.0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Hook indicator
                    if (signal.isFromHook)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          Icons.anchor,
                          size: 14,
                          color: Colors.purple.shade300,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        signal.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${signal.updateCount} updates',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                if (signal.isFromHook && signal.widgetName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${signal.source.displayName} in ${signal.widgetName}',
                    style: TextStyle(
                      color: Colors.purple.shade300,
                      fontSize: 10,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation(signal.color),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inMicroseconds < 1000) {
      return '${duration.inMicroseconds}μs';
    } else if (duration.inMilliseconds < 1000) {
      return '${duration.inMilliseconds}ms';
    } else {
      return '${(duration.inMilliseconds / 1000).toStringAsFixed(2)}s';
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final double width;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _DistributionLegend extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  final String percentage;

  const _DistributionLegend({
    required this.color,
    required this.label,
    required this.count,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label ($count)',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            ),
            Text(
              '$percentage%',
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}
