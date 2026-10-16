/// Annuaire des figures interactives.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import 'complexity_figure.dart';
import 'cross_figure.dart';
import 'eratosthene_figure.dart';
import 'fraction_bar_figure.dart';
import 'gears_figure.dart';
import 'loop_robot_figure.dart';
import 'moon_phases_figure.dart';
import 'orbits_figure.dart';
import 'parabola_figure.dart';
import 'pythagore_proof_figure.dart';
import 'retrograde_figure.dart';
import 'right_triangle_figure.dart';
import 'solar_system_figure.dart';
import 'speed_figure.dart';
import 'thales_figure.dart';
import 'truth_table_figure.dart';
import 'triangle_test_figure.dart';

/// Fabrique une figure à partir de son identifiant de contenu.
typedef FigureBuilder = Widget Function(BuildContext context, Color accent);

/// Relie les `figureId` du contenu JSON aux widgets qui les dessinent.
///
/// Le contenu pédagogique ne nomme qu'une clé (`"figureId": "triangle-sides"`)
/// et ignore tout de Flutter. Ajouter une figure se fait en deux temps : écrire
/// le widget, l'inscrire ici. Le test `figure_registry_test.dart` vérifie que
/// toute clé citée dans le contenu existe bien dans cet annuaire, pour qu'une
/// faute de frappe ne produise jamais un encadré vide chez l'élève.
abstract final class FigureRegistry {
  static final Map<String, FigureBuilder> _builders = <String, FigureBuilder>{
    // Triangle rectangle manipulable, pour nommer les côtés.
    'triangle-sides': (BuildContext context, Color accent) =>
        RightTriangleFigure(accent: accent),
    // Même triangle, avec les carrés construits sur les côtés.
    'pythagore-carres': (BuildContext context, Color accent) =>
        RightTriangleFigure(accent: accent, showSquares: true),
    // Un robot qui répète « avancer, tourner » sur une grille.
    'boucle-robot': (BuildContext context, Color accent) =>
        LoopRobotFigure(accent: accent),
    // La Lune autour de la Terre, et ce qu'on en voit d'ici.
    'phases-lune': (BuildContext context, Color accent) =>
        MoonPhasesFigure(accent: accent),
    // Une parabole dont on règle a, b et c.
    'parabole': (BuildContext context, Color accent) =>
        ParabolaFigure(accent: accent),
    // Mars vue depuis la Terre : la boucle qui a fait tomber le
    // géocentrisme.
    'retrogradation': (BuildContext context, Color accent) =>
        RetrogradeFigure(accent: accent),
    // Une barre partagée et coloriée, comparée à une demie.
    'fraction-barre': (BuildContext context, Color accent) =>
        FractionBarFigure(accent: accent),
    // Cinq courbes de coût, et le temps que cela ferait.
    'complexite': (BuildContext context, Color accent) =>
        ComplexityFigure(accent: accent),
    // Deux villes, deux ombres : la Terre mesurée au sol.
    'eratosthene': (BuildContext context, Color accent) =>
        EratostheneFigure(accent: accent),
    // Deux roues dentées en prise, dont on règle la seconde.
    'engrenages': (BuildContext context, Color accent) =>
        GearsFigure(accent: accent),
    // Croisement de deux pois : quatre descendants possibles.
    'croisement': (BuildContext context, Color accent) =>
        CrossFigure(accent: accent),
    // Un mobile sur une piste graduée, dont on règle la vitesse.
    'vitesse': (BuildContext context, Color accent) =>
        SpeedFigure(accent: accent),
    // Deux affirmations à basculer, et ce que valent et, ou, non.
    'table-de-verite': (BuildContext context, Color accent) =>
        TruthTableFigure(accent: accent),
    // Triangle coupé par une parallèle qu'on fait glisser.
    'thales': (BuildContext context, Color accent) =>
        ThalesFigure(accent: accent),
    // Réciproque : un triangle est-il rectangle ?
    'triangle-reciproque': (BuildContext context, Color accent) =>
        TriangleTestFigure(accent: accent),
    // La preuve par réarrangement : les triangles glissent, l'aire libre
    // passe de deux carrés à un seul.
    'pythagore-preuve': (BuildContext context, Color accent) =>
        PythagoreProofFigure(accent: accent),
    // Les quatre planètes rocheuses en orbite, le temps défilant.
    'orbites': (BuildContext context, Color accent) =>
        OrbitsFigure(accent: accent),
    // Les huit planètes à l'échelle de leurs distances au Soleil.
    'systeme-solaire': (BuildContext context, Color accent) =>
        SolarSystemFigure(accent: accent),
  };

  /// Identifiants connus.
  static Iterable<String> get ids => _builders.keys;

  /// `true` si [id] est une figure connue.
  static bool contains(String id) => _builders.containsKey(id);

  /// Construit la figure [id], ou un encadré d'avertissement si elle est
  /// inconnue — jamais une exception en pleine leçon.
  static Widget build(BuildContext context, String id, Color accent) {
    final FigureBuilder? builder = _builders[id];
    if (builder == null) return _MissingFigure(id: id);
    return builder(context, accent);
  }
}

class _MissingFigure extends StatelessWidget {
  const _MissingFigure({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.tokens.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.image_not_supported_rounded,
            color: context.tokens.inkSubtle,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Figure « $id » indisponible.',
              style: context.text.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
