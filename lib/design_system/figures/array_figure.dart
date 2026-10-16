/// Une multiplication posée en rectangle de jetons.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/question.dart';

/// Des jetons rangés en rectangle, et le produit qu'ils comptent.
///
/// Une table de multiplication s'apprend par cœur et ne se comprend pas
/// pour autant. Rangés en rectangle, les jetons rendent deux choses
/// visibles d'un coup : que 4 × 6 est bien quatre paquets de six, et que
/// tourner le rectangle d'un quart de tour donne 6 × 4 sans ajouter ni
/// retirer un seul jeton.
///
/// Le bouton qui échange les deux nombres existe pour cela : la
/// commutativité se démontre en comptant deux fois le même tas, pas en
/// retenant une règle.
class ArrayFigure extends StatefulWidget {
  const ArrayFigure({required this.accent, super.key});

  final Color accent;

  /// Nombre de jetons d'un rectangle de [lignes] sur [colonnes].
  static int produit(int lignes, int colonnes) => lignes * colonnes;

  /// Le produit, écrit comme une addition répétée.
  ///
  /// C'est la définition dont la multiplication est l'abréviation, et
  /// elle mérite d'être écrite en entier au moins une fois.
  static String addition(int lignes, int colonnes) =>
      List<String>.filled(lignes, '$colonnes').join(' + ');

  @override
  State<ArrayFigure> createState() => _ArrayFigureState();
}

class _ArrayFigureState extends State<ArrayFigure> {
  int _lignes = 4;
  int _colonnes = 6;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final int total = ArrayFigure.produit(_lignes, _colonnes);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AspectRatio(
          aspectRatio: 1.35,
          child: CustomPaint(
            painter: _JetonsPainter(
              lignes: _lignes,
              colonnes: _colonnes,
              accent: widget.accent,
              muted: tokens.inkMuted,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '$_lignes × $_colonnes = ${NumericQuestion.formatNumber(
            total.toDouble(),
          )}',
          style: AppTypography.formula(size: 20, color: widget.accent),
        ),
        Text(
          ArrayFigure.addition(_lignes, _colonnes),
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkMuted),
        ),
        const SizedBox(height: AppSpacing.xs),
        FilledButton.tonalIcon(
          onPressed: () {
            context.tapFeedback();
            setState(() {
              final int ancien = _lignes;
              _lignes = _colonnes;
              _colonnes = ancien;
            });
          },
          icon: const Icon(Icons.rotate_90_degrees_cw_rounded, size: 18),
          label: Text('Tourner : $_colonnes × $_lignes'),
        ),
        _Reglage(
          nom: 'lignes',
          valeur: _lignes,
          accent: widget.accent,
          onChanged: (int v) => setState(() => _lignes = v),
        ),
        _Reglage(
          nom: 'colonnes',
          valeur: _colonnes,
          accent: widget.accent,
          onChanged: (int v) => setState(() => _colonnes = v),
        ),
      ],
    );
  }
}

class _Reglage extends StatelessWidget {
  const _Reglage({
    required this.nom,
    required this.valeur,
    required this.accent,
    required this.onChanged,
  });

  final String nom;
  final int valeur;
  final Color accent;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 66,
          child: Text(
            nom,
            style: context.text.labelSmall?.copyWith(
              color: context.tokens.inkSubtle,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: valeur.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: (double v) {
              context.tapFeedback();
              onChanged(v.round());
            },
          ),
        ),
        SizedBox(
          width: 26,
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

class _JetonsPainter extends CustomPainter {
  const _JetonsPainter({
    required this.lignes,
    required this.colonnes,
    required this.accent,
    required this.muted,
  });

  final int lignes;
  final int colonnes;
  final Color accent;
  final Color muted;

  @override
  void paint(Canvas canvas, Size size) {
    const double marge = 14;
    final double pasX = (size.width - marge * 2) / 10;
    final double pasY = (size.height - marge * 2) / 10;
    // Un pas commun : les jetons doivent rester ronds et le rectangle
    // garder ses proportions quand on change les deux nombres.
    final double pas = math.min(pasX, pasY);
    final double rayon = pas * 0.32;

    final double largeur = pas * colonnes;
    final double hauteur = pas * lignes;
    final Offset coin = Offset(
      (size.width - largeur) / 2,
      (size.height - hauteur) / 2,
    );

    for (int i = 0; i < lignes; i++) {
      for (int j = 0; j < colonnes; j++) {
        canvas.drawCircle(
          coin + Offset(pas * (j + 0.5), pas * (i + 0.5)),
          rayon,
          Paint()..color = accent,
        );
      }
    }

    // Les deux comptages, en marge : le nombre de lignes à gauche, le
    // nombre de colonnes au-dessus.
    _texte(
      canvas,
      '$lignes lignes',
      Offset(coin.dx - 4, coin.dy + hauteur / 2),
      muted,
      vertical: true,
    );
    _texte(
      canvas,
      '$colonnes colonnes',
      Offset(coin.dx + largeur / 2, coin.dy - 11),
      muted,
    );
  }

  void _texte(
    Canvas canvas,
    String texte,
    Offset centre,
    Color couleur, {
    bool vertical = false,
  }) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: texte,
        style: TextStyle(
          fontFamily: AppTypography.body,
          color: couleur,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    if (vertical) canvas.rotate(-math.pi / 2);
    painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_JetonsPainter old) =>
      old.lignes != lignes ||
      old.colonnes != colonnes ||
      old.accent != accent;
}
