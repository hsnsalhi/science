/// Deux corps qu'on écarte, et la force qui s'effondre.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import 'autoplay.dart';
import '../../core/theme/app_typography.dart';
import 'realism.dart';

/// L'attraction entre deux corps, dont l'élève règle la distance.
///
/// « La force décroît comme le carré de la distance » est une phrase que
/// tout le monde récite et que presque personne ne sait appliquer : demande
/// ce que devient la force si l'on double la distance, et la réponse
/// spontanée est « elle est divisée par deux ».
///
/// Ici, l'élève tire le second corps et regarde la flèche. À distance
/// double, elle ne fait pas la moitié : elle fait le quart, et cela se voit
/// d'un coup d'œil parce que les deux longueurs sont dessinées côte à côte.
/// Le repère gris laissé à la position de départ est ce qui rend la
/// comparaison possible — sans lui, l'œil s'habitue et ne mesure plus rien.
class InverseSquareFigure extends StatefulWidget {
  const InverseSquareFigure({required this.accent, super.key});

  final Color accent;

  /// Distance de référence, celle où la force vaut 1.
  static const double distanceReference = 1;

  /// Distance maximale réglable, en unités de la distance de référence.
  static const double distanceMax = 5;

  /// La force, en unités de la force à la distance de référence.
  ///
  /// On ne modélise pas G, ni les masses en kilogrammes : ce qui compte au
  /// collège est la loi de variation, et des unités arbitraires la rendent
  /// plus lisible qu'un newton à quinze décimales.
  static double force(double distance) {
    if (distance <= 0) return double.infinity;
    final double rapport = distanceReference / distance;
    return rapport * rapport;
  }

  /// Par combien la force est divisée quand on passe de 1 à [distance].
  static double diviseePar(double distance) => 1 / force(distance);

  @override
  State<InverseSquareFigure> createState() => _InverseSquareFigureState();
}

class _InverseSquareFigureState extends State<InverseSquareFigure> {
  double _distance = 1;

