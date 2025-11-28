import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/signal_info.dart';
import 'signal_editor.dart';

/// A detail view for a selected signal.
class SignalDetailView extends StatelessWidget {
  final SignalInfo signal;
  final List<ComputedInfo> computeds;
  final List<EffectInfo> effects;
  final Future<bool> Function(String newValue)? onValueChanged;

  const SignalDetailView({
    super.key,
    required this.signal,
    required this.computeds,
    required this.effects,
    this.onValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildValueSection(context),
          const SizedBox(height: 24),
          _buildMetadataSection(context),
          const SizedBox(height: 24),
          _buildDependenciesSection(context),
          const SizedBox(height: 24),
          _buildSubscribersSection(context),
          if (signal.stackTrace != null) ...[
            const SizedBox(height: 24),
            _buildStackTraceSection(context),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            signal.icon,
            color: signal.color,
            size: 32,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      signal.displayName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  if (signal.updateCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.update,
                            size: 14,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${signal.updateCount} updates',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.amber,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              if (signal.label != null)
                Text(
                  signal.name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                        fontFamily: 'monospace',
                      ),
                ),
              Text(
                signal.type,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blue,
                      fontFamily: 'monospace',
                    ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy),
          tooltip: 'Copy signal ID',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: signal.id));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Signal ID copied to clipboard')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildValueSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'Current Value',
      icon: Icons.data_object,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onValueChanged != null)
            SignalEditor(
              signal: signal,
              onValueChanged: onValueChanged!,
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: SelectableText(
                signal.value,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
            ),
          if (onValueChanged != null && signal.isEditable) ...[
            const SizedBox(height: 8),
            QuickValueButtons(
              signal: signal,
              onValueChanged: onValueChanged!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetadataSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'Metadata',
      icon: Icons.info_outline,
      child: Column(
        children: [
          _buildMetadataRow(context, 'ID', signal.id),
          _buildMetadataRow(context, 'Type', signal.type),
          _buildMetadataRow(
            context,
            'Subscribers',
            '${signal.subscriberCount}',
          ),
          _buildMetadataRow(
            context,
            'Update Count',
            '${signal.updateCount}',
          ),
          if (signal.lastUpdated != null)
            _buildMetadataRow(
              context,
              'Last Updated',
              _formatDateTime(signal.lastUpdated!),
            ),
          _buildMetadataRow(
            context,
            'Editable',
            signal.isEditable ? 'Yes' : 'No',
          ),
          // Hook-specific metadata
          _buildMetadataRow(
            context,
            'Source',
            signal.source.displayName,
            color: signal.source.isHook ? Colors.purple : null,
          ),
          if (signal.isFromHook && signal.widgetName != null)
            _buildMetadataRow(
              context,
              'Widget',
              signal.widgetName!,
              color: Colors.purple.shade300,
            ),
          if (signal.hookWidgetId != null)
            _buildMetadataRow(
              context,
              'Widget Instance',
              signal.hookWidgetId!,
            ),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(
    BuildContext context,
    String label,
    String value, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDependenciesSection(BuildContext context) {
    final dependencies = signal.dependencyIds;

    return _buildSection(
      context,
      title: 'Dependencies (${dependencies.length})',
      icon: Icons.input,
      child: dependencies.isEmpty
          ? const Text(
              'No dependencies',
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            )
          : Column(
              children: dependencies.map((depId) {
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.radio_button_checked, size: 16),
                  title: Text(
                    depId,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildSubscribersSection(BuildContext context) {
    // Find computeds and effects that depend on this signal
    final dependentComputeds =
        computeds.where((c) => c.dependencyIds.contains(signal.id)).toList();
    final dependentEffects =
        effects.where((e) => e.dependencyIds.contains(signal.id)).toList();

    final totalSubscribers =
        dependentComputeds.length + dependentEffects.length;

    return _buildSection(
      context,
      title: 'Subscribers ($totalSubscribers)',
      icon: Icons.output,
      child: Column(
        children: [
          if (dependentComputeds.isEmpty && dependentEffects.isEmpty)
            const Text(
              'No subscribers',
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ...dependentComputeds.map((computed) {
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                computed.icon,
                size: 16,
                color: computed.color,
              ),
              title: Text(
                computed.displayName,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              subtitle: Text(
                computed.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11),
              ),
              trailing: computed.isDirty
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'dirty',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange,
                        ),
                      ),
                    )
                  : null,
            );
          }),
          ...dependentEffects.map((effect) {
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                effect.icon,
                size: 16,
                color: effect.color,
              ),
              title: Text(
                effect.displayName,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              subtitle: Text(
                'runs: ${effect.runCount}',
                style: const TextStyle(fontSize: 11),
              ),
              trailing: !effect.isActive
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'stopped',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.red,
                        ),
                      ),
                    )
                  : null,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStackTraceSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'Creation Stack Trace',
      icon: Icons.layers,
      child: Container(
        width: double.infinity,
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
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  tooltip: 'Copy stack trace',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: signal.stackTrace!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Stack trace copied to clipboard')),
                    );
                  },
                ),
              ],
            ),
            SelectableText(
              signal.stackTrace!,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
