/// Configuration de Thalès : une parallèle qui coupe un triangle.
library;


import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/question.dart';

/// Un triangle coupé par une parallèle qu'on fait glisser.
///
/// Tout bouge quand on déplace la parallèle : les six longueurs changent,
/// et les trois rapports restent égaux. C'est précisément ce qu'une figure
/// fixe ne peut pas établir — sur un seul dessin, l'égalité des rapports
/// passe pour une coïncidence de ce tracé-là.
class ThalesFigure extends StatefulWidget {
  const ThalesFigure({required this.accent, super.key});

  final Color accent;

  /// Longueurs du triangle de référence, en unités arbitraires.
  static const double ab = 8;
  static const double ac = 6;
  static const double bc = 7;

  @override
  State<ThalesFigure> createState() => _ThalesFigureState();
}

class _ThalesFigureState extends State<ThalesFigure> {
  /// Position de la parallèle : part de [A] vers [BC], de 0 à 1.
  double _k = 0.55;

  void _deplacer(double valeur) {
    final double borne = valeur.clamp(0.18, 0.92);
    if ((borne - _k).abs() < 0.004) return;
    context.tapFeedback();
    setState(() => _k = borne);
  }

  String _n(double valeur) =>
      NumericQuestion.formatNumber((valeur * 10).roundToDouble() / 10);

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    const double ab = ThalesFigure.ab;
    const double ac = ThalesFigure.ac;
    const double bc = ThalesFigure.bc;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double largeur = constraints.maxWidth;
            final double hauteur = largeur * 0.82;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: (DragUpdateDetails d) =>
                  _deplacer(d.localPosition.dy / hauteur),
              onTapDown: (TapDownDetails d) =>
                  _deplacer(d.localPosition.dy / hauteur),
              child: Semantics(
                label:
                    'Triangle ABC coupé par une parallèle DE. '
                    'AD vaut ${_n(ab * _k)}, AB vaut ${_n(ab)}. '
                    'Glisse pour déplacer la parallèle.',
                child: SizedBox(
                  width: largeur,
                  height: hauteur,
                  child: CustomPaint(
                    painter: _ThalesPainter(
                      k: _k,
                      accent: widget.accent,
                      ink: context.colors.onSurface,
                      muted: tokens.inkMuted,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        // Les trois rapports, côte à côte. Leur égalité constante est le
        // théorème ; la voir tenir en déplaçant la parallèle vaut mieux
        // que de l'énoncer.
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            _Rapport(
              haut: 'AD',
              bas: 'AB',
              valeur: _k,
              accent: widget.accent,
            ),
            _Rapport(
              haut: 'AE',
              bas: 'AC',
              valeur: _k,
              accent: widget.accent,
            ),
            _Rapport(
              haut: 'DE',
              bas: 'BC',
              valeur: _k,
              accent: widget.accent,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'AD = ${_n(ab * _k)}   AE = ${_n(ac * _k)}   DE = ${_n(bc * _k)}',
          style: context.text.bodySmall?.copyWith(color: tokens.inkMuted),
        ),
        Text(
          'AB = ${_n(ab)}   AC = ${_n(ac)}   BC = ${_n(bc)}',
          style: context.text.bodySmall?.copyWith(color: tokens.inkMuted),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.pan_tool_alt_rounded, size: 15, color: tokens.inkSubtle),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                'Glisse verticalement pour déplacer la parallèle',
                style: context.text.labelSmall?.copyWith(
                  color: tokens.inkSubtle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Un rapport affiché en fraction, avec sa valeur.
class _Rapport extends StatelessWidget {
  const _Rapport({
    required this.haut,
    required this.bas,
    required this.valeur,
    required this.accent,
  });

  final String haut;
  final String bas;
  final double valeur;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(haut, style: AppTypography.formula(size: 13, color: accent)),
            Container(width: 24, height: 1.5, color: accent),
            Text(bas, style: AppTypography.formula(size: 13, color: accent)),
          ],
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '= ${NumericQuestion.formatNumber((valeur * 100).roundToDouble() / 100)}',
          style: AppTypography.formula(size: 14, color: accent),
        ),
      ],
    );
  }
}

class _ThalesPainter extends CustomPainter {
  const _ThalesPainter({
    required this.k,
    required this.accent,
    required this.ink,
    required this.muted,
  });

  final double k;
  final Color accent;
  final Color ink;
  final Color muted;

  @override
  void paint(Canvas canvas, Size size) {
    const double marge = 26;
    final Offset a = Offset(size.width * 0.34, marge);
    final Offset b = Offset(marge, size.height - marge);
    final Offset c = Offset(size.width - marge, size.height - marge);

    // D et E sont sur [AB] et [AC], à la même fraction k du sommet.
    final Offset d = Offset.lerp(a, b, k)!;
    final Offset e = Offset.lerp(a, c, k)!;

    final Paint trait = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = ink.withValues(alpha: 0.75);

    // Le petit triangle ADE, teinté : c'est la réduction du grand.
    canvas.drawPath(
      Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(d.dx, d.dy)
        ..lineTo(e.dx, e.dy)
        ..close(),
      Paint()..color = accent.withValues(alpha: 0.18),
    );

    canvas.drawPath(
      Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..lineTo(c.dx, c.dy)
        ..close(),
      trait,
    );

    // La parallèle, tracée par-dessus et mise en avant.
    canvas.drawLine(
      d,
      e,
      Paint()
        ..strokeWidth = 3
        ..color = accent,
    );

    // Marques de parallélisme : un chevron sur (DE) et un sur (BC).
    _chevron(canvas, Offset.lerp(d, e, 0.5)!, e - d, accent);
    _chevron(canvas, Offset.lerp(b, c, 0.5)!, c - b, ink.withValues(alpha: 0.6));

    for (final (Offset point, String nom) in <(Offset, String)>[
      (a, 'A'),
      (b, 'B'),
      (c, 'C'),
      (d, 'D'),
      (e, 'E'),
    ]) {
      final bool mobile = nom == 'D' || nom == 'E';
      canvas.drawCircle(
        point,
        mobile ? 5 : 4,
        Paint()..color = mobile ? accent : ink,
      );
      _texte(
        canvas,
        nom,
        point + _ecart(nom),
        mobile ? accent : ink,
        mobile,
      );
    }
  }

  /// Décalage du libellé pour qu'il ne couvre pas le tracé.
  Offset _ecart(String nom) => switch (nom) {
    'A' => const Offset(0, -14),
    'B' => const Offset(-12, 10),
    'C' => const Offset(12, 10),
    'D' => const Offset(-14, 0),
    _ => const Offset(14, 0),
  };

  void _chevron(Canvas canvas, Offset centre, Offset direction, Color couleur) {
    final double longueur = direction.distance;
    if (longueur == 0) return;
    final Offset u = direction / longueur;
    final Offset n = Offset(-u.dy, u.dx);
    final Paint p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = couleur;
    canvas.drawLine(centre - u * 4 - n * 5, centre + u * 4, p);
    canvas.drawLine(centre - u * 4 + n * 5, centre + u * 4, p);
  }

  void _texte(
    Canvas canvas,
    String texte,
    Offset centre,
    Color couleur,
    bool gras,
  ) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: texte,
        style: TextStyle(
          fontFamily: AppTypography.body,
          color: couleur,
          fontSize: 14,
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
  bool shouldRepaint(_ThalesPainter old) => old.k != k || old.accent != accent;
}
