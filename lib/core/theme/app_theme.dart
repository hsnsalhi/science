/// Assemblage des [ThemeData] clair et sombre.
library;

import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_tokens.dart';
import 'app_typography.dart';

/// Thèmes de l'application.
///
/// Un seul endroit décide de l'apparence par défaut de chaque composant
/// Material, pour que les écrans n'aient presque jamais à styliser quoi que
/// ce soit eux-mêmes.
abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final AppTokens tokens = isDark ? AppTokens.dark : AppTokens.light;

    final Color bg = isDark ? AppColors.bgDark : AppColors.bgLight;
    final Color surface = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final Color ink = isDark ? AppColors.inkDark : AppColors.inkLight;
    final Color brand = isDark ? const Color(0xFF7D95FF) : AppColors.brand;

    final ColorScheme scheme = ColorScheme(
      brightness: brightness,
      primary: brand,
      onPrimary: isDark ? const Color(0xFF0B1024) : Colors.white,
      primaryContainer: tokens.brandSoft,
      onPrimaryContainer: isDark
          ? const Color(0xFFD7E0FF)
          : AppColors.brandDeep,
      secondary: tokens.gold,
      onSecondary: const Color(0xFF3A2606),
      secondaryContainer: tokens.goldSoft,
      onSecondaryContainer: isDark ? tokens.gold : const Color(0xFF6B4A05),
      error: tokens.error,
      onError: Colors.white,
      errorContainer: tokens.errorSoft,
      onErrorContainer: isDark ? tokens.error : const Color(0xFF8C1D21),
      surface: surface,
      onSurface: ink,
      surfaceContainerLowest: surface,
      surfaceContainerLow: bg,
      surfaceContainer: tokens.surfaceAlt,
      surfaceContainerHigh: tokens.surfaceAlt,
      surfaceContainerHighest: tokens.surfaceAlt,
      onSurfaceVariant: tokens.inkMuted,
      outline: tokens.border,
      outlineVariant: tokens.border,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: ink,
      onInverseSurface: surface,
      inversePrimary: brand,
    );

    final TextTheme textTheme = AppTypography.textTheme(ink, tokens.inkMuted);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      textTheme: textTheme,
      fontFamily: AppTypography.body,
      fontFamilyFallback: AppTypography.replis,
      extensions: <ThemeExtension<dynamic>>[tokens],
      splashFactory: InkSparkle.splashFactory,
      // Les interactions de l'application sont animées à la main (enfoncement,
      // rebond) ; la surbrillance Material par-dessus ferait double emploi.
      highlightColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall,
        iconTheme: IconThemeData(color: ink, size: 24),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.border,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: ink, size: 24),
      chipTheme: ChipThemeData(
        backgroundColor: tokens.surfaceAlt,
        side: BorderSide.none,
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        shape: const StadiumBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: tokens.inkSubtle),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: tokens.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: brand, width: 2),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.xl),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: tokens.border,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: surface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: brand,
        inactiveTrackColor: tokens.surfaceAlt,
        thumbColor: brand,
        overlayColor: brand.withValues(alpha: 0.12),
        trackHeight: 8,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : (isDark ? tokens.inkSubtle : Colors.white),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? brand : tokens.surfaceAlt,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : tokens.border,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: tokens.brandSoft,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelSmall),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 26,
            color: states.contains(WidgetState.selected)
                ? brand
                : tokens.inkSubtle,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: tokens.brandSoft,
        selectedIconTheme: IconThemeData(color: brand, size: 28),
        unselectedIconTheme: IconThemeData(color: tokens.inkSubtle, size: 26),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(color: brand),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: tokens.inkMuted,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: brand,
        linearTrackColor: tokens.surfaceAlt,
        circularTrackColor: tokens.surfaceAlt,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: ink,
          borderRadius: BorderRadius.circular(AppRadii.xs),
        ),
        textStyle: textTheme.labelMedium?.copyWith(color: surface),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
