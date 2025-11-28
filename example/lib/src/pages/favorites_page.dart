import 'package:flutter/material.dart';
import 'package:void_signals_flutter/void_signals_flutter.dart';

import '../state/favorites_state.dart';
import '../utils/responsive.dart';
import 'package_detail_page.dart';

/// Favorites page showing Flutter Favorites
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  void initState() {
    super.initState();
    favoritesState.load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCompact = ResponsiveLayout.isCompact(context);
    final padding = ResponsiveLayout.getContentPadding(context);
    final maxWidth = ResponsiveLayout.getMaxContentWidth(context);
    final gridColumns = ResponsiveLayout.getGridColumns(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: favoritesState.refresh,
        child: CustomScrollView(
          slivers: [
            SliverAppBar.large(title: const Text('Flutter Favorites')),

            // Hero card
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxWidth ?? double.infinity,
                  ),
                  child: Container(
                    margin: padding,
                    padding: EdgeInsets.all(isCompact ? 20 : 28),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.tertiaryContainer,
                          colorScheme.secondaryContainer,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isCompact ? 12 : 16),
                          decoration: BoxDecoration(
                            color: colorScheme.onTertiaryContainer
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.favorite,
                            size: isCompact ? 32 : 40,
                            color: colorScheme.onTertiaryContainer,
                          ),
                        ),
                        SizedBox(width: isCompact ? 16 : 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Curated by Flutter Team',
                                style: (isCompact
                                        ? theme.textTheme.titleMedium
                                        : theme.textTheme.titleLarge)
                                    ?.copyWith(
                                  color: colorScheme.onTertiaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'High quality packages recommended for Flutter development',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onTertiaryContainer
                                      .withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Package count
            Watch(
              builder: (context, child) {
                return favoritesState.favorites.value.when(
                  loading: () =>
                      const SliverToBoxAdapter(child: SizedBox.shrink()),
                  error: (_, __) =>
                      const SliverToBoxAdapter(child: SizedBox.shrink()),
                  data: (favorites) => SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: maxWidth ?? double.infinity,
                        ),
                        child: Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: padding.left),
                          child: Row(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 18,
                                color: colorScheme.outline,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${favorites.length} packages',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Favorites list
            Watch(
              builder: (context, child) {
                return favoritesState.favorites.value.when(
                  loading: () => const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => SliverFillRemaining(
                    hasScrollBody: false,
                    child: _ErrorState(
                      error: error,
                      colorScheme: colorScheme,
                      theme: theme,
                      onRetry: favoritesState.refresh,
                    ),
                  ),
                  data: (favorites) {
                    if (favorites.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(
                          colorScheme: colorScheme,
                          theme: theme,
                        ),
                      );
                    }

                    return _buildFavoritesGrid(
                      favorites: favorites,
                      padding: padding,
                      maxWidth: maxWidth,
                      gridColumns: gridColumns,
                      isCompact: isCompact,
                    );
                  },
                );
              },
            ),

            SliverToBoxAdapter(
              child:
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesGrid({
    required List<String> favorites,
    required EdgeInsets padding,
    required double? maxWidth,
    required int gridColumns,
    required bool isCompact,
  }) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.crossAxisExtent;
        final effectiveMaxWidth = maxWidth ?? availableWidth;
        final horizontalPadding = ((availableWidth - effectiveMaxWidth) / 2)
            .clamp(0.0, double.infinity);

        return SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding + padding.horizontal / 2,
          ),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 360,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              mainAxisExtent: 90,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final packageName = favorites[index];
                return _FavoritePackageChip(
                  packageName: packageName,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PackageDetailPage(
                        packageName: packageName,
                      ),
                    ),
                  ),
                );
              },
              childCount: favorites.length,
            ),
          ),
        );
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Object error;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.error,
    required this.colorScheme,
    required this.theme,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text('Failed to load favorites', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _EmptyState({
    required this.colorScheme,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.favorite_border,
                size: 48,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text('No favorites yet', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Flutter Favorites will appear here',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoritePackageChip extends StatelessWidget {
  final String packageName;
  final VoidCallback onTap;

  const _FavoritePackageChip({required this.packageName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.tertiaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    packageName[0].toUpperCase(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      packageName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.verified,
                          size: 14,
                          color: colorScheme.tertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Flutter Favorite',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.tertiary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
