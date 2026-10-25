/// Des noyaux radioactifs qui se désintègrent, un par un.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import 'autoplay.dart';
import '../../core/theme/app_typography.dart';

/// Un échantillon radioactif, suivi dans le temps.
///
/// La demi-vie s'enseigne d'ordinaire par sa courbe, et la courbe donne une
/// fausse idée : elle suggère un écoulement régulier, comme un sablier.
/// Or rien dans un échantillon ne décroît régulièrement. Chaque noyau tient
/// bon ou se désintègre, d'un coup, sans prévenir et sans savoir son âge ;
/// c'est seulement parce qu'ils sont nombreux que le total suit une loi
/// lisse.
///
/// La figure montre donc les noyaux eux-mêmes. Chacun a son instant de
/// désintégration, tiré une fois pour toutes selon la loi exponentielle, et
/// l'élève voit le total obéir sans qu'aucun noyau n'ait rien coordonné.
/// C'est le passage du hasard individuel à la régularité collective, et
/// c'est le vrai sujet du chapitre.
class HalfLifeFigure extends StatefulWidget {
  const HalfLifeFigure({required this.accent, super.key});

  final Color accent;

  /// Nombre de noyaux de l'échantillon.
  static const int effectif = 144;

  /// Durée observée, en demi-vies.
  static const double dureeMax = 6;

  /// Proportion théorique de noyaux restants après [demiVies] demi-vies.
  ///
  /// C'est la loi du cours, écrite sous sa forme la plus parlante : on
  /// divise par deux à chaque demi-vie.
  static double proportionTheorique(double demiVies) =>
      math.pow(0.5, demiVies).toDouble();

  /// Instants de désintégration des [effectif] noyaux, en demi-vies.
  ///
  /// Chaque noyau tire son instant selon la loi exponentielle, avec une
  /// graine fixe : l'échantillon est donc toujours le même, et les captures
  /// de référence restent stables. La formule inverse la fonction de
  /// survie — un tirage uniforme u donne l'instant −log₂(u), qui dépasse
  /// une demi-vie avec probabilité exactement 1/2.
  ///
  /// Exposée pour que le test confronte la simulation à la loi, plutôt que
  /// de croire la figure sur parole.
  static List<double> instants({int graine = 2026}) {
    final math.Random alea = math.Random(graine);
    return <double>[
      for (int i = 0; i < effectif; i++)
        -math.log(1 - alea.nextDouble()) / math.ln2,
    ];
  }

  /// Combien de noyaux restent intacts à [demiVies], pour ce tirage.
  static int restants(List<double> instants, double demiVies) {
    int total = 0;
    for (final double t in instants) {
      if (t > demiVies) total++;
    }
    return total;
  }

  @override
  State<HalfLifeFigure> createState() => _HalfLifeFigureState();
}

class _HalfLifeFigureState extends State<HalfLifeFigure> {
  static final List<double> _instants = HalfLifeFigure.instants();

