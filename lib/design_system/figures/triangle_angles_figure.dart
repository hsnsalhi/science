/// Un triangle dont on choisit deux angles — jamais le troisième.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/question.dart';

/// Deux angles réglables, et le troisième qui suit.
///
/// « La somme des angles d'un triangle vaut 180° » s'apprend comme une
/// formule et se vérifie au rapporteur, ce qui donne 179 ou 181 et
/// laisse un doute. Ici, le troisième angle n'est pas réglable : il est
/// calculé. On ne peut pas construire de contre-exemple, et c'est ce
/// que la règle veut dire.
///
/// Le triangle se déforme en direct. Pousser un angle vers 0 donne une
/// figure aplatie : la limite se voit, et avec elle la raison pour
/// laquelle un triangle ne peut pas avoir deux angles droits.
class TriangleAnglesFigure extends StatefulWidget {
  const TriangleAnglesFigure({required this.accent, super.key});

  final Color accent;

  /// Somme des angles d'un triangle, en degrés.
  static const double somme = 180;

  /// Troisième angle, déduit des deux autres.
  static double troisieme(double a, double b) => somme - a - b;

  /// Nature du triangle d'après ses trois angles.
  static String nature(double a, double b) {
    final double c = troisieme(a, b);
    final List<double> angles = <double>[a, b, c]..sort();
    if ((angles[2] - 90).abs() < 0.5) return 'rectangle';
    if (angles[2] > 90) return 'obtusangle';
    if ((angles[0] - 60).abs() < 0.5 && (angles[2] - 60).abs() < 0.5) {
      return 'équilatéral';
    }
    return 'acutangle';
  }

  @override
  State<TriangleAnglesFigure> createState() => _TriangleAnglesFigureState();
}

class _TriangleAnglesFigureState extends State<TriangleAnglesFigure> {
  double _a = 60;
  double _b = 70;

  /// Borne haute d'un angle, pour que le troisième reste positif.
  static const double _marge = 10;

  String _n(double v) => NumericQuestion.formatNumber(v.roundToDouble());

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final double c = TriangleAnglesFigure.troisieme(_a, _b);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AspectRatio(
          aspectRatio: 1.35,
          child: CustomPaint(
            painter: _TrianglePainter(
              a: _a,
              b: _b,
              accent: widget.accent,
              ink: context.colors.onSurface,
              trait: tokens.border,
              muted: tokens.inkMuted,
              surface: context.colors.surface,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${_n(_a)}° + ${_n(_b)}° + ${_n(c)}° = '
          '${_n(TriangleAnglesFigure.somme)}°',
          style: AppTypography.formula(size: 18, color: widget.accent),
        ),
        Text(
          'Triangle ${TriangleAnglesFigure.nature(_a, _b)}. Le troisième '
          'angle n\'est pas réglable : il se déduit des deux autres.',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkMuted),
        ),
        _Reglage(
          nom: 'angle A',
          valeur: _a,
          max: TriangleAnglesFigure.somme - _b - _marge,
          accent: widget.accent,
          onChanged: (double v) => setState(() => _a = v.roundToDouble()),
        ),
        _Reglage(
          nom: 'angle B',
          valeur: _b,
          max: TriangleAnglesFigure.somme - _a - _marge,
          accent: widget.accent,
          onChanged: (double v) => setState(() => _b = v.roundToDouble()),
        ),
      ],
    );
  }
}

class _Reglage extends StatelessWidget {
  const _Reglage({
    required this.nom,
    required this.valeur,
    required this.max,
    required this.accent,
    required this.onChanged,
  });

