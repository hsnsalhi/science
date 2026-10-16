/// Une matrice 2 × 2, et ce qu'elle fait au plan.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/question.dart';

/// Le carré unité transformé, et le déterminant qui s'y lit.
///
/// Le déterminant se présente d'ordinaire comme une formule, ad − bc, dont
/// on apprend ensuite qu'elle « vaut zéro quand la matrice n'est pas
/// inversible ». Les deux faits restent sans rapport visible.
///
/// Ici la matrice transforme le carré unité, et le déterminant est l'aire
/// du parallélogramme obtenu — au signe près. Quand on règle les
/// coefficients jusqu'à aplatir le carré sur une droite, l'aire tombe à
/// zéro sous les yeux, et c'est exactement le moment où l'application
/// cesse d'être inversible : toute une surface a été écrasée sur une
/// ligne, et rien ne peut la rouvrir.
///
/// Le signe aussi se voit : quand le déterminant devient négatif, les deux
/// vecteurs images ont échangé leur sens de rotation. Le plan a été
/// retourné.
class MatrixFigure extends StatefulWidget {
  const MatrixFigure({required this.accent, super.key});

  final Color accent;

  /// Déterminant de la matrice [[a, b], [c, d]].
  static double determinant(double a, double b, double c, double d) =>
      a * d - b * c;

  /// L'image du vecteur (x, y) par la matrice.
  static ({double x, double y}) applique(
    double a,
    double b,
    double c,
    double d,
    double x,
    double y,
  ) => (x: a * x + b * y, y: c * x + d * y);

  /// La matrice est-elle inversible ?
  ///
  /// Le seuil n'est pas l'égalité stricte à zéro : les coefficients de la
  /// figure se règlent par pas de 0,25, et un déterminant de 1e-17 n'a pas
  /// de sens pour un élève.
  static bool inversible(double a, double b, double c, double d) =>
      determinant(a, b, c, d).abs() > 1e-9;

  @override
  State<MatrixFigure> createState() => _MatrixFigureState();
}

class _MatrixFigureState extends State<MatrixFigure> {
  double _a = 1.5;
  double _b = 0.5;
  double _c = 0;
  double _d = 1;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final double det = MatrixFigure.determinant(_a, _b, _c, _d);
    final bool inversible = MatrixFigure.inversible(_a, _b, _c, _d);

