/// Pilotage automatique des figures, pour la lecture en fil.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/motion/app_motion.dart';

/// L'horloge de la scène, posée au-dessus de la figure à l'affiche.
///
/// Une figure manipulable attend qu'on la manipule : présentée dans un fil
/// qu'on fait défiler au pouce, elle resterait immobile le temps qu'on lit
/// la légende, et le cours redeviendrait du texte illustré. L'horloge lui
/// donne de quoi se jouer toute seule — le curseur balaie, les options
/// défilent — jusqu'à ce qu'un doigt la touche, moment où elle rend la
/// main pour de bon.
///
/// Rien n'oblige une figure à la lire. Celle qui l'ignore ne s'abonne pas,
/// donc ne se reconstruit pas à chaque image : le coût est payé par les
/// seules figures qui s'animent.
@immutable
class FigureStage extends InheritedWidget {
  const FigureStage({
    required this.phase,
    required this.actif,
    required super.child,
    super.key,
  });

  /// Position dans le cycle, de 0 inclus à 1 exclu.
  final double phase;

  /// `false` quand la figure est hors champ : une figure qui porte son
  /// propre `AnimationController` doit alors se mettre en pause.
  final bool actif;

  static FigureStage? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FigureStage>();

  @override
  bool updateShouldNotify(FigureStage old) =>
      old.phase != phase || old.actif != actif;
}

/// Lecture de l'horloge, et formes d'animation prêtes à l'emploi.
///
/// Toutes les fonctions renvoient `null` hors d'une scène, et `null` aussi
/// quand l'élève a demandé moins d'animations : la figure garde alors sa
/// valeur de départ, et reste manipulable à la main. C'est voulu — le
/// réglage de confort ne doit pas priver du contenu, seulement du
/// mouvement.
abstract final class Autoplay {
  /// Position brute dans le cycle, ou `null` si la figure n'est pas pilotée.
  static double? phase(BuildContext context) {
    if (context.reduceMotion) return null;
    return FigureStage.maybeOf(context)?.phase;
  }

  /// `true` si la figure est à l'affiche. Vrai hors scène : une figure
  /// ouverte seule, hors du fil, n'a pas à se mettre en pause.
  static bool actif(BuildContext context) =>
      FigureStage.maybeOf(context)?.actif ?? true;

  /// Balayage aller-retour adouci, de [min] à [max] et retour.
  ///
  /// Part de [min], atteint [max] au milieu du cycle. Le cosinus donne un
  /// arrêt net aux deux bouts : un curseur qui ralentit avant de repartir
  /// se lit comme une main qui hésite, et pas comme une machine.
  static double? sweep(
    BuildContext context, {
    required double min,
    required double max,
    int cycles = 1,
    double decalage = 0,
  }) {
    final double? p = phase(context);
    if (p == null) return null;
    final double t = (p * cycles + decalage) % 1;
    return min + (max - min) * (0.5 - 0.5 * math.cos(2 * math.pi * t));
  }

  /// Même balayage, arrondi à un pas.
  static double? sweepPas(
    BuildContext context, {
    required double min,
    required double max,
    required double pas,
    int cycles = 1,
    double decalage = 0,
  }) {
    final double? v = sweep(
      context,
      min: min,
      max: max,
      cycles: cycles,
      decalage: decalage,
    );
    if (v == null) return null;
    return (min + ((v - min) / pas).roundToDouble() * pas).clamp(min, max);
  }

  /// Entier balayé aller-retour, bornes incluses.
  static int? sweepEntier(
    BuildContext context, {
    required int min,
    required int max,
    int cycles = 1,
    double decalage = 0,
  }) {
    final double? v = sweep(
      context,
      min: min.toDouble(),
      max: max.toDouble(),
      cycles: cycles,
      decalage: decalage,
    );
    return v?.round().clamp(min, max);
  }

  /// Index qui défile sur [count] options, chacune tenue le même temps.
  static int? index(BuildContext context, int count, {double decalage = 0}) {
    final double? p = phase(context);
    if (p == null || count <= 0) return null;
    return (((p + decalage) % 1) * count).floor().clamp(0, count - 1);
  }

  /// Montée de 0 à 1 sur la première part du cycle, puis maintien à 1.
  ///
  /// Pour ce qui se remplit et ne se vide pas : une progression, un
  /// décompte, une accumulation. [maintien] est la fraction du cycle
  /// passée en haut.
  static double? ramp(
    BuildContext context, {
    double maintien = 0.25,
    int cycles = 1,
  }) {
    final double? p = phase(context);
    if (p == null) return null;
    final double t = (p * cycles) % 1;
    final double montee = 1 - maintien;
    if (t >= montee) return 1;
    final double u = t / montee;
    // Adouci aux deux bouts, comme le balayage.
    return 0.5 - 0.5 * math.cos(math.pi * u);
  }

  /// `true` pendant la seconde moitié du cycle : pour un interrupteur,
  /// une bascule, un état à deux positions.
  static bool? bascule(BuildContext context, {int cycles = 1}) {
    final double? p = phase(context);
    if (p == null) return null;
    return ((p * cycles) % 1) >= 0.5;
  }
}
