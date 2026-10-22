/// Échelle typographique d'Eurêka.
library;

import 'package:flutter/material.dart';

/// Construit l'échelle typographique de l'application.
///
/// Deux familles, embarquées dans l'APK (aucun téléchargement à l'exécution) :
///
/// * **Baloo 2** — titres. Arrondie et chaleureuse, elle donne le ton « jeu »
///   sans tomber dans l'enfantin, ce qui compte quand la même application
///   sert un élève de CE1 et un étudiant de licence.
/// * **Nunito** — texte courant. Très lisible en petit corps, avec des formes
///   ouvertes qui limitent les confusions de lettres.
///
/// Ce sont des polices **variables** : un seul fichier contient tout l'axe de
/// graisse. Flutter n'applique pas toujours `fontWeight` à l'axe `wght` d'une
/// police variable, donc chaque style déclare explicitement une
/// [FontVariation] — c'est la raison d'être de [_style].
///
/// Deux polices de **repli** complètent les deux premières, glyphe par
/// glyphe. Ni Nunito ni Baloo 2 ne contiennent l'alphabet grec : elles
/// n'ont que les cinq symboles mathématiques d'usage courant (pi, delta,
/// sigma, oméga et le micro). Un caractère absent ne provoque aucune
/// erreur — il est dessiné en rectangle vide chez l'élève — et un cours
/// de physique qui ne peut écrire ni lambda, ni thêta, ni oméga n'est pas
/// un cours de physique. Voir `assets/fonts/README.md`.
abstract final class AppTypography {
  static const String display = 'Baloo2';
  static const String body = 'Nunito';

  /// Les polices consultées, dans l'ordre, quand la famille principale
  /// n'a pas le glyphe demandé.
  ///
  /// Le grec vient d'une police de texte et non d'une police de symboles,
  /// pour qu'un lambda au milieu d'une phrase reste une lettre et non un
  /// pictogramme. Les opérateurs viennent ensuite, parce qu'eux n'existent
  /// nulle part ailleurs.
  static const List<String> replis = <String>['NotoSansGrec', 'NotoSansMath'];

  /// Fabrique un style en synchronisant [FontWeight] et l'axe `wght`.
  static TextStyle _style({
    required String family,
    required double size,
    required int weight,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: family,
      fontFamilyFallback: replis,
      fontSize: size,
      // Les deux sont nécessaires : `fontWeight` pour le repli et la
      // sémantique, `fontVariations` pour le rendu réel de la police variable.
      fontWeight: FontWeight.values[(weight ~/ 100) - 1],
      fontVariations: [FontVariation('wght', weight.toDouble())],
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Échelle complète, appliquée au [ThemeData].
  ///
  /// Les hauteurs de ligne des styles de corps (1,5) sont volontairement
  /// généreuses : un énoncé d'exercice se lit en plusieurs lignes.
  static TextTheme textTheme(Color ink, Color inkMuted) {
    final TextTheme theme = TextTheme(
      // Titres d'accueil et de célébration.
      displayLarge: _style(
        family: display,
        size: 40,
        weight: 800,
        height: 1.1,
        letterSpacing: -0.5,
      ),
      displayMedium: _style(
        family: display,
        size: 32,
        weight: 800,
        height: 1.15,
        letterSpacing: -0.3,
      ),
      displaySmall: _style(family: display, size: 28, weight: 700, height: 1.2),
      // Titres d'écran et de section.
      headlineLarge: _style(
        family: display,
        size: 25,
        weight: 700,
        height: 1.25,
      ),
      headlineMedium: _style(
        family: display,
        size: 22,
        weight: 700,
        height: 1.3,
      ),
      headlineSmall: _style(
        family: display,
        size: 19,
        weight: 600,
        height: 1.3,
      ),
      // Titres de carte.
      titleLarge: _style(family: body, size: 19, weight: 800, height: 1.3),
      titleMedium: _style(family: body, size: 16, weight: 700, height: 1.35),
      titleSmall: _style(family: body, size: 14, weight: 700, height: 1.35),
      // Texte courant.
      bodyLarge: _style(family: body, size: 17, weight: 400, height: 1.5),
      bodyMedium: _style(family: body, size: 15, weight: 400, height: 1.5),
      bodySmall: _style(family: body, size: 13, weight: 400, height: 1.45),
      // Étiquettes : boutons, badges, onglets.
      labelLarge: _style(
        family: body,
        size: 16,
        weight: 800,
        letterSpacing: 0.1,
      ),
      labelMedium: _style(
        family: body,
        size: 13,
        weight: 700,
        letterSpacing: 0.2,
      ),
      labelSmall: _style(
        family: body,
        size: 11,
        weight: 700,
        letterSpacing: 0.4,
      ),
    );

    return theme
        .apply(bodyColor: ink, displayColor: ink)
        .copyWith(
          bodySmall: theme.bodySmall?.copyWith(color: inkMuted),
          labelSmall: theme.labelSmall?.copyWith(color: inkMuted),
        );
  }

  /// Style des formules et du code : chiffres de largeur fixe pour que
  /// `a² + b² = c²` ne danse pas d'une carte à l'autre.
  static TextStyle formula({required double size, required Color color}) {
    return _style(family: body, size: size, weight: 700, height: 1.4).copyWith(
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}
