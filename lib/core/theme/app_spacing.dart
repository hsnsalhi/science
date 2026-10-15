/// Échelle d'espacement, de rayons et de durées.
///
/// Toute valeur de mise en page de l'application sort d'ici : c'est ce qui
/// donne à Eurêka son rythme visuel régulier. Une valeur numérique écrite
/// directement dans un widget est un bug de design.
library;

import 'package:flutter/animation.dart';

/// Espacements, sur une base de 4.
abstract final class AppSpacing {
  /// 2 — séparation de deux éléments collés (icône / texte d'un chip).
  static const double xxs = 2;

  /// 4 — interligne d'un groupe serré.
  static const double xs = 4;

  /// 8 — espace entre deux éléments d'un même bloc.
  static const double sm = 8;

  /// 12 — rembourrage interne d'un petit composant.
  static const double md = 12;

  /// 16 — rembourrage standard, marge d'écran sur téléphone.
  static const double lg = 16;

  /// 24 — séparation de deux blocs de contenu.
  static const double xl = 24;

  /// 32 — séparation de deux sections.
  static const double xxl = 32;

  /// 48 — respiration d'en-tête / de pied d'écran.
  static const double xxxl = 48;

  /// Marge horizontale d'écran selon la classe de largeur.
  static const double screenCompact = 16;
  static const double screenMedium = 24;
  static const double screenExpanded = 32;
}

/// Rayons de coin.
abstract final class AppRadii {
  /// 8 — petits éléments (badge, puce).
  static const double xs = 8;

  /// 12 — champs, petits boutons.
  static const double sm = 12;

  /// 16 — boutons, options de réponse.
  static const double md = 16;

  /// 22 — cartes.
  static const double lg = 22;

  /// 28 — grandes cartes, feuilles modales.
  static const double xl = 28;

  /// Entièrement arrondi.
  static const double pill = 999;
}

/// Durées d'animation.
///
/// Les valeurs sont volontairement courtes : une interface destinée à un
/// enfant de primaire doit répondre immédiatement, l'animation souligne
/// l'action, elle ne la fait pas attendre.
abstract final class AppDurations {
  /// 120 ms — retour tactile (enfoncement d'un bouton).
  static const Duration instant = Duration(milliseconds: 120);

  /// 180 ms — changement d'état d'un composant.
  static const Duration fast = Duration(milliseconds: 180);

  /// 280 ms — transition d'écran, apparition de contenu.
  static const Duration base = Duration(milliseconds: 280);

  /// 450 ms — révélation enchaînée, barre de progression.
  static const Duration slow = Duration(milliseconds: 450);

  /// 1200 ms — célébration de fin de leçon.
  static const Duration celebration = Duration(milliseconds: 1200);
}

/// Courbes d'animation.
abstract final class AppCurves {
  /// Entrée d'un élément : rapide puis ralentit.
  static const Curve enter = Curves.easeOutCubic;

  /// Sortie d'un élément.
  static const Curve exit = Curves.easeInCubic;

  /// Rebond discret pour les récompenses.
  static const Curve pop = Curves.easeOutBack;

  /// Déplacement d'un élément déjà visible.
  static const Curve move = Curves.easeInOutCubic;
}
