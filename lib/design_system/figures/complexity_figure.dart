/// Ce que coûtent les algorithmes quand les données grossissent.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/question.dart';

/// Une classe de complexité, avec son coût et sa couleur.
enum Complexite {
  logarithmique('log n', Color(0xFF16A34A)),
  lineaire('n', Color(0xFF2563EB)),
  quasiLineaire('n log n', Color(0xFF7C3AED)),
  quadratique('n²', Color(0xFFEA580C)),
  // « 2^n » plutôt que l'exposant en lettre supérieure : ce
  // caractère manque aux polices du projet et s'affichait en carré.
  exponentielle('2^n', Color(0xFFDC2626));

  const Complexite(this.etiquette, this.couleur);

  final String etiquette;
  final Color couleur;

  /// Nombre d'opérations pour une entrée de taille [n].
  ///
  /// On compte les opérations élémentaires, sans constante devant :
  /// c'est tout l'objet de la notation, et c'est aussi pourquoi
  /// comparer deux algorithmes sur de petites entrées ne veut rien dire.
  double operations(double n) => switch (this) {
    Complexite.logarithmique => math.max(1, math.log(n) / math.ln2),
    Complexite.lineaire => n,
    Complexite.quasiLineaire => n * math.max(1, math.log(n) / math.ln2),
    Complexite.quadratique => n * n,
    Complexite.exponentielle => math.pow(2, n).toDouble(),
  };
}

/// Cinq courbes de coût, et ce qu'elles donnent en temps réel.
///
/// Une table de complexités se lit en deux minutes et ne frappe
/// personne. Ce qui frappe, c'est de pousser le curseur à soixante et de
/// voir « 36 000 ans » s'afficher pour un algorithme qui, à vingt,
/// répondait en une milliseconde. L'écart entre n² et 2ⁿ n'est pas une
/// nuance de notation : c'est la différence entre un programme qu'on
/// peut lancer et un programme qu'on ne lancera jamais.
///
/// L'échelle verticale est logarithmique. Sur une échelle ordinaire,
/// quatre des cinq courbes seraient collées à l'axe horizontal.
class ComplexityFigure extends StatefulWidget {
  const ComplexityFigure({required this.accent, super.key});

  final Color accent;

  /// Opérations par seconde d'une machine ordinaire : un milliard.
  static const double operationsParSeconde = 1e9;

  /// Durée, en secondes, pour effectuer [operations] opérations.
  static double secondes(double operations) =>
      operations / operationsParSeconde;

  /// La même durée, écrite comme on la dirait.
  static String dureeLisible(double secondes) {
    if (secondes < 1e-6) return 'instantané';
    if (secondes < 1e-3) {
      return '${(secondes * 1e6).round()} µs';
    }
    if (secondes < 1) return '${(secondes * 1e3).round()} ms';
    if (secondes < 60) {
      return '${NumericQuestion.formatNumber(
        (secondes * 10).roundToDouble() / 10,
      )} s';
    }
    if (secondes < 3600) return '${(secondes / 60).round()} min';
    if (secondes < 86400) return '${(secondes / 3600).round()} h';
    if (secondes < 31557600) {
      final int jours = (secondes / 86400).round();
      return '$jours jour${jours > 1 ? 's' : ''}';
    }
    final double annees = secondes / 31557600;
    // En dessous de dix ans, l'arrondi à l'unité ferait écrire « 1 an »
    // pour quatorze mois : on garde une décimale.
    if (annees < 10) {
      final double arrondi = (annees * 10).roundToDouble() / 10;
      return '${NumericQuestion.formatNumber(arrondi)} '
          'an${arrondi >= 2 ? 's' : ''}';
    }
    if (annees < 1e6) {
      return '${NumericQuestion.formatNumber(annees.roundToDouble())} ans';
    }
    if (annees < 1e9) {
      return '${NumericQuestion.formatNumber(
        (annees / 1e6).roundToDouble(),
      )} millions d\'années';
    }
    return '${NumericQuestion.formatNumber(
      (annees / 1e9).roundToDouble(),
    )} milliards d\'années';
  }

  @override
  State<ComplexityFigure> createState() => _ComplexityFigureState();
}

