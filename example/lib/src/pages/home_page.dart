import 'package:flutter/material.dart';
import 'package:pub_api_client/pub_api_client.dart';
import 'package:void_signals_flutter/void_signals_flutter.dart';

import '../state/search_state.dart';
import '../state/favorites_state.dart';
import 'api_showcase_page.dart';
import 'lint_demo_page.dart';
import 'search_page.dart';
import 'favorites_page.dart';
import 'package_detail_page.dart';
import '../widgets/package_card.dart';

/// Home page with bottom navigation
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Local UI state - no dispose needed for simple signals
  // as Watch handles subscription lifecycle automatically
  final _selectedIndex = signal(0);

  @override
  void initState() {
    super.initState();
    // Load initial data
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Pre-load popular packages
    await searchState.search('flutter');
    // Pre-load favorites
    favoritesState.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Watch(
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
      ),
      bottomNavigationBar: Watch(
        builder: (context, child) {
          return NavigationBar(
            selectedIndex: _selectedIndex.value,
            onDestinationSelected: (index) => _selectedIndex.value = index,
            destinations: const [
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
            ],
          );
        },
      ),
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

    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: const Text('Pub.dev Explorer'),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showAboutDialog(context),
            ),
          ],
        ),

        // Hero section
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
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
            child: Column(
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
          ),
        ),

        // Category chips
        SliverToBoxAdapter(
          child: SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Section header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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

        const SliverToBoxAdapter(child: SizedBox(height: 8)),

        // Package list
        Watch(
          builder: (context, child) {
            return searchState.results.value.when(
              loading:
                  () => const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
              error:
                  (error, _) => SliverToBoxAdapter(
                    child: _ErrorWidget(
                      error: error,
                      onRetry:
                          () => searchState.search(searchState.query.value),
                    ),
                  ),
              data: (_) {
                final packages = searchState.packages.value;
                if (packages.isEmpty) {
                  return const SliverToBoxAdapter(child: _EmptyWidget());
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.separated(
                    itemCount: packages.length + (searchState.hasMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index >= packages.length) {
                        // Load more trigger
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
                        onTap:
                            () => _navigateToDetail(context, package.package),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
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
      applicationIcon: const FlutterLogo(size: 48),
      children: [
        const Text(
          'A beautiful pub.dev client built with void_signals and Material Design 3 Expressive.',
        ),
      ],
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
      child: Chip(
        avatar: const Icon(Icons.sort, size: 18),
        label: Text(_getLabel(value)),
      ),
      itemBuilder:
          (context) =>
              SearchOrder.values.map((order) {
                return PopupMenuItem(
                  value: order,
                  child: Text(_getLabel(order)),
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
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text('Something went wrong', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
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

class _EmptyWidget extends StatelessWidget {
  const _EmptyWidget();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text('No packages found', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
