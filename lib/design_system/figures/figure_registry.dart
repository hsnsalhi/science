/// Annuaire des figures interactives.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import 'right_triangle_figure.dart';
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
    // Réciproque : un triangle est-il rectangle ?
    'triangle-reciproque': (BuildContext context, Color accent) =>
        TriangleTestFigure(accent: accent),
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