  final String nom;
  final double valeur;
  final double max;
  final Color accent;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 68,
          child: Text(
            nom,
            style: context.text.labelSmall?.copyWith(
              color: context.tokens.inkSubtle,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: valeur.clamp(10, math.max(max, 11)),
            min: 10,
            max: math.max(max, 11),
            onChanged: (double v) {
              context.tapFeedback();
              onChanged(v);
            },
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(
            '${valeur.round()}°',
            textAlign: TextAlign.right,
            style: AppTypography.formula(size: 15, color: accent),
          ),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  const _TrianglePainter({
    required this.a,
    required this.b,
    required this.accent,
    required this.ink,
    required this.trait,
    required this.muted,
    required this.surface,
  });

  final double a;
  final double b;
  final Color accent;
  final Color ink;
  final Color trait;
  final Color muted;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    // Le côté AB est horizontal ; les deux autres partent de A et de B
    // avec les angles demandés, et se coupent en C.
    const double marge = 30;
    final double largeur = size.width - marge * 2;
    final Offset pointA = Offset(marge, size.height - marge);
    final Offset pointB = Offset(marge + largeur, size.height - marge);

    final double radA = a * math.pi / 180;
    final double radB = b * math.pi / 180;
    // Intersection des deux demi-droites, par la loi des sinus.
    final double c = TriangleAnglesFigure.troisieme(a, b);
    final double longueurAC = largeur * math.sin(radB) / math.sin(c * math.pi / 180);
    final Offset pointC =
        pointA + Offset(math.cos(radA), -math.sin(radA)) * longueurAC;

    // Si le triangle dépasse du cadre, on le réduit autour de AB.
    double echelle = 1;
    if (pointC.dy < marge) {
      echelle = (pointA.dy - marge) / (pointA.dy - pointC.dy);
    }
    final Offset c2 = pointA + (pointC - pointA) * echelle;
    final Offset b2 = pointA + (pointB - pointA) * echelle;

    final Path triangle = Path()
      ..moveTo(pointA.dx, pointA.dy)
      ..lineTo(b2.dx, b2.dy)
      ..lineTo(c2.dx, c2.dy)
      ..close();
    canvas.drawPath(triangle, Paint()..color = accent.withValues(alpha: 0.18));
    canvas.drawPath(
      triangle,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = accent,
    );

    _angle(canvas, pointA, b2, c2, a, 'A');
    _angle(canvas, b2, c2, pointA, b, 'B');
    _angle(canvas, c2, pointA, b2, c, 'C');
  }

  /// Marque l'angle au sommet [sommet], entre les deux autres points.
  void _angle(
    Canvas canvas,
    Offset sommet,
    Offset vers1,
    Offset vers2,
    double valeur,
    String nom,
  ) {
    final double a1 = math.atan2(vers1.dy - sommet.dy, vers1.dx - sommet.dx);
    final double a2 = math.atan2(vers2.dy - sommet.dy, vers2.dx - sommet.dx);
    double ouverture = a2 - a1;
    while (ouverture <= -math.pi) {
      ouverture += 2 * math.pi;
    }
    while (ouverture > math.pi) {
      ouverture -= 2 * math.pi;
    }
    const double rayon = 22;
    canvas.drawPath(
      Path()
        ..moveTo(sommet.dx, sommet.dy)
        ..arcTo(
          Rect.fromCircle(center: sommet, radius: rayon),
          a1,
          ouverture,
          false,
        )
        ..close(),
      Paint()..color = accent.withValues(alpha: 0.3),
    );

    final double milieu = a1 + ouverture / 2;
    _texte(
      canvas,
      '${valeur.round()}°',
      sommet + Offset(math.cos(milieu), math.sin(milieu)) * (rayon + 15),
      ink,
      gras: true,
    );
    _texte(
      canvas,
      nom,
      sommet - Offset(math.cos(milieu), math.sin(milieu)) * 14,
      muted,
    );
  }

  void _texte(
    Canvas canvas,
    String texte,
    Offset centre,
    Color couleur, {
    bool gras = false,
  }) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: texte,
        style: TextStyle(
          fontFamily: AppTypography.body,
          fontFamilyFallback: AppTypography.replis,
          color: couleur,
          fontSize: gras ? 13 : 11,
          fontWeight: gras ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      centre - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_TrianglePainter old) =>
      old.a != a || old.b != b || old.accent != accent;
}
