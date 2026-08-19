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
      surface: dark ? const Color(0xFF111318) : const Color(0xFFF9F9FC),
      surfaceContainerLowest: dark ? const Color(0xFF0C0E13) : Colors.white,
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
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 3,
        centerTitle: false,
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        surfaceTintColor: colors.surfaceTint,
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
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