class _ComplexityFigureState extends State<ComplexityFigure> {
  double _n = 20;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AspectRatio(
          aspectRatio: 1.25,
          child: CustomPaint(
            painter: _CourbesPainter(
              n: _n,
              trait: tokens.border,
              muted: tokens.inkMuted,
              ink: context.colors.onSurface,
              surface: context.colors.surface,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Nombre d\'opérations pour n = '
          '${NumericQuestion.formatNumber(_n.roundToDouble())}, '
          'à un milliard d\'opérations par seconde',
          textAlign: TextAlign.center,
          style: context.text.labelSmall?.copyWith(color: tokens.inkSubtle),
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final Complexite c in Complexite.values)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(
              children: <Widget>[
                Container(
                  width: 12,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.couleur,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 56,
                  child: Text(
                    c.etiquette,
                    style: AppTypography.formula(size: 14, color: c.couleur),
                  ),
                ),
                Expanded(
                  child: Text(
                    ComplexityFigure.dureeLisible(
                      ComplexityFigure.secondes(c.operations(_n)),
                    ),
                    textAlign: TextAlign.right,
                    style: context.text.bodySmall?.copyWith(
                      color: context.colors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Slider(
          value: _n,
          min: 2,
          max: 70,
          divisions: 68,
          onChanged: (double v) {
            context.tapFeedback();
            setState(() => _n = v.roundToDouble());
          },
        ),
        Text(
          'Fais grossir la taille des données',
          style: context.text.labelSmall?.copyWith(color: tokens.inkSubtle),
        ),
      ],
    );
  }
}

class _CourbesPainter extends CustomPainter {
  const _CourbesPainter({
    required this.n,
    required this.trait,
    required this.muted,
    required this.ink,
    required this.surface,
  });

  final double n;
  final Color trait;
  final Color muted;
  final Color ink;
  final Color surface;

  /// Taille maximale portée par l'axe horizontal.
  static const double nMax = 70;

  /// Exposant maximal porté par l'axe vertical : 10²⁰ opérations.
  static const double exposantMax = 20;

  @override
  void paint(Canvas canvas, Size size) {
    const double margeGauche = 30;
    const double margeBas = 20;
    final Rect cadre = Rect.fromLTRB(
      margeGauche,
      8,
      size.width - 6,
      size.height - margeBas,
    );

    canvas.drawRect(cadre, Paint()..color = surface);
    canvas.save();
    canvas.clipRect(cadre);

    Offset p(double taille, double operations) {
      final double y = math.log(math.max(operations, 1)) / math.ln10;
      return Offset(
        cadre.left + cadre.width * taille / nMax,
        cadre.bottom - cadre.height * (y / exposantMax).clamp(0.0, 1.0),
      );
    }

    // Repères décimaux : chaque trait vaut mille fois le précédent.
    for (int e = 0; e <= exposantMax.toInt(); e += 5) {
      final Offset point = p(0, math.pow(10, e).toDouble());
      canvas.drawLine(
        Offset(cadre.left, point.dy),
        Offset(cadre.right, point.dy),
        Paint()
          ..color = trait.withValues(alpha: 0.5)
          ..strokeWidth = 1,
      );
    }

    for (final Complexite c in Complexite.values) {
      final Path courbe = Path();
      bool commence = false;
      for (int i = 0; i <= 140; i++) {
        final double taille = 2 + (nMax - 2) * i / 140;
        final double ops = c.operations(taille);
        // Au-delà du cadre, on cesse de tracer : prolonger la courbe à
        // plat au sommet laisserait croire que la croissance s'arrête.
        if (math.log(ops) / math.ln10 > exposantMax) break;
        final Offset point = p(taille, ops);
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
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..color = c.couleur,
      );
      // Le point atteint pour la taille réglée, s'il tient dans le
      // cadre.
      if (math.log(c.operations(n)) / math.ln10 <= exposantMax) {
        canvas.drawCircle(p(n, c.operations(n)), 4, Paint()..color = c.couleur);
      }
    }

    // La verticale de la taille courante.
    canvas.drawLine(
      Offset(p(n, 1).dx, cadre.top),
      Offset(p(n, 1).dx, cadre.bottom),
      Paint()
        ..color = ink.withValues(alpha: 0.35)
        ..strokeWidth = 1.5,
    );
    canvas.restore();

    canvas.drawRect(
      cadre,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = trait,
    );

    // Graduations : la verticale en puissances de dix, l'horizontale en
    // tailles de données.
    for (int e = 0; e <= exposantMax.toInt(); e += 5) {
      final double y = cadre.bottom - cadre.height * (e / exposantMax);
      _texte(canvas, e == 0 ? '1' : '10^$e', Offset(margeGauche / 2 + 2, y),
          muted);
    }
    for (final int taille in <int>[10, 30, 50, 70]) {
      _texte(
        canvas,
        '$taille',
        Offset(cadre.left + cadre.width * taille / nMax, cadre.bottom + 10),
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
          color: couleur,
          fontSize: 9,
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
  bool shouldRepaint(_CourbesPainter old) => old.n != n;
}
