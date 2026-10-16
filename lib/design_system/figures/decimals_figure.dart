/// Les décimaux, colonne par colonne.
library;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';

/// Trois colonnes — unités, dixièmes, centièmes — et la retenue qui passe.
///
/// Un élève qui écrit « 0,25 est plus grand que 0,9 parce que 25 dépasse
/// 9 » ne confond pas les nombres : il lit la partie décimale comme un
/// entier. Lui répéter la règle ne défait pas la lecture.
///
/// Ici chaque colonne se règle séparément, et la barre montre la valeur
/// réelle. On voit alors que neuf dixièmes remplissent presque l'unité
/// quand vingt-cinq centièmes en remplissent le quart. Et quand on ajoute
/// un dixième à neuf dixièmes, la retenue passe à l'unité sous les yeux :
/// dix dixièmes font une unité, comme dix unités font une dizaine.
class DecimalsFigure extends StatefulWidget {
  const DecimalsFigure({required this.accent, super.key});

  final Color accent;

  /// Les noms des trois colonnes, de la plus forte à la plus faible.
  static const List<String> colonnes = <String>[
    'unités',
    'dixièmes',
    'centièmes',
  ];

  /// La valeur d'un nombre donné par ses trois chiffres.
  static double valeur(List<int> chiffres) =>
      chiffres[0] + chiffres[1] / 10 + chiffres[2] / 100;

  /// Ajoute [pas] à la colonne [colonne], retenues comprises.
  ///
  /// C'est la retenue qui enseigne : ajouter un dixième à neuf dixièmes
  /// ne donne pas « dix dixièmes », cela donne une unité. Le résultat est
  /// borné entre 0 et 9,99 — la figure ne montre rien au-delà.
  static List<int> ajouter(List<int> chiffres, int colonne, int pas) {
    final int total =
        (valeur(chiffres) * 100).round() +
        pas * <int>[100, 10, 1][colonne];
    final int borne = total.clamp(0, 999);
    return <int>[borne ~/ 100, (borne ~/ 10) % 10, borne % 10];
  }

  /// L'écriture décimale, à la française.
  static String ecriture(List<int> chiffres) =>
      '${chiffres[0]},${chiffres[1]}${chiffres[2]}';

  @override
  State<DecimalsFigure> createState() => _DecimalsFigureState();
}

class _DecimalsFigureState extends State<DecimalsFigure> {
  List<int> _chiffres = <int>[0, 9, 0];

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final double valeur = DecimalsFigure.valeur(_chiffres);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            for (int i = 0; i < DecimalsFigure.colonnes.length; i++) ...<Widget>[
              if (i == 1)
                Padding(
                  padding: const EdgeInsets.only(top: 18, right: 2),
                  child: Text(
                    ',',
                    style: AppTypography.formula(
                      size: 26,
                      color: widget.accent,
                    ),
                  ),
                ),
              _Colonne(
                nom: DecimalsFigure.colonnes[i],
                chiffre: _chiffres[i],
                accent: widget.accent,
                onChange: (int pas) {
                  context.tapFeedback();
                  setState(
                    () => _chiffres = DecimalsFigure.ajouter(_chiffres, i, pas),
                  );
                },
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Trois unités de barre, graduées à chaque unité. Dix unités
        // rendaient « 0,9 » invisible — un dixième de la largeur — alors
        // que c'est précisément la valeur que la leçon veut faire voir
        // presque pleine. Au-delà de trois, la barre sature, ce qui
        // dépasse ce que le chapitre demande.
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints contraintes) {
            final double large = contraintes.maxWidth;
            return SizedBox(
              height: 26,
              child: Stack(
                children: <Widget>[
                  Container(
                    decoration: BoxDecoration(
                      color: tokens.border.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  AnimatedContainer(
                    duration: context.motionDuration(AppDurations.fast),
                    width: large * (valeur / 3).clamp(0, 1),
                    decoration: BoxDecoration(
                      color: widget.accent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  // Les graduations à chaque unité.
                  for (int u = 1; u < 3; u++)
                    Positioned(
                      left: large * u / 3,
                      top: 0,
                      bottom: 0,
                      // Une graduation qui se voit aussi bien sur le
                      // rempli que sur le vide : sans elle, on ne sait
                      // pas où l'unité s'arrête.
                      child: Container(
                        width: 1.5,
                        color: tokens.inkMuted.withValues(alpha: 0.55),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          DecimalsFigure.ecriture(_chiffres),
          style: AppTypography.formula(size: 22, color: widget.accent),
        ),
        SizedBox(
          height: 34,
          child: Text(
            _chiffres[2] == 0
                ? '${DecimalsFigure.ecriture(_chiffres)} et '
                      '${_chiffres[0]},${_chiffres[1]} sont le même nombre.'
                : '${_chiffres[1]} dixièmes et ${_chiffres[2]} centièmes.',
            textAlign: TextAlign.center,
            style: context.text.bodySmall?.copyWith(color: tokens.inkMuted),
          ),
        ),
      ],
    );
  }
}

/// Une colonne : son chiffre, et deux boutons pour le changer.
class _Colonne extends StatelessWidget {
  const _Colonne({
    required this.nom,
    required this.chiffre,
    required this.accent,
    required this.onChange,
  });

  final String nom;
  final int chiffre;
  final Color accent;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            nom,
            style: context.text.labelSmall?.copyWith(color: tokens.inkMuted),
          ),
          const SizedBox(height: 2),
          IconButton(
            onPressed: () => onChange(1),
            icon: const Icon(Icons.keyboard_arrow_up_rounded),
            visualDensity: VisualDensity.compact,
            color: accent,
          ),
          Container(
            width: 42,
            height: 46,
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: tokens.border, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              '$chiffre',
              style: AppTypography.formula(size: 24, color: accent),
            ),
          ),
          IconButton(
            onPressed: () => onChange(-1),
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            visualDensity: VisualDensity.compact,
            color: accent,
          ),
        ],
      ),
    );
  }
}
