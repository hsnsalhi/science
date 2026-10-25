/// Une parabole dont on règle les trois coefficients.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import 'autoplay.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/question.dart';

/// La courbe de x ↦ ax² + bx + c, et ce que le discriminant annonce.
///
/// Le discriminant se présente d'ordinaire comme une formule à appliquer,
/// et son signe comme une règle à retenir. Ici on règle a, b et c, et on
/// voit la courbe monter ou descendre pendant que Δ change de signe : le
/// moment où elle décolle de l'axe est exactement celui où Δ devient
/// négatif. La règle cesse d'être arbitraire.
///
/// Le cas a = 0 est exclu du réglage : l'équation ne serait plus du
/// second degré, et la figure montrerait une droite en prétendant parler
/// de paraboles.
class ParabolaFigure extends StatefulWidget {
  const ParabolaFigure({required this.accent, super.key});

  final Color accent;

  /// Discriminant : b² − 4ac.
  static double discriminant(double a, double b, double c) => b * b - 4 * a * c;

  /// Racines réelles, dans l'ordre croissant. Vide si le discriminant
  /// est négatif.
  static List<double> racines(double a, double b, double c) {
    final double delta = discriminant(a, b, c);
    if (delta < 0) return const <double>[];
    if (delta == 0) return <double>[-b / (2 * a)];
    final double r = math.sqrt(delta);
    final List<double> deux = <double>[(-b - r) / (2 * a), (-b + r) / (2 * a)];
    deux.sort();
    return deux;
  }

  /// Sommet de la parabole.
  ///
  /// Son abscisse est le milieu des racines quand il y en a deux : la
  /// parabole est symétrique par rapport à la verticale qui le porte.
  static ({double x, double y}) sommet(double a, double b, double c) {
    final double x = -b / (2 * a);
    return (x: x, y: a * x * x + b * x + c);
  }

  @override
  State<ParabolaFigure> createState() => _ParabolaFigureState();
}

class _ParabolaFigureState extends State<ParabolaFigure> {
  double _a = 1;
  double _b = -1;
  double _c = -2;
  /// Vrai dès le premier geste : l'horloge rend la main pour de bon.
  bool _tenue = false;


  String _n(double v) =>
      NumericQuestion.formatNumber((v * 100).roundToDouble() / 100);

  /// L'expression, écrite comme on l'écrirait à la main.
  ///
  /// « 1x² + -1x + -2 » est lisible par une machine et par personne
  /// d'autre : les coefficients 1 disparaissent, et les signes se
  /// fondent dans l'écriture.
  String _polynome(double a, double b, double c) {
    final StringBuffer texte = StringBuffer();
    String facteur(double v) => v.abs() == 1 ? '' : _n(v.abs());

    texte.write(a < 0 ? '−' : '');
    texte.write('${facteur(a)}x²');
    if (b != 0) {
      texte.write(b < 0 ? ' − ' : ' + ');
      texte.write('${facteur(b)}x');
    }
    if (c != 0) {
      texte.write(c < 0 ? ' − ' : ' + ');
      texte.write(_n(c.abs()));
    }
    return texte.toString();
  }

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    // Seul c balaie : la courbe monte et descend sans changer de forme,
    // et les racines apparaissent, se confondent, puis disparaissent. Le
    // discriminant change de signe sous les yeux de l'élève, ce qui est
    // exactement ce que la figure a à montrer.
    final double a = _a;
    final double b = _b;
    final double c = _tenue
        ? _c
        : Autoplay.sweepPas(context, min: -6, max: 3, pas: 0.25) ?? _c;
    final double delta = ParabolaFigure.discriminant(a, b, c);
    final List<double> racines = ParabolaFigure.racines(a, b, c);

    final String verdict = switch (racines.length) {
      0 => 'Δ < 0 : aucune racine, la courbe ne touche pas l\'axe.',
      1 => 'Δ = 0 : une racine double, la courbe effleure l\'axe.',
      _ => 'Δ > 0 : deux racines, la courbe traverse l\'axe deux fois.',
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AspectRatio(
          aspectRatio: 1.15,
          child: CustomPaint(
            painter: _ParabolePainter(
              a: a,
              b: b,
              c: c,
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
          'y = ${_polynome(a, b, c)}',
          style: AppTypography.formula(size: 17, color: widget.accent),
        ),
        Text(
          'Δ = ${_n(delta)}'
          '${racines.isEmpty ? '' : '   ·   '
              'x = ${racines.map(_n).join('  et  ')}'}',
          style: AppTypography.formula(size: 15, color: context.colors.onSurface),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          verdict,
          textAlign: TextAlign.center,
          style: context.text.bodySmall?.copyWith(color: tokens.inkMuted),
        ),
        for (final (String nom, double valeur, double min, double max)
            in <(String, double, double, double)>[
          ('a', a, -3, 3),
          ('b', b, -6, 6),
          ('c', c, -6, 6),
        ])
          _Coefficient(
            nom: nom,
            valeur: valeur,
            min: min,
            max: max,
            accent: widget.accent,
            onChanged: (double v) => setState(() {
              _tenue = true;
              switch (nom) {
                case 'a':
                  // a = 0 donnerait une droite : on saute la valeur.
                  _a = v.abs() < 0.25 ? (v < 0 ? -0.25 : 0.25) : v;
                case 'b':
                  _b = v;
                default:
                  _c = v;
              }
            }),
          ),
      ],
    );
  }
}

