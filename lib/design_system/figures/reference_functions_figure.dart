/// Les fonctions de référence, sur un même repère.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/question.dart';

/// Une fonction de référence du programme de seconde.
enum FonctionReference {
  carre('x²', 'le carré'),
  cube('x³', 'le cube'),
  racine('√x', 'la racine carrée'),
  inverse('1/x', 'l’inverse'),
  absolue('|x|', 'la valeur absolue');

  const FonctionReference(this.etiquette, this.nom);

  /// Ce qui s'écrit sur la puce de sélection.
  final String etiquette;

  /// Le nom de la fonction, en toutes lettres.
  final String nom;

  /// L'image de [x], ou `null` si la fonction n'y est pas définie.
  ///
  /// Rendre `null` plutôt qu'une valeur infinie ou zéro est ce qui permet
  /// à la figure de couper la courbe au bon endroit — et à l'élève de voir
  /// que 1/x et √x ne sont pas définies partout.
  double? image(double x) => switch (this) {
    FonctionReference.carre => x * x,
    FonctionReference.cube => x * x * x,
    FonctionReference.racine => x < 0 ? null : math.sqrt(x),
    FonctionReference.inverse => x == 0 ? null : 1 / x,
    FonctionReference.absolue => x.abs(),
  };
}

/// Cinq courbes de référence, et le point qu'on promène dessus.
///
/// Les fonctions de référence s'apprennent d'ordinaire comme cinq dessins
/// à mémoriser. Ici on promène un point sur la courbe et on lit ses deux
/// coordonnées : la parité se voit en comparant x et son opposé, le sens
/// de variation en déplaçant le point, et le domaine de définition se
/// manifeste tout seul — la courbe s'arrête, et la lecture affiche que la
/// fonction n'est pas définie là.
///
/// Les cinq sont dessinées sur le même repère, à la même échelle. C'est ce
/// qui permet de les comparer : à droite de 1, le cube monte plus vite que
/// le carré, qui monte plus vite que la racine. Présentées sur cinq
/// vignettes séparées, elles se ressemblent toutes.
class ReferenceFunctionsFigure extends StatefulWidget {
  const ReferenceFunctionsFigure({required this.accent, super.key});

  final Color accent;

  /// Demi-largeur de la fenêtre, en unités du repère.
  static const double portee = 4;

  /// Les abscisses proposées par le curseur.
  static const double pas = 0.25;

  /// La fonction est-elle définie en [x] ?
  static bool definieEn(FonctionReference f, double x) => f.image(x) != null;

  @override
  State<ReferenceFunctionsFigure> createState() =>
      _ReferenceFunctionsFigureState();
}

class _ReferenceFunctionsFigureState extends State<ReferenceFunctionsFigure> {
  FonctionReference _fonction = FonctionReference.carre;
  double _x = 1.5;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final double? y = _fonction.image(_x);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            for (final FonctionReference f in FonctionReference.values)
              ChoiceChip(
                selected: f == _fonction,
                label: Text(
                  f.etiquette,
                  style: AppTypography.formula(
                    size: 14,
                    color: f == _fonction
                        ? widget.accent
                        : context.colors.onSurface,
                  ),
                ),
                onSelected: (bool _) {
                  context.tapFeedback();
                  setState(() => _fonction = f);
                },
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AspectRatio(
          aspectRatio: 1.15,
          child: CustomPaint(
            painter: _CourbePainter(
              fonction: _fonction,
              x: _x,
              accent: widget.accent,
              ink: context.colors.onSurface,
              trait: tokens.border,
              muted: tokens.inkMuted,
              surface: context.colors.surface,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          y == null
              ? '${_fonction.nom} n’est pas définie en '
                    '${NumericQuestion.formatNumber(_x)}'
              : 'x = ${NumericQuestion.formatNumber(_x)}   '
                    'f(x) = ${NumericQuestion.formatNumber(
                      (y * 100).roundToDouble() / 100,
                    )}',
          textAlign: TextAlign.center,
          style: AppTypography.formula(
            size: 15,
            color: y == null ? tokens.error : widget.accent,
          ),
        ),
        Slider(
          value: _x,
          min: -ReferenceFunctionsFigure.portee,
          max: ReferenceFunctionsFigure.portee,
          divisions:
              (2 * ReferenceFunctionsFigure.portee /
                      ReferenceFunctionsFigure.pas)
                  .round(),
          onChanged: (double v) {
            context.tapFeedback();
            setState(() {
              _x =
                  (v / ReferenceFunctionsFigure.pas).roundToDouble() *
                  ReferenceFunctionsFigure.pas;
            });
          },
        ),
      ],
    );
  }
}

