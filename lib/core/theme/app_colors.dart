/// Palette de couleurs d'Eurêka.
library;

import 'package:flutter/material.dart';

/// Couleurs de marque et neutres, en clair et en sombre.
///
/// Les couleurs ne sont jamais utilisées directement dans les écrans : elles
/// alimentent [ThemeData] et [AppTokens] (voir `app_theme.dart`), ce qui garantit
/// qu'un même composant s'adapte automatiquement au thème sombre.
abstract final class AppColors {
  // ---------------------------------------------------------------- Marque

  /// Bleu-violet Eurêka : actions principales, éléments actifs.
  static const Color brand = Color(0xFF4C6FFF);
  static const Color brandDeep = Color(0xFF3550D8);
  static const Color brandSoft = Color(0xFFE8EDFF);
  static const Color brandSoftDark = Color(0xFF1C2746);

  /// Or : expérience gagnée, récompenses, séries.
  static const Color gold = Color(0xFFFFB020);
  static const Color goldSoft = Color(0xFFFFF2D6);

  // ------------------------------------------------------------- Sémantique

  static const Color success = Color(0xFF16A96A);
  static const Color successSoft = Color(0xFFDFF6EB);
  static const Color successSoftDark = Color(0xFF123428);

  static const Color error = Color(0xFFE5484D);
  static const Color errorSoft = Color(0xFFFDE8E8);
  static const Color errorSoftDark = Color(0xFF3A1A1C);

  static const Color warning = Color(0xFFF5A524);
  static const Color info = Color(0xFF0EA5E9);

  // --------------------------------------------------------- Neutres clairs

  static const Color bgLight = Color(0xFFF4F6FB);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceAltLight = Color(0xFFEDF1F8);
  static const Color borderLight = Color(0xFFDDE4F0);
  static const Color inkLight = Color(0xFF101624);
  static const Color inkMutedLight = Color(0xFF566079);
  static const Color inkSubtleLight = Color(0xFF8A93A8);

  // -------------------------------------------------------- Neutres sombres

  static const Color bgDark = Color(0xFF0C1018);
  static const Color surfaceDark = Color(0xFF151B26);
  static const Color surfaceAltDark = Color(0xFF1E2634);
  static const Color borderDark = Color(0xFF2B3444);
  static const Color inkDark = Color(0xFFF2F5FA);
  static const Color inkMutedDark = Color(0xFFA8B2C5);
  static const Color inkSubtleDark = Color(0xFF76819A);
}

/// Jeu de couleurs attaché à une matière.
///
/// Chaque matière a sa propre identité chromatique : l'élève reconnaît
/// « sa » couleur avant même de lire le titre de l'écran.
@immutable
class SubjectPalette {
  const SubjectPalette({
    required this.base,
    required this.gradientEnd,
    required this.tintLight,
    required this.tintDark,
  });

  /// Couleur pleine : icônes, anneaux de progression, accents.
  final Color base;

  /// Fin du dégradé des grandes tuiles de matière.
  final Color gradientEnd;

  /// Fond très clair pour les surfaces teintées en thème clair.
  final Color tintLight;

  /// Équivalent en thème sombre.
  final Color tintDark;

  /// Dégradé de la tuile de matière, en diagonale.
  LinearGradient get gradient => LinearGradient(
    colors: [base, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Fond teinté adapté au thème courant.
  Color tint(Brightness brightness) =>
      brightness == Brightness.dark ? tintDark : tintLight;
}

/// Palettes par identifiant de matière, telles qu'écrites dans `catalog.json`.
abstract final class SubjectPalettes {
  static const SubjectPalette maths = SubjectPalette(
    base: Color(0xFF5B5BD6),
    gradientEnd: Color(0xFF8E7BFF),
    tintLight: Color(0xFFEDEDFD),
    tintDark: Color(0xFF1E1E3C),
  );

  static const SubjectPalette physiqueChimie = SubjectPalette(
    base: Color(0xFFF2762E),
    gradientEnd: Color(0xFFFFAE5B),
    tintLight: Color(0xFFFEF0E5),
    tintDark: Color(0xFF34210F),
  );

  static const SubjectPalette informatique = SubjectPalette(
    base: Color(0xFF0E9C9C),
    gradientEnd: Color(0xFF42CFC4),
    tintLight: Color(0xFFE3F6F5),
    tintDark: Color(0xFF0D2A2A),
  );

  static const SubjectPalette svt = SubjectPalette(
    base: Color(0xFF2FA85A),
    gradientEnd: Color(0xFF6ED98B),
    tintLight: Color(0xFFE6F6EB),
    tintDark: Color(0xFF112D1C),
  );

  /// Palette de repli, pour une matière ajoutée au catalogue sans palette.
  static const SubjectPalette fallback = SubjectPalette(
    base: AppColors.brand,
    gradientEnd: Color(0xFF8AA3FF),
    tintLight: AppColors.brandSoft,
    tintDark: AppColors.brandSoftDark,
  );

  static const Map<String, SubjectPalette> _byId = {
    'maths': maths,
    'physique-chimie': physiqueChimie,
    'informatique': informatique,
    'svt': svt,
  };

  /// Palette d'une matière, ou [fallback] si l'identifiant est inconnu.
  static SubjectPalette of(String subjectId) => _byId[subjectId] ?? fallback;
}

/// Couleurs des quatre niveaux scolaires.
abstract final class LevelColors {
  static const Color primaire = Color(0xFFF2709C);
  static const Color college = Color(0xFF3FA9F5);
  static const Color lycee = Color(0xFF8B5CF6);
  static const Color universite = Color(0xFFD9A325);
}