  double _temps = 0;
  /// Vrai dès le premier geste : l'horloge rend la main pour de bon.
  bool _tenue = false;


  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    // Le temps avance de zéro à six demi-vies et repart : l'effectif
    // fond de moitié en moitié, et l'élève voit qu'il n'atteint jamais
    // zéro. Une courbe qui se dessine dit cela mieux qu'une phrase.
    final double? montee = Autoplay.ramp(context, maintien: 0.2);
    final double temps = _tenue || montee == null
        ? _temps
        : montee * HalfLifeFigure.dureeMax;
    final int restants = HalfLifeFigure.restants(_instants, temps);
    final double theorique =
        HalfLifeFigure.effectif * HalfLifeFigure.proportionTheorique(temps);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 210,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints contraintes) {
                return CustomPaint(
                  size: Size(contraintes.maxWidth, 210),
                  painter: _NoyauxPainter(
                    instants: _instants,
                    temps: temps,
                    accent: widget.accent,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '$restants noyaux sur ${HalfLifeFigure.effectif}',
          textAlign: TextAlign.center,
          style: AppTypography.formula(size: 18, color: widget.accent),
        ),
        Text(
          'La loi en prévoit ${theorique.toStringAsFixed(1).replaceAll('.', ',')} : '
          'aucun noyau ne s\'est concerté.',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkSubtle),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: <Widget>[
            SizedBox(
              width: 66,
              child: Text(
                'temps',
                style: context.text.labelSmall?.copyWith(
                  color: tokens.inkSubtle,
                ),
              ),
            ),
            Expanded(
              child: Slider(
                value: temps,
                max: HalfLifeFigure.dureeMax,
                divisions: 48,
                onChanged: (double v) {
                  context.tapFeedback();
                  setState(() {
                    _tenue = true;
                    _temps = v;
                  });
                },
              ),
            ),
            SizedBox(
              width: 74,
              child: Text(
                '${temps.toStringAsFixed(2).replaceAll('.', ',')} T',
                textAlign: TextAlign.right,
                style: AppTypography.formula(size: 13, color: widget.accent),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NoyauxPainter extends CustomPainter {
  const _NoyauxPainter({
    required this.instants,
    required this.temps,
    required this.accent,
  });

  final List<double> instants;
  final double temps;
  final Color accent;

  static const int _colonnes = 18;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF14181F),
    );

    final int lignes = (instants.length / _colonnes).ceil();
    final double pas = math.min(
      (size.width - 24) / _colonnes,
      (size.height - 24) / lignes,
    );
    final double gauche = (size.width - pas * _colonnes) / 2 + pas / 2;
    final double haut = (size.height - pas * lignes) / 2 + pas / 2;
    final double rayon = pas * 0.33;

    for (int i = 0; i < instants.length; i++) {
      final Offset centre = Offset(
        gauche + (i % _colonnes) * pas,
        haut + (i ~/ _colonnes) * pas,
      );
      final double instant = instants[i];
      final bool intact = instant > temps;
      // Un noyau qui vient de se désintégrer garde un instant sa lueur :
      // l'événement est ponctuel, et sans cette trace on ne verrait pas
      // qu'il s'est passé quelque chose en déplaçant le curseur.
      final double fraicheur =
          intact ? 0 : math.max(0, 1 - (temps - instant) * 6);

      if (intact) {
        // Un noyau intact : une petite sphère dense et lumineuse.
        canvas.drawCircle(
          centre,
          rayon * 1.7,
          Paint()
            ..color = accent.withValues(alpha: 0.18)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
        canvas.drawCircle(
          centre,
          rayon,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-0.4, -0.4),
              colors: <Color>[
                Color.lerp(accent, Colors.white, 0.6)!,
                accent,
                Color.lerp(accent, Colors.black, 0.35)!,
              ],
            ).createShader(
              Rect.fromCircle(center: centre, radius: rayon),
            ),
        );
      } else {
        // Un noyau désintégré : le produit reste, éteint.
        canvas.drawCircle(
          centre,
          rayon * 0.72,
          Paint()..color = const Color(0xFF3C434E),
        );
        if (fraicheur > 0) {
          // La particule émise, qui s'éloigne et pâlit.
          final double distance = rayon * (1 + (1 - fraicheur) * 2.6);
          final double angle = (i * 2.399) % (2 * math.pi);
          canvas.drawCircle(
            centre + Offset(math.cos(angle), math.sin(angle)) * distance,
            rayon * 0.3,
            Paint()
              ..color = const Color(0xFFFFD36B)
                  .withValues(alpha: fraicheur * 0.9),
          );
          canvas.drawCircle(
            centre,
            rayon * 1.6,
            Paint()
              ..color = const Color(0xFFFFD36B)
                  .withValues(alpha: fraicheur * 0.35)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_NoyauxPainter old) =>
      old.temps != temps || old.accent != accent;
}
