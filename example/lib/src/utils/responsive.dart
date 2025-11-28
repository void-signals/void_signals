import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Breakpoints for responsive design following Material Design 3 guidelines
class Breakpoints {
  Breakpoints._();

  /// Compact: 0-599dp (phones in portrait)
  static const double compact = 600;

  /// Medium: 600-839dp (tablets in portrait, foldables)
  static const double medium = 840;

  /// Expanded: 840-1199dp (tablets in landscape, small laptops)
  static const double expanded = 1200;

  /// Large: 1200-1599dp (laptops, desktops)
  static const double large = 1600;

  /// Extra Large: 1600dp+ (large desktops, TVs)
  static const double extraLarge = double.infinity;
}

/// Window size class based on Material Design 3
enum WindowSizeClass {
  /// 0-599dp
  compact,

  /// 600-839dp
  medium,

  /// 840-1199dp
  expanded,

  /// 1200-1599dp
  large,

  /// 1600dp+
  extraLarge,
}

/// Responsive layout utilities
class ResponsiveLayout {
  ResponsiveLayout._();

  /// Get the current window size class based on width
  static WindowSizeClass getWindowSizeClass(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return getWindowSizeClassFromWidth(width);
  }

  /// Get window size class from a specific width
  static WindowSizeClass getWindowSizeClassFromWidth(double width) {
    if (width < Breakpoints.compact) {
      return WindowSizeClass.compact;
    } else if (width < Breakpoints.medium) {
      return WindowSizeClass.medium;
    } else if (width < Breakpoints.expanded) {
      return WindowSizeClass.expanded;
    } else if (width < Breakpoints.large) {
      return WindowSizeClass.large;
    } else {
      return WindowSizeClass.extraLarge;
    }
  }

  /// Check if the current layout is compact (mobile phone)
  static bool isCompact(BuildContext context) =>
      getWindowSizeClass(context) == WindowSizeClass.compact;

  /// Check if the current layout is medium (tablet portrait)
  static bool isMedium(BuildContext context) =>
      getWindowSizeClass(context) == WindowSizeClass.medium;

  /// Check if the current layout is expanded or larger (tablet landscape, desktop)
  static bool isExpanded(BuildContext context) {
    final sizeClass = getWindowSizeClass(context);
    return sizeClass == WindowSizeClass.expanded ||
        sizeClass == WindowSizeClass.large ||
        sizeClass == WindowSizeClass.extraLarge;
  }

  /// Check if navigation rail should be used instead of bottom navigation
  static bool useNavigationRail(BuildContext context) =>
      !isCompact(context);

  /// Check if navigation drawer should be permanent
  static bool usePermanentDrawer(BuildContext context) =>
      isExpanded(context);

  /// Get the number of columns for grid layouts
  static int getGridColumns(BuildContext context) {
    final sizeClass = getWindowSizeClass(context);
    return switch (sizeClass) {
      WindowSizeClass.compact => 1,
      WindowSizeClass.medium => 2,
      WindowSizeClass.expanded => 3,
      WindowSizeClass.large => 4,
      WindowSizeClass.extraLarge => 5,
    };
  }

  /// Get content padding based on window size
  static EdgeInsets getContentPadding(BuildContext context) {
    final sizeClass = getWindowSizeClass(context);
    return switch (sizeClass) {
      WindowSizeClass.compact => const EdgeInsets.all(16),
      WindowSizeClass.medium => const EdgeInsets.all(24),
      WindowSizeClass.expanded => const EdgeInsets.symmetric(
          horizontal: 32,
          vertical: 24,
        ),
      WindowSizeClass.large => const EdgeInsets.symmetric(
          horizontal: 48,
          vertical: 24,
        ),
      WindowSizeClass.extraLarge => const EdgeInsets.symmetric(
          horizontal: 64,
          vertical: 32,
        ),
    };
  }

  /// Get maximum content width for centered layouts
  static double? getMaxContentWidth(BuildContext context) {
    final sizeClass = getWindowSizeClass(context);
    return switch (sizeClass) {
      WindowSizeClass.compact => null,
      WindowSizeClass.medium => null,
      WindowSizeClass.expanded => 1040,
      WindowSizeClass.large => 1200,
      WindowSizeClass.extraLarge => 1400,
    };
  }

  /// Get the number of panes for master-detail layouts
  static int getPaneCount(BuildContext context) {
    final sizeClass = getWindowSizeClass(context);
    return switch (sizeClass) {
      WindowSizeClass.compact => 1,
      WindowSizeClass.medium => 1,
      WindowSizeClass.expanded => 2,
      WindowSizeClass.large => 2,
      WindowSizeClass.extraLarge => 2,
    };
  }
}

/// Widget that builds different layouts based on window size class
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context) compact;
  final Widget Function(BuildContext context)? medium;
  final Widget Function(BuildContext context)? expanded;
  final Widget Function(BuildContext context)? large;
  final Widget Function(BuildContext context)? extraLarge;

  const ResponsiveBuilder({
    super.key,
    required this.compact,
    this.medium,
    this.expanded,
    this.large,
    this.extraLarge,
  });

  @override
  Widget build(BuildContext context) {
    final sizeClass = ResponsiveLayout.getWindowSizeClass(context);

    return switch (sizeClass) {
      WindowSizeClass.extraLarge =>
        (extraLarge ?? large ?? expanded ?? medium ?? compact)(context),
      WindowSizeClass.large =>
        (large ?? expanded ?? medium ?? compact)(context),
      WindowSizeClass.expanded => (expanded ?? medium ?? compact)(context),
      WindowSizeClass.medium => (medium ?? compact)(context),
      WindowSizeClass.compact => compact(context),
    };
  }
}

