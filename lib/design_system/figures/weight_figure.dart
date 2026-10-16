/// La même masse sur trois astres, et la flèche du poids qui change.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';

/// Un astre, un objet, et le poids dessiné à l'échelle.
///
/// « Le poids n'est pas la masse » se dit en une phrase et ne s'entend pas :
/// la balance de la salle de bain affiche des kilogrammes, et l'école
/// emploie « peser » pour les deux. Tant que les deux grandeurs restent des
/// mots, elles restent interchangeables.
///
/// Ici elles ne peuvent plus l'être, parce qu'elles n'ont pas la même
/// apparence. La masse est un nombre qu'on règle et qui ne bronche pas quand
/// on change d'astre. Le poids est une flèche, qui s'allonge sur Jupiter et
/// se réduit presque à rien sur la Lune. Changer d'astre sans toucher au
/// curseur de masse est le geste que la figure existe pour rendre possible.
class WeightFigure extends StatefulWidget {
  const WeightFigure({required this.accent, super.key});

  final Color accent;

  /// Intensité de la pesanteur, en newtons par kilogramme.
  ///
  /// Valeurs de surface, arrondies au dixième — celles que le chapitre
  /// annonce et que les questions font calculer.
  static const Map<String, double> pesanteur = <String, double>{
    'Lune': 1.6,
    'Mars': 3.7,
    'Terre': 9.8,
    'Jupiter': 24.8,
  };

  /// Poids d'une masse sur un astre, en newtons : P = m × g.
  ///
  /// Renvoie `null` si l'astre est inconnu, plutôt que de supposer la Terre :
  /// une faute de frappe doit se voir, pas se corriger toute seule.
  static double? poids(double masseKg, String astre) {
    final double? g = pesanteur[astre];
    return g == null ? null : masseKg * g;
  }

  /// Masse correspondant à un poids mesuré sur un astre : m = P ÷ g.
  static double? masse(double poidsN, String astre) {
    final double? g = pesanteur[astre];
    return g == null || g == 0 ? null : poidsN / g;
  }

  /// Combien de fois le poids est plus faible sur [astre] que sur Terre.
  static double? facteurFaceALaTerre(String astre) {
    final double? g = pesanteur[astre];
    final double terre = pesanteur['Terre']!;
    return g == null || g == 0 ? null : terre / g;
  }

  @override
  State<WeightFigure> createState() => _WeightFigureState();
}

class _WeightFigureState extends State<WeightFigure> {
  double _masse = 4;
  String _astre = 'Terre';

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final double g = WeightFigure.pesanteur[_astre]!;
    final double poids = WeightFigure.poids(_masse, _astre)!;
    final double maxPoids =
        _masse * WeightFigure.pesanteur['Jupiter']!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: 165,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return CustomPaint(
                size: Size(constraints.maxWidth, 165),
                painter: _PoidsPainter(
                  // La flèche est à l'échelle du poids le plus fort
                  // atteignable, pour que passer de la Lune à Jupiter se
                  // voie sans que la figure se redimensionne à chaque fois.
                  fraction: maxPoids == 0 ? 0 : poids / maxPoids,
                  accent: widget.accent,
                  trait: tokens.border,
                  muted: tokens.inkMuted,
                  surface: context.colors.surface,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'P = ${_nombre(_masse)} × ${_nombre(g)} = ${_nombre(poids)} N',
          textAlign: TextAlign.center,
          style: AppTypography.formula(size: 18, color: widget.accent),
        ),
        Text(
          'La masse reste ${_nombre(_masse)} kg sur les quatre astres.',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkSubtle),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.xs,
          children: WeightFigure.pesanteur.keys.map((String nom) {
            final bool actif = nom == _astre;
            return ChoiceChip(
              label: Text(nom),
              selected: actif,
              onSelected: (_) {
                context.tapFeedback();
                setState(() => _astre = nom);
              },
            );
          }).toList(growable: false),
        ),
        Row(
          children: <Widget>[
            SizedBox(
              width: 54,
              child: Text(
                'masse',
                style: context.text.labelSmall?.copyWith(
                  color: tokens.inkSubtle,
                ),
              ),
            ),
            Expanded(
              child: Slider(
                value: _masse,
                min: 1,
                max: 20,
                divisions: 19,
                onChanged: (double v) {
                  context.tapFeedback();
                  setState(() => _masse = v.roundToDouble());
                },
              ),
            ),
            SizedBox(
              width: 46,
              child: Text(
                '${_nombre(_masse)} kg',
                textAlign: TextAlign.right,
                style: AppTypography.formula(
                  size: 14,
                  color: widget.accent,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Écrit un nombre à la française, sans décimale inutile.
  static String _nombre(double valeur) {
    if (valeur == valeur.roundToDouble()) return valeur.round().toString();
    return valeur.toStringAsFixed(1).replaceAll('.', ',');
  }
}

class _PoidsPainter extends CustomPainter {
  const _PoidsPainter({
    required this.fraction,
    required this.accent,
    required this.trait,
    required this.muted,
    required this.surface,
  });

  final double fraction;
  final Color accent;
  final Color trait;
  final Color muted;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    final double centre = size.width / 2;
    const double hautObjet = 18;
    const double cote = 40;

    // L'objet : même taille quel que soit l'astre, puisque sa masse ne
    // change pas. C'est le point que la figure doit rendre impossible à
    // manquer.
    final RRect boite = RRect.fromRectAndRadius(
      Rect.fromLTWH(centre - cote / 2, hautObjet, cote, cote),
      const Radius.circular(8),
    );
    canvas.drawRRect(boite, Paint()..color = surface);
    canvas.drawRRect(
      boite,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = trait,
    );

    // La flèche du poids, depuis le centre de l'objet vers le bas. Les
    // flèches sont dessinées et non écrites : la police du contenu ne porte
    // pas de glyphe de flèche, et un carré blanc serait pire que rien.
    const double depart = hautObjet + cote;
    const double longueurMax = 165 - depart - 26;
    final double longueur = math.max(6, longueurMax * fraction.clamp(0, 1));
    final Paint plume = Paint()
      ..color = accent
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(centre, depart),
      Offset(centre, depart + longueur),
      plume,
    );
    final Path pointe = Path()
      ..moveTo(centre, depart + longueur + 9)
      ..lineTo(centre - 7, depart + longueur - 2)
      ..lineTo(centre + 7, depart + longueur - 2)
      ..close();
    canvas.drawPath(pointe, Paint()..color = accent);

    // Le repère de la flèche la plus longue possible, en pointillé : sans
    // lui, « plus court » n'aurait rien à quoi se comparer.
    final Paint repere = Paint()
      ..color = muted.withValues(alpha: 0.35)
      ..strokeWidth = 1.4;
    const double pas = 6;
    for (double y = depart; y < depart + longueurMax; y += pas * 2) {
      canvas.drawLine(
        Offset(centre + 26, y),
        Offset(centre + 26, math.min(y + pas, depart + longueurMax)),
        repere,
      );
    }
  }

  @override
  bool shouldRepaint(_PoidsPainter old) =>
      old.fraction != fraction || old.accent != accent;
}
