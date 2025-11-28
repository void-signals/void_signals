import 'package:flutter/material.dart';

/// Material Design 3 Expressive theme for the app
class AppTheme {
  AppTheme._();

  // Expressive color scheme - vibrant and playful
  static const _seedColor = Color(0xFF6750A4); // Deep purple
  static const _secondaryColor = Color(0xFF00BCD4); // Cyan
  static const _tertiaryColor = Color(0xFFFF9800); // Orange

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      secondary: _secondaryColor,
      tertiary: _tertiaryColor,
      brightness: Brightness.light,
      dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
    );

    return _buildTheme(colorScheme, Brightness.light);
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      secondary: _secondaryColor,
      tertiary: _tertiaryColor,
      brightness: Brightness.dark,
      dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
    );

    return _buildTheme(colorScheme, Brightness.dark);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,

      // Visual density for different platforms
      visualDensity: VisualDensity.adaptivePlatformDensity,

      // Expressive typography with better scaling
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.25,
          height: 1.12,
        ),
        displayMedium: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w400,
          height: 1.16,
        ),
        displaySmall: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w400,
          height: 1.22,
        ),
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          height: 1.25,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          height: 1.29,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          height: 1.33,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          height: 1.27,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
          height: 1.5,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          height: 1.43,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          height: 1.43,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
          height: 1.33,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          height: 1.43,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          height: 1.33,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          height: 1.45,
        ),
      ),

      // Expressive app bar with better elevation handling
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: colorScheme.surfaceTint,
      ),

      // Expressive cards with rounded corners
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: colorScheme.outlineVariant.withAlpha((0.5 * 255).round()),
          ),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        color: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
      ),

      // Expressive chips
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),

      // Expressive floating action button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 3,
        highlightElevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // Expressive filled buttons
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          minimumSize: const Size(64, 48),
        ),
      ),

      // Expressive outlined buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          minimumSize: const Size(64, 48),
        ),
      ),

      // Expressive text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(48, 40),
        ),
      ),

      // Expressive input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withAlpha(
          (0.5 * 255).round(),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),

      // Navigation bar for bottom navigation
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        indicatorColor: colorScheme.secondaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),

      // Navigation rail for tablet/desktop
      navigationRailTheme: NavigationRailThemeData(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        indicatorColor: colorScheme.secondaryContainer,
        selectedIconTheme:
            IconThemeData(color: colorScheme.onSecondaryContainer),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
        selectedLabelTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      // Navigation drawer for large screens
      navigationDrawerTheme: NavigationDrawerThemeData(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        indicatorColor: colorScheme.secondaryContainer,
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // Bottom sheet
      bottomSheetTheme: BottomSheetThemeData(
        showDragHandle: true,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        dragHandleColor:
            colorScheme.onSurfaceVariant.withAlpha((0.4 * 255).round()),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        elevation: 6,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isDark ? colorScheme.inverseSurface : colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      // Search bar
      searchBarTheme: SearchBarThemeData(
        elevation: WidgetStateProperty.all(0),
        backgroundColor:
            WidgetStateProperty.all(colorScheme.surfaceContainerHigh),
        surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),

      // Search view
      searchViewTheme: SearchViewThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),

      // List tile
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      // Progress indicator
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.primaryContainer,
        circularTrackColor: colorScheme.primaryContainer,
      ),

      // Tooltip
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(
          color: colorScheme.onInverseSurface,
          fontSize: 12,
        ),
      ),

      // Badge
      badgeTheme: BadgeThemeData(
        backgroundColor: colorScheme.error,
        textColor: colorScheme.onError,
      ),

      // Icon button
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Page transitions - expressive animations with platform awareness
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
          TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
        },
      ),

      // Scrollbar
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(
          colorScheme.onSurfaceVariant.withAlpha((0.5 * 255).round()),
        ),
        radius: const Radius.circular(8),
        thickness: WidgetStateProperty.all(8),
        interactive: true,
      ),

      // Expansion tile
      expansionTileTheme: ExpansionTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: colorScheme.surfaceContainerLow,
        collapsedBackgroundColor: Colors.transparent,
      ),

      // Popup menu
      popupMenuTheme: PopupMenuThemeData(
        elevation: 3,
        color: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Dropdown menu
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withAlpha(
            (0.5 * 255).round(),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),

      // Menu button
      menuButtonTheme: MenuButtonThemeData(
        style: MenuItemButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // Menu
      menuTheme: MenuThemeData(
        style: MenuStyle(
          elevation: WidgetStateProperty.all(3),
          backgroundColor: WidgetStateProperty.all(colorScheme.surface),
          surfaceTintColor: WidgetStateProperty.all(colorScheme.surfaceTint),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),

      // Tab bar
      tabBarTheme: TabBarThemeData(
        indicatorColor: colorScheme.primary,
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        dividerColor: colorScheme.outlineVariant,
        indicatorSize: TabBarIndicatorSize.label,
      ),

      // Segmented button
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}