/// Widget that constrains content to a maximum width and centers it
class ContentConstraint extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;

  const ContentConstraint({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth =
        maxWidth ?? ResponsiveLayout.getMaxContentWidth(context);
    final effectivePadding =
        padding ?? ResponsiveLayout.getContentPadding(context);

    Widget content = child;

    if (effectiveMaxWidth != null) {
      content = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
          child: content,
        ),
      );
    }

    return Padding(
      padding: effectivePadding,
      child: content,
    );
  }
}

/// Sliver version of ContentConstraint
class SliverContentConstraint extends StatelessWidget {
  final Widget sliver;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;

  const SliverContentConstraint({
    super.key,
    required this.sliver,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth =
        maxWidth ?? ResponsiveLayout.getMaxContentWidth(context);
    final effectivePadding =
        padding ?? ResponsiveLayout.getContentPadding(context);

    if (effectiveMaxWidth != null) {
      return SliverLayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.crossAxisExtent;
          final horizontalPadding = ((availableWidth - effectiveMaxWidth) / 2)
              .clamp(0.0, double.infinity);

          return SliverPadding(
            padding: effectivePadding.add(
              EdgeInsets.symmetric(horizontal: horizontalPadding),
            ),
            sliver: sliver,
          );
        },
      );
    }

    return SliverPadding(
      padding: effectivePadding,
      sliver: sliver,
    );
  }
}

/// Extension on EdgeInsetsGeometry for convenience
extension EdgeInsetsGeometryExtension on EdgeInsetsGeometry {
  EdgeInsetsGeometry add(EdgeInsetsGeometry other) {
    return this.add(other);
  }
}

/// Responsive grid delegate that adjusts columns based on screen size
class ResponsiveGridDelegate extends SliverGridDelegate {
  final double minCrossAxisExtent;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;

  const ResponsiveGridDelegate({
    this.minCrossAxisExtent = 300,
    this.mainAxisSpacing = 16,
    this.crossAxisSpacing = 16,
    this.childAspectRatio = 1.0,
  });

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final crossAxisCount =
        (constraints.crossAxisExtent / minCrossAxisExtent).ceil().clamp(1, 6);
    final usableCrossAxisExtent = constraints.crossAxisExtent -
        crossAxisSpacing * (crossAxisCount - 1);
    final childCrossAxisExtent = usableCrossAxisExtent / crossAxisCount;
    final childMainAxisExtent = childCrossAxisExtent / childAspectRatio;

    return SliverGridRegularTileLayout(
      crossAxisCount: crossAxisCount,
      mainAxisStride: childMainAxisExtent + mainAxisSpacing,
      crossAxisStride: childCrossAxisExtent + crossAxisSpacing,
      childMainAxisExtent: childMainAxisExtent,
      childCrossAxisExtent: childCrossAxisExtent,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(ResponsiveGridDelegate oldDelegate) {
    return oldDelegate.minCrossAxisExtent != minCrossAxisExtent ||
        oldDelegate.mainAxisSpacing != mainAxisSpacing ||
        oldDelegate.crossAxisSpacing != crossAxisSpacing ||
        oldDelegate.childAspectRatio != childAspectRatio;
  }
}

/// A scaffold that adapts to different screen sizes with proper navigation
class AdaptiveScaffold extends StatelessWidget {
  final Widget body;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? appBar;

  const AdaptiveScaffold({
    super.key,
    required this.body,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.floatingActionButton,
    this.appBar,
  });

  @override
  Widget build(BuildContext context) {
    final useRail = ResponsiveLayout.useNavigationRail(context);
    final usePermanent = ResponsiveLayout.usePermanentDrawer(context);
    final colorScheme = Theme.of(context).colorScheme;

    if (usePermanent) {
      // Large screens: Navigation drawer + body
      return Scaffold(
        appBar: appBar,
        body: Row(
          children: [
            NavigationDrawer(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              children: [
                const SizedBox(height: 16),
                ...destinations.map((dest) {
                  return NavigationDrawerDestination(
                    icon: dest.icon,
                    selectedIcon: dest.selectedIcon,
                    label: Text(dest.label),
                  );
                }),
                const SizedBox(height: 16),
              ],
            ),
            Expanded(child: body),
          ],
        ),
        floatingActionButton: floatingActionButton,
      );
    } else if (useRail) {
      // Medium screens: Navigation rail + body
      return Scaffold(
        appBar: appBar,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              backgroundColor: colorScheme.surface,
              destinations: destinations
                  .map(
                    (dest) => NavigationRailDestination(
                      icon: dest.icon,
                      selectedIcon: dest.selectedIcon,
                      label: Text(dest.label),
                    ),
                  )
                  .toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: body),
          ],
        ),
        floatingActionButton: floatingActionButton,
      );
    } else {
      // Compact screens: Bottom navigation
      return Scaffold(
        appBar: appBar,
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: destinations,
        ),
        floatingActionButton: floatingActionButton,
      );
    }
  }
}
