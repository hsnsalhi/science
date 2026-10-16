/// Annuaire des figures interactives.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import 'array_figure.dart';
import 'binary_figure.dart';
import 'cell_figure.dart';
import 'circuit_figure.dart';
import 'classification_figure.dart';
import 'complexity_figure.dart';
import 'cross_figure.dart';
import 'decimals_figure.dart';
import 'derivative_figure.dart';
import 'distributivity_figure.dart';
import 'dna_figure.dart';
import 'energy_chain_figure.dart';
import 'entropy_figure.dart';
import 'eratosthene_figure.dart';
import 'expansion_figure.dart';
import 'fraction_bar_figure.dart';
import 'feedback_figure.dart';
import 'food_web_figure.dart';
import 'gears_figure.dart';
import 'implication_figure.dart';
import 'loop_robot_figure.dart';
import 'matrix_figure.dart';
import 'moon_phases_figure.dart';
import 'number_line_figure.dart';
import 'orbits_figure.dart';
import 'parabola_figure.dart';
import 'pattern_figure.dart';
import 'projectile_figure.dart';
import 'pythagore_proof_figure.dart';
import 'reference_functions_figure.dart';
import 'retrograde_figure.dart';
import 'right_triangle_figure.dart';
import 'seasons_figure.dart';
import 'selection_figure.dart';
import 'sensor_chain_figure.dart';
import 'sequence_figure.dart';
import 'solar_system_figure.dart';
import 'speed_figure.dart';
import 'states_figure.dart';
import 'thales_figure.dart';
import 'truth_table_figure.dart';
import 'triangle_angles_figure.dart';
import 'turing_figure.dart';
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
    // Le rectangle k(a + b) coupé en deux : la distributivité comme aire.
    'distributivite': (BuildContext context, Color accent) =>
        DistributivityFigure(accent: accent),
    // Un robot qui répète « avancer, tourner » sur une grille.
    'boucle-robot': (BuildContext context, Color accent) =>
        LoopRobotFigure(accent: accent),
    // La Lune autour de la Terre, et ce qu'on en voit d'ici.
    'phases-lune': (BuildContext context, Color accent) =>
        MoonPhasesFigure(accent: accent),
    // Trois suites de motifs, et la case suivante à trouver.
    'suite-motifs': (BuildContext context, Color accent) =>
        PatternFigure(accent: accent),
    // Une machine de Turing qui ajoute 1, pas à pas.
    'machine-turing': (BuildContext context, Color accent) =>
        TuringFigure(accent: accent),
    // Les cinq fonctions de référence, sur un même repère.
    'fonctions-reference': (BuildContext context, Color accent) =>
        ReferenceFunctionsFigure(accent: accent),
    // Quatre étages de conversion, et le rendement qui en sort.
    'chaine-energie': (BuildContext context, Color accent) =>
        EnergyChainFigure(accent: accent),
    // Une matrice 2 × 2, et le carré unité qu'elle transforme.
    'matrice': (BuildContext context, Color accent) =>
        MatrixFigure(accent: accent),
    // Un variant avantagé qui se répand, génération après génération.
    'selection': (BuildContext context, Color accent) =>
        SelectionFigure(accent: accent),
    // Une rangée de galaxies qui s'écartent, sans centre.
    'expansion': (BuildContext context, Color accent) =>
        ExpansionFigure(accent: accent),
    // Des boîtes emboîtées, et les animaux qu'on y range.
    'classification': (BuildContext context, Color accent) =>
        ClassificationFigure(accent: accent),
    // Un gaz qui envahit la boîte, et la probabilité du retour.
    'entropie': (BuildContext context, Color accent) =>
        EntropyFigure(accent: accent),
    // Unités, dixièmes, centièmes, et la retenue qui passe.
    'decimaux': (BuildContext context, Color accent) =>
        DecimalsFigure(accent: accent),
    // Un asservissement proportionnel, et le réglage de son gain.
    'asservissement': (BuildContext context, Color accent) =>
        FeedbackFigure(accent: accent),
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
    // Un thermomètre, une boîte, et les particules qui se rangent.
    'etats-matiere': (BuildContext context, Color accent) =>
        StatesFigure(accent: accent),
    // Une sécante qu'on resserre jusqu'à la tangente.
    'secante-tangente': (BuildContext context, Color accent) =>
        DerivativeFigure(accent: accent),
    // Des jetons en rectangle : une multiplication qu'on peut compter.
    'jetons-multiplication': (BuildContext context, Color accent) =>
        ArrayFigure(accent: accent),
    // Un réseau alimentaire dont on peut retirer une espèce.
    'chaine-alimentaire': (BuildContext context, Color accent) =>
        FoodWebFigure(accent: accent),
    // Une droite graduée où l'on avance et recule.
    'droite-graduee': (BuildContext context, Color accent) =>
        NumberLineFigure(accent: accent),
    // « Si… alors », sa réciproque, et le seul cas interdit.
    'implication': (BuildContext context, Color accent) =>
        ImplicationFigure(accent: accent),
    // Deux lampes, en série ou en dérivation, et une à dévisser.
    'circuit': (BuildContext context, Color accent) =>
        CircuitFigure(accent: accent),
    // La Terre sur son orbite, axe penché, et la durée du jour.
    'saisons': (BuildContext context, Color accent) =>
        SeasonsFigure(accent: accent),
    // Une cellule à explorer, animale ou végétale.
    'cellule': (BuildContext context, Color accent) =>
        CellFigure(accent: accent),
    // Capteur, traitement, actionneur : un thermostat complet.
    'chaine-information': (BuildContext context, Color accent) =>
        SensorChainFigure(accent: accent),
    // Deux angles réglables, et le troisième qui suit.
    'angles-triangle': (BuildContext context, Color accent) =>
        TriangleAnglesFigure(accent: accent),
    // Un projectile lancé, dont on règle l'angle et la vitesse.
    'projectile': (BuildContext context, Color accent) =>
        ProjectileFigure(accent: accent),
    // Huit bits qu'on bascule, et le nombre qu'ils écrivent.
    'binaire': (BuildContext context, Color accent) =>
        BinaryFigure(accent: accent),
    // Les dix premiers termes d'une suite, en bâtons.
    'suite': (BuildContext context, Color accent) =>
        SequenceFigure(accent: accent),
    // Une séquence d'ARN qu'on mute, et la protéine qui en sort.
    'code-genetique': (BuildContext context, Color accent) =>
        DnaFigure(accent: accent),
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
