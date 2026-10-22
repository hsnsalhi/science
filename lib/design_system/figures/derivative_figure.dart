/// La sécante qui devient tangente, quand l'écart se referme.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/question.dart';

/// Le nombre dérivé, obtenu en resserrant une sécante.
///
/// On pose un point A sur la courbe, un point B un peu plus loin, et on
/// trace la droite qui les joint. Puis on rapproche B de A. La droite
/// pivote, de moins en moins, et finit par se poser sur la courbe : la
/// pente de la sécante tend vers le nombre dérivé.
///
/// La définition par limite est courte à écrire et difficile à se
/// représenter, parce qu'elle parle d'un objet qui n'existe à aucune
/// étape du calcul — la tangente n'est jamais une sécante. Ici on
/// resserre l'écart à la main et on voit le nombre se stabiliser bien
/// avant que l'écart ne soit nul.
class DerivativeFigure extends StatefulWidget {
  const DerivativeFigure({required this.accent, super.key});

  final Color accent;

  /// La fonction étudiée : le carré, dont la dérivée est connue.
  static double f(double x) => x * x;

  /// Pente de la sécante entre les abscisses [a] et [a] + [h].
  ///
  /// C'est le taux d'accroissement, et rien d'autre : une division de
  /// deux écarts, que n'importe quel élève sait faire.
  static double penteSecante(double a, double h) => (f(a + h) - f(a)) / h;

  /// Nombre dérivé en [a], vers lequel la pente de la sécante tend.
  static double derivee(double a) => 2 * a;

  @override
  State<DerivativeFigure> createState() => _DerivativeFigureState();
}

class _DerivativeFigureState extends State<DerivativeFigure> {
  double _a = 1;

  /// Position du curseur d'écart, entre 0 et 1.
  double _reglage = 0.75;

  /// Écart entre les deux points, lu sur une échelle logarithmique.
  ///
  /// Sans cela, la moitié de la course du curseur servirait à passer de
  /// 2 à 1, et il serait impossible d'atteindre les petits écarts qui
  /// font tout l'intérêt de la figure.
  double get _h => math.pow(10, -2 + 2.3 * _reglage).toDouble();

  String _n(double v, {int decimales = 3}) {
    final double facteur = math.pow(10, decimales).toDouble();
    return NumericQuestion.formatNumber(
      (v * facteur).roundToDouble() / facteur,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final double pente = DerivativeFigure.penteSecante(_a, _h);
    final double limite = DerivativeFigure.derivee(_a);
    final bool confondue = _h < 0.05;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AspectRatio(
          aspectRatio: 1.1,
          child: CustomPaint(
            painter: _CourbePainter(
              a: _a,
              h: _h,
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
          'pente de la sécante = ${_n(pente)}',
          style: AppTypography.formula(size: 17, color: widget.accent),
        ),
        Text(
          confondue
              ? 'La sécante se confond avec la tangente : f\'(${_n(_a, decimales: 2)}) = ${_n(limite, decimales: 2)}'
              : 'Resserre encore l\'écart h = ${_n(_h)}',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(
            color: confondue ? widget.accent : tokens.inkMuted,
          ),
        ),
        _Reglage(
          nom: 'a',
          affichage: _n(_a, decimales: 2),
          valeur: _a,
          min: -2,
          max: 2,
          accent: widget.accent,
          onChanged: (double v) =>
              setState(() => _a = (v * 4).roundToDouble() / 4),
        ),
        _Reglage(
          nom: 'h',
          affichage: _n(_h),
          valeur: _reglage,
          min: 0,
          max: 1,
          accent: widget.accent,
          onChanged: (double v) => setState(() => _reglage = v),
        ),
      ],
    );
  }
}

class _Reglage extends StatelessWidget {
  const _Reglage({
    required this.nom,
    required this.affichage,
    required this.valeur,
    required this.min,
    required this.max,
    required this.accent,
    required this.onChanged,
  });

