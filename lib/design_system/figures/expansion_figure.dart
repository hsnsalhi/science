/// L'expansion de l'Univers, vue depuis n'importe quelle galaxie.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import 'autoplay.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/question.dart';

/// Une rangée de galaxies qui s'écartent, et l'absence de centre.
///
/// « L'Univers n'a pas de centre » est une phrase qu'on accepte sans la
/// comprendre, parce que chaque image de l'expansion en suggère un. Ici
/// l'observateur se choisit d'une touche : depuis n'importe quelle galaxie,
/// toutes les autres s'éloignent, et d'autant plus vite qu'elles sont
/// loin. Changer d'observateur ne change pas le tableau.
///
/// Les galaxies ne se déplacent pas dans l'espace : leurs coordonnées sont
/// fixes, et c'est l'échelle qui grandit. C'est pourquoi la vitesse
/// d'éloignement est proportionnelle à la distance, et non quelque chose
/// qu'il faudrait expliquer par une poussée.
class ExpansionFigure extends StatefulWidget {
  const ExpansionFigure({required this.accent, super.key});

  final Color accent;

  /// Nombre de galaxies alignées.
  static const int galaxies = 7;

  /// Taux d'expansion, en unités de la figure.
  ///
  /// C'est la constante de Hubble du modèle : la vitesse d'éloignement
  /// vaut ce taux multiplié par la distance.
  static const double taux = 0.07;

  /// Distance entre deux galaxies, pour un facteur d'échelle donné.
  ///
  /// Les coordonnées des galaxies ne changent jamais : seule l'échelle
  /// grandit. C'est tout le modèle.
  static double distance(int depuis, int vers, double facteur) =>
      ((vers - depuis).abs()) * facteur;

  /// Vitesse d'éloignement d'une galaxie vue d'une autre.
  ///
  /// Proportionnelle à la distance : c'est la loi de Hubble, et elle
  /// découle du seul fait que l'échelle grandit uniformément.
  static double vitesse(int depuis, int vers, double facteur) =>
      taux * distance(depuis, vers, facteur);

  @override
  State<ExpansionFigure> createState() => _ExpansionFigureState();
}

class _ExpansionFigureState extends State<ExpansionFigure> {
  double _facteur = 1;
  int _observateur = 3;
  /// Vrai dès le premier geste : l'horloge rend la main pour de bon.
  bool _tenue = false;


  @override
  Widget build(BuildContext context) {
    // L'espace se dilate tout seul : toutes les galaxies s'écartent, et
    // les plus lointaines s'écartent le plus vite. C'est la loi de Hubble
    // en acte, et elle ne se lit pas dans un tableau.
    final double facteur = _tenue
        ? _facteur
        : Autoplay.sweep(context, min: 1, max: 2.2) ?? _facteur;
    final AppTokens tokens = context.tokens;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints contraintes) {
            // L'écartement dessiné suit le facteur d'échelle. La rangée
            // étant centrée sur l'observateur, un observateur de bord a
            // six galaxies du même côté : l'écartement est donc borné par
            // ce que cette moitié-là peut contenir, sans quoi la figure
            // perdrait des galaxies hors de l'écran dès qu'on choisit un
            // observateur excentré.
            final int plusLoin = math.max(
              _observateur,
              ExpansionFigure.galaxies - 1 - _observateur,
            );
            final double place = (contraintes.maxWidth / 2 - 14) / plusLoin;
            final double ecart = math.min(
              (contraintes.maxWidth - 28) /
                  (ExpansionFigure.galaxies - 1) *
                  facteur /
                  2,
              place,
            );
            return SizedBox(
              height: 74,
              child: Stack(
                children: <Widget>[
                  for (int i = 0; i < ExpansionFigure.galaxies; i++)
                    Positioned(
                      left:
                          contraintes.maxWidth / 2 -
                          14 +
                          (i - _observateur) * ecart,
                      top: 10,
                      child: GestureDetector(
                        onTap: () {
                          context.tapFeedback();
                          setState(() {
                            _tenue = true;
                            _facteur = facteur;
                            _observateur = i;
                          });
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            AnimatedContainer(
                              duration: context.motionDuration(
                                AppDurations.fast,
                              ),
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: i == _observateur
                                    ? widget.accent
                                    : widget.accent.withValues(alpha: 0.35),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: i == _observateur
                                      ? widget.accent
                                      : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              i == _observateur
                                  ? 'ici'
                                  : NumericQuestion.formatNumber(
                                      (ExpansionFigure.vitesse(
                                                _observateur,
                                                i,
                                                facteur,
                                              ) *
                                              100)
                                          .roundToDouble() /
                                          100,
                                    ),
                              style: context.text.labelSmall?.copyWith(
                                color: i == _observateur
                                    ? widget.accent
                                    : tokens.inkMuted,
                                fontWeight: i == _observateur
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Vitesses d’éloignement vues depuis la galaxie choisie',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkMuted),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Touche une autre galaxie : le tableau est le même.',
          textAlign: TextAlign.center,
          style: AppTypography.formula(size: 14, color: widget.accent),
        ),
        Row(
          children: <Widget>[
            SizedBox(
              width: 64,
              child: Text(
                'Échelle',
                style: context.text.labelSmall?.copyWith(
                  color: tokens.inkMuted,
                ),
              ),
            ),
            Expanded(
              child: Slider(
                value: facteur,
                min: 0.5,
                max: 2.5,
                divisions: 8,
                onChanged: (double v) {
                  context.tapFeedback();
                  setState(
                    () {
                      _tenue = true;
                      _facteur = (v * 4).roundToDouble() / 4;
                    },
                  );
                },
              ),
            ),
            SizedBox(
              width: 44,
              child: Text(
                NumericQuestion.formatNumber(facteur),
                textAlign: TextAlign.right,
                style: AppTypography.formula(
                  size: 14,
                  color: context.colors.onSurface,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
