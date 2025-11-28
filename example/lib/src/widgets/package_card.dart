import 'package:flutter/material.dart';
import 'package:pub_api_client/pub_api_client.dart';
import 'package:void_signals_flutter/void_signals_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../data/pub_repository.dart';

/// A card displaying package info with async loading
class PackageCard extends StatefulWidget {
  final String packageName;
  final VoidCallback? onTap;

  const PackageCard({super.key, required this.packageName, this.onTap});

  @override
  State<PackageCard> createState() => _PackageCardState();
}

class _PackageCardState extends State<PackageCard> {
  late final Signal<AsyncValue<PubPackage>> _info;
  late final Signal<AsyncValue<PackageScore>> _score;

  @override
  void initState() {
    super.initState();
    _info = signal(const AsyncLoading());
    _score = signal(const AsyncLoading());
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await pubRepository.packageInfo(widget.packageName);
      if (mounted) {
        _info.value = AsyncData(info);
      }
    } catch (e, st) {
      if (mounted) {
        _info.value = AsyncError(e, st);
      }
    }

    try {
      final score = await pubRepository.packageScore(widget.packageName);
      if (mounted) {
        _score.value = AsyncData(score);
      }
    } catch (e, st) {
      if (mounted) {
        _score.value = AsyncError(e, st);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with name and version
              Row(
                children: [
                  // Package icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primaryContainer,
                          colorScheme.secondaryContainer,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        widget.packageName[0].toUpperCase(),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.packageName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Watch(
                          builder: (context, child) {
                            return _info.value.when(
                              loading: () => _buildVersionPlaceholder(),
                              error: (_, __) => const SizedBox.shrink(),
                              data:
                                  (info) => Text(
                                    'v${info.version}',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(color: colorScheme.primary),
                                  ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: colorScheme.outline),
                ],
              ),

              const SizedBox(height: 12),

              // Description
              Watch(
                builder: (context, child) {
                  return _info.value.when(
                    loading: () => _buildDescriptionPlaceholder(),
                    error:
                        (error, _) => Text(
                          'Failed to load: $error',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.error,
                          ),
                        ),
                    data:
                        (info) => Text(
                          info.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // Stats row
              Watch(
                builder: (context, child) {
                  return _score.value.when(
                    loading: () => _buildStatsPlaceholder(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (score) => _buildStatsRow(score, colorScheme),
                  );
                },
              ),

              // Published date
              Watch(
                builder: (context, child) {
                  return _info.value.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data:
                        (info) => Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 14,
                                color: colorScheme.outline,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                timeago.format(info.latest.published),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVersionPlaceholder() {
    return Container(
      width: 50,
      height: 14,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildDescriptionPlaceholder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 14,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 200,
          height: 14,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsPlaceholder() {
    return Row(
      children: List.generate(
        3,
        (index) => Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            width: 60,
            height: 20,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(PackageScore score, ColorScheme colorScheme) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _StatChip(
          icon: Icons.star,
          value: '${score.grantedPoints ?? 0}',
          label: 'pts',
          color: colorScheme.primary,
        ),
        _StatChip(
          icon: Icons.favorite,
          value: '${score.likeCount}',
          label: '',
          color: colorScheme.tertiary,
        ),
        if (score.popularityScore != null)
          _StatChip(
            icon: Icons.trending_up,
            value: '${(score.popularityScore! * 100).toInt()}%',
            label: '',
            color: colorScheme.secondary,
          ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$value$label',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
