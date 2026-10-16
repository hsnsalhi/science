/// Un rectangle coupé en deux, pour voir d'où vient la distributivité.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';

/// Le rectangle k × (a + b), découpé le long de la coupure a | b.
///
/// La règle k(a + b) = ka + kb s'apprend d'ordinaire comme une consigne de
/// recopie, et c'est pourquoi elle s'applique de travers : on multiplie le
/// premier terme et on oublie le second. Vue comme une aire, elle n'est plus
/// une consigne du tout. Le grand rectangle ne change pas quand on trace un
/// trait dedans ; seule l'écriture de son aire change. Il n'y a donc rien à
/// retenir, seulement quelque chose à ne pas perdre de vue.
///
/// Les trois côtés sont réglables pour que l'égalité ne tienne pas à un
/// choix de nombres heureux : les deux totaux affichés restent égaux quoi
/// qu'on bouge, et c'est le seul fait que la figure a à transmettre.
class DistributivityFigure extends StatefulWidget {
  const DistributivityFigure({required this.accent, super.key});

  final Color accent;

  /// Aire du rectangle entier, lue d'un seul bloc : k × (a + b).
  static int aireEntiere(int k, int a, int b) => k * (a + b);

  /// Aire des deux morceaux additionnés : k × a + k × b.
  static int aireDecoupee(int k, int a, int b) => k * a + k * b;

  /// Les deux lectures tombent-elles juste ?
  ///
  /// C'est la distributivité elle-même. La fonction existe pour que le test
  /// puisse la mettre en défaut sur beaucoup de triplets plutôt que de
  /// relire la figure.
  static bool concordent(int k, int a, int b) =>
      aireEntiere(k, a, b) == aireDecoupee(k, a, b);

  @override
  State<DistributivityFigure> createState() => _DistributivityFigureState();
}

class _DistributivityFigureState extends State<DistributivityFigure> {
  int _k = 3;
  int _a = 4;
  int _b = 2;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final int entiere = DistributivityFigure.aireEntiere(_k, _a, _b);
    final int decoupee = DistributivityFigure.aireDecoupee(_k, _a, _b);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: 170,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return CustomPaint(
                size: Size(constraints.maxWidth, 170),
                painter: _RectanglePainter(
                  k: _k,
                  a: _a,
                  b: _b,
                  accent: widget.accent,
                  second: tokens.inkMuted,
                  trait: tokens.border,
                  surface: context.colors.surface,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '$_k × ($_a + $_b) = $entiere',
          textAlign: TextAlign.center,
          style: AppTypography.formula(size: 18, color: widget.accent),
        ),
        Text(
          '$_k × $_a + $_k × $_b = ${_k * _a} + ${_k * _b} = $decoupee',
          textAlign: TextAlign.center,
          style: AppTypography.formula(size: 16, color: tokens.inkMuted),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          entiere == decoupee
              ? 'Le trait ne change pas l\'aire : les deux écritures la disent.'
              : 'Écart constaté : la figure est fausse.',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkSubtle),
        ),
        const SizedBox(height: AppSpacing.xs),
        _Reglage(
          nom: 'k',
          valeur: _k,
          min: 1,
          max: 6,
          accent: widget.accent,
          onChanged: (int v) => setState(() => _k = v),
        ),
        _Reglage(
          nom: 'a',
          valeur: _a,
          min: 1,
          max: 8,
          accent: widget.accent,
          onChanged: (int v) => setState(() => _a = v),
        ),
        _Reglage(
          nom: 'b',
          valeur: _b,
          min: 1,
          max: 8,
          accent: widget.accent,
          onChanged: (int v) => setState(() => _b = v),
        ),
      ],
    );
  }
}

/// Un réglage entier, avec son nom à gauche.
class _Reglage extends StatelessWidget {
  const _Reglage({
    required this.nom,
    required this.valeur,
    required this.min,
    required this.max,
    required this.accent,
    required this.onChanged,
  });

