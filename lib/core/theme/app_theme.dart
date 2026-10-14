import 'package:flutter/material.dart';

import '../models/app_models.dart';
import 'siqi_design.dart';

abstract final class AppTheme {
  static ThemeData light(AppSettings settings) =>
      _build(settings, Brightness.light);
  static ThemeData dark(AppSettings settings) =>
      _build(settings, Brightness.dark);

  static ThemeData _build(AppSettings settings, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final seeded = ColorScheme.fromSeed(
      seedColor: Color(settings.seedColor),
      brightness: brightness,
      contrastLevel: 0,
    );
    final colors = seeded.copyWith(
      primary: dark ? const Color(0xFFF3F4F6) : const Color(0xFF17191E),
      onPrimary: dark ? const Color(0xFF17191E) : Colors.white,
      primaryContainer: dark
          ? const Color(0xFF2A2D34)
          : const Color(0xFFE6E8ED),
      onPrimaryContainer: dark ? Colors.white : const Color(0xFF17191E),
      secondary: dark ? const Color(0xFFCED1D8) : const Color(0xFF4C5059),
      onSecondary: dark ? const Color(0xFF17191E) : Colors.white,
      secondaryContainer: dark
          ? const Color(0xFF24272E)
          : const Color(0xFFEDF0F4),
      onSecondaryContainer: dark ? Colors.white : const Color(0xFF17191E),
      tertiary: dark ? const Color(0xFFD9DCE2) : const Color(0xFF50545D),
      tertiaryContainer: dark
          ? const Color(0xFF24272E)
          : const Color(0xFFEDF0F4),
      onTertiaryContainer: dark ? Colors.white : const Color(0xFF17191E),
      outline: dark ? const Color(0xFF727781) : const Color(0xFF858A94),
      outlineVariant: dark ? const Color(0xFF30343C) : const Color(0xFFDEE1E6),
      surfaceTint: Colors.transparent,
      onSurface: dark ? const Color(0xFFF1F2F4) : const Color(0xFF191B20),
      onSurfaceVariant: dark
          ? const Color(0xFFBBC0C9)
          : const Color(0xFF555B66),
      surface: dark ? const Color(0xFF08090C) : const Color(0xFFF7F8FA),
      surfaceContainerLowest: dark ? const Color(0xFF101216) : Colors.white,
      surfaceContainer: dark
          ? const Color(0xFF17191E)
          : const Color(0xFFF0F2F5),
      surfaceContainerLow: dark
          ? const Color(0xFF14161B)
          : const Color(0xFFF4F5F7),
      surfaceContainerHigh: dark
          ? const Color(0xFF1C1F25)
          : const Color(0xFFEDEFF3),
      surfaceContainerHighest: dark
          ? const Color(0xFF202329)
          : const Color(0xFFE9ECF0),
    );
    final textTheme =
        (dark
                ? Typography.material2021(
                    platform: TargetPlatform.android,
                  ).white
                : Typography.material2021(
                    platform: TargetPlatform.android,
                  ).black)
            .copyWith(
              titleLarge: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
              titleMedium: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              titleSmall: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            )
            .apply(
              bodyColor: dark
                  ? const Color(0xFFF1F2F4)
                  : const Color(0xFF191B20),
              displayColor: dark
                  ? const Color(0xFFF1F2F4)
                  : const Color(0xFF191B20),
            );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(SiqiRadius.surface),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surface,
      canvasColor: colors.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        surfaceTintColor: colors.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SiqiRadius.surface),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          backgroundColor: colors.surfaceContainerHighest,
          foregroundColor: colors.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SiqiRadius.surface),
          ),
          minimumSize: const Size(48, 48),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: colors.surfaceContainerLowest,
        indicatorColor: colors.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      navigationRailTheme: NavigationRailThemeData(
        elevation: 0,
        backgroundColor: colors.surfaceContainerLowest,
        indicatorColor: colors.primaryContainer,
        labelType: NavigationRailLabelType.all,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colors.surfaceContainerLowest,
        surfaceTintColor: colors.surfaceTint,
        clipBehavior: Clip.antiAlias,
        shape: shape,
      ),
      dialogTheme: DialogThemeData(
        elevation: 8,
        backgroundColor: colors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: shape,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: colors.surfaceContainerLowest,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(SiqiRadius.surface),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SiqiRadius.surface),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SiqiRadius.surface),
          borderSide: BorderSide(color: colors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SiqiRadius.surface),
          borderSide: BorderSide(color: colors.primary, width: 1.6),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceContainer,
        side: BorderSide(color: colors.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SiqiRadius.surface),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SiqiRadius.surface),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SiqiRadius.surface),
          ),
        ),
      ),
      sliderTheme: const SliderThemeData(
        trackHeight: 3,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 18),
      ),
    );
  }
}

class MaterialSurface extends StatelessWidget {
  const MaterialSurface({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = SiqiRadius.surface,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: child,
    );
  }
}
