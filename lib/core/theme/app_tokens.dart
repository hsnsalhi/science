/// Jetons de design qui n'ont pas d'équivalent dans [ColorScheme].
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Couleurs et ombres propres à Eurêka, transportées par le thème.
///
/// Material ne prévoit pas de place pour « le vert de réponse juste » ou
/// « l'or de l'XP ». Les mettre dans une [ThemeExtension] plutôt que dans des
/// constantes globales permet à un même widget de basculer en thème sombre
/// sans une seule condition `if (isDark)` dans le code des écrans.
///
/// Usage : `context.tokens.success`.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.surfaceAlt,
    required this.border,
    required this.inkMuted,
    required this.inkSubtle,
    required this.success,
    required this.successSoft,
    required this.error,
    required this.errorSoft,
    required this.warning,
    required this.info,
    required this.gold,
    required this.goldSoft,
    required this.brandSoft,
    required this.cardShadow,
    required this.floatingShadow,
  });

  /// Surface secondaire : fond d'un champ, d'une pastille, d'une piste de barre.
  final Color surfaceAlt;

  /// Trait de séparation et contour des cartes.
  final Color border;

  /// Texte secondaire (sous-titres, légendes).
  final Color inkMuted;

  /// Texte tertiaire (métadonnées, états désactivés).
  final Color inkSubtle;

  final Color success;
  final Color successSoft;
  final Color error;
  final Color errorSoft;
  final Color warning;
  final Color info;

  /// Or de l'expérience et des séries.
  final Color gold;
  final Color goldSoft;

  /// Fond teinté de la couleur de marque.
  final Color brandSoft;

  /// Ombre douce des cartes posées.
  final List<BoxShadow> cardShadow;

  /// Ombre des éléments flottants (boutons d'action, feuilles).
  final List<BoxShadow> floatingShadow;

  static const AppTokens light = AppTokens(
    surfaceAlt: AppColors.surfaceAltLight,
    border: AppColors.borderLight,
    inkMuted: AppColors.inkMutedLight,
    inkSubtle: AppColors.inkSubtleLight,
    success: AppColors.success,
    successSoft: AppColors.successSoft,
    error: AppColors.error,
    errorSoft: AppColors.errorSoft,
    warning: AppColors.warning,
    info: AppColors.info,
    gold: AppColors.gold,
    goldSoft: AppColors.goldSoft,
    brandSoft: AppColors.brandSoft,
    cardShadow: [
      BoxShadow(color: Color(0x14101624), blurRadius: 18, offset: Offset(0, 6)),
    ],
    floatingShadow: [
      BoxShadow(
        color: Color(0x24101624),
        blurRadius: 28,
        offset: Offset(0, 12),
      ),
    ],
  );

  static const AppTokens dark = AppTokens(
    surfaceAlt: AppColors.surfaceAltDark,
    border: AppColors.borderDark,
    inkMuted: AppColors.inkMutedDark,
    inkSubtle: AppColors.inkSubtleDark,
    success: Color(0xFF34C98A),
    successSoft: AppColors.successSoftDark,
    error: Color(0xFFFF6369),
    errorSoft: AppColors.errorSoftDark,
    warning: Color(0xFFFFB84D),
    info: Color(0xFF38BDF8),
    gold: Color(0xFFFFC44D),
    goldSoft: Color(0xFF3A2D10),
    brandSoft: AppColors.brandSoftDark,
    // En thème sombre, l'ombre portée ne se voit pas : on garde une ombre
    // très discrète pour la profondeur et on s'appuie sur `border`.
    cardShadow: [
      BoxShadow(color: Color(0x40000000), blurRadius: 14, offset: Offset(0, 4)),
    ],
    floatingShadow: [
      BoxShadow(
        color: Color(0x66000000),
        blurRadius: 24,
        offset: Offset(0, 10),
      ),
    ],
  );

  @override
  AppTokens copyWith({
    Color? surfaceAlt,
    Color? border,
    Color? inkMuted,
    Color? inkSubtle,
    Color? success,
    Color? successSoft,
    Color? error,
    Color? errorSoft,
    Color? warning,
    Color? info,
    Color? gold,
    Color? goldSoft,
    Color? brandSoft,
    List<BoxShadow>? cardShadow,
    List<BoxShadow>? floatingShadow,
  }) {
    return AppTokens(
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      border: border ?? this.border,
      inkMuted: inkMuted ?? this.inkMuted,
      inkSubtle: inkSubtle ?? this.inkSubtle,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      error: error ?? this.error,
      errorSoft: errorSoft ?? this.errorSoft,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      gold: gold ?? this.gold,
      goldSoft: goldSoft ?? this.goldSoft,
      brandSoft: brandSoft ?? this.brandSoft,
      cardShadow: cardShadow ?? this.cardShadow,
      floatingShadow: floatingShadow ?? this.floatingShadow,
    );
  }

  @override
  AppTokens lerp(AppTokens? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppTokens(
      surfaceAlt: c(surfaceAlt, other.surfaceAlt),
      border: c(border, other.border),
      inkMuted: c(inkMuted, other.inkMuted),
      inkSubtle: c(inkSubtle, other.inkSubtle),
      success: c(success, other.success),
      successSoft: c(successSoft, other.successSoft),
      error: c(error, other.error),
      errorSoft: c(errorSoft, other.errorSoft),
      warning: c(warning, other.warning),
      info: c(info, other.info),
      gold: c(gold, other.gold),
      goldSoft: c(goldSoft, other.goldSoft),
      brandSoft: c(brandSoft, other.brandSoft),
      cardShadow: BoxShadow.lerpList(cardShadow, other.cardShadow, t)!,
      floatingShadow: BoxShadow.lerpList(
        floatingShadow,
        other.floatingShadow,
        t,
      )!,
    );
  }
}

/// Raccourcis de lecture du thème, pour éviter `Theme.of(context)` partout.
extension AppThemeContext on BuildContext {
  /// Jetons Eurêka du thème courant.
  AppTokens get tokens =>
      Theme.of(this).extension<AppTokens>() ?? AppTokens.light;

  /// Jeu de couleurs Material du thème courant.
  ColorScheme get colors => Theme.of(this).colorScheme;

  /// Échelle typographique du thème courant.
  TextTheme get text => Theme.of(this).textTheme;

  /// `true` si le thème courant est sombre.
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
