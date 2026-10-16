/// La sélection naturelle, génération après génération.
library;


import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/question.dart';

/// Une population où un variant se répand, et le compte des générations.
///
/// « La sélection naturelle agit lentement » est une phrase qu'on retient
/// sans jamais la chiffrer. Ici l'avantage se règle, et le nombre de
/// générations s'affiche : un variant 10 % plus fécond passe de 1 % à 99 %
/// de la population en quatre-vingt-dix-sept générations. Pour une bactérie
/// c'est une journée, pour un chêne quelques millénaires.
///
/// Le modèle est volontairement déterministe. La dérive existe et compte,
/// mais la mélanger ici brouillerait le seul point que cette figure doit
/// faire passer : un avantage même minuscule finit toujours par l'emporter,
/// et ce qui change, c'est le temps qu'il y met.
class SelectionFigure extends StatefulWidget {
  const SelectionFigure({required this.accent, super.key});

  final Color accent;

  /// Nombre d'individus dessinés dans la grille.
  static const int individus = 100;

  /// Fréquence de départ du variant avantagé.
  static const double frequenceInitiale = 0.01;

  /// La fréquence du variant à la génération suivante.
  ///
  /// Modèle le plus simple : le variant laisse (1 + avantage) fois plus de
  /// descendants, et les fréquences sont renormalisées.
  static double prochaine(double frequence, double avantage) {
    final double part = frequence * (1 + avantage);
    return part / (part + (1 - frequence));
  }

  /// La fréquence après [generations] générations.
  static double apres(double depart, double avantage, int generations) {
    double p = depart;
    for (int i = 0; i < generations; i++) {
      p = prochaine(p, avantage);
    }
    return p;
  }

  /// Nombre de générations pour passer de [depart] à [cible].
  ///
  /// Rend [max] si la cible n'est pas atteinte — un avantage nul ne la
  /// fait jamais atteindre, et c'est un résultat, pas une erreur.
  static int generationsPour(
    double depart,
    double cible,
    double avantage, {
    int max = 5000,
  }) {
    double p = depart;
    for (int i = 0; i < max; i++) {
      if (p >= cible) return i;
      p = prochaine(p, avantage);
    }
    return max;
  }

  @override
  State<SelectionFigure> createState() => _SelectionFigureState();
}

class _SelectionFigureState extends State<SelectionFigure> {
  double _avantage = 0.1;
  int _generation = 0;
  double _frequence = SelectionFigure.frequenceInitiale;

  void _avancer(int pas) {
    setState(() {
      _generation += pas;
      _frequence = SelectionFigure.apres(
        SelectionFigure.frequenceInitiale,
        _avantage,
        _generation,
      );
    });
  }

  void _reinitialiser() {
    setState(() {
      _generation = 0;
      _frequence = SelectionFigure.frequenceInitiale;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final int avantages = (_frequence * SelectionFigure.individus).round();
    final int pourCent = (_frequence * 100).round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Dix rangées de dix, et non un enroulement libre : une ligne
        // pleine vaut exactement 10 %, et la proportion se lit alors sans
        // compter ni consulter le pourcentage.
        for (int ligne = 0; ligne < SelectionFigure.individus ~/ 10; ligne++)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (int colonne = 0; colonne < 10; colonne++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: AnimatedContainer(
                      duration: context.motionDuration(AppDurations.fast),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: ligne * 10 + colonne < avantages
                            ? widget.accent
                            : tokens.border.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Génération $_generation   '
          '${NumericQuestion.formatNumber(pourCent.toDouble())} % de variants',
          style: AppTypography.formula(size: 15, color: widget.accent),
        ),
        SizedBox(
          height: 34,
          child: Text(
            _avantage == 0
                ? 'Sans avantage, la proportion ne bouge pas.'
                : 'Il faut ${SelectionFigure.generationsPour(SelectionFigure.frequenceInitiale, 0.99, _avantage)} '
                      'générations pour atteindre 99 %.',
            textAlign: TextAlign.center,
            style: context.text.bodySmall?.copyWith(color: tokens.inkMuted),
          ),
        ),
        Row(
          children: <Widget>[
            SizedBox(
              width: 72,
              child: Text(
                'Avantage',
                style: context.text.labelSmall?.copyWith(
                  color: tokens.inkMuted,
                ),
              ),
            ),
            Expanded(
              child: Slider(
                value: _avantage,
                max: 0.5,
                divisions: 10,
                onChanged: (double v) {
                  context.tapFeedback();
                  setState(() {
                    _avantage = (v * 20).roundToDouble() / 20;
                    _frequence = SelectionFigure.apres(
                      SelectionFigure.frequenceInitiale,
                      _avantage,
                      _generation,
                    );
                  });
                },
              ),
            ),
            SizedBox(
              width: 48,
              child: Text(
                '+${(_avantage * 100).round()} %',
                textAlign: TextAlign.right,
                style: AppTypography.formula(
                  size: 14,
                  color: context.colors.onSurface,
                ),
              ),
            ),
          ],
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            FilledButton.tonalIcon(
              onPressed: () {
                context.tapFeedback();
                _avancer(1);
              },
              icon: const Icon(Icons.skip_next_rounded, size: 18),
              label: const Text('Une génération'),
            ),
            FilledButton.tonalIcon(
              onPressed: () {
                context.tapFeedback();
                _avancer(10);
              },
              icon: const Icon(Icons.fast_forward_rounded, size: 18),
              label: const Text('Dix générations'),
            ),
            TextButton.icon(
              onPressed: () {
                context.tapFeedback();
                _reinitialiser();
              },
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Recommencer'),
            ),
          ],
        ),
      ],
    );
  }
}