  final String nom;
  final String affichage;
  final double valeur;
  final double min;
  final double max;
  final Color accent;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 20,
          child: Text(
            nom,
            style: AppTypography.formula(size: 15, color: accent),
          ),
        ),
        Expanded(
          child: Slider(
            value: valeur.clamp(min, max),
            min: min,
            max: max,
            onChanged: (double v) {
              context.tapFeedback();
              onChanged(v);
            },
          ),
        ),
        SizedBox(
          width: 50,
          child: Text(
            affichage,
            textAlign: TextAlign.right,
            style: AppTypography.formula(
              size: 14,
              color: context.colors.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _CourbePainter extends CustomPainter {
  const _CourbePainter({
    required this.a,
    required this.h,
    required this.accent,
    required this.ink,
    required this.trait,
    required this.muted,
    required this.surface,
  });

  final double a;
  final double h;
  final Color accent;
  final Color ink;
  final Color trait;
  final Color muted;
  final Color surface;

  static const double porteeX = 3;
  static const double porteeY = 5;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = surface);
    canvas.clipRect(Offset.zero & size);

    final double echelleX = size.width / (2 * porteeX);
    final double echelleY = size.height / (porteeY + 1.2);
    final Offset origine = Offset(size.width / 2, size.height - echelleY * 1.2);

    Offset p(double x, double y) =>
        Offset(origine.dx + x * echelleX, origine.dy - y * echelleY);

    final Paint grille = Paint()
      ..color = trait.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    for (int i = -porteeX.toInt(); i <= porteeX.toInt(); i++) {
      canvas.drawLine(p(i.toDouble(), -1.2), p(i.toDouble(), porteeY), grille);
    }
    for (int j = -1; j <= porteeY.toInt(); j++) {
      canvas.drawLine(p(-porteeX, j.toDouble()), p(porteeX, j.toDouble()), grille);
    }
    final Paint axes = Paint()
      ..color = ink.withValues(alpha: 0.6)
      ..strokeWidth = 1.8;
    canvas.drawLine(p(-porteeX, 0), p(porteeX, 0), axes);
    canvas.drawLine(p(0, -1.2), p(0, porteeY), axes);

    // La courbe.
    final Path courbe = Path();
    for (int i = 0; i <= size.width.toInt(); i++) {
      final double x = -porteeX + 2 * porteeX * i / size.width;
      final Offset point = p(x, DerivativeFigure.f(x));
      i == 0 ? courbe.moveTo(point.dx, point.dy) : courbe.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      courbe,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = ink.withValues(alpha: 0.75),
    );

    // La sécante, prolongée des deux côtés du cadre.
    final double pente = DerivativeFigure.penteSecante(a, h);
    final double ordonnee = DerivativeFigure.f(a) - pente * a;
    canvas.drawLine(
      p(-porteeX, pente * -porteeX + ordonnee),
      p(porteeX, pente * porteeX + ordonnee),
      Paint()
        ..color = accent
        ..strokeWidth = 2.5,
    );

    // Le triangle des accroissements : Δx en bas, Δy à droite. C'est le
    // quotient de ces deux longueurs qu'on calcule, et le voir dessiné
    // vaut mieux que de le lire dans une formule.
    final Offset pointA = p(a, DerivativeFigure.f(a));
    final Offset pointB = p(a + h, DerivativeFigure.f(a + h));
    final Paint pointille = Paint()
      ..color = muted
      ..strokeWidth = 1.5;
    canvas.drawLine(pointA, Offset(pointB.dx, pointA.dy), pointille);
    canvas.drawLine(Offset(pointB.dx, pointA.dy), pointB, pointille);

    // A porte son nom en bas à gauche, B en haut à droite : posés du
    // même côté, ils tombaient tous deux dans le triangle.
    for (final (Offset point, String nom, Offset decalage)
        in <(Offset, String, Offset)>[
      (pointA, 'A', const Offset(-15, 13)),
      (pointB, 'B', const Offset(15, -12)),
    ]) {
      canvas.drawCircle(point, 5.5, Paint()..color = surface);
      canvas.drawCircle(
        point,
        5.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = accent,
      );
      _texte(canvas, nom, point + decalage, accent);
    }
  }

  void _texte(Canvas canvas, String texte, Offset centre, Color couleur) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: texte,
        style: TextStyle(
          fontFamily: AppTypography.body,
          fontFamilyFallback: AppTypography.replis,
          color: couleur,
          fontSize: 13,
          fontWeight: FontWeight.w800,
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
  bool shouldRepaint(_CourbePainter old) =>
      old.a != a || old.h != h || old.accent != accent;
}