  final String nom;
  final int valeur;
  final int min;
  final int max;
  final Color accent;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 24,
          child: Text(
            nom,
            style: AppTypography.formula(
              size: 15,
              color: context.tokens.inkSubtle,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: valeur.toDouble().clamp(min.toDouble(), max.toDouble()),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: math.max(1, max - min),
            onChanged: (double v) {
              context.tapFeedback();
              onChanged(v.round());
            },
          ),
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$valeur',
            textAlign: TextAlign.right,
            style: AppTypography.formula(size: 15, color: accent),
          ),
        ),
      ],
    );
  }
}

class _RectanglePainter extends CustomPainter {
  const _RectanglePainter({
    required this.k,
    required this.a,
    required this.b,
    required this.accent,
    required this.second,
    required this.trait,
    required this.surface,
  });

  final int k;
  final int a;
  final int b;
  final Color accent;
  final Color second;
  final Color trait;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    const double marge = 30;
    const double hautGraphe = 26;
    final double dispoLargeur = size.width - marge * 2;
    const double dispoHauteur = 170 - hautGraphe - 30;

    // L'unité est commune aux deux axes, sinon les aires ne se
    // comparent plus à l'œil et la figure perd tout son intérêt.
    final double unite = math.min(dispoLargeur / (a + b), dispoHauteur / k);
    final double largeurA = unite * a;
    final double largeurB = unite * b;
    final double hauteur = unite * k;
    const double gauche = marge;
    final double haut = hautGraphe + (dispoHauteur - hauteur) / 2;

    final Rect partA = Rect.fromLTWH(gauche, haut, largeurA, hauteur);
    final Rect partB = Rect.fromLTWH(gauche + largeurA, haut, largeurB,
        hauteur);

    canvas.drawRect(
      partA.expandToInclude(partB),
      Paint()..color = surface,
    );
    canvas.drawRect(partA, Paint()..color = accent.withValues(alpha: 0.42));
    canvas.drawRect(partB, Paint()..color = second.withValues(alpha: 0.38));

    // La grille unité : c'est elle qui transforme « aire » en « nombre de
    // carreaux », donc en quelque chose qu'on peut compter plutôt que croire.
    final Paint grille = Paint()
      ..color = trait.withValues(alpha: 0.5)
      ..strokeWidth = 0.8;
    for (int i = 1; i < a + b; i++) {
      final double x = gauche + unite * i;
      canvas.drawLine(Offset(x, haut), Offset(x, haut + hauteur), grille);
    }
    for (int j = 1; j < k; j++) {
      final double y = haut + unite * j;
      canvas.drawLine(
        Offset(gauche, y),
        Offset(gauche + largeurA + largeurB, y),
        grille,
      );
    }

    // La coupure, plus épaisse que la grille : c'est le geste du
    // développement, et le seul trait qu'on ajoute au rectangle.
    canvas.drawLine(
      Offset(gauche + largeurA, haut - 6),
      Offset(gauche + largeurA, haut + hauteur + 6),
      Paint()
        ..color = accent
        ..strokeWidth = 2.6,
    );

    canvas.drawRect(
      partA.expandToInclude(partB),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = trait,
    );

    _texte(canvas, '$a', Offset(gauche + largeurA / 2, haut - 20), accent,
        centre: true);
    _texte(canvas, '$b',
        Offset(gauche + largeurA + largeurB / 2, haut - 20), second,
        centre: true);
    _texte(canvas, '$k', Offset(gauche - 18, haut + hauteur / 2 - 8), trait);
    _texte(canvas, '${k * a}',
        Offset(gauche + largeurA / 2, haut + hauteur + 8), accent,
        centre: true);
    _texte(canvas, '${k * b}',
        Offset(gauche + largeurA + largeurB / 2, haut + hauteur + 8), second,
        centre: true);
  }

  void _texte(
    Canvas canvas,
    String texte,
    Offset position,
    Color couleur, {
    bool centre = false,
  }) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: texte,
        style: TextStyle(
          fontFamily: AppTypography.body,
          color: couleur,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      centre ? position.translate(-painter.width / 2, 0) : position,
    );
  }

  @override
  bool shouldRepaint(_RectanglePainter old) =>
      old.k != k || old.a != a || old.b != b || old.accent != accent;
}
