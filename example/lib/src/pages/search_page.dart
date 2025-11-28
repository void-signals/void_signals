import 'dart:async';

import 'package:flutter/material.dart';
import 'package:void_signals_flutter/void_signals_flutter.dart';

import '../state/search_state.dart';
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

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text('Search'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(72),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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

          // Recent searches or suggestions
          Watch(
            builder: (context, child) {
              if (searchState.query.value.isEmpty) {
                return SliverToBoxAdapter(
                  child: _SearchSuggestions(
                    onSelect: (query) {
                      _controller.text = query;
                      searchState.search(query);
                    },
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
                loading:
                    () => const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                error:
                    (error, _) => SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text('Error: $error'),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed:
                                  () => searchState.search(
                                    searchState.query.value,
                                  ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                data: (_) {
                  final packages = searchState.packages.value;
                  if (packages.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No results for "${searchState.query.value}"',
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList.separated(
                      itemCount:
                          packages.length + (searchState.hasMore ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
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
                          onTap:
                              () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (context) => PackageDetailPage(
                                        packageName: package.package,
                                      ),
                                ),
                              ),
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
      ),
    );
  }
}

class _SearchSuggestions extends StatelessWidget {
  final ValueChanged<String> onSelect;

  const _SearchSuggestions({required this.onSelect});

  static const _suggestions = [
    ('flutter', Icons.flutter_dash),
    ('bloc', Icons.account_tree),
    ('riverpod', Icons.water_drop),
    ('provider', Icons.inventory_2),
    ('dio', Icons.cloud),
    ('http', Icons.http),
    ('firebase', Icons.local_fire_department),
    ('animations', Icons.animation),
    ('sqflite', Icons.storage),
    ('json', Icons.code),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Popular searches', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _suggestions.map((suggestion) {
                  return ActionChip(
                    avatar: Icon(suggestion.$2, size: 18),
                    label: Text(suggestion.$1),
                    onPressed: () => onSelect(suggestion.$1),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}
