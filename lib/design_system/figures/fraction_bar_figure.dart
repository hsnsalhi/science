/// Deux barres partagées, pour voir ce que vaut une fraction.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';

/// Une barre qu'on partage et qu'on colorie, à comparer à une demie.
///
/// Une fraction écrite ne dit rien à qui ne l'a pas vue : 3/8 et 1/2 ont
/// l'air de se valoir tant qu'ils restent des chiffres. Posées l'une
/// sous l'autre et coloriées, les deux barres se comparent d'un coup
/// d'œil, et la comparaison précède la règle plutôt que de la suivre.
///
/// Le dénominateur change le nombre de parts, pas la longueur de la
/// barre : c'est le point que la figure doit rendre évident, parce que
/// c'est celui qui manque quand on croit que 1/8 est plus grand que 1/4
/// au motif que huit est plus grand que quatre.
class FractionBarFigure extends StatefulWidget {
  const FractionBarFigure({required this.accent, super.key});

  final Color accent;

  /// Valeur décimale d'une fraction.
  static double valeur(int numerateur, int denominateur) =>
      numerateur / denominateur;

  /// Compare deux fractions : -1, 0 ou 1.
  ///
  /// On compare les produits en croix plutôt que les décimales, pour que
  /// 1/3 et 2/6 soient déclarés égaux sans dépendre d'un arrondi.
  static int comparer(int n1, int d1, int n2, int d2) {
    final int gauche = n1 * d2;
    final int droite = n2 * d1;
    return gauche.compareTo(droite);
  }

  /// Fraction réduite, sous sa forme la plus simple.
  static ({int numerateur, int denominateur}) simplifier(
    int numerateur,
    int denominateur,
  ) {
    int a = numerateur.abs();
    int b = denominateur.abs();
    while (b != 0) {
      final int reste = a % b;
      a = b;
      b = reste;
    }
    final int pgcd = a == 0 ? 1 : a;
    return (
      numerateur: numerateur ~/ pgcd,
      denominateur: denominateur ~/ pgcd,
    );
  }

  @override
  State<FractionBarFigure> createState() => _FractionBarFigureState();
}

class _FractionBarFigureState extends State<FractionBarFigure> {
  int _parts = 8;
  int _coloriees = 3;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final int signe = FractionBarFigure.comparer(_coloriees, _parts, 1, 2);
    final String verdict = switch (signe) {
      < 0 => 'moins de la moitié',
      0 => 'exactement la moitié',
      _ => 'plus de la moitié',
    };
    final ({int numerateur, int denominateur}) simple =
        FractionBarFigure.simplifier(_coloriees, _parts);
    final bool reductible =
        simple.denominateur != _parts && _coloriees > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: 150,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return CustomPaint(
                size: Size(constraints.maxWidth, 150),
                painter: _BarresPainter(
                  parts: _parts,
                  coloriees: _coloriees,
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
          '$_coloriees/$_parts, c\'est $verdict.',
          textAlign: TextAlign.center,
          style: AppTypography.formula(size: 18, color: widget.accent),
        ),
        Text(
          reductible
              ? 'C\'est aussi ${simple.numerateur}/${simple.denominateur} : '
                    'les mêmes parts, autrement découpées.'
              : 'Cette fraction ne peut pas s\'écrire plus simplement.',
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkMuted),
        ),
        const SizedBox(height: AppSpacing.xs),
        _Reglage(
          nom: 'parts',
          valeur: _parts,
          min: 2,
          max: 12,
          accent: widget.accent,
          onChanged: (int v) => setState(() {
            _parts = v;
            _coloriees = math.min(_coloriees, v);
          }),
        ),
        _Reglage(
          nom: 'coloriées',
          valeur: _coloriees,
          min: 0,
          max: _parts,
          accent: widget.accent,
          onChanged: (int v) => setState(() => _coloriees = v),
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
          width: 74,
          child: Text(
            nom,
            style: context.text.labelSmall?.copyWith(
              color: context.tokens.inkSubtle,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: valeur.toDouble().clamp(
              min.toDouble(),
              max.toDouble(),
            ),
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

class _BarresPainter extends CustomPainter {
  const _BarresPainter({
    required this.parts,
    required this.coloriees,
    required this.accent,
    required this.trait,
    required this.muted,
    required this.surface,
  });

  final int parts;
  final int coloriees;
  final Color accent;
  final Color trait;
  final Color muted;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    const double marge = 14;
    final double largeur = size.width - marge * 2;
    const double hauteur = 42;

    // La barre réglable, puis la demie de référence : même longueur,
    // posées l'une sous l'autre pour que la comparaison soit immédiate.
    _barre(canvas, const Offset(marge, 20), largeur, hauteur, parts,
        coloriees, accent, '$coloriees/$parts');
    _barre(canvas, const Offset(marge, 92), largeur, hauteur, 2, 1,
        muted.withValues(alpha: 0.55), '1/2');
  }

  void _barre(
    Canvas canvas,
    Offset coin,
    double largeur,
    double hauteur,
    int parts,
    int coloriees,
    Color couleur,
    String etiquette,
  ) {
    final Rect cadre = Rect.fromLTWH(coin.dx, coin.dy, largeur, hauteur);
    final RRect arrondi = RRect.fromRectAndRadius(
      cadre,
      const Radius.circular(8),
    );
    canvas.drawRRect(arrondi, Paint()..color = surface);

    canvas.save();
    canvas.clipRRect(arrondi);
    canvas.drawRect(
      Rect.fromLTWH(
        cadre.left,
        cadre.top,
        largeur * coloriees / parts,
        hauteur,
      ),
      Paint()..color = couleur,
    );
    for (int i = 1; i < parts; i++) {
      final double x = cadre.left + largeur * i / parts;
      canvas.drawLine(
        Offset(x, cadre.top),
        Offset(x, cadre.bottom),
        Paint()
          ..color = trait
          ..strokeWidth = 1.5,
      );
    }
    canvas.restore();

    canvas.drawRRect(
      arrondi,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = trait,
    );

    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: etiquette,
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
    painter.paint(canvas, Offset(cadre.left, cadre.top - 17));
  }

  @override
  bool shouldRepaint(_BarresPainter old) =>
      old.parts != parts ||
      old.coloriees != coloriees ||
      old.accent != accent;
}