class _CourbePainter extends CustomPainter {
  const _CourbePainter({
    required this.fonction,
    required this.x,
    required this.accent,
    required this.ink,
    required this.trait,
    required this.muted,
    required this.surface,
  });

  final FonctionReference fonction;
  final double x;
  final Color accent;
  final Color ink;
  final Color trait;
  final Color muted;
  final Color surface;

  static const double portee = ReferenceFunctionsFigure.portee;

  @override
  void paint(Canvas canvas, Size size) {
    final double echelleX = size.width / (2 * portee);
    final double echelleY = size.height / (2 * portee);
    final Offset origine = Offset(size.width / 2, size.height / 2);

    Offset p(double a, double b) =>
        Offset(origine.dx + a * echelleX, origine.dy - b * echelleY);

    canvas.drawRect(Offset.zero & size, Paint()..color = surface);
    canvas.clipRect(Offset.zero & size);

    final Paint grille = Paint()
      ..color = trait.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    for (int i = -portee.toInt(); i <= portee.toInt(); i++) {
      canvas.drawLine(p(i.toDouble(), -portee), p(i.toDouble(), portee), grille);
      canvas.drawLine(p(-portee, i.toDouble()), p(portee, i.toDouble()), grille);
    }
    final Paint axes = Paint()
      ..color = ink.withValues(alpha: 0.6)
      ..strokeWidth = 1.8;
    canvas.drawLine(p(-portee, 0), p(portee, 0), axes);
    canvas.drawLine(p(0, -portee), p(0, portee), axes);

    // La courbe, échantillonnée au pixel. Le trait s'interrompt là où la
    // fonction n'est pas définie, et là où elle sort du cadre : sans cela
    // l'inverse serait reliée d'une branche à l'autre, ce qui est
    // exactement le contresens à éviter.
    final Path courbe = Path();
    bool commence = false;
    for (int i = 0; i <= size.width.toInt(); i++) {
      final double a = -portee + 2 * portee * i / size.width;
      final double? b = fonction.image(a);
      if (b == null || b.abs() > portee) {
        commence = false;
        continue;
      }
      final Offset point = p(a, b);
      if (!commence) {
        courbe.moveTo(point.dx, point.dy);
        commence = true;
      } else {
        courbe.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(
      courbe,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = accent,
    );

    // Le point courant, et les deux pointillés qui donnent ses
    // coordonnées : la lecture d'un graphique s'apprend en la voyant.
    final double? y = fonction.image(x);
    if (y != null && y.abs() <= portee) {
      final Paint pointille = Paint()
        ..color = muted.withValues(alpha: 0.7)
        ..strokeWidth = 1.2;
      for (double t = 0; t < y.abs(); t += 0.4) {
        final double debut = y >= 0 ? t : -t;
        final double fin = y >= 0 ? math.min(t + 0.2, y) : math.max(-t - 0.2, y);
        canvas.drawLine(p(x, debut), p(x, fin), pointille);
      }
      for (double t = 0; t < x.abs(); t += 0.4) {
        final double debut = x >= 0 ? t : -t;
        final double fin = x >= 0 ? math.min(t + 0.2, x) : math.max(-t - 0.2, x);
        canvas.drawLine(p(debut, y), p(fin, y), pointille);
      }
      canvas.drawCircle(p(x, y), 6, Paint()..color = surface);
      canvas.drawCircle(
        p(x, y),
        6,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = accent,
      );
    } else {
      // Non définie : on marque l'abscisse sur l'axe plutôt que de ne
      // rien montrer, pour que le curseur ne paraisse pas cassé.
      final Paint croix = Paint()
        ..color = muted
        ..strokeWidth = 2;
      final Offset c = p(x, 0);
      canvas.drawLine(c + const Offset(-5, -5), c + const Offset(5, 5), croix);
      canvas.drawLine(c + const Offset(-5, 5), c + const Offset(5, -5), croix);
    }
  }

  @override
  bool shouldRepaint(_CourbePainter old) =>
      old.fonction != fonction || old.x != x || old.accent != accent;
}