class _Coefficient extends StatelessWidget {
  const _Coefficient({
    required this.nom,
    required this.valeur,
    required this.min,
    required this.max,
    required this.accent,
    required this.onChanged,
  });

  final String nom;
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
          width: 22,
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
            divisions: ((max - min) * 4).round(),
            onChanged: (double v) {
              context.tapFeedback();
              onChanged((v * 4).roundToDouble() / 4);
            },
          ),
        ),
        SizedBox(
          width: 42,
          child: Text(
            NumericQuestion.formatNumber(
              (valeur * 100).roundToDouble() / 100,
            ),
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

class _ParabolePainter extends CustomPainter {
  const _ParabolePainter({
    required this.a,
    required this.b,
    required this.c,
    required this.accent,
    required this.ink,
    required this.trait,
    required this.muted,
    required this.surface,
  });

  final double a;
  final double b;
  final double c;
  final Color accent;
  final Color ink;
  final Color trait;
  final Color muted;
  final Color surface;

  /// Demi-largeur de la fenêtre, en unités du repère.
  static const double portee = 7;

  @override
  void paint(Canvas canvas, Size size) {
    final double echelleX = size.width / (2 * portee);
    final double echelleY = size.height / (2 * portee);
    final Offset origine = Offset(size.width / 2, size.height / 2);

    Offset p(double x, double y) =>
        Offset(origine.dx + x * echelleX, origine.dy - y * echelleY);

    canvas.drawRect(Offset.zero & size, Paint()..color = surface);
    // Le repère est un cadre, pas une surface libre : sans découpe, les
    // branches de la parabole débordaient sur le texte de la leçon.
    canvas.clipRect(Offset.zero & size);

    // Quadrillage à l'unité : sans lui, on ne peut rien lire sur la
    // courbe, et les racines ne seraient que des points flottants.
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

    // La courbe, échantillonnée au pixel : on la coupe quand elle sort
    // du cadre, sinon le trait de retour barrerait le dessin.
    final Path courbe = Path();
    bool commence = false;
    for (int i = 0; i <= size.width.toInt(); i++) {
      final double x = -portee + 2 * portee * i / size.width;
      final double y = a * x * x + b * x + c;
      if (y.abs() > portee) {
        commence = false;
        continue;
      }
      final Offset point = p(x, y);
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

    // Les racines, là où la courbe coupe l'axe.
    for (final double racine in ParabolaFigure.racines(a, b, c)) {
      if (racine.abs() > portee) continue;
      final Offset point = p(racine, 0);
      canvas.drawCircle(point, 6, Paint()..color = surface);
      canvas.drawCircle(
        point,
        6,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = accent,
      );
    }

    // Le sommet, et l'axe de symétrie qui le porte.
    final ({double x, double y}) s = ParabolaFigure.sommet(a, b, c);
    if (s.x.abs() <= portee && s.y.abs() <= portee) {
      final Paint pointille = Paint()
        ..color = muted.withValues(alpha: 0.6)
        ..strokeWidth = 1.2;
      for (double y = -portee; y < portee; y += 0.5) {
        canvas.drawLine(p(s.x, y), p(s.x, y + 0.25), pointille);
      }
      canvas.drawCircle(p(s.x, s.y), 4.5, Paint()..color = muted);
      // Le libellé se place du côté où la parabole n'est pas : sous le
      // sommet quand elle s'ouvre vers le haut, au-dessus sinon.
      _texte(
        canvas,
        'sommet',
        p(s.x, s.y) + Offset(0, a > 0 ? 18 : -18),
        muted,
      );
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
          fontSize: 11,
          fontWeight: FontWeight.w700,
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
  bool shouldRepaint(_ParabolePainter old) =>
      old.a != a || old.b != b || old.c != c || old.accent != accent;
}
