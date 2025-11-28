import 'dart:async';

import 'package:flutter/material.dart';
import 'package:void_signals_flutter/void_signals_flutter.dart';

import '../state/search_state.dart';
import '../utils/responsive.dart';
import '../widgets/package_card.dart';
import 'package_detail_page.dart';

/// Search page with real-time search
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      searchState.search(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCompact = ResponsiveLayout.isCompact(context);
    final gridColumns = ResponsiveLayout.getGridColumns(context);
    final padding = ResponsiveLayout.getContentPadding(context);
    final maxWidth = ResponsiveLayout.getMaxContentWidth(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text('Search'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(80),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxWidth ?? double.infinity,
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      padding.left,
                      0,
                      padding.right,
                      16,
                    ),
                    child: SearchBar(
                      controller: _controller,
                      focusNode: _focusNode,
                      hintText: 'Search packages...',
                      leading: const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.search),
                      ),
                      trailing: [
                        Watch(
                          builder: (context, child) {
                            if (searchState.query.value.isNotEmpty) {
                              return IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _controller.clear();
                                  searchState.clear();
                                },
                                tooltip: 'Clear search',
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                      onChanged: _onSearchChanged,
                      onSubmitted: (value) => searchState.search(value),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Recent searches or suggestions
          Watch(
            builder: (context, child) {
              if (searchState.query.value.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: maxWidth ?? double.infinity,
                      ),
                      child: _SearchSuggestions(
                        padding: padding,
                        onSelect: (query) {
                          _controller.text = query;
                          searchState.search(query);
                        },
                      ),
                    ),
                  ),
                );
              }
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            },
          ),

          // Search results
          Watch(
            builder: (context, child) {
              if (searchState.query.value.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }

              return searchState.results.value.when(
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
                  ),
                ),
                data: (_) {
                  final packages = searchState.packages.value;
                  if (packages.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(
                        query: searchState.query.value,
                        colorScheme: colorScheme,
                        theme: theme,
                      ),
                    );
                  }

                  if (isCompact) {
                    return _buildPackageList(
                      padding: padding,
                      maxWidth: maxWidth,
                    );
                  } else {
                    return _buildPackageGrid(
                      padding: padding,
                      maxWidth: maxWidth,
                      gridColumns: gridColumns,
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
      ),
    );
  }

  Widget _buildPackageList({
    required EdgeInsets padding,
    required double? maxWidth,
  }) {
    final packages = searchState.packages.value;

    return SliverToBoxAdapter(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth ?? double.infinity,
          ),
          child: Padding(
            padding: padding,
            child: Column(
              children: [
                for (int index = 0; index < packages.length; index++) ...[
                  PackageCard(
                    packageName: packages[index].package,
                    onTap: () => _navigateToDetail(packages[index].package),
                  ),
                  if (index < packages.length - 1) const SizedBox(height: 12),
                ],
                if (searchState.hasMore) _buildLoadMoreSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPackageGrid({
    required EdgeInsets padding,
    required double? maxWidth,
    required int gridColumns,
  }) {
    final packages = searchState.packages.value;

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.crossAxisExtent;
        final effectiveMaxWidth = maxWidth ?? availableWidth;
        final horizontalPadding = ((availableWidth - effectiveMaxWidth) / 2)
            .clamp(0.0, double.infinity);

        return SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding + padding.horizontal / 2,
            vertical: padding.vertical / 2,
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
                  onTap: () => _navigateToDetail(package.package),
                );
              },
              childCount: packages.length + (searchState.hasMore ? 1 : 0),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadMoreSection() {
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

  void _navigateToDetail(String packageName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PackageDetailPage(packageName: packageName),
      ),
    );
  }
}

class _SearchSuggestions extends StatelessWidget {
  final EdgeInsets padding;
  final ValueChanged<String> onSelect;

  const _SearchSuggestions({required this.padding, required this.onSelect});

  static const _suggestions = [
    ('flutter', Icons.flutter_dash, 'Flutter SDK'),
    ('bloc', Icons.account_tree, 'State management'),
    ('riverpod', Icons.water_drop, 'Reactive caching'),
    ('provider', Icons.inventory_2, 'Dependency injection'),
    ('dio', Icons.cloud, 'HTTP client'),
    ('http', Icons.http, 'HTTP requests'),
    ('firebase', Icons.local_fire_department, 'Backend services'),
    ('animations', Icons.animation, 'UI animations'),
    ('sqflite', Icons.storage, 'SQLite database'),
    ('json', Icons.code, 'JSON serialization'),
    ('get', Icons.flash_on, 'State & routing'),
    ('hooks', Icons.code, 'Flutter Hooks'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isExpanded = ResponsiveLayout.isExpanded(context);

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Popular searches',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isExpanded)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _suggestions.map((suggestion) {
                return _SuggestionChip(
                  label: suggestion.$1,
                  icon: suggestion.$2,
                  description: suggestion.$3,
                  onTap: () => onSelect(suggestion.$1),
                  isExpanded: true,
                );
              }).toList(),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _suggestions.map((suggestion) {
                return _SuggestionChip(
                  label: suggestion.$1,
                  icon: suggestion.$2,
                  description: suggestion.$3,
                  onTap: () => onSelect(suggestion.$1),
                  isExpanded: false,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final String description;
  final VoidCallback onTap;
  final bool isExpanded;

  const _SuggestionChip({
    required this.label,
    required this.icon,
    required this.description,
    required this.onTap,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isExpanded) {
      return Material(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: colorScheme.primary),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Object error;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _ErrorState({
    required this.error,
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
            Text('Search failed', style: theme.textTheme.titleLarge),
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
              onPressed: () => searchState.search(searchState.query.value),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String query;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _EmptyState({
    required this.query,
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
                Icons.search_off,
                size: 48,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No results found',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'No packages matching "$query"',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term or check the spelling',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