    final String verdict;
    if (!inversible) {
      verdict = 'Aire nulle : le carré est écrasé sur une droite, '
          'et la matrice n’est pas inversible.';
    } else if (det < 0) {
      verdict = 'Déterminant négatif : le plan a été retourné.';
    } else {
      verdict = 'Les aires sont multipliées par ${_format(det.abs())}.';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AspectRatio(
          aspectRatio: 1.2,
          child: CustomPaint(
            painter: _MatricePainter(
              a: _a,
              b: _b,
              c: _c,
              d: _d,
              accent: widget.accent,
              ink: context.colors.onSurface,
              trait: tokens.border,
              muted: tokens.inkMuted,
              surface: context.colors.surface,
              alerte: tokens.warning,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'det = ${_format(_a)} × ${_format(_d)} − '
          '${_format(_b)} × ${_format(_c)} = ${_format(det)}',
          textAlign: TextAlign.center,
          style: AppTypography.formula(
            size: 15,
            color: inversible ? widget.accent : tokens.warning,
          ),
        ),
        SizedBox(
          height: 38,
          child: Text(
            verdict,
            textAlign: TextAlign.center,
            style: context.text.bodySmall?.copyWith(color: tokens.inkMuted),
          ),
        ),
        for (final ({String nom, double valeur, ValueChanged<double> poser})
            reglage in <({String nom, double valeur, ValueChanged<double> poser})>[
          (nom: 'a', valeur: _a, poser: (double v) => _a = v),
          (nom: 'b', valeur: _b, poser: (double v) => _b = v),
          (nom: 'c', valeur: _c, poser: (double v) => _c = v),
          (nom: 'd', valeur: _d, poser: (double v) => _d = v),
        ])
          Row(
            children: <Widget>[
              SizedBox(
                width: 20,
                child: Text(
                  reglage.nom,
                  style: AppTypography.formula(
                    size: 15,
                    color: widget.accent,
                  ),
                ),
              ),
              Expanded(
                child: Slider(
                  value: reglage.valeur,
                  min: -2,
                  max: 2,
                  divisions: 16,
                  onChanged: (double v) {
                    context.tapFeedback();
                    setState(
                      () => reglage.poser((v * 4).roundToDouble() / 4),
                    );
                  },
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  _format(reglage.valeur),
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

  String _format(double v) =>
      NumericQuestion.formatNumber((v * 100).roundToDouble() / 100);
}

class _MatricePainter extends CustomPainter {
  const _MatricePainter({
    required this.a,
    required this.b,
    required this.c,
    required this.d,
    required this.accent,
    required this.ink,
    required this.trait,
    required this.muted,
    required this.surface,
    required this.alerte,
  });

  final double a;
  final double b;
  final double c;
  final double d;
  final Color accent;
  final Color ink;
  final Color trait;
  final Color muted;
  final Color surface;
  final Color alerte;

  /// Demi-largeur de la fenêtre, en unités du repère.
  static const double portee = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final double echelle = math.min(
      size.width / (2 * portee),
      size.height / (2 * portee),
    );
    final Offset origine = Offset(size.width / 2, size.height / 2);

    Offset p(double x, double y) =>
        Offset(origine.dx + x * echelle, origine.dy - y * echelle);

    canvas.drawRect(Offset.zero & size, Paint()..color = surface);
    canvas.clipRect(Offset.zero & size);

    final Paint grille = Paint()
      ..color = trait.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    for (int i = -portee.toInt(); i <= portee.toInt(); i++) {
      canvas.drawLine(p(i.toDouble(), -portee), p(i.toDouble(), portee), grille);
      canvas.drawLine(p(-portee, i.toDouble()), p(portee, i.toDouble()), grille);
    }
    canvas.drawLine(
      p(-portee, 0),
      p(portee, 0),
      Paint()
        ..color = ink.withValues(alpha: 0.6)
        ..strokeWidth = 1.6,
    );
    canvas.drawLine(
      p(0, -portee),
      p(0, portee),
      Paint()
        ..color = ink.withValues(alpha: 0.6)
        ..strokeWidth = 1.6,
    );

    // Le carré unité de départ, en pointillé : sans lui, on ne voit pas
    // de quoi le parallélogramme est l'image.
    final Paint pointille = Paint()
      ..color = muted.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawRect(Rect.fromPoints(p(0, 0), p(1, 1)), pointille);

    final ({double x, double y}) e1 = MatrixFigure.applique(a, b, c, d, 1, 0);
    final ({double x, double y}) e2 = MatrixFigure.applique(a, b, c, d, 0, 1);
    final double det = MatrixFigure.determinant(a, b, c, d);
    final Color couleur = det.abs() < 1e-9
        ? alerte
        : (det < 0 ? alerte : accent);

    // L'image du carré : un parallélogramme, ou un segment si le
    // déterminant est nul. Le remplissage rend l'aire lisible.
    final Path image = Path()
      ..moveTo(p(0, 0).dx, p(0, 0).dy)
      ..lineTo(p(e1.x, e1.y).dx, p(e1.x, e1.y).dy)
      ..lineTo(p(e1.x + e2.x, e1.y + e2.y).dx, p(e1.x + e2.x, e1.y + e2.y).dy)
      ..lineTo(p(e2.x, e2.y).dx, p(e2.x, e2.y).dy)
      ..close();
    canvas.drawPath(
      image,
      Paint()..color = couleur.withValues(alpha: 0.18),
    );
    canvas.drawPath(
      image,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = couleur,
    );

    // Les deux vecteurs images, qui portent les côtés.
    for (final ({({double x, double y}) v, String nom}) fleche
        in <({({double x, double y}) v, String nom})>[
          (v: e1, nom: 'a, c'),
          (v: e2, nom: 'b, d'),
        ]) {
      canvas.drawLine(
        p(0, 0),
        p(fleche.v.x, fleche.v.y),
        Paint()
          ..color = couleur
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(
        p(fleche.v.x, fleche.v.y),
        4.5,
        Paint()..color = couleur,
      );
    }
  }

  @override
  bool shouldRepaint(_MatricePainter old) =>
      old.a != a || old.b != b || old.c != c || old.d != d;
}