  /// Vrai dès que l'élève a touché la figure : l'horloge rend alors la
  /// main pour de bon, et ne reprend pas le curseur sous le doigt.
  bool _tenue = false;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final double distance = _tenue
        ? _distance
        : Autoplay.sweep(
                context,
                min: 0.5,
                max: InverseSquareFigure.distanceMax,
              ) ??
              _distance;
    final double force = InverseSquareFigure.force(distance);
    final double divisee = InverseSquareFigure.diviseePar(distance);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 196,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints contraintes) {
                return GestureDetector(
                  // On peut tirer le corps directement, en plus du curseur :
                  // c'est le geste que l'élève tente d'abord.
                  onHorizontalDragUpdate: (DragUpdateDetails details) {
                    final double largeur = contraintes.maxWidth;
                    final double x = details.localPosition.dx;
                    final double d = ((x - largeur * 0.16) /
                            (largeur * 0.72) *
                            InverseSquareFigure.distanceMax)
                        .clamp(0.5, InverseSquareFigure.distanceMax);
                    _regler(d);
                  },
                  child: CustomPaint(
                    size: Size(contraintes.maxWidth, 196),
                    painter: _AttractionPainter(
                      distance: distance,
                      accent: widget.accent,
                      tokens: tokens,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'distance ×${_nombre(distance)}   '
          'force ÷${_nombre(divisee)}',
          textAlign: TextAlign.center,
          style: AppTypography.formula(size: 18, color: widget.accent),
        ),
        Text(
          force == 1
              ? 'Position de départ.'
              : '${_nombre(distance)} × ${_nombre(distance)} = '
                  '${_nombre(divisee)} : c\'est le carré qui décide.',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkSubtle),
        ),
        Row(
          children: <Widget>[
            SizedBox(
              width: 54,
              child: Text(
                'distance',
                style: context.text.labelSmall?.copyWith(
                  color: tokens.inkSubtle,
                ),
              ),
            ),
            Expanded(
              child: Slider(
                value: distance,
                min: 0.5,
                max: InverseSquareFigure.distanceMax,
                divisions: 45,
                onChanged: _regler,
              ),
            ),
            SizedBox(
              width: 46,
              child: Text(
                '×${_nombre(distance)}',
                textAlign: TextAlign.right,
                style: AppTypography.formula(size: 14, color: widget.accent),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _regler(double valeur) {
    final double d = (valeur * 10).roundToDouble() / 10;
    if (d == _distance && _tenue) return;
    context.tapFeedback();
    setState(() {
      _tenue = true;
      _distance = d;
    });
  }

  static String _nombre(double valeur) {
    if (valeur == valeur.roundToDouble()) return valeur.round().toString();
    return valeur.toStringAsFixed(valeur < 10 ? 1 : 0).replaceAll('.', ',');
  }
}

class _AttractionPainter extends CustomPainter {
  _AttractionPainter({
    required this.distance,
    required this.accent,
    required this.tokens,
  });

  final double distance;
  final Color accent;
  final AppTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    final double y = size.height * 0.42;
    final double xGauche = size.width * 0.16;
    final double course = size.width * 0.72;
    final double xDroite =
        xGauche + course * (distance / InverseSquareFigure.distanceMax);

    _peindreRegle(canvas, size, xGauche, course, y);

    // Le repère de la position de départ : sans lui, l'œil s'habitue à la
    // nouvelle flèche et ne compare plus rien.
    final double xReference =
        xGauche + course * (1 / InverseSquareFigure.distanceMax);
    if (distance != 1) {
      _peindreFantome(canvas, xReference, y);
    }

    _peindreCorps(canvas, Offset(xGauche, y), 26, gros: true);
    _peindreCorps(canvas, Offset(xDroite, y), 15, gros: false);

    _peindreFleches(canvas, size, xGauche, xDroite, y);
  }

  void _peindreRegle(
    Canvas canvas,
    Size size,
    double x0,
    double course,
    double y,
  ) {
    final Paint trait = Paint()
      ..color = tokens.inkSubtle.withValues(alpha: 0.3)
      ..strokeWidth = 1;
    final double yRegle = size.height - 30;
    canvas.drawLine(Offset(x0, yRegle), Offset(x0 + course, yRegle), trait);
    for (int d = 1; d <= InverseSquareFigure.distanceMax.round(); d++) {
      final double x = x0 + course * (d / InverseSquareFigure.distanceMax);
      canvas.drawLine(Offset(x, yRegle - 4), Offset(x, yRegle + 4), trait);
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: '×$d',
          style: AppTypography.formula(
            size: 10,
            color: tokens.inkSubtle.withValues(alpha: 0.8),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, yRegle + 6));
    }
  }

  void _peindreFantome(Canvas canvas, double x, double y) {
    final Paint fantome = Paint()
      ..color = tokens.inkSubtle.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), 15, fantome);
    // La flèche de référence, à sa longueur d'origine.
    final Paint trait = Paint()
      ..color = tokens.inkSubtle.withValues(alpha: 0.35)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(x - 15, y - 34), Offset(x - 15 - 54, y - 34), trait);
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: 'force au départ',
        style: AppTypography.formula(
          size: 10,
          color: tokens.inkSubtle.withValues(alpha: 0.7),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x - 15 - 54, y - 50));
  }

  void _peindreCorps(
    Canvas canvas,
    Offset centre,
    double rayon, {
    required bool gros,
  }) {
    // Deux sphères éclairées, pas deux disques : l'ombrage est ce qui dit
    // qu'on regarde des corps et non des pastilles.
    Realisme.sphere(
      canvas,
      centre,
      rayon,
      couleur: gros ? const Color(0xFF5B8DEF) : const Color(0xFFC9772F),
      lumiere: const Offset(-0.45, -0.5),
    );
  }

  void _peindreFleches(
    Canvas canvas,
    Size size,
    double xGauche,
    double xDroite,
    double y,
  ) {
    final double force = InverseSquareFigure.force(distance);
    // La flèche de référence mesure 54 points ; les autres suivent la loi.
    final double longueur = (54 * force).clamp(0.0, 92.0);

    final Paint trait = Paint()
      ..color = tokens.error
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;

    // Les deux corps s'attirent mutuellement : deux flèches opposées, de
    // même longueur. Une seule flèche laisserait croire que l'un subit et
    // que l'autre agit, ce qui est faux.
    _fleche(canvas, Offset(xDroite - 15, y - 34),
        Offset(xDroite - 15 - longueur, y - 34), trait);
    _fleche(canvas, Offset(xGauche + 26, y + 34),
        Offset(xGauche + 26 + longueur, y + 34), trait);

    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: force >= 0.01
            ? 'F = ${force.toStringAsFixed(2).replaceAll('.', ',')}'
            : 'F ≈ 0',
        style: AppTypography.formula(size: 12, color: tokens.error),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(xDroite - 15 - longueur, y - 52));
  }

  void _fleche(Canvas canvas, Offset depart, Offset bout, Paint trait) {
    if ((bout - depart).distance < 3) {
      // Une force trop faible pour être dessinée reste signalée par un
      // point : « négligeable » ne veut pas dire « nulle ».
      canvas.drawCircle(depart, 2.2, Paint()..color = trait.color);
      return;
    }
    canvas.drawLine(depart, bout, trait);
    final double angle = math.atan2(bout.dy - depart.dy, bout.dx - depart.dx);
    final Path pointe = Path()
      ..moveTo(bout.dx, bout.dy)
      ..lineTo(bout.dx - 7 * math.cos(angle - 0.4),
          bout.dy - 7 * math.sin(angle - 0.4))
      ..lineTo(bout.dx - 7 * math.cos(angle + 0.4),
          bout.dy - 7 * math.sin(angle + 0.4))
      ..close();
    canvas.drawPath(pointe, Paint()..color = trait.color);
  }

  @override
  bool shouldRepaint(_AttractionPainter ancien) =>
      ancien.distance != distance || ancien.accent != accent;
}
