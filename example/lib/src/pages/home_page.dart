import 'package:flutter/material.dart';
import 'package:pub_api_client/pub_api_client.dart';
import 'package:void_signals_flutter/void_signals_flutter.dart';

import '../state/search_state.dart';
import '../state/favorites_state.dart';
import '../utils/responsive.dart';
import 'api_showcase_page.dart';
import 'lint_demo_page.dart';
import 'search_page.dart';
import 'favorites_page.dart';
import 'package_detail_page.dart';
import '../widgets/package_card.dart';

/// Home page with adaptive navigation
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _selectedIndex = signal(0);

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await searchState.search('flutter');
    favoritesState.load();
  }

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.explore_outlined),
      selectedIcon: Icon(Icons.explore),
      label: 'Explore',
    ),
    NavigationDestination(
      icon: Icon(Icons.search_outlined),
      selectedIcon: Icon(Icons.search),
      label: 'Search',
    ),
    NavigationDestination(
      icon: Icon(Icons.favorite_outline),
      selectedIcon: Icon(Icons.favorite),
      label: 'Favorites',
    ),
    NavigationDestination(
      icon: Icon(Icons.code_outlined),
      selectedIcon: Icon(Icons.code),
      label: 'API Demo',
    ),
    NavigationDestination(
      icon: Icon(Icons.bug_report_outlined),
      selectedIcon: Icon(Icons.bug_report),
      label: 'Lint Demo',
    ),
  ];

  Widget _buildBody() {
    return Watch(
      builder: (context, child) {
        return IndexedStack(
          index: _selectedIndex.value,
          children: const [
            _ExplorePage(),
            SearchPage(),
            FavoritesPage(),
            ApiShowcasePage(),
            LintDemoPage(),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Watch(
      builder: (context, child) {
        return AdaptiveScaffold(
          body: _buildBody(),
          selectedIndex: _selectedIndex.value,
          onDestinationSelected: (index) => _selectedIndex.value = index,
          destinations: _destinations,
        );
      },
    );
  }
}

/// Explore page showing popular packages
class _ExplorePage extends StatelessWidget {
  const _ExplorePage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCompact = ResponsiveLayout.isCompact(context);
    final gridColumns = ResponsiveLayout.getGridColumns(context);
    final padding = ResponsiveLayout.getContentPadding(context);
    final maxWidth = ResponsiveLayout.getMaxContentWidth(context);

    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: const Text('Pub.dev Explorer'),
          floating: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showAboutDialog(context),
              tooltip: 'About',
            ),
          ],
        ),

        // Hero section
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth ?? double.infinity,
              ),
              child: Padding(
                padding: padding,
                child: _HeroSection(colorScheme: colorScheme, theme: theme),
              ),
            ),
          ),
        ),

        // Category chips
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth ?? double.infinity,
              ),
              child: SizedBox(
                height: 56,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(
                    horizontal: padding.horizontal / 2,
                  ),
                  children: [
                    _CategoryChip(
                      label: 'Popular',
                      icon: Icons.trending_up,
                      onTap: () => searchState.search('flutter'),
                    ),
                    _CategoryChip(
                      label: 'State Management',
                      icon: Icons.account_tree,
                      onTap: () => searchState.search('state management'),
                    ),
                    _CategoryChip(
                      label: 'UI',
                      icon: Icons.widgets,
                      onTap: () => searchState.search('ui components'),
                    ),
                    _CategoryChip(
                      label: 'Networking',
                      icon: Icons.cloud,
                      onTap: () => searchState.search('http client'),
                    ),
                    _CategoryChip(
                      label: 'Database',
                      icon: Icons.storage,
                      onTap: () => searchState.search('database'),
                    ),
                    _CategoryChip(
                      label: 'Firebase',
                      icon: Icons.local_fire_department,
                      onTap: () => searchState.search('firebase'),
                    ),
                    _CategoryChip(
                      label: 'Animation',
                      icon: Icons.animation,
                      onTap: () => searchState.search('animation'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Section header
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth ?? double.infinity,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: padding.horizontal / 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Popular Packages', style: theme.textTheme.titleLarge),
                    Watch(
                      builder: (context, child) {
                        return _SortDropdown(
                          value: searchState.sortOrder.value,
                          onChanged: searchState.changeSortOrder,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 8)),

        // Package list/grid based on screen size
        Watch(
          builder: (context, child) {
            return searchState.results.value.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              error: (error, _) => SliverToBoxAdapter(
                child: _ErrorWidget(
                  error: error,
                  onRetry: () => searchState.search(searchState.query.value),
                ),
              ),
              data: (_) {
                final packages = searchState.packages.value;
                if (packages.isEmpty) {
                  return const SliverToBoxAdapter(child: _EmptyWidget());
                }

                // Use grid for larger screens, list for compact
                if (isCompact) {
                  return _buildPackageList(
                    packages: packages,
                    padding: padding,
                    maxWidth: maxWidth,
                    context: context,
                  );
                } else {
                  return _buildPackageGrid(
                    packages: packages,
                    padding: padding,
                    maxWidth: maxWidth,
                    gridColumns: gridColumns,
                    context: context,
                  );
                }
              },
            );
          },
        ),

        // Bottom padding for safe area
        SliverToBoxAdapter(
          child: SizedBox(
            height: MediaQuery.of(context).padding.bottom + 100,
          ),
        ),
      ],
    );
  }

  Widget _buildPackageList({
    required List<PackageResult> packages,
    required EdgeInsets padding,
    required double? maxWidth,
    required BuildContext context,
  }) {
    return SliverToBoxAdapter(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth ?? double.infinity,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: padding.horizontal / 2),
            child: Column(
              children: [
                for (int index = 0; index < packages.length; index++) ...[
                  PackageCard(
                    packageName: packages[index].package,
                    onTap: () => _navigateToDetail(context, packages[index].package),
                  ),
                  if (index < packages.length - 1) const SizedBox(height: 12),
                ],
                if (searchState.hasMore) _buildLoadMoreButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPackageGrid({
    required List<PackageResult> packages,
    required EdgeInsets padding,
    required double? maxWidth,
    required int gridColumns,
    required BuildContext context,
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
              maxCrossAxisExtent: 320,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              mainAxisExtent: 200,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= packages.length) {
                  searchState.loadMore();
                  return Watch(
                    builder: (context, child) {
                      if (searchState.isLoadingMore.value) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  );
                }

                final package = packages[index];
                return PackageCard(
                  packageName: package.package,
                  onTap: () => _navigateToDetail(context, package.package),
                );
              },
              childCount: packages.length + (searchState.hasMore ? 1 : 0),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Watch(
        builder: (context, child) {
          if (searchState.isLoadingMore.value) {
            return const Center(child: CircularProgressIndicator());
          }
          return Center(
            child: FilledButton.tonal(
              onPressed: searchState.loadMore,
              child: const Text('Load More'),
            ),
          );
        },
      ),
    );
  }

  void _navigateToDetail(BuildContext context, String packageName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PackageDetailPage(packageName: packageName),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Pub.dev Explorer',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.tertiary,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.flutter_dash, color: Colors.white, size: 32),
      ),
      children: [
        const Text(
          'A beautiful pub.dev client built with void_signals and Material Design 3 Expressive.',
        ),
        const SizedBox(height: 16),
        Text(
          'Powered by void_signals for reactive state management.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _HeroSection extends StatelessWidget {
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _HeroSection({required this.colorScheme, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isExpanded = ResponsiveLayout.isExpanded(context);

    return Container(
      padding: EdgeInsets.all(isExpanded ? 32 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: isExpanded
          ? Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Discover Flutter Packages',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Explore the best packages from pub.dev powered by void_signals.\nFind state management, UI components, networking solutions, and more.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onPrimaryContainer.withAlpha(
                            (0.8 * 255).round(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimaryContainer.withAlpha(
                      (0.1 * 255).round(),
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    Icons.flutter_dash,
                    size: 72,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.flutter_dash,
                  size: 48,
                  color: colorScheme.onPrimaryContainer,
                ),
                const SizedBox(height: 16),
                Text(
                  'Discover Flutter Packages',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Explore the best packages from pub.dev powered by void_signals',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer.withAlpha(
                      (0.8 * 255).round(),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
        onPressed: onTap,
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  final SearchOrder value;
  final ValueChanged<SearchOrder> onChanged;

  const _SortDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SearchOrder>(
      initialValue: value,
      onSelected: onChanged,
      tooltip: 'Sort order',
      child: Chip(
        avatar: const Icon(Icons.sort, size: 18),
        label: Text(_getLabel(value)),
      ),
      itemBuilder: (context) => SearchOrder.values.map((order) {
        return PopupMenuItem(
          value: order,
          child: Row(
            children: [
              if (order == value)
                Icon(
                  Icons.check,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                )
              else
                const SizedBox(width: 18),
              const SizedBox(width: 12),
              Text(_getLabel(order)),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getLabel(SearchOrder order) {
    return switch (order) {
      SearchOrder.top => 'Top',
      SearchOrder.text => 'Relevance',
      SearchOrder.created => 'Newest',
      SearchOrder.updated => 'Recently Updated',
      SearchOrder.popularity => 'Popularity',
      SearchOrder.downloads => 'Downloads',
      SearchOrder.like => 'Likes',
      SearchOrder.points => 'Pub Points',
    };
  }
}

class _ErrorWidget extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorWidget({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
            Text(
              'Something went wrong',
              style: theme.textTheme.titleLarge,
            ),
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
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyWidget extends StatelessWidget {
  const _EmptyWidget();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                Icons.search_off,
                size: 48,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No packages found',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
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
