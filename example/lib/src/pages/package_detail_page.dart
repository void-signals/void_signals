import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pub_api_client/pub_api_client.dart';
import 'package:void_signals_flutter/void_signals_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../state/package_detail_state.dart';
import '../utils/responsive.dart';

/// Package detail page
///
/// Demonstrates usage of:
/// - [SignalScrollController] for reactive scroll state with back-to-top button
class PackageDetailPage extends StatefulWidget {
  final String packageName;

  const PackageDetailPage({super.key, required this.packageName});

  @override
  State<PackageDetailPage> createState() => _PackageDetailPageState();
}

class _PackageDetailPageState extends State<PackageDetailPage> {
  late final PackageDetailState _state;
  late final SignalScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _state = PackageDetailState(widget.packageName);
    _scrollController = SignalScrollController(showBackToTopThreshold: 300);
    _state.load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = ResponsiveLayout.isCompact(context);
    final padding = ResponsiveLayout.getContentPadding(context);
    final maxWidth = ResponsiveLayout.getMaxContentWidth(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _state.refresh,
        child: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController.controller,
              slivers: [
                // App bar
                SliverAppBar.large(
                  title: Text(widget.packageName),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.open_in_new),
                      onPressed: () => _openPubDev(),
                      tooltip: 'Open on pub.dev',
                    ),
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () => _sharePackage(),
                      tooltip: 'Share',
                    ),
                  ],
                ),

                // Content wrapper for responsive layout
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: maxWidth ?? double.infinity,
                      ),
                      child: Watch(
                        builder: (context, child) {
                          return _state.info.value.when(
                            loading: () => const _LoadingSection(),
                            error: (error, _) => _ErrorSection(
                              error: error,
                              onRetry: _state.refresh,
                            ),
                            data: (info) => _buildContent(
                              context,
                              info,
                              isCompact: isCompact,
                              padding: padding,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 100),
                ),
              ],
            ),

            // Floating back-to-top button
            Positioned(
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 100,
              child: Watch(
                builder: (context, child) {
                  final showButton = _scrollController.showBackToTop.value;
                  return AnimatedSlide(
                    duration: const Duration(milliseconds: 200),
                    offset: showButton ? Offset.zero : const Offset(0, 2),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: showButton ? 1.0 : 0.0,
                      child: FloatingActionButton.small(
                        heroTag: 'detail_back_to_top',
                        onPressed: _scrollController.animateToTop,
                        tooltip: 'Back to top',
                        child: const Icon(Icons.arrow_upward),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    PubPackage info, {
    required bool isCompact,
    required EdgeInsets padding,
  }) {
    if (isCompact) {
      return _buildCompactLayout(info, padding);
    }
    return _buildExpandedLayout(info, padding);
  }

  Widget _buildCompactLayout(PubPackage info, EdgeInsets padding) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PackageInfoSection(info: info),
          const SizedBox(height: 16),
          Watch(
            builder: (context, child) {
              return _state.score.value.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (score) => _ScoreSection(score: score),
              );
            },
          ),
          const SizedBox(height: 16),
          Watch(
            builder: (context, child) {
              return _state.publisher.value.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (publisher) => _PublisherSection(publisher: publisher),
              );
            },
          ),
          const SizedBox(height: 16),
          _VersionsSection(info: info),
          const SizedBox(height: 24),
          _ActionsSection(
            onCopyDependency: _copyDependency,
            onOpenPubDev: _openPubDev,
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedLayout(PubPackage info, EdgeInsets padding) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main content
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PackageInfoSection(info: info),
                const SizedBox(height: 16),
                _VersionsSection(info: info),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Sidebar
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Watch(
                  builder: (context, child) {
                    return _state.score.value.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (score) => _ScoreSection(score: score),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Watch(
                  builder: (context, child) {
                    return _state.publisher.value.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (publisher) =>
                          _PublisherSection(publisher: publisher),
                    );
                  },
                ),
                const SizedBox(height: 24),
                _ActionsSection(
                  onCopyDependency: _copyDependency,
                  onOpenPubDev: _openPubDev,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openPubDev() {
    launchUrl(
      Uri.parse('https://pub.dev/packages/${widget.packageName}'),
      mode: LaunchMode.externalApplication,
    );
  }

  void _sharePackage() {
    Clipboard.setData(
      ClipboardData(text: 'https://pub.dev/packages/${widget.packageName}'),
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Link copied to clipboard')));
  }

  void _copyDependency() {
    final info = _state.info.value;
    if (info is AsyncData<PubPackage>) {
      final version = info.value.version;
      final dep = '${widget.packageName}: ^$version';
      Clipboard.setData(ClipboardData(text: dep));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied: $dep'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _ActionsSection extends StatelessWidget {
  final VoidCallback onCopyDependency;
  final VoidCallback onOpenPubDev;

  const _ActionsSection({
    required this.onCopyDependency,
    required this.onOpenPubDev,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: onCopyDependency,
          icon: const Icon(Icons.copy),
          label: const Text('Copy dependency'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onOpenPubDev,
          icon: const Icon(Icons.open_in_browser),
          label: const Text('View on pub.dev'),
        ),
      ],
    );
  }
}

class _LoadingSection extends StatelessWidget {
  const _LoadingSection();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorSection extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorSection({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: colorScheme.error),
          const SizedBox(height: 16),
          Text('Failed to load package', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(error.toString(), style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _PackageInfoSection extends StatelessWidget {
  final PubPackage info;

  const _PackageInfoSection({required this.info});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Version badges
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'v${info.version}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (info.isDiscontinued == true)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Discontinued',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            Text(info.description, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),

            // Published date
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: colorScheme.outline),
                const SizedBox(width: 8),
                Text(
                  'Published ${timeago.format(info.latest.published)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              ],
            ),

            // Repository/Homepage links
            if (info.latestPubspec.repository != null ||
                info.latestPubspec.homepage != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (info.latestPubspec.repository != null)
                    _LinkChip(
                      icon: Icons.code,
                      label: 'Repository',
                      url: info.latestPubspec.repository.toString(),
                    ),
                  if (info.latestPubspec.homepage != null)
                    _LinkChip(
                      icon: Icons.home,
                      label: 'Homepage',
                      url: info.latestPubspec.homepage.toString(),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LinkChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;

  const _LinkChip({required this.icon, required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onPressed: () =>
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
    );
  }
}

class _ScoreSection extends StatelessWidget {
  final PackageScore score;

  const _ScoreSection({required this.score});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics_outlined,
                    size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Package Score',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 280;
                if (isNarrow) {
                  return Column(
                    children: [
                      _ScoreItem(
                        icon: Icons.star,
                        label: 'Pub Points',
                        value:
                            '${score.grantedPoints ?? 0}/${score.maxPoints ?? 160}',
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      _ScoreItem(
                        icon: Icons.favorite,
                        label: 'Likes',
                        value: '${score.likeCount}',
                        color: colorScheme.tertiary,
                      ),
                      const SizedBox(height: 16),
                      _ScoreItem(
                        icon: Icons.trending_up,
                        label: 'Popularity',
                        value: score.popularityScore != null
                            ? '${(score.popularityScore! * 100).toInt()}%'
                            : 'N/A',
                        color: colorScheme.secondary,
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: _ScoreItem(
                        icon: Icons.star,
                        label: 'Pub Points',
                        value:
                            '${score.grantedPoints ?? 0}/${score.maxPoints ?? 160}',
                        color: colorScheme.primary,
                      ),
                    ),
                    Expanded(
                      child: _ScoreItem(
                        icon: Icons.favorite,
                        label: 'Likes',
                        value: '${score.likeCount}',
                        color: colorScheme.tertiary,
                      ),
                    ),
                    Expanded(
                      child: _ScoreItem(
                        icon: Icons.trending_up,
                        label: 'Popularity',
                        value: score.popularityScore != null
                            ? '${(score.popularityScore! * 100).toInt()}%'
                            : 'N/A',
                        color: colorScheme.secondary,
                      ),
                    ),
                  ],
                );
              },
            ),
            if (score.downloadCount30Days != null) ...[
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.download,
                        size: 16, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(
                      '${_formatNumber(score.downloadCount30Days!)} downloads in last 30 days',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

class _ScoreItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ScoreItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}

class _PublisherSection extends StatelessWidget {
  final PackagePublisher publisher;

  const _PublisherSection({required this.publisher});

  @override
  Widget build(BuildContext context) {
    if (publisher.publisherId == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.secondaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.verified,
                color: colorScheme.onSecondaryContainer,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verified Publisher',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    publisher.publisherId!,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VersionsSection extends StatelessWidget {
  final PubPackage info;

  const _VersionsSection({required this.info});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final versions = info.versions.take(10).toList();

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.history, size: 20, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Recent Versions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${info.versions.length} total',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: versions.map((v) {
                final isLatest = v.version == info.version;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isLatest
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: isLatest
                        ? Border.all(color: colorScheme.primary, width: 1.5)
                        : null,
                  ),
                  child: Text(
                    v.version,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isLatest
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                      fontWeight:
                          isLatest ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
